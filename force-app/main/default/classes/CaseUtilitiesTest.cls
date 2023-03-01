@isTest
public with sharing class CaseUtilitiesTest {
    @isTest
    static void testGetCaseSalesRecordTypeIds() {
        Id reaCaseRTId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND Name = 'REA'].Id;
        Test.startTest();
        System.assert(new CaseUtilities().getCaseSalesRecordTypeIds().contains(reaCaseRTId), 'REA record type should be included to sales record types');
        Test.stopTest();
    }

    @isTest
    static void testGetCaseServiceRecordTypeIds() {
        Id supportRequestCaseRTId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND Name = 'Support Request'].Id;
        Case c = new Case(RecordTypeId = supportRequestCaseRTId, Status = 'New');
        Test.startTest();
        System.assertEquals(1, new CaseUtilities().getServiceOnlyCases(new List<Case>{ c }).size(), 'Support request case should be included to service cases');
        System.assert(new CaseUtilities().getSalesOnlyCases(new List<Case>{ c }).isEmpty(), 'Support request case should not be included to sales cases');
        Test.stopTest();
    }
}