/*********************************************************************************************************
    Author        :  Shobhit Gahlot
    Description   :  New Journey inserted or old journey status changes to MQL then fields 'Journey Created On' 
                     and 'MQL Identified On' gets updated on Lead and Contact respectively.  
    Issue No.     :  ST-8957
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1          09-Sept-2021      Shobhit Gahlot     Trigger Refactor
**********************************************************************************************************/
public class JourneyManageContactAndLeadTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Journey__c> newJourneys;
    @TestVisible
    private Map<Id, Journey__c> oldJourneys;
    @TestVisible
    Map<Id, Lead> leadToUpdate = new Map<Id, Lead>();
    @TestVisible
    Map<Id, Contact> contactToUpdate = new Map<Id, Contact>();
    private static final String CONTACT_STATUS_MQL = 'MQL';
    
    public JourneyManageContactAndLeadTrH() {
        this((List<Journey__c>) Trigger.new, (Map<Id, Journey__c>) Trigger.oldMap);
    }
    
    @TestVisible
    private JourneyManageContactAndLeadTrH(List<Journey__c> newJourneys, Map<Id, Journey__c> oldJourneys) {
        this.newJourneys = newJourneys;
        this.oldJourneys = oldJourneys;
    }
    
    public override void afterInsert(){
        manageContactAndLead();
    }
    
    public override void afterUpdate(){
        manageContactAndLead();
    }
    
    @TestVisible
    private void manageContactAndLead() {
        for (Journey__c journey : newJourneys) {
           if (journey.Primary_Lead__c != null) {
                Lead lead = new Lead(Id = journey.Primary_Lead__c);
                if (this.context == TriggerContext.AFTER_INSERT){
                    lead.Journey_Created_On__c = System.today();
                }
                if (journey.Status__c == CONTACT_STATUS_MQL && (this.context == TriggerContext.AFTER_INSERT || (this.context == TriggerContext.AFTER_UPDATE && oldJourneys.get(journey.Id).Status__c != CONTACT_STATUS_MQL))){
                    lead.MQL_Identified_On__c = System.today();
                }
                if (leadToUpdate.containsKey(journey.Primary_Lead__c)) {
                    lead = leadToUpdate.get(journey.Primary_Lead__c);
                }
                leadToUpdate.put(journey.Primary_Lead__c, lead);
            }else if (journey.Primary_Contact__c != null) {
                Contact contact = new Contact(Id = journey.Primary_Contact__c);
                if (this.context == TriggerContext.AFTER_INSERT){
                    contact.Journey_Created_On__c = System.today();
                }
                if (journey.Status__c == CONTACT_STATUS_MQL && (this.context == TriggerContext.AFTER_INSERT || (this.context == TriggerContext.AFTER_UPDATE && oldJourneys.get(journey.Id).Status__c != CONTACT_STATUS_MQL))){
                    contact.MQL_Identified_On__c = System.today(); 
                }
                if (contactToUpdate.containsKey(journey.Primary_Contact__c)) {
                    contact = contactToUpdate.get(journey.Primary_Contact__c);
                }
                contactToUpdate.put(journey.Primary_Contact__c, contact);
            }
        }
        if (!leadToUpdate.isEmpty()) {
            dml.add(leadToUpdate.values(), DmlConsolidator.Operation.FOR_UPDATE);
        }
        if (!contactToUpdate.isEmpty()) {
            dml.add(contactToUpdate.values(), DmlConsolidator.Operation.FOR_UPDATE);
        }
    } 
}