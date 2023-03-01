/**
* @description Test class for the trac_QueueManagerController
* @date 2021-10-11
*/
@isTest
public class trac_QueueManagerControllerTest {
    @testSetup
    public static void createTestDatas(){
        
        List<QueueSobject> queueList = [SELECT Id,Queue.Name,QueueId FROM QueueSobject WHERE SobjectType = 'Case'];
        
        Global__c testGlobalSetting = new Global__c();
        testGlobalSetting.Security_Only_Queue_Prefixes__c = 'GSOC_Security_Systems_and_Operations';
        testGlobalSetting.Security_Only_Queues__c = 'GSOC_Security_Systems_and_Operations';
        insert testGlobalSetting;
        
        Building__c testLocation = new Building__c();
        testLocation.Name = 'US';
        insert testLocation;
        
        List<Location_Queue__c> testLocationQueueList = new List<Location_Queue__c>();
        Location_Queue__c locationQueueTest = new Location_Queue__c();
        locationQueueTest.Queue_Id__c = queueList[0].QueueId;
        locationQueueTest.Queue_Label__c = 'WWBA: USTEST';
        locationQueueTest.Queue_Developer_Name__c = 'WWBA_US_Test';
        locationQueueTest.Queue_Prefix__c = 'USTEST';
        locationQueueTest.building_Id__c = testLocation.Id;
        testLocationQueueList.add(locationQueueTest);
        
        Location_Queue__c locationQueueTestTwo = new Location_Queue__c();
        locationQueueTestTwo.Queue_Id__c = queueList[0].QueueId;
        locationQueueTestTwo.Queue_Label__c = 'FM';
        locationQueueTestTwo.Queue_Developer_Name__c = 'FM';
        locationQueueTestTwo.Queue_Prefix__c = 'FM';
        locationQueueTestTwo.building_Id__c = testLocation.Id;
        testLocationQueueList.add(locationQueueTestTwo);
        
        insert testLocationQueueList;
    }
    
    @isTest
    public static void testExternalVendorTrac_QueueManagerController(){
        List<UserRole> userRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'External_Vendor'];
        User loggedUser = [SELECT Id,ProfileId,Profile.Name FROM User WHERE Id =:UserInfo.getUserId()];
        Boolean isUserAdmin = loggedUser.Profile.Name == TLOrgConstants.PROFILE_SYSTEM_ADMIN ? true : false;
        loggedUser.UserRoleId = userRole[0].Id;
        update loggedUser;
            
        Test.startTest();
        Boolean isAdmin = trac_QueueManagerController.isUserAdmin();
        List<Location_Queue_Type__mdt> locationQueueTypes = trac_QueueManagerController.getLocationQueueTypes();
        List<trac_QueueManagerController.LocationQueueMembership> cMLocationQueues = trac_QueueManagerController.getCMLocationQueues(loggedUser.Id);
        
        trac_QueueManagerController.LocationQueueMembership wrapperClass = new trac_QueueManagerController.LocationQueueMembership(
            '', '', '', '', 'Other', 'Location unavailable', true, false
        );
        wrapperClass.getLocationId();
        wrapperClass.getLocationName();
        wrapperClass.getQueueName();
        wrapperClass.getQueueId();
        wrapperClass.getPrefix();
        wrapperClass.getTimeZone();
        wrapperClass.getIsMember();
        wrapperClass.getIsLocation();
        Test.stopTest();
        
        system.assert(isUserAdmin == isAdmin);
        system.assert(locationQueueTypes.size() > 0);
        system.assert(cMLocationQueues.size() > 0);
    }
    
    @isTest
    public static void testLoggedUserTrac_QueueManagerController(){
        User loggedUser = [SELECT Id,ProfileId,Profile.Name FROM User WHERE Id =:UserInfo.getUserId()];
        Boolean isUserAdmin = loggedUser.Profile.Name == TLOrgConstants.PROFILE_SYSTEM_ADMIN ? true : false;
            
        Test.startTest();
        Boolean isAdmin = trac_QueueManagerController.isUserAdmin();
        List<Location_Queue_Type__mdt> locationQueueTypes = trac_QueueManagerController.getLocationQueueTypes();
        List<trac_QueueManagerController.LocationQueueMembership> cMLocationQueues = trac_QueueManagerController.getCMLocationQueues(loggedUser.Id);
        Test.stopTest();
        
        system.assert(isUserAdmin == isAdmin);
        system.assert(locationQueueTypes.size() > 0);
        system.assert(cMLocationQueues.size() > 0);
    }
    
    @isTest
    public static void insertDeleteQueueMemberTest(){
        List<String> queueIds = new List<String>();
        
        for(QueueSobject q : [SELECT Id,Queue.Name,QueueId FROM QueueSobject WHERE SobjectType = 'Case' LIMIT 2]){
            queueIds.add(q.QueueId);
        }
        
        Test.startTest();
        Boolean success = trac_QueueManagerController.insertQueueMember(queueIds, UserInfo.getUserId());
        system.assert(success);
        
        Boolean successDelete = trac_QueueManagerController.deleteQueueMember(queueIds);
        system.assert(successDelete);
        Test.stopTest();
    }
}