/*************************************************************************************************************************************
    Author      :   Rashad Saeed
    Description :   Future class for posting request to rollbar.
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR            DETAIL
    1          31 Dec, 2018    Rashad Saeed      Initial Deployment - WeWork SF-Rollbar Integration Google Doc
    2          25 Nov, 2021    Pawel Biszczak    Refactor
**************************************************************************************************************************************/
public class QueueRollbarItemSubmit implements Queueable, Database.AllowsCallouts, Callable {
    private RollbarItem item;
    private String project;
    private List <Apex_Debug_Log__c> apexDebugLogs;
    private Apex_Debug_Log__c apexLog;
    private final Integer HOURS_FILTER =
            (Integer) (Integration_Data__mdt.getInstance('RollBar').HoursFilter__c);

    public QueueRollbarItemSubmit() {
        List <AsyncApexJob> asyncApexJobs  = [ SELECT Id, Status
                                              FROM AsyncApexJob
                                              WHERE ApexClassId IN (SELECT Id
                                                                   FROM ApexClass
                                                                   WHERE NamespacePrefix = null
                                                                   AND Name = 'QueueRollbarItemSubmit')
                                                    AND Status ='Queued' ];
        if (!asyncApexJobs.isEmpty()) {
            System.abortJob(asyncApexJobs[0].Id);
        }
        Integer hoursFilter = HOURS_FILTER;
        if (HOURS_FILTER == null) {
            hoursFilter = 1;
        }
        Datetime LastNHours = System.now().addHours(-hoursFilter);
        this.apexDebugLogs = [ SELECT Id, Name, Apex_Class__c,
                                      ApexLogId__c, ErrorLineNumber__c,
                                      Type__c, ExceptionTypeName__c,
                                      InstanceName__c, Login_UserId__c,
                                      Login_User_ProfileId__c, Message__c,
                                      Method__c, Record_Id__c, ReplayId__c,
                                      Stack_Trace__c, Status__c
                               FROM Apex_Debug_Log__c
                               WHERE RollBar_Integration_status__c = null
                                     AND CreatedDate >=: LastNHours
                               LIMIT 1 ];
        if (apexDebugLogs.isEmpty()) {
            return;
        }
        this.item = new RollbarItem(apexDebugLogs[0]);
        this.project = 'RollBar';
        this.apexLog = apexDebugLogs[0];
    }

    public QueueRollbarItemSubmit call(String action, Map<String, Object> args) {
        return new QueueRollbarItemSubmit();
    }

    public void execute(QueueableContext qc) {
        List<Apex_Debug_Log__c> logs = [ SELECT Id
                                         FROM Apex_Debug_Log__c
                                         WHERE Apex_Class__c = 'Test' ];

        if (apexDebugLogs.isEmpty() || (Test.isRunningTest() && logs.isEmpty())) {
            return;
        }
        apexLog.RollBar_Integration_status__c = String.valueOf(Rollbar.submitItem(item, project).getStatusCode());
        update apexLog;

        AsyncsExecutor asyncsExecutor = new AsyncsExecutor(QueueRollbarItemSubmit.class, new Map<String, Object>{});
        asyncsExecutor.execute();
    }
}