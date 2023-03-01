/*************************************************************************************************************************************
 Author      :   Tomasz Sadowski
 Description :   This class is selector implementation of particular SObject (Account)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               12/15/2021      Tomasz Sadowski     Initial Deployment
 **************************************************************************************************************************************/
public with sharing class AccountSelector extends SObjectSelector {
    private final String ACCOUNT_FIELDS_METADATA = 'Account_Fields_Metadata';
    private final Set<String> DEFAULT_FIELDS = new Set<String>{'Id',
                                                               'Name',
                                                               'RecordTypeId',
                                                               'RecordType.Name',
                                                               'OwnerId',
                                                               'Owner.Name',
                                                               'ParentId',
                                                               'Account_Type__c'};
    private final Set<String> UNOMY_FIELDS = new Set<String>{'Id',
                                                             'Name',
                                                             'RecordTypeId',
                                                             'Account_FTE__c',
                                                             'BillingAddress',
                                                             'CI_Company__c',
                                                             'CI_Updated_DateTime__c',
                                                             'Website',
                                                             'LinkedIn_URL__c'};

    public AccountSelector() {
        super(Account.getSObjectType());
    }

    public override Set<String> getDefaultFields() {
        MetadataSetting__mdt metadataRecord = Settings.getMetadataSettingByDevName(ACCOUNT_FIELDS_METADATA);
        if (String.isNotBlank(metadataRecord?.Data__c)) {
            return (Set<String>) (JSON.deserialize(metadataRecord.Data__c, Set<String>.class));
        } else {
            return DEFAULT_FIELDS;
        }
    }

    public List<Account> getAccountsById(List<Id> ids) {
        if (ids == null || ids.isEmpty()) {
            return null;
        }

        List<String> fields = new List<String>(DEFAULT_FIELDS);
        return (List<Account>) getSObjectByIds(fields, ids);
    }

    /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get Accounts based on Ids and Ultimat parents
     Created Date        : 01 Feb 2022
     *****************************************************************************************************************************/
    public List<Account> getAccountsByIdOrUltimateParent(List<Id> ids, List<Id> parentIds) {
        if ((ids == null || ids.isEmpty()) && (parentIds == null || parentIds.isEmpty())) {
            return new List<Account>();
        }
        List<String> fields = new List<String> { 'Id', 'Customer_Group__c', 'Ultimate_Parent_Org__c', 'Ultimate_Parent_Org__r.Account_FTE__c' };
        String whereClause = 'Id IN :ids OR Ultimate_Parent_Org__c IN :parentIds';
        List<Object> bindings = new List<Object> { ids, parentIds };
        return (List<Account>) getSObjects(fields, whereClause, bindings);
    }

    /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get Accounts based on Unomy company
     Created Date        : 01 Feb 2022
     *****************************************************************************************************************************/
    public List<Account> getAccountsByUnomyCompany(List<Id> unomyIds) {
        if (unomyIds == null || unomyIds.isEmpty()) {
            return new List<Account>();
        }
        List<String> fields = new List<String>(DEFAULT_FIELDS);
        String whereClause = 'CI_Company__c IN :unomyIds AND CI_Updated_DateTime__c != null';
        List<Object> bindings = new List<Object> { unomyIds };
        return (List<Account>) getSObjects(fields, whereClause, bindings);
    }

    /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get Accounts based on Ultimate Parent
     Created Date        : 01 Feb 2022
     *****************************************************************************************************************************/
    public List<Account> getAccountsByUltimateParent(List<Id> parentRecords) {
        if (parentRecords == null || parentRecords.isEmpty()) {
            return new List<Account>();
        }
        List<String> fields = new List<String> { 'Id', 'Customer_Group__c', 'Ultimate_Parent_Org__r.Account_FTE__c' };
        String whereClause = 'Ultimate_Parent_Org__c IN :parentRecords';
        List<Object> bindings = new List<Object> { parentRecords };
        return (List<Account>) getSObjects(fields, whereClause, bindings);
    }
    
    /************************************************************************************************************************
     Author              : Vipul Chaudhari
     Description         : This method is used to get Accounts based AccountTeamMembers Roles
     Created Date        : 4 Feb 2022
	************************************************************************************************************************/    
    public List<Account> getAccountWithAccountTeam(Set<String> teamMemberRoles, Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return null;
        }
        String innerQuery = 'SELECT Id, Region__c FROM AccountTeamMembers';
        String innerWhere = 'TeamMemberRole IN :teamMemberRoles';
        List<String> fields = new List<String>{ 'Id', 'Co_Prime_Region__c', 'Co_Prime__c'};
        String outerWhere = 'Id IN :accountIds';
        return (List<Account>) getSObjectsWithChilds(fields, innerQuery, innerWhere, outerWhere, new List<Object>{teamMemberRoles}, new List<Object>{teamMemberRoles, accountIds});
    }
    
    public List<Account> getAccountWithOpportunities(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return null;
        }
        String innerQuery = 'SELECT Id, OwnerId FROM Opportunities';
        String innerWhere = 'Id != null';
        List<String> fields = new List<String>{'Id'};
        String outerWhere = 'Id IN :accountIds';
        return (List<Account>) getSObjectsWithChilds(fields, innerQuery, innerWhere, outerWhere, new List<Object>(), new List<Object>{accountIds});
    }
    
    public List<Account> getAccountWithOpportunities(Set<Id> accountIds, Set<String> parentIds) {
        if (accountIds == null || accountIds.isEmpty() || parentIds == null || parentIds.isEmpty()) {
            return null;
        }
        String innerQuery = 'SELECT Id, AccountId, Opportunity_Account_Name__c, CloseDate, Name, RecordTypeId, Building__c' +
                             ', Building__r.Name, Geography__c, Geography__r.Name, Geography__r.City__c, Geography__r.State__c' +
                             ', Geography__r.Country__c, Type__c, Requirement_Quantity__c, Interested_in_Number_of_Desks__c FROM Opportunities';
        String innerWhere = 'AccountId IN :accountIds';
        List<String> fields = new List<String>{'Id', 'Name', 'Parent_Org_Id__c', 'Account_Type__c', 'Parent_Org_Name__c', 'Nickname__c'};
        String outerWhere = 'Id IN :accountIds OR Parent_Org_Id__c IN :parentIds OR Parent_Org__c IN :parentIds';
        return (List<Account>) getSObjectsWithChilds(fields, innerQuery, innerWhere, outerWhere, new List<Object>{accountIds}, new List<Object>{accountIds, accountIds, parentIds, parentIds});
    }
    
    public List<Account> getAccountWithContacts(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return null;
        }
        String innerQuery = 'SELECT Id, Name FROM Contacts';
        String innerWhere = 'Id != null';
        List<String> fields = new List<String>(DEFAULT_FIELDS);
        String outerWhere = 'Id IN :accountIds';
        return (List<Account>) getSObjectsWithChilds(fields, innerQuery, innerWhere, outerWhere, new List<Object>(), new List<Object>{accountIds});
    }
    
    public List<Account> getAccountWithAccContactRelations(Set<String> roles, Set<String> rtDevName, Set<Id> ultimateParentIds) {
        if (roles == null || roles.isEmpty() || rtDevName == null || rtDevName.isEmpty() || ultimateParentIds == null || ultimateParentIds.isEmpty()) {
            return null;
        }
        String innerQuery = 'SELECT AccountId, ContactId, Contact.Name, Contact.Email, Roles FROM AccountContactRelations';
        String innerWhere = 'Roles IN :roles LIMIT 1';
        List<String> fields = new List<String>{'Id', 'Name', 'Ultimate_Parent_Org__c', 'Ultimate_Business_Account_Owner__c',
                                               'Ultimate_Parent_Org__r.Name', 'Ultimate_Parent_Org__r.OwnerId'};
        String outerWhere = 'RecordType.DeveloperName IN :rtDevName AND Ultimate_Parent_Org__c IN :ultimateParentIds';
        return (List<Account>) getSObjectsWithChilds(fields, innerQuery, innerWhere, outerWhere, new List<Object>{roles}, new List<Object>{roles, rtDevName, ultimateParentIds});
    }

    public List<Account> getAccountManagerByAccId(List<Id> ids) {
        if (ids == null || ids.isEmpty()) {
            return null;
        }

        List<String> fields = new List<String>(new Set<String>{'Account_Manager_Lookup__c'});
        return (List<Account>) getSObjectByIds(fields, ids);
    }
    
    public List<Account> getAccountsByNameAndAccType(Set<String> names, String accType) {
        if (names == null || names.isEmpty() || String.isBlank(accType)) {
            return new List<Account>();
        }
        List<String> fields = new List<String>(DEFAULT_FIELDS);
        String whereClause = 'Name IN :names AND Account_Type__c = :accType';
        List<Object> bindings = new List<Object>{names, accType};
        return (List<Account>) getSObjects(fields, whereClause, bindings);
    }
    
    public List<Account> getAccountsByParentAccount(Set<Id> parentIds) {
        if (parentIds == null || parentIds.isEmpty()) {
            return new List<Account>();
        }
        List<String> fields = new List<String>(DEFAULT_FIELDS);
        String whereClause = 'ParentId IN :parentIds';
        List<Object> bindings = new List<Object>{parentIds};
        return (List<Account>) getSObjects(fields, whereClause, bindings);
    }
    
    public List<Account> getAccountsWithParentsDeep(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return new List<Account>();
        }
        List<String> fields = new List<String>{'Id', 'Name', 'HierarchyLevel__c', 'ParentId', 'Parent.Parent.Id', 'Parent.Parent.Parent.Id', 'Parent.Parent.Parent.Parent.Id', 'Parent.Parent.Parent.Parent.Parent.Id'};
        String whereClause = 'Id IN :accountIds';
        List<Object> bindings = new List<Object>{accountIds};
        return (List<Account>) getSObjects(fields, whereClause, bindings);
    }

    public List<Account> getSalesAccountsById(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return new List<Account>();
        }

        List<String> fields = new List<String>{ 'Id',
                                                'Name',
                                                'Primary_Member__c',
                                                'Lead_Source__c',
                                                'Parent_Org__c',
                                                'Parent_Org_Id__c',
                                                'OwnerId',
                                                'Account_Type__c',
                                                'External_Parent_Org_Id__c',
                                                'Date_of_First_Business__c'
                                            };
        return (List<Account>) getSObjectByIds(fields, new List<Id>(accountIds));
    }

    public List<Account> getAccountsAndFieldsById(List<String> fields, Set<Id> accountIds) {
        if (fields == null || fields.isEmpty() || accountIds == null || accountIds.isEmpty()) {
            return new List<Account>();
        }

        return (List<Account>) getSObjectByIds(fields, new List<Id>(accountIds));
    }

    public List<Account> getAccountsByParentIdsAndIdAndSalesOrgType(String parentOrgId, String parentId, String recordId) {
        String whereClause = '(Parent_Org_Id__c = :parentOrgId'
                                + ' OR ParentId = :parentId'
                                + ' OR Id = :recordId)'
                                + ' AND Account_Type__c IN :accTypes';
        List<Object> bindings = new List<Object>{ parentOrgId, parentId, recordId, new List<String>{ 'Sales', 'Org' } };
        List<String> fields = new List<String>{ 'Id', 'Name', 'Primary_Member__c', 'Primary_Member__r.Name', 'Primary_Member__r.Email', 'Parent_Org_Id__c', 'Parent_Org_Name__c', 'RecordType.Name', 'Account_Type__c', 'OwnerId', 'Owner.Name', 'ID_Status2__c', 'CreatedDate' };
        return (List<Account>) getSObjects(fields, whereClause, bindings);
    }

    public List<Account> getAccountsByParentIdsAndSalesOrgType(String parentOrgId, String parentId) {
        String whereClause = '(Parent_Org_Id__c = :parentOrgId'
                                + ' OR ParentId = :parentId)'
                                + ' AND Account_Type__c IN :accTypes';
        List<Object> bindings = new List<Object>{ parentOrgId, parentId, new List<String>{ 'Sales', 'Org' } };
        List<String> fields = new List<String>{ 'Id', 'Name', 'Primary_Member__c', 'Primary_Member__r.Name', 'Primary_Member__r.Email', 'Parent_Org_Id__c', 'Parent_Org_Name__c', 'RecordType.Name', 'Account_Type__c', 'OwnerId', 'Owner.Name', 'ID_Status2__c', 'CreatedDate' };
        return (List<Account>) getSObjects(fields, whereClause, bindings);
    }

    public List<Account> getUnomyAccountsById(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return null;
        }

        List<String> fields = new List<String>(UNOMY_FIELDS);
        return (List<Account>) getSObjectByIds(fields, new List<Id>(accountIds));
    }
}