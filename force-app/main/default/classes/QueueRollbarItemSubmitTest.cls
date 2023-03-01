/*************************************************************************************************************************************
    Author      :   Rashad Saeed
    Description :   Test class for (Rollbar, RollbarConnection, QueueRollbarItemSubmit, RollBarItem)
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR          DETAIL
    1          31 Dec, 2018    Rashad Saeed    Initial Deployment - WeWork SF-Rollbar Integration Google Doc
**************************************************************************************************************************************/
@IsTest
private class QueueRollbarItemSubmitTest {
    @IsTest
    static void shouldSuccessfullyCalloutToRollbar() {
        Apex_Debug_Log__c apexDebugLog = new Apex_Debug_Log__c(Apex_Class__c='Test');
        insert apexDebugLog;
        new RollbarItem(apexDebugLog);
        QueueableContext qc;
        QueueRollbarItemSubmit queueRollbarItem = new QueueRollbarItemSubmit();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        queueRollbarItem.execute(qc);
        Test.stopTest();
    }
}