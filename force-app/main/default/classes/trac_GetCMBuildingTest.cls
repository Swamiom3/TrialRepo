/************************************************************************************************************************************
Author      :   Daniel Labonte
Description :   This class provides sufficient test coverage for trac_GetCMBuilding class
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           24 Oct 2019         Daniel Labonte      Initial Developement
2           29 Novem 2021         Vamsi               To Increase Code Coverage
**************************************************************************************************************************************/

@isTest
private class trac_GetCMBuildingTest {
    static final TLTestFactory FACTORY = new TLTestFactory();    
    static final String ADMIN_UNIQUE = 'test-admin-user';
    static final String DOMAIN = '@test-weco.test';
    
    static final String REGION_NAME = 'Region';
    static final String TERRITORY_NAME = 'Territory';
    static final String BUILDING_NAME = 'Building1234qwerasdfzxcvasdfqwer1234';
    
    
    @TestSetup
    static void setup() {
        User admin = TLTestUtils.createUsers('System Administrator',1)[0];
        admin.Username = ADMIN_UNIQUE + DOMAIN;
        admin.CommunityNickname = ADMIN_UNIQUE;
        
        insert admin;
        
        Test.startTest();
        Building__c newBuilding = new Building__c();
        newBuilding.Building_Status__c = 'Opened';
        newBuilding.City__c = 'Hyd';
        newBuilding.Region_Name__c = 'TestHyd';
        insert newBuilding;
        Test.stopTest();
    }
    
    
    @isTest
    static void testGetCMBuilding() {
        User user = [SELECT Id FROM User WHERE Username = :ADMIN_UNIQUE+DOMAIN];
        
        List<Group>  lstGroup = new List<Group>();
        Group testGroup = new Group(Name = 'CM_Building1234qwerasdfzxcvasdfqwer1234', Type = 'Queue');
        lstGroup.add(testGroup);
        TestingUtility.insertListWithAssert(lstGroup);
        
        insert new GroupMember(GroupId = lstGroup[0].Id, UserOrGroupId = user.Id);
        
        List<GroupMember> getGroupMembers = [SELECT GroupId FROM GroupMember WHERE UserOrGroupId = :user.Id];
        Building__c getbuildings = [SELECT Id FROM Building__c WHERE Building_Status__c = 'Opened' AND City__c = 'Hyd' AND Region_Name__c = 'TestHyd' LIMIT 1];
        System.runAs(user){
            List<Location_Queue__c> locationQueueList = new List<Location_Queue__c>();
            Location_Queue__c locationQueue = new Location_Queue__c(
                building_Id__c = getbuildings.Id,
                Queue_Label__c = 'TEST: Building Name',
                Queue_Prefix__c = 'CM'
            );
            locationQueueList.add(locationQueue);
            insert locationQueueList;            
            
            locationQueue.Queue_Id__c = getGroupMembers.get(0).GroupId;
            update locationQueue;
        }   
        
        trac_GetCMBuilding.Inputs inputs = new trac_GetCMBuilding.Inputs();
        inputs.userId = user.Id;
        inputs.prefix = 'CM';
        inputs.match = 'none';
        List<String> listWithNoneMatch = trac_GetCMBuilding.getCMBuilding(new List<trac_GetCMBuilding.Inputs>{inputs});
        
        inputs.match = 'first';
        List<String> listWithFirstMatch = trac_GetCMBuilding.getCMBuilding(new List<trac_GetCMBuilding.Inputs>{inputs});	
        List<String> listWithEmptyInput = trac_GetCMBuilding.getCMBuilding(new List<trac_GetCMBuilding.Inputs>());
        
        System.runAs(user){
            List<Location_Queue__c> locationQueueList = new List<Location_Queue__c>();
            Location_Queue__c locationQueue = new Location_Queue__c(
                building_Id__c = getbuildings.Id,
                Queue_Label__c = 'TEST: Building Name Test',
                Queue_Prefix__c = 'CM'
            );
            locationQueueList.add(locationQueue);
            insert locationQueueList;            
            
            locationQueue.Queue_Id__c = getGroupMembers.get(0).GroupId;
            update locationQueue;
        }
        
        inputs.userId = user.Id;
        inputs.prefix = 'CM';
        inputs.match = 'last';
        List<String> listWithLastMatch = trac_GetCMBuilding.getCMBuilding(new List<trac_GetCMBuilding.Inputs>{inputs});
        
        Set<String> membershipIds = TLList.collectStrings([SELECT GroupId FROM GroupMember WHERE UserOrGroupId = :user.Id],GroupMember.GroupId);
        List<Location_Queue__c> locationQueues = [SELECT Id,Location__r.Id FROM Location_Queue__c WHERE Queue_Id__c=:getGroupMembers.get(0).GroupId AND Queue_Prefix__c='CM'];
        
        System.assertEquals(null, listWithNoneMatch, 'List must be empty');
        System.assertEquals(locationQueues.get(0).Location__r.Id, listWithFirstMatch.get(0), 'Not an expected Id');
        System.assertEquals(locationQueues.get(locationQueues.size()-1).Location__r.Id, listWithLastMatch.get(0), 'If there are more than 1 LocationQueues should get the last Record');
        System.assertEquals(null, listWithEmptyInput, 'List must be empty');
    }
}