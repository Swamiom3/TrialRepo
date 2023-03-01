@isTest
public class CaseBuildingChangedTrHTest {
    
    @isTest
    static void getBuildingCodeTest(){
        Group q1 = [select Id,Name from Group where Type = 'Queue'limit 1];
        BusinessHours hours = [SELECT ID FROM BusinessHours WHERE Name='India (Asia/Kolkata)'];
        List<Trigger_Configuration__mdt> configurationRecord = [SELECT Implementing_Class__c,
                                                                      Object_API_Name__c,
                                                                      Order_of_Execution__c,
                                                                      Is_Forced_Execution__c,
                                                                      Active__c
                                                               FROM Trigger_Configuration__mdt
                                                               WHERE Event_Time__c = null
                                                               ORDER BY Order_of_Execution__c];
        List<Building__c> createdBuildingList = new List<Building__c>();
        Building__c createdBuilding = new Building__c();
        createdBuilding.Address__c = '123 test street';
        createdBuilding.Building_Class__c = 'A';
        createdBuilding.Territory_Name__c = 'Test Territory One';
        createdBuilding.WeCode__c = '12345678';
        createdBuilding.Country__c = 'Canada';
        createdBuilding.Default_Language__c = 'English';
        createdBuilding.Business_Hours_Id__c = hours.Id;
        createdBuilding.City__c = 'Toronto';
        
        Building__c createdBuilding1 = new Building__c();
        createdBuilding1.Address__c = '12345 test street';
        createdBuilding1.Building_Class__c = 'B';
        createdBuilding1.Territory_Name__c = 'Test Territory Two';
        createdBuilding1.WeCode__c = '1234567899';
        createdBuilding1.Country__c = 'Canada';
        createdBuilding1.Default_Language__c = 'English';
        createdBuilding1.Business_Hours_Id__c = hours.Id;
        createdBuilding1.City__c = 'Toronto';
        
        createdBuildingList.add(createdBuilding);
        createdBuildingList.add(createdBuilding1);
        insert createdBuildingList;
      
        Location_Queue__c locqueue = new Location_Queue__c();
        locqueue.Queue_Developer_Name__c ='Test';
        locqueue.Building_Id__c = createdBuilding.Id;
        locqueue.Queue_Id__c = q1.Id;
        locqueue.Queue_Label__c ='TestLabel';
        insert locqueue;
        
        Location_Queue__c locque1 =[select Id, Name,Building_Id__c,Queue_Id__c from Location_Queue__c where Id =: locqueue.Id];
        
        Case createCase = new Case();
        createCase.SuppliedEmail = 'test@test.test';
        createCase.Status = 'Waiting_on_Support_Request_Submitter';  
        createCase.BusinessHoursId = hours.Id;
        createCase.Building_Nearest_Address__c = createdBuildingList[0].Id;
        createCase.RecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('Enterprise Finance & Strategy').getRecordTypeId();        
        
        Id profId = [Select Id, Name FROM Profile WHERE Name='WeWork Interr Vendor'].Id;
        User usrId =[Select Id, Name FROM User WHERE profileId=:profId AND isActive=true LIMIT 1];
        Test.startTest();
        System.runAs(usrId){           
            insert createCase;
        }    
        createCase.Building_Nearest_Address__c = createdBuildingList[1].Id;
        update createCase;
        Test.stopTest();
    }
}