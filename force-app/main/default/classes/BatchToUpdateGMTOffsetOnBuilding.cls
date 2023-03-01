/************************************************************************************************************************************
	Author		: 	Rohit Nimase
	Description	: 	This batch class used to update GMTOffset on Building according to daylight savings.
	----------------------------------------------------------------------------------------------------------------------------------
	VERSION		DATE	        		AUTHOR                     	DETAIL
	1	    	12 Feb 2020				Rohit Nimase             	Initial Developement
**************************************************************************************************************************************/
public class BatchToUpdateGMTOffsetOnBuilding implements Database.Batchable<sObject>, Schedulable, Database.stateful {

    Boolean updateAllGMTOffset = false;
    public Set<String> dSTTimezones = new set<String>();
    public Set<String> noDSTTimezones = new set<String>();
    @TestVisible
    private BuildingSelector buildSelector = new BuildingSelector();
   
  /************************************************************************************************************************************
        Author              :   Rohit Nimase
        Description         :   Constructor used to initialize metadata and find records to update the GMTOffset.
        Created Date  		:   12 Feb 2020	
		Issue No.			:	ST-5593, ST-5705
  **************************************************************************************************************************************/ 
    public BatchToUpdateGMTOffsetOnBuilding(){        
        this.initializeMetadata();
    }
    
    public void execute(SchedulableContext SC) {
        Database.executeBatch(new BatchToUpdateGMTOffsetOnBuilding(), 100); 
    }
    
    public void initializeMetadata(){
        DayLightOffsetSetting dayLightOffsetSetting;
        MetadataSetting__mdt objMetadataSetting = Settings.getMetadataSettingByDevName('Daylight_Offset_Metadata');
        if(objMetadataSetting != NULL && String.isNotBlank(objMetadataSetting.Data__c)){
            dayLightOffsetSetting = (DayLightOffsetSetting)JSON.deserialize(objMetadataSetting.Data__c, DayLightOffsetSetting.class);            
            if(dayLightOffsetSetting != NULL){
                updateAllGMTOffset = Boolean.valueOf(dayLightOffsetSetting.updateAllGMTOffset);
                dSTTimezones = dayLightOffsetSetting.dSTTimezones;
                if(updateAllGMTOffset){
                    noDSTTimezones = dayLightOffsetSetting.noDSTTimezones;
                }
            }
        }        
    } 
    
  /************************************************************************************************************************************
        Author              :   Rohit Nimase
        Description         :   This method quries the records on which we need to update GMTOffset.
        Created Date  		:   12 Feb 2020	
		Issue No.			:	ST-5593, ST-5705
  **************************************************************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext BC){ 
		return Database.getQueryLocator(buildSelector.getQueryLocatorForGMTOffset(dSTTimezones, noDSTTimezones));
    }  
    
   /************************************************************************************************************************************
        Author              :   Rohit Nimase
        Description         :   Execute method processes the records according to batch size and updates the GMTOffset on buildings.
        Created Date  		:   12 Feb 2020	
		Issue No.			:	ST-5593, ST-5705
   **************************************************************************************************************************************/
    public void execute(Database.BatchableContext BC, List<sObject> lstRecords){
        List<Building__c> lstBuildingsToUpdate = new List<Building__c>();
        for(Building__c objBuild : (List<Building__c>)lstRecords){
            if(String.isNotBlank(objBuild.Time_Zone__c)){
                Timezone objTimezone = Timezone.getTimeZone(String.valueOf(objBuild.Time_Zone__c));
                Decimal GMTOffset = Decimal.valueOf(objTimezone.getOffset(DateTime.now())).divide(3600000, 2);
                
                if(objBuild.GMT_Offset__c != GMTOffset){
                    objBuild.GMT_Offset__c = GMTOffset;
                    lstBuildingsToUpdate.add(objBuild);
                }
            }
        }
        if(!lstBuildingsToUpdate.isEmpty()){
            Database.SaveResult[] results = Database.update(lstBuildingsToUpdate, false);
            for(Database.SaveResult objResult : results){
                if(!objResult.isSuccess()){
                    for(Database.Error err : objResult.getErrors()){
                        ApexDebugLog.logException(new buildingGMTOffsetUpdateException(err.getMessage()), String.valueOf(err.getStatusCode()), 'BatchToUpdateGMTOffsetOnBuilding', 'execute_nopush');
                    }
                }
            }
        }
    }
    
    public void finish(Database.BatchableContext BC){} 
    
    public class DayLightOffsetSetting{
        public String updateAllGMTOffset{get; set;}
        public Set<String> dSTTimezones{get; set;}
        public Set<String> noDSTTimezones{get; set;}
    }
    public class buildingGMTOffsetUpdateException extends Exception{}
    
}