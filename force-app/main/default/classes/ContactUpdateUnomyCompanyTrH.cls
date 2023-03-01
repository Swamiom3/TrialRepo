/************************************************************************************************************************************
    Author     : Krishana Tupe
    Description: This class will contain buisness logic of Contact trigger which updates the CI_Company__c Lookup.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE                AUTHOR                DETAIL                                    ISSUE
    1              25 March 2019       Krishana Tupe         Initial Developement                      ST-3671
    2              13 April, 2021      Tomasz Sadowski       Migration to new trigger framework        ST-8042
    3              19 Jan 2022         Rohit Nimase          Migration to OrgC                         ST-10172
**************************************************************************************************************************************/
public class ContactUpdateUnomyCompanyTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Contact> newContacts;

    public ContactUpdateUnomyCompanyTrH() {
        this(
            (List<Contact>) Trigger.new
        );
    }

    @TestVisible
    private ContactUpdateUnomyCompanyTrH(List<Contact> newContacts) {
        this.newContacts = newContacts;
    }

    public override void beforeInsert() {
        updateUnomyCompany();
    }

    @TestVisible
    private void updateUnomyCompany() {
        Set<Id> accountIds = new Set<Id>(); 
        List<Contact> validContacts = new List<Contact>();
        for (Contact contact : newContacts) {
            if (String.isNotBlank(contact.AccountId) && String.isBlank(contact.CI_Company__c)) {
                accountIds.add(contact.AccountId);
                validContacts.add(contact);
            }
        }
        if (accountIds.isEmpty()) {
            return;
        }
        Map<Id, Account> idToAccount = new Map<Id, Account>([SELECT Id, CI_Company__c FROM Account WHERE Id IN :accountIds AND CI_Company__c <> NULL LIMIT 50000]);
        prepareCICompanyDataForContacts(validContacts, idToAccount);
    }

    @TestVisible
    private void prepareCICompanyDataForContacts(List<Contact> validContacts, Map<Id, Account> idToAccount) {
        if (idToAccount.isEmpty()) {
            return;
        }
        for (Contact contact : validContacts) {
            if (String.isNotBlank(contact.AccountId) && idToAccount.containsKey(contact.AccountId)) {
                contact.CI_Company__c = idToAccount.get(contact.AccountId).CI_Company__c;
                contact.CI_Updated_DateTime__c = System.now();
            }
        }
    }
}