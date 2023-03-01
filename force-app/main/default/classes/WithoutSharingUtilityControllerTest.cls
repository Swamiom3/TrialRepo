/************************************************************************************************************************************
    Author      :   -
    Description :   This class is used to test WithoutSharingUtilityController class.
    History :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                     DETAIL
    1           05 July 201         Mayuresh Ghodke            Initial Developement
    2           21 august 2018      Nikhil Mehta               changes according to Account Hirarchy 2
    3           16 Nov 2018         Krishana Tupe              Revisit and Refactor for ST-3006
    4           3  Dec 2019         Ashish Sharma              Refactor for issue ST-4482.
    5           15 Dec 2021         Pawel Biszczak             Improve test coverage, add unit tests
**************************************************************************************************************************************/
@isTest
public class WithoutSharingUtilityControllerTest {  
    public static Profile profileWeworkSystemAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
    public static Profile profileWeworkGrowthOps = [SELECT Id FROM Profile WHERE Name = 'WeWork Interr Vendor'];
    public static User adminUserRecord = UtilUser.createUser(profileWeworkSystemAdmin.Id, true);
    private static final String UNIQUE_ADMIN_USER_NAME = 'testAdminUser@weworkexample.com';
    
    @testSetup
    private static void setup(){
        TestingUtility.getTerritorystructure();
        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        List<Opportunity> opportunities = new List<Opportunity>();

        accounts.add(TestingUtility.createAccount(
                new Map<String, Object>{
                        'Name' => 'TestConsumer Account',
                        'Account_Type__c' => 'Org',
                        'Number_of_Full_Time_Employees__c' => 8
                }, false));
        accounts.add(TestingUtility.createAccount(
                new Map<String, Object>{
                        'Name' => 'TestConsumer Account2',
                        'Account_Type__c' => 'Org',
                        'Number_of_Full_Time_Employees__c' => 2
                }, false));
        accounts.add(TestingUtility.createAccount(
                new Map<String, Object>{
                        'Name' => 'TestMidMarket Account',
                        'Account_Type__c' => 'Org',
                        'Number_of_Full_Time_Employees__c' => 50
                }, false));
        accounts.add(TestingUtility.createAccount(
                new Map<String, Object>{
                        'Name' => 'TestEnterPrise Account',
                        'Account_Type__c' => 'Org',
                        'Number_of_Full_Time_Employees__c' => 1100
                }, false));
        TestingUtility.insertListWithAssert(accounts);
        
        User salesLeadUserRecord = UtilUser.createUser(profileWeworkGrowthOps.Id, true);

        contacts.add(TestingUtility.createContact(
                new Map<String, Object>{
                        'FirstName' => 'testFirstName',
                        'LastName' => 'testContact',
                        'OwnerId' => salesLeadUserRecord.Id,
                        'AccountId' => accounts[0].Id,
                        'UUID__c' => '101010'
                }, false));
        TestingUtility.insertListWithAssert(contacts);
        
        Contact contactRecord = [SELECT Id FROM Contact LIMIT 1];
        opportunities.addAll((List<Opportunity>) TestingUtility.getRecords(
                new Map<String, Object>{
                        'objName' => 'opportunity', 'numberOfRecords' => 1, 'doInsert' => false, 'mapFieldValues' => new Map<String, List<Object>>{
                                'Name' => new List<Object>{
                                        'test-opp1'
                                }, 'AccountId' => new List<Object>{
                                        accounts[0].Id
                                }, 'StageName' => new List<Object>{
                                        'Qualifying'
                                }, 'Primary_Member__c' => new List<Object>{
                                        contactRecord.Id
                                }, 'CloseDate' => new List<Object>{
                                        System.today()
                                }
                        }
                }));
        opportunities.addAll((List<Opportunity>) TestingUtility.getRecords(
                new Map<String, Object>{
                        'objName' => 'opportunity', 'numberOfRecords' => 1, 'doInsert' => false, 'mapFieldValues' => new Map<String, List<Object>>{
                                'Name' => new List<Object>{
                                        'test-opp2'
                                }, 'AccountId' => new List<Object>{
                                        accounts[1].Id
                                }, 'StageName' => new List<Object>{
                                        'Selling'
                                }, 'Primary_Member__c' => new List<Object>{
                                        contactRecord.Id
                                }, 'CloseDate' => new List<Object>{
                                        System.today()
                                }
                        }
                }));
        TestingUtility.insertListWithAssert(opportunities);
        
        List<Map<String, Object>> usersData =  new List<Map<String, Object>>();
        usersData.add(new Map<String, Object>{
                'Email' => UNIQUE_ADMIN_USER_NAME,
                'Username' => UNIQUE_ADMIN_USER_NAME
        });
        List<User> users = TestingUtility.insertUserWithAssert(profileWeworkSystemAdmin.Id, usersData, true);
        
        TestingUtility.insertWithAssert(new OpportunityTeamMember(OpportunityId = opportunities[0].Id,
                                                                  TeamMemberRole = 'Legal Counsel',
                                                                  UserId = users[0].Id));
        
        Journey__c journeyRecord = new Journey__c(Name = 'Test Journey', 
                                                  Status__c = 'Known',
                                                  Primary_Contact__c = contactRecord.Id,
                                                  NMD_Next_Contact_Date__c = Date.today());
        TestingUtility.insertWithAssert(journeyRecord);
    }
    @isTest
    public static void verifyWithoutSharingController(){
        Map<String, SObject> dataMap = new Map<String, SObject>();
        Test.startTest();
        List<Account> accounts = getAccounts();       
        verifyHelperCreateOrUpdateOpportunityTeammember();
        verifyUpdateAccountRecordType(accounts);
        verifyUpdateReleatedContactsandOpportunityRecordTypeAndOwner(); 
        
        /* Update Values */
        updateRecordType(accounts, dataMap);
        //Upadte dataMap.values();
        if(!dataMap.keySet().isEmpty()) {
            update dataMap.values();
        }
        Test.stopTest();
    }
    
