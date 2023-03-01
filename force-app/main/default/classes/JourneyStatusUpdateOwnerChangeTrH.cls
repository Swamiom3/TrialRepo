/*********************************************************************************************************
	Author        :  Ishwar Shinde
	Description   :  This class is used to Update Journey Status on Change of Journey Owner.
	Issue No.     :  TWSPG-12475
	History       :
-----------------------------------------------------------------------------------------------------------
	VERSION        DATE            AUTHOR             DETAIL
	1          15-June-2022      Ishwar Shinde     Initial Developement
**********************************************************************************************************/
public class JourneyStatusUpdateOwnerChangeTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Journey__c> newJourneys;
    @TestVisible
    private Map<Id, Journey__c> oldJourneys;
    @TestVisible 
    private static final String STATUS_TO_UPDATE = 'Accepted';
    @TestVisible 
    private static String STATUS_FOR_TEST = '';
    
    public JourneyStatusUpdateOwnerChangeTrH(){
        this((List<Journey__c>) Trigger.new, (Map<Id, Journey__c>) Trigger.oldMap);
    }
    
    @TestVisible
    private JourneyStatusUpdateOwnerChangeTrH(List<Journey__c> newJourneys, Map<Id, Journey__c> oldJourneys){
        this.newJourneys = newJourneys;
        this.oldJourneys = oldJourneys;
    }
    
    public override void beforeUpdate(){
        updateJourneyStatusOwnerChangeQueueToUser();
    }
    
    @TestVisible
    private void updateJourneyStatusOwnerChangeQueueToUser() {
        Set<String> journeyCloseStages = (Set<String>) JSON.deserialize(MetadataSetting__mdt.getInstance('ClosedJourneyStages').Data__c, Set<String>.class);
        System.debug('journeyCloseStages ' + journeyCloseStages);
        for(Journey__c journey : newJourneys){
            Journey__c oldJourney = (Journey__c)oldJourneys.get(journey.Id);
            if(TriggerUtility.isFieldValueChanged(journey, oldJourney, 'OwnerId') && String.valueOf(journey.OwnerId).startsWith('005') && String.valueOf(oldJourney.OwnerId).startsWith('00G') && !journeyCloseStages.contains(journey.Status__c)){
                journey.Status__c = STATUS_TO_UPDATE; 
                STATUS_FOR_TEST = journey.Status__c;
            }
        }
    }
}