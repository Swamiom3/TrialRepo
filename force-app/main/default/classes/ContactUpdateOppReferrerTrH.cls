/************************************************************************************************************************************
    Author     : Nicholas Zozaya
    Description: When Contact has Account changed, also change Referrer Account on Opportunity.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION       DATE              AUTHOR                DETAIL                                  ISSUE
    1             15 Nov 2019       Nicholas Zozaya       Initial Developement
    2             13 April, 2021    Tomasz Sadowski       Migration to new trigger framework      ST-8042
**************************************************************************************************************************************/
public class ContactUpdateOppReferrerTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Contact> newContacts;
    @TestVisible
    private Map<Id, Contact> newContactsMap;
    @TestVisible
    private Map<Id, Contact> oldContactsMap;
    public final List<String> opportunityClosedStageNames = Label.Opportunity_Closed_StageNames.split(',');
    @TestVisible
    private List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();

    public ContactUpdateOppReferrerTrH() {
        this(
            (List<Contact>) Trigger.new,
            (Map<Id, Contact>) Trigger.newMap,
            (Map<Id, Contact>) Trigger.oldMap
        );
    }

    @TestVisible
    private ContactUpdateOppReferrerTrH(List<Contact> newContacts, Map<Id, Contact> newContactsMap, Map<Id, Contact> oldContactsMap) {
        this.newContacts = newContacts;
        this.newContactsMap = newContactsMap;
        this.oldContactsMap = oldContactsMap;
    }

    public override void afterUpdate() {
        updateOpportunityReferrerAccount();
    }

    @TestVisible
    private void updateOpportunityReferrerAccount() {
        Set<Id> matchingContacts = new Set<Id>();
        for (Contact contact : newContacts) {
            Contact oldContact = oldContactsMap?.get(contact.Id);
            if (contact.AccountId != null && TriggerUtility.isFieldValueChanged(contact, oldContact, 'AccountId')) {
                matchingContacts.add(contact.Id);
            }
        }
        if (matchingContacts.isEmpty()) {
            return;
        }
        for (Opportunity referrerOpportunity : [SELECT Referrer__c, Referrer_Account__c FROM Opportunity WHERE (Referrer__c IN:matchingContacts) AND (StageName NOT IN:opportunityClosedStageNames)]) {
            checkReferrerAccountAndPrepareOpportunityForUpdate(referrerOpportunity);
        }
        updateOpportunities();
    }

    @TestVisible
    private void updateOpportunities() {
        if(opportunitiesToUpdate.isEmpty()) {
           return;
        }
        this.dml.add(opportunitiesToUpdate, DmlConsolidator.Operation.FOR_UPDATE);
    }

    @TestVisible
    private void checkReferrerAccountAndPrepareOpportunityForUpdate(Opportunity referrerOpportunity) {
        if (referrerOpportunity.Referrer_Account__c != newContactsMap.get(referrerOpportunity.Referrer__c).AccountId) {
            referrerOpportunity.Referrer_Account__c = newContactsMap.get(referrerOpportunity.Referrer__c).AccountId;
            opportunitiesToUpdate.add(referrerOpportunity);
        }
    }
}