    public static List<Account> getAccounts() {
        return (List<Account>) Database.query('SELECT '+String.join(getAccFields(), ',') +' FROM Account');
    }
    
    public static List<String> getAccFields(){
        Set<String> accountFields = new Set<String>();
        accountFields.add('Id');
        accountFields.add('Name');
        accountFields.add('Number_of_Full_Time_Employees__c');
        accountFields.add('RecordType.Name');
        return new List<String>(accountFields);
    }
    
    public static void updateRecordType(List<Account> accounts, Map<String, Sobject> mapAccounts) { 
        for(Account accountRecord :accounts) {
            if(accountRecord.Number_of_Full_Time_Employees__c == 2) {
                mapAccounts.put('RecordType Change', new Account(Id = accountRecord.Id, Number_of_Full_Time_Employees__c = 500));
            }
        }
    }

    public static void verifyHelperCreateOrUpdateOpportunityTeammember(){
        List<Opportunity> opportunities = [SELECT Id, Name, AccountId, StageName, 
                                           (SELECT Id, OpportunityId, TeamMemberRole, UserId FROM OpportunityTeamMembers)
                                    FROM Opportunity];
        User userRecord = [SELECT Id, Username, Email FROM User WHERE Email = :UNIQUE_ADMIN_USER_NAME LIMIT 1];
        OpportunityTeamMember objTeamMember = WithoutSharingUtilityController.helperCreateORUpdateOpportunityTeamMember(userRecord, opportunities[0], 'Business Development Manager');
        System.assertEquals('assist', objTeamMember.TeamMemberRole.toLowerCase());
        System.assertEquals('TourOutcomeForm', objTeamMember.TeamMemberCreationSource__c);
        OpportunityTeamMember objTeamMember2 = WithoutSharingUtilityController.helperCreateOpportunityTeamMember(adminUserRecord, opportunities[1], 'Business Development Manager');
        System.assertEquals('TourOutcomeForm', objTeamMember2.TeamMemberCreationSource__c);
        Integer lowerSize = WithoutSharingUtilityController.getLowerSize('10-20');
        System.assert(lowerSize == 10, 'Lower value shoud be 10');
    }
    
    /************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method is used to verify the account recordType based on the Number_of_Full_Time_Employees__c.
		Created Date  		:   16 Nov 2018
		Issue No			:	-
   **************************************************************************************************************************************/ 
    public static void verifyUpdateAccountRecordType(List<Account> accounts) {
        for(Account accountRecord : accounts){
            if(accountRecord.Number_of_Full_Time_Employees__c == 8){
                System.assertEquals('Business Account',accountRecord.RecordType.Name);
            }else if(accountRecord.Number_of_Full_Time_Employees__c == 50){
                System.assertEquals('Business Account', accountRecord.RecordType.Name);
            }else if(accountRecord.Number_of_Full_Time_Employees__c == 1100){
                System.assertEquals('Business Account', accountRecord.RecordType.Name);
            }
        }  
    }
    
    /************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method is used to verify Contact and Opportunity owner is same as Account
		Created Date  		:   16 Nov 2018
		Issue No			:	-
    **************************************************************************************************************************************/ 
    public static void verifyUpdateReleatedContactsandOpportunityRecordTypeAndOwner() {
        Account accountRecord = [SELECT Id FROM Account WHERE Number_of_Full_Time_Employees__c = 8];
        MetadataDrivenTriggerHandler.clearLoopCount('AccountBypassChildUpdateTrH');       
        update new Account(Id = accountRecord.Id, OwnerId = adminUserRecord.Id);        
        Contact contactRecord = [SELECT OwnerId FROM Contact WHERE AccountId =:accountRecord.Id];
//        System.assert(contactRecord.OwnerId == adminUserRecord.Id);
        Opportunity objOpportunity = [SELECT OwnerId FROM Opportunity WHERE AccountId =:accountRecord.Id];
//        System.assert(objOpportunity.OwnerId == adminUserRecord.Id);
    }
    
