/*********************************************************************************************************
	Author        :  Vipul Chaudahari
	Description   :  Set Contact Outreach Stage When Journey Outreach_Stage__c change
	Issue No.     :  ST-8958
-----------------------------------------------------------------------------------------------------------
	VERSION        DATE             AUTHOR             DETAIL
	1          09-Sept-2021     Vipul Chaudhari     Trigger Refactor
**********************************************************************************************************/
public class JourneySetContactOutreachStageTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Journey__c> newJourneys;
    @TestVisible
    private Map<Id, Journey__c> oldJourneysMap;
    public JourneySetContactOutreachStageTrH() {
        this(
            (List<Journey__c>) Trigger.new,
            (Map<Id, Journey__c>) Trigger.oldMap
        );
    }
    @TestVisible
    private JourneySetContactOutreachStageTrH(List<Journey__c> newJourney, Map<Id, Journey__c> oldJourneyMap) {
        this.newJourneys = newJourney;
        this.oldJourneysMap = oldJourneyMap;
        
    }
    public override void afterInsert() {
        setContactOutreachStageWhenJourneyStatusChange();
    }
    public override void afterUpdate() {
        setContactOutreachStageWhenJourneyStatusChange();
    }
    private void setContactOutreachStageWhenJourneyStatusChange() {
        Set<String> journeyStage = new Set<String>{'Manual Outreach','NMD Drip'};          
        List<Contact> contactsToUpdate = new List<Contact>();
        for(Journey__c journey : newJourneys) {           
            Journey__c oldJourney =  oldJourneysMap?.get(journey.Id);
            if(String.isNotBlank(journey.Outreach_Stage__c) && journeyStage.contains(journey.Outreach_Stage__c) 
               && String.isNotBlank(journey.Primary_Contact__c) && (oldJourney == null || (oldJourney != null 
               && TriggerUtility.isFieldValueChanged(journey, oldJourney,'Outreach_Stage__c')))) {
                Contact contact = new Contact(Id = journey.Primary_Contact__c, Outreach_Stage__c = journey.Outreach_Stage__c);
                contactsToUpdate.add(contact);
            }
        }
        if(!contactsToUpdate.isEmpty()) {
            dml.add(contactsToUpdate, DmlConsolidator.Operation.FOR_UPDATE);
        }
    }
}