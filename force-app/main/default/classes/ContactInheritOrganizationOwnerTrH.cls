/************************************************************************************************************************************
    Author         : Pawel Biszczak
    Description    : This class allows to inherit organization owner on Contacts record
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             DETAIL
    1          18 Mar, 2022    Pawel Biszczak     Initial Deployment
**************************************************************************************************************************************/
public with sharing class ContactInheritOrganizationOwnerTrH extends SObjectTriggerHandler {

    @TestVisible
    private List<Contact> newContacts;

    public ContactInheritOrganizationOwnerTrH() {
        this(
            (List<Contact>) Trigger.new
        );
    }

    @TestVisible
    private ContactInheritOrganizationOwnerTrH(List<Contact> newContacts) {
        this.newContacts = newContacts;
    }

    public override void beforeInsert() {
        inheritOrganizationOwner();
    }

    @TestVisible
    private void inheritOrganizationOwner() {
        for (Contact contact : newContacts) {
            if (isLeadSourceValid(contact.LeadSource, contact.Lead_Source_Detail__c)
                && String.isNotBlank(contact.Account_Owner__c)
                && UserUtility.getUserActive(contact.Account_Owner__c)) {
                contact.OwnerId = contact.Account_Owner__c;
            }
        }
    }

    @TestVisible
    private Boolean isLeadSourceValid(String leadSource, String leadSourceDetail) {
        if (String.isBlank(leadSource) || String.isBlank(leadSourceDetail)) {
            return true;
        } else if (String.isNotBlank(leadSource) && String.isNotBlank(leadSourceDetail)) {
            return !((leadSource == GlobalConstants.CONTACT_LEAD_SOURCE_OUT_EMAIL_COLD_CALL && leadSourceDetail == GlobalConstants.UNOMY)
                    || leadSourceDetail == System.Label.NewContactFormLeadSourceDetail);
        } else {
            return true;
        }
    }
}