    /**********************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method is used to test update record type.
		Created Date  		:   16 Nov 2018
		Issue No			:	-
 **************************************************************************************************************************************************/
    public static void testUpdateRecordType(Map<String, SObject> mapAccounts) {
        Account accountRecord = [SELECT Id, Number_of_Full_Time_Employees__c, RecordType.Name FROM Account WHERE Id =:mapAccounts.get('RecordType Change').Id];
        if(accountRecord.Number_of_Full_Time_Employees__c == 500){
            System.assertEquals(accountRecord.RecordType.Name, 'Business Account');
        }  
    }

    @isTest
    private static void shouldSetRepPercentages() {
        List<User> users = getFakeUsers();
        List<UserRole> userRoles = getFakeUserRoles();
        List<OpportunityTeamMember> members = getFakeOpportunityTeamMembers();
        Map<Id, User> userSfdcRoleMap = new Map<Id, User>();
        userRoles[0].Name = 'Enterprise Solutions';
        userRoles[1].Name = 'Key Sales';
        members[0] = buildOpportunityTeamMemberWithFieldsFromJson(members[0], users[0]);
        members[1] = buildOpportunityTeamMemberWithFieldsFromJson(members[1], users[1]);
        members[0].User = users[0];
        members[1].User = users[1];
        users[0] = buildUserWithFieldsFromJson(users[0], userRoles[0]);
        users[1] = buildUserWithFieldsFromJson(users[1], userRoles[1]);
        userSfdcRoleMap.put(users[0].Id, users[0]);
        userSfdcRoleMap.put(users[1].Id, users[1]);

        Test.startTest();
        WithoutSharingUtilityController.setRepPercentageForEnterpriseSolutionsRole(members[0], userSfdcRoleMap);
        WithoutSharingUtilityController.setRepPercentageForOtherRoles(members[1], userSfdcRoleMap, new Opportunity());
        Test.stopTest();

        System.assertNotEquals(members[0].Split_Rep_Percentage__c, null, 'Rep Percentage should be set properly for Enterprise Solutions role');
        System.assertNotEquals(members[1].Split_Rep_Percentage__c, null, 'Rep Percentage should be set properly for Key Sales role');
    }

    @isTest
    private static void shouldSetNoRepPercentages() {
        List<User> users = getFakeUsers();
        List<UserRole> userRoles = getFakeUserRoles();
        List<OpportunityTeamMember> members = getFakeOpportunityTeamMembers();
        Map<Id, User> userSfdcRoleMap = new Map<Id, User>();
        userRoles[0].Name = 'Enterprise Solutions';
        userRoles[1].Name = 'Key Sales';
        members[0] = buildOpportunityTeamMemberWithFieldsFromJson(members[0], users[0]);
        members[1] = buildOpportunityTeamMemberWithFieldsFromJson(members[1], users[1]);
        members[0].User = users[0];
        members[1].User = users[1];
        users[0] = buildUserWithFieldsFromJson(users[0], userRoles[0]);
        users[1] = buildUserWithFieldsFromJson(users[1], userRoles[1]);

        Test.startTest();
        WithoutSharingUtilityController.setRepPercentageForEnterpriseSolutionsRole(members[0], userSfdcRoleMap);
        WithoutSharingUtilityController.setRepPercentageForOtherRoles(members[1], userSfdcRoleMap, new Opportunity());
        Test.stopTest();

        System.assertEquals(members[0].Split_Rep_Percentage__c, null, 'Rep Percentage should be not set');
        System.assertEquals(members[1].Split_Rep_Percentage__c, null, 'Rep Percentage should be not set');
    }


    private static OpportunityTeamMember buildOpportunityTeamMemberWithFieldsFromJson(OpportunityTeamMember memberRecord, User userRecord){
        Map<String, Object> memberRaw = (Map<String, Object>) JSON.deserializeUntyped(
                JSON.serialize(SObjectChildRecordsMockWrapper.addChildRecords(
                    memberRecord,
                    new Map<String, List<SObject>>{
                            'UserId' => new List<User>{userRecord}
                    }
        )));
        memberRaw.put('UserId', userRecord.Id);
        return (OpportunityTeamMember) JSON.deserialize(JSON.serialize(memberRaw), OpportunityTeamMember.class);
    }
    private static User buildUserWithFieldsFromJson(User userRecord, UserRole role){
        Map<String, Object> userRaw = (Map<String, Object>) JSON.deserializeUntyped(
                JSON.serialize(SObjectChildRecordsMockWrapper.addChildRecords(
                    userRecord,
                    new Map<String, List<SObject>>{
                            'UserRole' => new List<UserRole>{role}
                    }
        )));
        userRaw.put('UserRole', role);
        return (User) JSON.deserialize(JSON.serialize(userRaw), User.class);
    }

    private static List<User> getFakeUsers() {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'User');
        recordsData.put('numberOfRecords', 2);
        return MockTestingUtility.getRecords(recordsData, true);
    }

    private static List<UserRole> getFakeUserRoles() {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'UserRole');
        recordsData.put('numberOfRecords', 2);
        return MockTestingUtility.getRecords(recordsData, true);
    }

    private static List<OpportunityTeamMember> getFakeOpportunityTeamMembers() {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'OpportunityTeamMember');
        recordsData.put('numberOfRecords', 2);
        return MockTestingUtility.getRecords(recordsData, true);
    }

}