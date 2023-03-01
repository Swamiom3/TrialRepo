/************************************************************************************************************************************
    Author     : Nicholas Zozaya
    Description: This class will push Referrer Contact's Type field to their Referral Opportunities.
----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE              AUTHOR                  DETAIL                                 ISSUE
    1              13 June, 2019     Nicholas Zozaya         Initial Developement                   ST-4108
    2              13 April, 2021    Tomasz Sadowski         Migration to new trigger framework     ST-8042
**************************************************************************************************************************************/
public class ContactUpdateReferrerTypeTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Contact> newContacts;
    @TestVisible
    private Map<Id, Contact> oldContactsMap;
    @TestVisible
    private List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();

    public ContactUpdateReferrerTypeTrH() {
        this(
            (List<Contact>) Trigger.new,
            (Map<Id, Contact>) Trigger.oldMap
        );
    }

    @TestVisible
    private ContactUpdateReferrerTypeTrH(List<Contact> newContacts, Map<Id, Contact> oldContactsMap) {
        this.newContacts = newContacts;
        this.oldContactsMap = oldContactsMap;
    }

    public override void afterInsert() {
        updateOpportunityReferrerContactType();
    }

    public override void afterUpdate() {
        updateOpportunityReferrerContactType();
    }

    @TestVisible
    private void updateOpportunityReferrerContactType() {
        Set<Id> contactIds = new Set<Id>();
        for (Contact contact : newContacts) {
            Contact oldContact = oldContactsMap?.get(contact.Id);
            if (oldContact == null || TriggerUtility.isFieldValueChanged(contact, oldContact, 'Type__c')) {
                contactIds.add(contact.Id);
            }
        }
        if(contactIds.isEmpty()) {
            return;
        }
        for (Opportunity typeChangeRelatedOpportunity : [SELECT Referrer_Contact_Type__c, Referrer__r.Type__c FROM Opportunity WHERE Referrer__c IN: contactIds]) {
            changeReferrerContactType(typeChangeRelatedOpportunity);
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
    private void changeReferrerContactType(Opportunity typeChangeRelatedOpportunity) {
        typeChangeRelatedOpportunity.Referrer_Contact_Type__c = typeChangeRelatedOpportunity.Referrer__r.Type__c;
        opportunitiesToUpdate.add(typeChangeRelatedOpportunity);
    }
}