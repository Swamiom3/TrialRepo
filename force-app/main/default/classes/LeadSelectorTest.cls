/*************************************************************************************************************************************
    Author      :    Pawel Biszczak
    Description :    This class provides sufficient test coverage for LeadSelector class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             DETAIL
    1          13 Apr, 2021    Pawel Biszczak     Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class LeadSelectorTest {
    private static LeadSelector leadSelector = new LeadSelector();

    @testSetup
    static void makeData(){
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objName', 'Lead');
        recordsData.put('numberOfRecords', 2);
        recordsData.put('doInsert', true);
        TestingUtility.getRecords(recordsData);
    }

    @isTest
    static void shouldGetLeadsByIds(){
        List<Lead> leads;
        Set<Id> leadIds = new Map <Id, Lead> ([SELECT Id
                                               FROM Lead]).keySet();

        Test.startTest();
        leads = leadSelector.getLeadsById(new List<Id>(leadIds));
        Test.stopTest();

        System.assertEquals(2, leads.size(), 'Should get 2 leads');
    }

    @isTest
    static void shouldGetLeadsByIdsAndNotNullEmail(){
        List<Lead> leads;
        Set<Id> leadIds = new Map <Id, Lead> ([SELECT Id
                                               FROM Lead]).keySet();

        Test.startTest();
        leads = leadSelector.getLeadsByIdAndNotNullEmail(new List<Id>(leadIds));
        Test.stopTest();

        System.assertEquals(2, leads.size(), 'Should get 2 leads');
    }
}