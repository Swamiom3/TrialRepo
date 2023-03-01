/**
 * @description Unit tests for the trac_LocationQueue class
 * @see trac_LocationQueue
 * @author Daniel Labonte, Traction on Demand
 * @date 2020-05-04
 */

@IsTest
private class trac_LocationQueueTest {
    static final TLTestFactory factory = new TLTestFactory();


    @IsTest
    static void testInsert() {
        //SObjectDomain.getTriggerEvent(trac_Location.class).disableAll();

        Building__c building = new Building__c(Name = 'Building Name');
        insert building;
        
        Location_Queue__c locationQueue = new Location_Queue__c(
            building_Id__c = building.Id,
            Queue_Developer_Name__c = 'TEST_Building_Name',
                Queue_Label__c = 'TEST: Building Name'
        );
        Test.startTest();
        insert locationQueue;
        Test.stopTest();

        Group queue = [SELECT Id, Name FROM Group WHERE DeveloperName = 'TEST_Building_Name'];
        System.assertEquals('TEST: Building Name',queue.Name);
    }


    @IsTest
    static void testUpdate() {
        //SObjectDomain.getTriggerEvent(trac_Location.class).disableAll();
        
        Building__c building = new Building__c(Name = 'Building Name');
        insert building;
        
        Location_Queue__c locationQueue = new Location_Queue__c(
                building_Id__c = building.Id,
                Queue_Developer_Name__c = 'TEST_Building_Name',
                Queue_Label__c = 'TEST: Building Name'
        );
        insert locationQueue;

        Test.startTest();
        locationQueue.Queue_Label__c = 'TEST: Building NEW Name';
        update locationQueue;
        Test.stopTest();

        Group queue = [SELECT Id, Name FROM Group WHERE DeveloperName = 'TEST_Building_Name'];
        System.assertEquals('TEST: Building NEW Name',queue.Name);
    }


    @IsTest
    static void testDelete() {
        //SObjectDomain.getTriggerEvent(trac_Location.class).disableAll();
        
        Building__c building = new Building__c(Name = 'Building Name');
        insert building;
        
        Location_Queue__c locationQueue = new Location_Queue__c(
                building_Id__c = building.Id,
                Queue_Developer_Name__c = 'TEST_Building_Name',
                Queue_Label__c = 'TEST: Building Name'
        );
        insert locationQueue;

        Test.startTest();
        delete locationQueue;
        Test.stopTest();

        List<Group> queues = [SELECT Id FROM Group WHERE DeveloperName = 'TEST_Building_Name'];
        System.assertEquals(0,queues.size());
    }
}