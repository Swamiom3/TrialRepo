/**
 * @description Batch class for time based actions
 * @name trac_SupportRequestBatch
 * @author Shubham Jain, Traction on Demand
 * @date 2020-01-21
 */
global class trac_SupportRequestBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Is_24_Hours_After_Email_Sent__c, First_Response_Time__c, RecordType.DeveloperName, Is_4_Days_After_Email_Sent__c, Is_7_Days_After_Email_Sent__c, Is_Status_Closed_After_3_Days__c, Contact.Language__c, ContactId,  Support_Request_Re_Open_Till_Date__c, RecordType.Name, Status, Waiting_on_Support_Request_24_hours__c, Waiting_on_Support_Request_4_days__c, Waiting_on_Support_Request_Submitter__c, Contact.Email, WeCo_Line_of_Business__c  FROM Case';
        query += ' WHERE (((LastModifiedDate = LAST_N_DAYS:10) AND (RecordType.DeveloperName = \'Support_Request\' AND Status =  \'Waiting_on_Support_Request_Submitter\' AND (WeCo_Line_of_Business__c = \'WeWork\' OR WeCo_Line_of_Business__c = \'WeLive\')';
        query += ' AND ((NOT(Contact.Email LIKE \'%@wework.com%\')) AND (NOT(Contact.Email LIKE \'%@wework.co.in%\')) AND (NOT(Contact.Email LIKE \'%@lavazza.com%\')))';
        query += ' AND Waiting_on_Support_Request_24_hours__c != null AND Contact.Id != null AND Contact.Email != null AND (Waiting_on_Support_Request_24_hours__c = LAST_N_DAYS:2 OR Waiting_on_Support_Request_4_days__c = LAST_N_DAYS:2 OR Waiting_on_Support_Request_Submitter__c = LAST_N_DAYS:2) AND (Is_24_Hours_After_Email_Sent__c = false OR Is_4_Days_After_Email_Sent__c = false OR Is_7_Days_After_Email_Sent__c = false) AND (Do_Not_Send_Notifications__c = FALSE)))';
        query += ' OR (RecordType.Name = \'Support Request\' AND Status = \'Solved\' AND Support_Request_Re_Open_Till_Date__c != null AND Support_Request_Re_Open_Till_Date__c = LAST_N_DAYS:2 AND Is_Status_Closed_After_3_Days__c = false))';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Case> scope) {
        /*List<Case> solvedBefore3Days = new List<Case>();
        */ 
        List<Case> waitingOnSupportRequest24Hrs = new List<Case>();
        List<Case> waitingOnSupportRequest4Days = new List<Case>();
        List<Case> waitingOnSupportRequestSubmitter = new List<Case>();
        for (Case cs : scope) {

           /* //Process records on solved + 3 days
     		* @MOVING TO TIME BASED WORKFLOW 1/25 - JM
           * if (cs.RecordType.Name.equals('Support Request')
           *        && cs.Status.equals('Solved')
           *         && cs.Support_Request_Re_Open_Till_Date__c != null
           *         && cs.Support_Request_Re_Open_Till_Date__c > (System.now().addMinutes(-420))
           *         && cs.Support_Request_Re_Open_Till_Date__c < System.now()
           *         && !cs.Is_Status_Closed_After_3_Days__c) {

                solvedBefore3Days.add(cs);
            }*/

            //Process records for waiting on Support Request for 24 hours, 4 days and 7 days.
            if (cs.RecordType.DeveloperName.equals('Support_Request')
                    && cs.Status.equals('Waiting_on_Support_Request_Submitter')
                    && (cs.WeCo_Line_of_Business__c.equals('WeWork') || cs.WeCo_Line_of_Business__c.equals('WeLive'))
                    && (!cs.Contact.Email.contains('@wework.com') || !cs.Contact.Email.contains('@wework.co.in'))
                    && cs.Waiting_on_Support_Request_24_hours__c != null
                    && String.isNotBlank(cs.ContactId)
                    && String.isNotBlank(cs.Contact.Email)) {

                if (cs.Waiting_on_Support_Request_24_hours__c > (System.now().addMinutes(-420)) && cs.Waiting_on_Support_Request_24_hours__c < System.now() && !cs.Is_24_Hours_After_Email_Sent__c)
                    waitingOnSupportRequest24Hrs.add(cs);
                if (cs.Waiting_on_Support_Request_4_days__c > (System.now().addMinutes(-420)) && cs.Waiting_on_Support_Request_4_days__c < System.now() && !cs.Is_4_Days_After_Email_Sent__c)
                    waitingOnSupportRequest4Days.add(cs);
                if (cs.Waiting_on_Support_Request_Submitter__c > (System.now().addMinutes(-420)) && cs.Waiting_on_Support_Request_Submitter__c < System.now() && !cs.Is_7_Days_After_Email_Sent__c)
                    waitingOnSupportRequestSubmitter.add(cs);
            }
        }
        System.debug('waitingOnSupportRequest24Hrs '+waitingOnSupportRequest24Hrs);
        //Call helper methods for all the lists.
        /*if (solvedBefore3Days.size() > 0)
            trac_SupportRequestBatchHelper.handleCasesSolvedBefore3DAys(solvedBefore3Days);
        */
        if (waitingOnSupportRequest24Hrs.size() > 0)
            trac_SupportRequestBatchHelper.handleWaitingOnSupportRequest24Hrs(waitingOnSupportRequest24Hrs);
        if (waitingOnSupportRequest4Days.size() > 0)
            trac_SupportRequestBatchHelper.handleWaitingOnSupportRequest4Days(waitingOnSupportRequest4Days);
        if (waitingOnSupportRequestSubmitter.size() > 0)
            trac_SupportRequestBatchHelper.handleWaitingOnSupportRequestSubmitter(waitingOnSupportRequestSubmitter);
    }

    global void finish(Database.BatchableContext BC) {
        // Get the ID of the AsyncApexJob representing this batch job
        // from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob a = [
                SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                FROM AsyncApexJob
                WHERE Id = :BC.getJobId()
        ];
        // Send an email to the Apex job's submitter notifying of job completion.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[]{
                a.CreatedBy.Email
        };
        mail.setToAddresses(toAddresses);
        mail.setSubject('Support Request Batch processed ' + a.Status);
        mail.setPlainTextBody
                ('The batch Apex job processed ' + a.TotalJobItems +
                        ' batches with ' + a.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                mail
        });
    }
}