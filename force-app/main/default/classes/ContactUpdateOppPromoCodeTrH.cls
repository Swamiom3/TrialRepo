/************************************************************************************************************************************
    Author      :   Oleksandr Liesnik	
    Description :   Trigger handler class for updating Promo_Code__c field on related Opportunity (TWSPG-14547)
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           Sep 19, 2022        Oleksandr Liesnik       Initial version
**************************************************************************************************************************************/
public inherited sharing class ContactUpdateOppPromoCodeTrH extends SObjectTriggerHandler{

    @TestVisible
    private List<Contact> newContacts;
    @TestVisible
    private Map<Id, Contact> newContactsMap;
    @TestVisible
    private Map<Id, Contact> oldContactsMap;
    @TestVisible
    private OpportunitySelector oppSelector = new OpportunitySelector();

    public ContactUpdateOppPromoCodeTrH() {
        this(
            (List<Contact>) Trigger.new,
            (Map<Id, Contact>) Trigger.newMap,
            (Map<Id, Contact>) Trigger.oldMap
        );
    }

    @TestVisible
    private ContactUpdateOppPromoCodeTrH (List<Contact> newContacts, Map<Id, Contact> newContactsMap, Map<Id, Contact> oldContactsMap) {
        this.newContacts = newContacts;
        this.newContactsMap = newContactsMap;
        this.oldContactsMap = oldContactsMap;
    }

    public override void afterInsert() {
        updateOppPromoCode();
    }

    public override void afterUpdate() {
        updateOppPromoCode();
    }

    private void updateOppPromoCode() {
        List<Opportunity> oppsToUpdate = getOppsToUpdate();
        if (oppsToUpdate != null && !oppsToUpdate.isEmpty()) {
            dml.add(oppsToUpdate, DmlConsolidator.Operation.FOR_UPDATE);
        }
    }

    @TestVisible
    private List<Opportunity> getOppsToUpdate() {
        Map<Id, Id> relatedAccIds = getRelatedAccIds();
        removeAccsWithChilds(relatedAccIds);
        List<Opportunity> relatedOpps = getRelatedOpps(relatedAccIds.keySet());
        if (relatedOpps.isEmpty()) {
            return relatedOpps;
        }
        for (Opportunity opp : relatedOpps) {
            Id relatedAccount = opp.AccountId;
            if (relatedAccount != null && relatedAccIds.containsKey(relatedAccount)) {
                opp.Promo_Code__c = newContactsMap.get(relatedAccIds.get(relatedAccount)).Promo_Code__c;
            }
        }
        return relatedOpps;

    }

    private List<Opportunity> getRelatedOpps(Set<Id> relatedAccIds) {
        return oppSelector.getSelfServeOppsByAccountIds(relatedAccIds);
    }

    @TestVisible
    private Map<Id, Id> getRelatedAccIds() {
        Map<Id, Id> relatedAccIds = new Map<Id, Id>();
        for (Contact contact : newContacts) {
        if (contact.Promo_Code__c != null && contact.AccountId != null
                && ((this.context == TriggerContext.AFTER_UPDATE && TriggerUtility.isFieldValueChanged(contact, oldContactsMap.get(contact.Id), 'Promo_Code__c'))
                        || this.context == TriggerContext.AFTER_INSERT)) {
                relatedAccIds.put(contact.AccountId, contact.Id);
            }
        }
        return relatedAccIds;
    }

    private void removeAccsWithChilds(Map<Id, Id> relatedAccIds) {
        List<Account> accs = [SELECT Id, (SELECT Id FROM Contacts LIMIT 2) FROM Account WHERE Id IN :relatedAccIds.keySet()];
        for (Account acc : accs) {
            if (acc.Contacts.size() > 1) {
                relatedAccIds.remove(acc.Id);
            }
        }
    }
}