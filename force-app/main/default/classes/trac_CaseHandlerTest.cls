/************************************************************************************************************************************
Author : Vamsi
Description : This class provides sufficient test coverage for trac_CaseHandler class
----------------------------------------------------------------------------------------------------------------------------------
VERSION    DATE        AUTHOR    DETAIL
1          20 Nov 2021 Vamsi     Initial Developement
**************************************************************************************************************************************/
@isTest
public class trac_CaseHandlerTest {
    static final TLTestFactory factory = new TLTestFactory();
    
    static final String REGION_NAME = 'My Region';
    static final String TERRITORY_NAME = 'My Territory';
    static final String BUILDING_NAME = 'My Building';
    
    @testSetup
    static void setup() {
        Building__c createdBuilding = new Building__c();
        createdBuilding.Address__c = '123 test street';
        createdBuilding.Building_Class__c = 'A';
        createdBuilding.WeCode__c = '12345678';
        insert createdBuilding;
    }
    
    @isTest
    static void getBuildingCodeTest(){
        Test.startTest();
        String actualcode = trac_CaseHandler.getBuildingCode('Test Subject');
        Test.stopTest();
        
        System.assertEquals('Subject', actualcode,'Billingcode is not correct');
    }
    
    @isTest
    static void isSolvedStatusTest(){
        BusinessHours hours = [SELECT ID
        FROM BusinessHours
        WHERE Name='India (Asia/Kolkata)'];
        Case testCase = new Case();
        testCase.SuppliedEmail = 'test@test.test';
        testCase.Status='Solved';
        testCase.RecordTypeId=(Schema.SObjectType.Case.getRecordTypeInfosByName().get('Enterprise Finance & Strategy').getRecordTypeId());
        testCase.Origin = 'Email';
        testCase.BusinessHoursId = hours.Id;
        testCase.First_Response_Time__c = System.now();
        testCase.CreatedDate = System.now();
        insert testCase;
        
        System.assertEquals(testCase.Id, [SELECT Status FROM Case WHERE SuppliedEmail = 'test@test.test' AND BusinessHoursId=:hours.Id LIMIT 1].Id, 'Record not Created');
        
        List<Case> cases = new List<Case>();
        cases.add(testCase);
        
        Test.startTest();
        Boolean solvedStatus = trac_CaseHandler.isSolvedStatus(testCase);
        Boolean supportRequest = trac_CaseHandler.isSupportRequest(testCase);
        trac_CaseHandler.IsWeLOB(testCase);
        Boolean notNull = trac_CaseHandler.isValue(testCase);
        trac_CaseHandler.queryDefaultBusinessHour();
        
        trac_CaseHandler.maskCreditCardNumbers(cases);
        
        testCase.Origin = 'Printer Email';
        
        testCase.Status = 'Waiting_on_Support_Request_Submitter';
        testCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Request').getRecordTypeId();
        trac_CaseHandler.updateSupportRequestWaitingOnSubmitterFields(testCase);
        
        testCase.Status = 'New';
        testCase.WeCo_Line_of_Business__c = 'WeWork';
        trac_CaseHandler.updateSupportRequestIsBusinessDay(testCase);
        
        Test.stopTest();
        
        System.assertEquals(true, solvedStatus,'Case Not Sloved yet');
        System.assertEquals(false, supportRequest,'Record Type Id is not equal to Service Request Id');
        System.assertEquals(true, notNull,'Input is a Null Object');
    }
    
    @isTest
    static void queryLocationsByIdsTest(){
        Test.startTest();
        Building__c building = [SELECT ID,Name FROM Building__c WHERE WeCode__c='12345678' AND Building_Class__c='A' LIMIT 1];
        Set<Id> buildingIds = new Set<Id>();
        buildingIds.add(building.Id);
        
        List<Building__c> Buildings = trac_CaseHandler.queryLocationsByIds(buildingIds);
        
        Test.stopTest();
        
        System.assertEquals(building, Buildings[0], 'Should get the Building records');
    }
    
    @isTest
    static void businessHoursTest(){
        Test.startTest();
        
        BusinessHours hours = [SELECT ID FROM BusinessHours WHERE Name='India (Asia/Kolkata)'];
        
        DateTime modifyDate = DateTime.newInstance(2020, 12, 22);
        Boolean workingDay = trac_CaseHandler.isWorkingDay(hours.Id,modifyDate);
        
        Date expectedStartDate = modifyDate.addDays(1).Date();
        DateTime startDate = trac_CaseHandler.addDays(hours.Id, modifyDate, 1);
        
        modifyDate = DateTime.newInstance(2020, 12, 25);
        Boolean Holiday = trac_CaseHandler.isHoliday(hours.Id, modifyDate);
        
        modifyDate = Datetime.newInstance(2020, 12, 24);
        DateTime newDate = trac_CaseHandler.addDays(hours.Id, modifyDate, 1);
        
        Test.stopTest();
        
	    System.assertEquals(true, Holiday,'Not a hoilday');
	    System.assertEquals(true, workingDay, 'Not a WorkingDay');
	    System.assertEquals(expectedStartDate, startDate.date(), 'Incorrect Date');
	    System.assertEquals(DateTime.newInstance(2020, 12, 27).Date(), newDate.date(), 'Incorrect Date');
   
    }
}