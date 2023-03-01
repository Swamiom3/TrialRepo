/************************************************************************************************************************************
	Author		: 	Nikhil Mehta
	Description	: 	This Queueable class insert Geography to related to Building.
	----------------------------------------------------------------------------------------------------------------------------------
	VERSION		DATE	        	AUTHOR                     DETAIL
	1	    	4 December 2018		Nikhil Mehta               Initial Developement
    2           04 August 2021      Oleg Krasko                Refactoring
**************************************************************************************************************************************/
public class QueueInsertGeographyForBuilding implements Queueable, Database.AllowsCallouts, Callable {
    public List<Building__c> newBuildings;
    public Integer maxCallouts;
    private Integer counter = 0;
    @TestVisible
    private GeographySelector geographySelector = new GeographySelector();

    public QueueInsertGeographyForBuilding() {}

    public QueueInsertGeographyForBuilding(List<Building__c> newBuildings){
        this.newBuildings = newBuildings;
        this.maxCallouts = newBuildings.size();
    }

    public QueueInsertGeographyForBuilding(List<Building__c> newBuildings, Integer counter){
        this(newBuildings);
        this.counter = counter;
    }

    public QueueInsertGeographyForBuilding call(String action, Map<String, Object> args) {
        if((Integer)args.get('counter') != null) {
            return new QueueInsertGeographyForBuilding((List<Building__c>)args.get('buildings'), (Integer)args.get('counter'));
        } else {
            return new QueueInsertGeographyForBuilding((List<Building__c>)args.get('buildings'));
        }
    }
    /************************************************************************************************************************************
        Author              :   Nikhil Mehta
        Description         :   This method insert geography record for Building.
		Last Modified By	:	Nikhil Mehta
        Last Modified Date  :   04 December 2018
    **************************************************************************************************************************************/    
    public void execute(QueueableContext context) {
        try{
            if(newBuildings?.isEmpty() != false){
                return;
            }
            Building__c building = newBuildings[counter];
            Map<String, String> addressMap = new Map<String, String>();
            addressMap.put('address', building.Address__c);
            addressMap.put('city', building.City__c);
            addressMap.put('state', building.State__c);
            addressMap.put('country', building.Country__c);
            Geography__c geographyRec = new GeographyHandler().getGeography(addressMap);
            if(String.isEmpty(geographyRec.Id)){
                geographyRec.Nearest_Building__c = building.Id;
                Database.insert(geographyRec, false);
            }
            if(geographyRec.Id != null){
                Building__c newBuilding = new Building__c(Id = building.Id, Geography__c = geographyRec.Id);
                update newBuilding;
                List<Geography__c> geographies = new List<Geography__c>(geographySelector.getGeographiesById(geographyRec.Id));

                if(!geographies.isEmpty()){
                    Geography__c newGeographyRec = geographies[0];
                    Geography__c nearestGeographyRec = newGeographyRec.Nearest_Building__r.Geography__r;
                    if(building != null && nearestGeographyRec != null){
                        List<Geography__c> nearestBuildingGeographies = (geographySelector.getGeographiesByNearestBuilding(nearestGeographyRec.Nearest_Building__c));
                        if(!nearestBuildingGeographies.isEmpty()){
                            List<Geography__c> geographiesToUpdate = new List<Geography__c>();
                            System.Location newGeographyRecLocation = System.Location.newInstance(newGeographyRec.Geocode__Latitude__s, newGeographyRec.Geocode__Longitude__s);
                            System.Location nearestGeographyRecLocation = System.Location.newInstance(nearestGeographyRec.Geocode__Latitude__s, nearestGeographyRec.Geocode__Longitude__s);
                            System.Location geographyLocation;
                            for(Geography__c nearestBuildingGeographyRec : nearestBuildingGeographies){
                                geographyLocation = System.Location.newInstance(nearestBuildingGeographyRec.Geocode__Latitude__s, nearestBuildingGeographyRec.Geocode__Longitude__s);
                                if(System.Location.getDistance(geographyLocation, newGeographyRecLocation, 'mi') < System.Location.getDistance(geographyLocation, nearestGeographyRecLocation, 'mi')){
                                    nearestBuildingGeographyRec.Building_Updated_Date__c = System.now();
                                    nearestBuildingGeographyRec.Previous_Building__c = nearestGeographyRec.Nearest_Building__c;
                                    nearestBuildingGeographyRec.Nearest_Building__c = building.Id;
                                    geographiesToUpdate.add(nearestBuildingGeographyRec);
                                }
                            }
                            if(!geographiesToUpdate.isEmpty()){
                                Database.update(geographiesToUpdate, false);
                            }
                        }
                    }
                }
            }
            counter += 1;
            if(maxCallouts > counter && !Test.isRunningTest()) {
                AsyncsExecutor asyncsExecutor = new AsyncsExecutor(QueueInsertGeographyForBuilding.class,
                        new Map<String, Object>{
                                'buildings' => newBuildings,
                                'counter' => counter
                        });
                asyncsExecutor.execute();
            }
        } catch(Exception pEx) {
            new ApexDebugLog().createLog( 
                new ApexDebugLog.Error('QueueInsertGeographyForBuilding','execute',null,pEx)
            );
            throw new QueueInsertGeographyForBuildingException(pEx.getMessage());
        }
    }
    
    public class QueueInsertGeographyForBuildingException extends Exception{}
}