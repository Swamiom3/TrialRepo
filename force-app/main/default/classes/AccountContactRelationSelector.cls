/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class is selector implementation of particular SObject (AccountContactRelation)
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR            DETAIL
    1          24 Mar, 2022    Pawel Biszczak    Initial Deployment
**************************************************************************************************************************************/
public with sharing class AccountContactRelationSelector extends SObjectSelector {
    private static final List<String> DEFAULT_FIELDS = new List<String>{ 'Id',
                                                                         'Roles',
                                                                         'AccountId' };

    public AccountContactRelationSelector() {
        super(AccountContactRelation.getSObjectType());
    }

    public override Set<String> getDefaultFields() {
        return new Set<String> (DEFAULT_FIELDS);
    }

    public List<AccountContactRelation> getAccountContactRelationsByAccountIdsAndRoles(List<Id> accountIds, List<String> roles) {
        if (accountIds == null || accountIds.isEmpty() || roles == null || roles.isEmpty()) {
            return new List<AccountContactRelation>();
        }
        List<String> rolesPlusEscape = new List<String>();
        for (String roleName : roles) {
            rolesPlusEscape.add('\'' + String.escapeSingleQuotes(roleName) + '\'');
        }

        String rolesAsString = '(' + String.join(rolesPlusEscape, ',') +  ')';
        List<String> fields = new List<String>(DEFAULT_FIELDS);
        List<Object> bindings = new List<Object>{
                accountIds
        };
        String whereClause = 'AccountId IN:accountIds AND Roles INCLUDES' + rolesAsString;
        return (List<AccountContactRelation>) getSObjects(fields, whereClause, bindings, false);
    }

    public List<AccountContactRelation> getAccountContactRelationsByAccountIdsAndRoles(Id contactId) {
        if (String.isBlank(contactId)) {
            return new List<AccountContactRelation>();
        }
        List<String> fields = new List<String>{ 'Id', 'Account.Name', 'Contact.Name' };
        List<Object> bindings = new List<Object>{
            contactId
        };
        String whereClause = 'Roles INCLUDES (\'Primary Member\') AND IsActive = true AND ContactId = :contactId';
        return (List<AccountContactRelation>) getSObjects(fields, whereClause, bindings, false);
    }
}