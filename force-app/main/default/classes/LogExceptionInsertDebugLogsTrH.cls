/*************************************************************************************************************************************
    Author      :   Krishana Tupe
    Description :   This class contains logic to insert Apex_Debug_Log__c on LogException__e records creation
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR            DETAIL
    1          2 May, 2018     Krishana Tupe     Initial development
    2          29 Nov, 2021    Pawel Biszczak    Refactor, moving to a new framework
**************************************************************************************************************************************/
public with sharing class LogExceptionInsertDebugLogsTrH extends SObjectTriggerHandler {
    private final String EXCEPTION_TYPE_ERROR = 'Error';
    private final String IDS_SEPARATOR = ',';
    private final Integer SECONDS_DELAY = -30;
    private final Boolean ROLLBAR_INTEGRATION_IS_ACTIVE =
            Integration_Data__mdt.getInstance('RollBar').Is_Active__c;

    @TestVisible
    private List<LogException__e> newLogExceptions;

    public LogExceptionInsertDebugLogsTrH() {
        this((List<LogException__e>) Trigger.new);
    }

    @TestVisible
    private LogExceptionInsertDebugLogsTrH(List<LogException__e> newLogExceptions) {
        this.newLogExceptions = newLogExceptions;
    }

    public override void afterInsert() {
        insertApexDebugLogs();
    }

    public void insertApexDebugLogs(){
        try {
            Datetime myDateTime = Datetime.now().addSeconds(SECONDS_DELAY);
            Set<Id> apexLogsIds = new Map<Id, ApexLog> ([ SELECT Id, StartTime
                                                          FROM ApexLog
                                                          WHERE StartTime >= :myDateTime
                                                          ORDER BY StartTime
                                                          LIMIT 10 ]).keySet();
            String JOINED_IDS = String.join(new List<Id>(apexLogsIds), IDS_SEPARATOR);
            List<Apex_Debug_Log__c> logsTobeCreated = new List<Apex_Debug_Log__c>();
            for (LogException__e exceptionRecord : newLogExceptions) {
                Apex_Debug_Log__c apexDebugLog = new Apex_Debug_Log__c(
                        ReplayId__c = exceptionRecord.ReplayId,
                        OwnerId = exceptionRecord.Login_UserId__c,
                        Type__c = EXCEPTION_TYPE_ERROR,
                        Apex_Class__c = exceptionRecord.Apex_Class__c,
                        Method__c = exceptionRecord.Method__c,
                        Record_Id__c = exceptionRecord.Record__c,
                        Login_User_ProfileId__c = exceptionRecord.Login_User_ProfileId__c,
                        Login_UserId__c = exceptionRecord.Login_UserId__c,
                        Message__c = exceptionRecord.Message__c,
                        Stack_Trace__c = exceptionRecord.Stack_Trace__c,
                        ErrorLineNumber__c = Integer.valueOf(exceptionRecord.ErrorLineNumber__c),
                        ExceptionTypeName__c = exceptionRecord.ExceptionTypeName__c,
                        ApexLogId__c = JOINED_IDS,
                        InstanceName__c = exceptionRecord.InstanceName__c,
                        Affected_User__c = UserInfo.getUserId()
                );
                logsTobeCreated.add(apexDebugLog);

            }
            if (logsTobeCreated.isEmpty()) {
                return;
            }
            Database.insert(logsTobeCreated, false);
            if (!(logsTobeCreated.size() == 1 && logsTobeCreated[0].Method__c.containsIgnoreCase('_nopush'))
                && ROLLBAR_INTEGRATION_IS_ACTIVE) {
                AsyncsExecutor asyncsExecutor = new AsyncsExecutor(QueueRollbarItemSubmit.class,
                        new Map<String, Object>{});
                asyncsExecutor.execute();
            }
        } catch (Exception ex) {
            ApexDebugLog.logException(ex, 'newItems ==>' + JSON.serialize(newLogExceptions),
                                      'LogExceptionInsertDebugLogsTrH', 'insertApexDebugLogs');
        }
    }
}