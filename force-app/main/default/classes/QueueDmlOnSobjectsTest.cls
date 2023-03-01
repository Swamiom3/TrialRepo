/************************************************************************************************************************************
    Author 		: Shobhit Gahlot
    Description : This class will have the logic to test QueueDmlOnSobjects
	Issue		: ST-6416
--------------------------------------------------------------------------------------------------------------------------------------
    VERSION					DATE					AUTHOR							DETAIL
    1					    12 June, 2020		    Shobhit Gahlot               	Initial Development
*************************************************************************************************************************************/
@isTest
public class QueueDmlOnSobjectsTest {
    
    @testSetup
    static void testSetup(){
        Test.startTest();
        System.enqueueJob(new QueueDmlOnSobjects(UtilBuilding.createBuildings(1, false), false, false, true, false, true));
        Test.stopTest();
        List<Building__c> lstBuildings = [SELECT Id FROM Building__c];
        System.assert(lstBuildings.size() == 1);
    }
    
    @isTest
    static void testUpdateSobjects(){
        List<Building__c> lstBuildings = [SELECT Id FROM Building__c];
        lstBuildings[0].UUID__c = 'QueueDmlOnSobjectsTest01';
        Test.startTest();
        System.enqueueJob(new QueueDmlOnSobjects(new List<Building__c>{lstBuildings[0]}, false, true, false, false, true));
        Test.stopTest();
        lstBuildings = [SELECT Id, UUID__c FROM Building__c];
        System.assert(lstBuildings[0].UUID__c == 'QueueDmlOnSobjectsTest01');
    }
    
    @isTest
    static void testDeleteSobjects(){
        List<Building__c> lstBuildings = [SELECT Id FROM Building__c];
        Test.startTest();
        delete[select Id,Name from serviceterritory where Name='test1'];
        System.enqueueJob(new QueueDmlOnSobjects(new List<Building__c>{lstBuildings[0]}, true, false, false, false, true));
        Test.stopTest();
        System.assert([SELECT Id, UUID__c FROM Building__c].size() == 0);
    }
    
    @isTest
    static void testUnDeleteSobjects(){
        delete[select Id,Name from serviceterritory where Name='test1'];
        List<Building__c> lstBuildings = [SELECT Id FROM Building__c];
        delete lstBuildings;
        System.assert([SELECT Id, UUID__c FROM Building__c].size() == 0);
        QueueDmlOnSobjects objQueueDmlOnSobjects = new QueueDmlOnSobjects(null, false, false, false, true, true);
        Test.startTest();
        System.enqueueJob(new QueueDmlOnSobjects(new List<Building__c>{lstBuildings[0]}, false, false, false, true, true));
        try{
            objQueueDmlOnSobjects.execute(null);
        }catch(Exception ex){
            System.assertEquals(objQueueDmlOnSobjects.ERROR_MESSAGE, ex.getMessage());
        }
        Test.stopTest();
        System.assert([SELECT Id, UUID__c FROM Building__c].size() == 1);
    }
}