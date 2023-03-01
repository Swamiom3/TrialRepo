/*************************************************************************************************************************************
 Author      :   Salesforce
 Description :   This class is selector implementation of particular SObject (User)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               18 Oct 2021     Salesforce       Initial Deployment
 2               23 March, 2022  Ishwar Shinde    Implementation Of ST-10054
 **************************************************************************************************************************************/
public with sharing class UserSelector extends SObjectSelector {
    public UserSelector() {
        super(User.getSObjectType());
    }

    /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get default fields from Object
     Created Date        : 18 Oct 2021
     *****************************************************************************************************************************/
    public override Set<String> getDefaultFields() {
        return new Set<String> { 'Id', 'Name' };
    }

    /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get users based on record Ids
     Created Date        : 18 Oct 2021
     *****************************************************************************************************************************/
    public List<User> getUsersById(List<Id> userIds) {
        if(userIds.isEmpty()) {
            return new List<User>();
        }
        List<String> fields = new List<String> { 'Id', 'Name', 'FirstName', 'LastName', 'Salesforce_Scheduler_User__c' };
        String whereClause = 'Id IN: userIds';
        List<Object> bindings = new List<Object> { userIds};
        return (List<User>) getSObjects(fields, whereClause, bindings);
    }
    
    public List<User> getUsersById(Set<Id> userIds) {
        if(userIds.isEmpty()) {
            return new List<User>();
        }
        List<String> fields = new List<String> { 'Id', 'Name', 'TimeZoneSidKey', 'IsActive', 'Email'};
        String whereClause = 'Id IN: userIds AND IsActive = TRUE';
        List<Object> bindings = new List<Object> { userIds };
        return (List<User>) getSObjects(fields, whereClause, bindings);
    }
    
    public List<User> getUsersWithAdditionalFieldsById(Id userId) {
        if(userId == null) {
            return new List<User>();
        }
        List<String> additionalFields = new List<String> { 'Profile.Name',
                                                           'Email',
                                                           'Username',
                                                           'FirstName',
                                                           'LastName',
                                                           'Profile.Id',
                                                           'TimeZoneSidKey',
                                                           'CurrencyIsoCode',
                                                           'SmallPhotoUrl'};
        additionalFields.addAll(getDefaultFields());
        String whereClause = 'Id =: userId';
    List<Object> bindings = new List<Object> { userId };
        return (List<User>) getSObjects(additionalFields, whereClause, bindings);
    }
    
    public List<User> getActiveUsersByIdWithOrderByName(Set<Id> userIds) {
        if(userIds.isEmpty()) {
            return new List<User>();
        }
        List<String> fields = new List<String> { 'Name', 'Username', 'Email' };
        
        String whereClause = 'IsActive = true AND Id IN : userIds ORDER BY Name ASC';
        List<Object> bindings = new List<Object> { userIds };
        return (List<User>) getSObjects(fields, whereClause, bindings);
    }
    
    public List<User> getUsersByProfileId(String profileId) {
        if(profileId == null) {
            return new List<User>();
        }
        List<String> fields = new List<String> { 'Id' };
        String whereClause = 'ProfileId =: profileId';
        String orderByClause = 'Name';
        List<Object> bindings = new List<Object> { profileId};
        return (List<User>) getSObjects(fields, whereClause, bindings, orderByClause);
    }
    
    public List<User> getUsersByEmailAndUsername(String email, String userName) {
        if(String.isBlank(email) || String.isBlank(userName)) {
            return new List<User>();
        }
        List<String> fields = new List<String> { 'Id' };
        String whereClause = 'Email = :email AND UserName LIKE :userName';
        List<Object> bindings = new List<Object> { email, userName};
        return (List<User>) getSObjects(fields, whereClause, bindings);
    }
    
    public List<User> getActiveUsersByEmail(String email) {
        if(String.isBlank(email)) {
            return new List<User>();
        }
        List<String> fields = new List<String> { 'Id', 'Email','FederationIdentifier'};
        String whereClause = 'Email LIKE :email AND isActive = true ORDER BY LastLoginDate DESC';
        List<Object> bindings = new List<Object> { email };
        return (List<User>) getSObjects(fields, whereClause, bindings);
    }
    
    public List<User> getAllActiveUsers() {
        List<String> fields = new List<String> { 'Id',
                                                 'Name',
                                                 'Email',
                                                 'Region__c',
                                                 'UserRole.Name',
                                                 'Sales_Role__c',
                                                 'Sales_Pod__c',
                                                 'IsActive',
                                                 'Phone',
                                                 'ProfileId',
                                                 'Profile.Name',
                                                 'Portfolio__c',
                                                 'TimeZoneSidKey',
                                                 'ManagerId',
                                                 'Full_Name__c',
                                                 'Gainsight_Permission__c'};

        String whereClause = ' WHERE IsActive = true';
        return (List<User>) getSObjects(fields, whereClause);
    }
    public List<User> getUserByFederationId(String FederationIdentifier){
        if(String.isBlank(FederationIdentifier)) {
            return new List<User>();
        }
        List<String> fields = new List<String> { 'Id', 'Email','FederationIdentifier'};
        String whereClause = 'FederationIdentifier =:FederationIdentifier';
        List<Object> bindings = new List<Object> { FederationIdentifier };
        return (List<User>) getSObjects(fields, whereClause, bindings);
    }
}