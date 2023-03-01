/*********************************************************************************************************
	Author        :  Vipul Chaudahari
	Description   :  This method get active Referrence record and set Referrer__c field value of lead or contact based on email Id.
	Issue No.     :  ST-8958
-----------------------------------------------------------------------------------------------------------
	VERSION        DATE             AUTHOR             DETAIL
	1          09-Sept-2021     Vipul Chaudhari     Trigger Refactor
**********************************************************************************************************/
public class JourneyUpdateActiveReferrerTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Journey__c> newJourneys;
    @TestVisible
    private Set<String> leadEmails = new Set<String>();
    @TestVisible
    private Set<String> contactEmails = new Set<String>();

    public JourneyUpdateActiveReferrerTrH() {
        this((List<Journey__c>) trigger.new);
    }
    
    @TestVisible
    private JourneyUpdateActiveReferrerTrH(List<Journey__c> newJourney) {
        this.newJourneys = newJourney;
    }
    
    public override void beforeInsert() {
        updateActiveReferrerOnJourney();
    }

    private void updateActiveReferrerOnJourney() {
        Set<Id> contactIds = new Set<Id>();
        Set<Id> leadIds = new Set<Id>();
        Map<Id,String> leads = new Map<Id,String>();
        for(Journey__c journey :  newJourneys) {
            if(journey.Primary_Contact__c != null) {
                contactIds.add(journey.Primary_Contact__c);
            }
            if(journey.Primary_Lead__c != null) {
                leadIds.add(journey.Primary_Lead__c);
            }
        }
        if(!contactIds.isEmpty()) {
            updateJourneyReferrerForContact(contactIds);
        }
        if(leadIds.isEmpty()) {
            return;
        }
        updateJourneyReferrerForLead(leadIds);
    }

    private void updateJourneyReferrerForContact(Set<Id> contactIds){
        Map<Id,String> contacts = new Map<Id,String>();
        for(Contact contact :  [SELECT Id,Email,Referrer__c FROM Contact WHERE Id IN:contactIds AND Email != null]) {
            contactEmails.add(contact.Email.toLowerCase());
            contacts.put(contact.Id,contact.Email.toLowerCase());
        }
        if(!contactEmails.isEmpty()) {
            Map<String,Id> contactActiveReference = ReferenceHandler.getActiveReference(contactEmails);
            if(contactActiveReference != null && !contactActiveReference.isEmpty()) {
                for(Journey__c journey : newJourneys) {
                    if(journey.Primary_Contact__c != null 
                       && contactActiveReference.get(contacts.get(journey.Primary_Contact__c)) != null){
                        journey.Referrer__c = contactActiveReference.get(contacts.get(journey.Primary_Contact__c));
                    }
                }
            }
        }
    }

    private void updateJourneyReferrerForLead(Set<Id> leadIds){
        Map<Id,String> leads = new Map<Id,String>();
        for(Lead lead :  [SELECT Id,Email,Referrer__c FROM Lead WHERE Id IN:leadIds AND Email != null]) {
            leadEmails.add(lead.Email.toLowerCase());
            leads.put(lead.Id,lead.Email.toLowerCase());
        }
        if(!leadEmails.isEmpty()) {
            Map<String,Id> leadActiveReference = ReferenceHandler.getActiveReference(leadEmails);
            if(leadActiveReference != null && !leadActiveReference.isEmpty()) {
                for(Journey__c journey : newJourneys) {
                    if( journey.Primary_Lead__c != null && leadActiveReference.get(leads.get(journey.Primary_Lead__c)) != null){
                        journey.Referrer__c = leadActiveReference.get(leads.get(journey.Primary_Lead__c));
                    }
                }
            }
        }
    }
}