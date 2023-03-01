/************************************************************************************************************************************
    Author         : Pawel Biszczak
    Description    : This class provides an Cleansed_Company_Name__c for Contact records
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1              19 Jan, 2022    Pawel Biszczak     Initial Deployment
**************************************************************************************************************************************/
public with sharing class ContactUpdateCleansedNameTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Contact> newContacts;

    public ContactUpdateCleansedNameTrH() {
        this(
                (List<Contact>) Trigger.new
        );
    }

    @TestVisible
    private ContactUpdateCleansedNameTrH(List<Contact> newContacts) {
        this.newContacts = newContacts;
    }

    public override void beforeInsert() {
        updateCleansedName();
    }

    public override void beforeUpdate() {
        updateCleansedName();
    }

    @TestVisible
    private void updateCleansedName() {
        for (Contact contact : newContacts) {
            if (String.isNotBlank(contact.Account_Name__c)) {
                contact.Cleansed_Company_Name__c = OrganizationHelper.getCleansedName(contact.Account_Name__c);
            }
            else if (String.isNotBlank(contact.Company__c)) {
                contact.Cleansed_Company_Name__c = OrganizationHelper.getCleansedName(contact.Company__c);
            }
            else if (String.isNotBlank(contact.Billing_Account_Name__c)) {
                contact.Cleansed_Company_Name__c = OrganizationHelper.getCleansedName(contact.Billing_Account_Name__c);
            }
            else if (String.isNotBlank(contact.FirstName) && String.isNotBlank(contact.LastName)) {
                contact.Cleansed_Company_Name__c = OrganizationHelper.getCleansedName(contact.FirstName + ' ' + contact.LastName);
            }
            else {
                contact.Cleansed_Company_Name__c = OrganizationHelper.getCleansedName(contact.LastName);
            }
        }
    }
}