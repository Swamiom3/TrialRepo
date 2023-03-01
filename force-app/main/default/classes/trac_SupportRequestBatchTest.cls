/**
 * @description Scheduler class for trac_SupportRequestBatch - It runs in every 6 hours
 * @name trac_SupportRequestBatchSchedule
 * @author Shubham Jain, Traction on Demand
 * @date 2020-01-21
 */
@IsTest
public with sharing class trac_SupportRequestBatchTest {
    private static TLTestFactory factory = new TLTestFactory();
    @TestSetup
    public static void createCaseData() {
        Account testAccount = new Account(LastName = 'Test Contact', RecordTypeId = TLOrgConstants.PERSON_ACCOUNT_RECORD_TYPE_ID, personEmail = 'test@tractionondemand.com');
        insert testAccount;
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Location__c region = (Location__c) factory.createSObject(new Location__c(Name = 'Region', RecordTypeId = trac_LocationConstants.RTID_REGION), true);
        Location__c territory = (Location__c) factory.createSObject(new Location__c(Name = 'Territory', Region__c = region.Id, RecordTypeId = trac_LocationConstants.RTID_TERRITORY), true);
        Location__c building1 = (Location__c) factory.createSObject(new Location__c(Name = 'Building1', Territory__c = territory.Id, RecordTypeId = trac_LocationConstants.RTID_BUILDING, City__c='London'), true);

        List<Case> testSupportRequests = (List<Case>) FACTORY.createSObjects(new Case(
                Subject = 'Test Subject',
                ContactId = testContact.Id,
                RecordTypeId = TLOrgConstants.SUPPORT_REQUEST_RECORD_TYPE_ID,
                Status = TLOrgConstants.CASE_STATUS_WAITING,
                WeCo_Line_of_Business__c = TLOrgConstants.CASE_LINE_OF_BUSINESS_WEWORK,
                Location__c = building1.Id
        ), 3, true);
        Case testSupportRequest1 = (Case) FACTORY.createSObject(new Case(
                Subject = 'Test Subject',
                ContactId = testContact.Id,
                RecordTypeId = TLOrgConstants.SUPPORT_REQUEST_RECORD_TYPE_ID,
                Status = TLOrgConstants.CASE_STATUS_SOLVED,
                WeCo_Line_of_Business__c = TLOrgConstants.CASE_LINE_OF_BUSINESS_WEWORK,
                Location__c = building1.Id
        ), true);
        for (Case testSupportRequest : testSupportRequests) {
            testSupportRequest.Waiting_on_Support_Request_24_hours__c = System.Now().addMinutes(-120);
            testSupportRequest.Waiting_on_Support_Request_4_days__c = System.Now().addMinutes(-120);
            //testSupportRequest.Waiting_on_Support_Request_Submitter__c = System.Now().addMinutes(-120);
        }
        update testSupportRequests;
        testSupportRequest1.Support_Request_Re_Open_Till_Date__c = System.Now().addMinutes(-120);
        update testSupportRequest1;
    }

    @IsTest
    public static void runSupportRequestBatch() {
        Test.startTest();
        Database.executeBatch(new trac_SupportRequestBatch(), 200);
        Test.stopTest();
        for (Case cs : [
                SELECT Id, Waiting_on_Support_Request_24_hours__c, Waiting_on_Support_Request_4_days__c, Waiting_on_Support_Request_Submitter__c,
                        Status, Is_24_Hours_After_Email_Sent__c, Support_Request_Re_Open_Till_Date__c,
                        Is_4_Days_After_Email_Sent__c, Is_7_Days_After_Email_Sent__c,
                        Is_Status_Closed_After_3_Days__c
                FROM Case
                ORDER BY CreatedDate DESC
                LIMIT 4
        ]) {
            if (cs.Waiting_on_Support_Request_24_hours__c > (System.now().addMinutes(-420)) && cs.Waiting_on_Support_Request_24_hours__c < System.now() && !cs.Is_24_Hours_After_Email_Sent__c)
                //System.assertEquals(true, cs.Is_24_Hours_After_Email_Sent__c, '24 hour email not sent.');
            if (cs.Waiting_on_Support_Request_4_days__c > (System.now().addMinutes(-420)) && cs.Waiting_on_Support_Request_4_days__c < System.now() && !cs.Is_4_Days_After_Email_Sent__c)
                //System.assertEquals(true, cs.Is_4_Days_After_Email_Sent__c, '4 day email not sent.');
            if (cs.Waiting_on_Support_Request_Submitter__c > (System.now().addMinutes(-420)) && cs.Waiting_on_Support_Request_Submitter__c < System.now() && !cs.Is_7_Days_After_Email_Sent__c)
                //System.assertEquals(true, cs.Is_7_Days_After_Email_Sent__c, '7 day email not sent.');
            if (cs.Support_Request_Re_Open_Till_Date__c > (System.now().addMinutes(-420)) && cs.Support_Request_Re_Open_Till_Date__c < System.now() && !cs.Is_Status_Closed_After_3_Days__c){
                //System.assertEquals(true, cs.Is_Status_Closed_After_3_Days__c, 'Status not closed after 3 days.');
                System.debug('>>>3days>>>');

            }
        }
    }
}