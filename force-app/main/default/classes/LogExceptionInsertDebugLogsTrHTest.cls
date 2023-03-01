/*************************************************************************************************************************************
    Author      :   Krishana Tupe
    Description :   This class is used to test LogExceptionInsertDebugLogsTrH
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR            DETAIL
    1          2 May, 2018     Krishana Tupe     Initial development
    2          29 Nov, 2021    Pawel Biszczak    Refactor
**************************************************************************************************************************************/
@isTest
public with sharing class LogExceptionInsertDebugLogsTrHTest {
    @isTest
    public static void verifyApexDebugLogsExceptionUsingPlatformEvent(){
        try{
            Test.startTest();
            LogException__e newEvent = new LogException__e(
                    Apex_Class__c = 'strClassName',
                    ErrorLineNumber__c = 5,
                    Exception_Type__c = 'Error',
                    ExceptionTypeName__c = 'ex.getTypeName()',
                    Message__c = 'ex.getMessage()',
                    Method__c = 'strMethodName',
                    Record__c = 'listRecordIds',
                    Login_User_ProfileId__c =  UserInfo.getProfileId(),
                    Login_UserId__c         =  UserInfo.getUserId(),
                    Stack_Trace__c = 'ex.getStackTraceString()'
            );
            // Call method to publish events
            EventBus.publish(newEvent);
            Test.stopTest();

            List<Apex_Debug_Log__c> apexDebugLogs = [ SELECT Id, Apex_Class__c, ApexLogId__c, Message__c,
                                                             Method__c, Record_Id__c, Stack_Trace__c,
                                                             Login_UserId__c, Login_User_ProfileId__c
                                                      FROM Apex_Debug_Log__c ];
            System.assert(apexDebugLogs != null);
            System.assertEquals('strClassName', apexDebugLogs[0].Apex_Class__c);
            System.assertEquals('ex.getMessage()', apexDebugLogs[0].Message__c);
            System.assertEquals('ex.getStackTraceString()', apexDebugLogs[0].Stack_Trace__c);
            System.assertEquals('strMethodName', apexDebugLogs[0].Method__c);
            System.assertEquals(UserInfo.getUserId(), apexDebugLogs[0].Login_UserId__c);
            System.assertEquals(UserInfo.getProfileId(), apexDebugLogs[0].Login_User_ProfileId__c);

        }catch(Exception pEx) {
            ApexDebugLog.logException(pEx, 'Test Exception', 'LogExceptionInsertDebugLogsTrHTest', 'verifyApexDebugLogsExceptionUsingPlatformEvent');
            throw new ApexDebugLog.ApexLogCustomException('Exception thrown ' +
                                                          'from LogExceptionInsertDebugLogsTrHTest' +
                                                          '.verifyApexDebugLogsExceptionUsingPlatformEvent(): ' +
                                                          pEx);
        }
    }

    public static void getException(){
        try{
            insert new Lead();
        }catch(Exception pEx){
            Test.startTest();
            ApexDebugLog.logException(pEx,'Test Exception', 'LogExceptionInsertDebugLogsTrHTest', 'getException');
            Test.stopTest();
            throw new ApexDebugLog.ApexLogCustomException('Exception thrown from ' +
                                                          'LogExceptionInsertDebugLogsTrHTest.getException(): ' + pEx);
        }
    }

    @IsTest
    public static void verifyApexDebugLogsException(){
        try{
            getException();
        }catch(Exception pEx){
            List<Apex_Debug_Log__c> apexDebugLogs = [ SELECT Id, ReplayId__c, Apex_Class__c,
                                                             ApexLogId__c, Message__c, Method__c, Record_Id__c,
                                                             Stack_Trace__c, Login_UserId__c, Login_User_ProfileId__c
                                                      FROM Apex_Debug_Log__c
                                                      ORDER BY CreatedDate DESC ];
            System.assert(apexDebugLogs != null);
            System.assertEquals('LogExceptionInsertDebugLogsTrHTest',apexDebugLogs[0].Apex_Class__c);
            System.assertEquals(pEx.getMessage(), 'Exception thrown from LogExceptionInsertDebugLogsTrHTest.getException(): ' +
                                                  'System.DmlException: ' + apexDebugLogs[0].Message__c);
            System.assertEquals('getException',apexDebugLogs[0].Method__c);
            System.assertEquals(UserInfo.getUserId(),apexDebugLogs[0].Login_UserId__c);
            System.assertEquals(UserInfo.getProfileId(),apexDebugLogs[0].Login_User_ProfileId__c);
        }
    }
}