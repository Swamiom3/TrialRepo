/*********************************************************************************************************
	Author        :  Vipul Chaudahari
	Description   :  If Journey's Primary Lead or Primary Contact has more than 1 active journey then 
                     set "Has Active Journey" checkbox to true.
	Issue No.     :  ST-8958
-----------------------------------------------------------------------------------------------------------
	VERSION        DATE             AUTHOR             DETAIL
	1          09-Sept-2021     Vipul Chaudhari     Trigger Refactor
**********************************************************************************************************/
public class JourneyUpdateHasActiveJourneyTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Journey__c> newJourneys;
    @TestVisible
    private Map<Id, Journey__c> oldJourneysMap;
    @TestVisible
    private List<Sobject> sObjectToUpdate = new List<Sobject>();

    public JourneyUpdateHasActiveJourneyTrH() {
        this((List<Journey__c>) trigger.new, (Map<Id, Journey__c>) trigger.oldMap);
    }
    
    @TestVisible
    private JourneyUpdateHasActiveJourneyTrH(List<Journey__c> newJourney, Map<Id, Journey__c> oldJourneyMap) {
        this.newJourneys = newJourney;
        this.oldJourneysMap = oldJourneyMap;
    }
    
    public override void afterInsert() {
        updateHasActiveJourneyField();
    }

    public override void afterUpdate() {
        updateHasActiveJourneyField();
    }

    private void updateHasActiveJourneyField() {
        set<Id> contactId = new set<Id>();
        set<Id> leadId = new set<Id>();
        for(Journey__c journey :  newJourneys) {
            Journey__c oldJourney = oldJourneysMap?.get(journey.Id);
            if(oldJourney == null || (oldJourney != null 
                                      && ((String.isNotBlank(journey.Status__c) && String.isNotBlank(oldJourney.Status__c) != null 
                                           && TriggerUtility.isFieldValueChanged(journey, oldJourney, 'Status__c')) 
                                          || (String.isNotBlank(journey.Primary_Lead__c) && String.isNotBlank(oldJourney.Primary_Lead__c) 
                                              && TriggerUtility.isFieldValueChanged(journey, oldJourney, 'Primary_Lead__c'))))) {
                if(String.isNotBlank(journey.Primary_Contact__c)) {
                    contactId.add(journey.Primary_Contact__c);
                }else if(String.isNotBlank(journey.Primary_Lead__c)) {
                    leadId.add(journey.Primary_Lead__c);
                }
            }
        }
        Set<String> journeyClosedStages  = LeadRoutingHelper.getJourneyClosedStages();
        if(journeyClosedStages.isEmpty()){
            return;
        }
        if(!contactId.isEmpty()) {
            for(Contact contact : [SELECT Id, OwnerId,
                                        (SELECT Id, OwnerId, CreatedDate, Status__c 
                                        FROM Journeys__r 
                                        WHERE Status__c NOT IN :journeyClosedStages LIMIT 1) 
                                   FROM Contact 
                                   WHERE Id IN : contactId]) {
                Integer count = 0;
                for(Journey__c journey : contact.Journeys__r){
                    count++;
                }
                if(count > 0){
                    sObjectToUpdate.add(new Contact(Id = contact.Id));
                }
            }
        }
        
        if(!leadId.isEmpty()){
            for(Lead lead : [SELECT Id, OwnerId, Has_Active_Journey__c,
                                    (SELECT Id, OwnerId, CreatedDate, Status__c 
                                    FROM Journeys__r 
                                    WHERE Status__c NOT IN :journeyClosedStages LIMIT 1) 
                             FROM Lead 
                             WHERE Id IN : leadId]){
                Integer count = 0;
                for(Journey__c journey : lead.Journeys__r){
                    count++;
                }
                if(count > 0){
                    sObjectToUpdate.add(new Lead(Id = lead.Id, Has_Active_Journey__c = true));
                }else if(lead.Has_Active_Journey__c){
                    sObjectToUpdate.add(new Lead(Id = lead.Id, Has_Active_Journey__c = false));
                }
            }              
        }
        
        if(!sObjectToUpdate.isEmpty()){
            dml.add(sObjectToUpdate, DmlConsolidator.Operation.FOR_UPDATE);
        }
    }
}