/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class is selector implementation of particular SObject (Contact)
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR            DETAIL
    1          9 Apr, 2021    Pawel Biszczak    Initial Deployment
**************************************************************************************************************************************/
public with sharing class ContactSelector extends SObjectSelector {
    private final String CONTACT_FIELDS_METADATA = 'Contact_Fields_Metadata';
    private static final List<String> DEFAULT_FIELDS = new List<String>{ 'Id',
                                                                         'Email',
                                                                         'Name',
                                                                         'UUID__c' };

    private static final List<String> PERSON_FIELDS = new List<String> { 'Email_Domain_Text__c', 'CI_Company__c', 'CI_Updated_DateTime__c', 'Account.Parent_Org_Id__c', 'Account_Name__c', 'RecordTypeId',
                                                                         'AccountId', 'Account.Name', 'Account.Account_Type__c', 'Email_Domain__c', 'Company__c', 'Cleansed_Company_Name__c',
                                                                         'Unomy_Company_ID_Formula__c', 'FirstName', 'LastName', 'Phone', 'Type__c', 'LeadSource', 'Lead_Source_Detail__c',
                                                                         'utm_campaign__c', 'utm_content__c', 'utm_medium__c', 'utm_source__c', 'utm_term__c', 'Locale__c', 'Country_Code__c', 'Account.Ultimate_Parent_Org__c'
                                                                        };

    private static final String ACCOUNT_CONTACT_RELATIONSHIP_SUBQUERY = ' (SELECT Id, Roles, Account.RecordType.DeveloperName, AccountId FROM AccountContactRelations WHERE Roles = \'Primary Member\' AND Account.Recordtype.DeveloperName = \'Billing_Account\') ' ; 

    public ContactSelector() {
        super(Contact.getSObjectType());
    }

    public override Set<String> getDefaultFields(){
        MetadataSetting__mdt metadataRecord = Settings.getMetadataSettingByDevName(CONTACT_FIELDS_METADATA);
        if (String.isNotBlank(metadataRecord?.Data__c)) {
            return (Set<String>) (JSON.deserialize(metadataRecord.Data__c, Set<String>.class));
        } else {
            return new Set<String> (DEFAULT_FIELDS);
        }
    }

    public List<Contact> getContactsByIdAndNotNullEmail(List<Id> ids){
        if (ids == null || ids.isEmpty()) {
            return null;
        }

        List<String> fields = new List<String>(DEFAULT_FIELDS);
        List<Object> bindings = new List<Object>{ ids };
        String whereClause = 'Id IN :ids AND Email <> NULL';
        return (List<Contact>) getSObjects(fields, whereClause, bindings);
    }

    public List<Contact> getContactsByUUIDs(List<String> uuids){
        if (uuids == null || uuids.isEmpty()) {
            return null;
        }

        List<String> fields = new List<String>(DEFAULT_FIELDS);
        return (List<Contact>) getSObjectByField(fields, 'UUID__c', uuids, false);
    }

    public List<Contact> getContactsByIds(Set<Id> ids) {
        if (ids == null || ids.isEmpty()) {
            return new List<Contact>();
        }
        List<String> fields = new List<String>{'Id', 'Email', 'Type__c'};
        List<Object> bindings = new List<Object>{ ids };
        String whereClause = 'Id IN :ids';
        return (List<Contact>) getSObjects(fields, whereClause, bindings);
    }

    public List<Contact> getContactsWithPersonFieldsByIds(List<Id> ids){
        if (ids == null || ids.isEmpty()) {
            return new List<Contact>();
        }
        List<String> fields = new List<String>(DEFAULT_FIELDS);
        fields.addAll(PERSON_FIELDS);
        fields.add(ACCOUNT_CONTACT_RELATIONSHIP_SUBQUERY);
        return (List<Contact>) getSObjectByField(fields, 'Id', ids, false, false);
    }

    public List<Contact> getContactsWithPersonFieldsByEmails(List<String> emails){
        if (emails == null || emails.isEmpty()) {
            return new List<Contact>();
        }
        List<String> fields = new List<String>(DEFAULT_FIELDS);
        fields.addAll(PERSON_FIELDS);
        fields.add(ACCOUNT_CONTACT_RELATIONSHIP_SUBQUERY);
        return (List<Contact>) getSObjectByField(fields, 'Email', emails, false, false);
    }

    public List<Contact> getContactsWithAccountFieldsByIdsOrLoggedInUserEmail(Set<Id> contactIds) {
        if (contactIds == null || contactIds.isEmpty()) {
            return new List<Contact>();
        }
        List<String> fields = new List<String>{'Id', 'AccountId', 'Email'};
        List<Object> bindings = new List<Object>{ contactIds, UserInfo.getUserEmail() };
        String whereClause = 'Id IN :contactIds OR Email = :userEmail';
        return (List<Contact>) getSObjects(fields, whereClause, bindings);
    }
}