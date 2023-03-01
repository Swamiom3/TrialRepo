/**
 * @description Handler for batch class trac_SupportRequestBatch
 * @name trac_SupportRequestBatchHelper
 * @author Shubham Jain, Traction on Demand
 * @date 2020-01-21
 */
public class trac_SupportRequestBatchHelper {
    private static final Id READ_ONLY_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Request Read Only').getRecordTypeId();

    private static final List<OrgWideEmailAddress> ORG_WIDE_EMAIL_ADDRESS =
            new List<OrgWideEmailAddress>([
                    SELECT Id, Address
                    FROM OrgWideEmailAddress
                    WHERE DisplayName =: TLOrgConstants.WEWORK_SUPPORT_ORG_WIDE
                    LIMIT 1
            ]);

    /*public static void handleCasesSolvedBefore3DAys(List<Case> caseList) {
        for (Case cs : caseList) {
            cs.RecordTypeId = READ_ONLY_RECORD_TYPE_ID;
            cs.Status = TLOrgConstants.CASE_STATUS_CLOSED;
            cs.Is_Status_Closed_After_3_Days__c = true;
            //cs.Status_Is_Closed__c = true;
        }
        update caseList;
    }*/

    public static void handleWaitingOnSupportRequest24Hrs(List<Case> caseList) {
        String defaultEmailTemplate = 'Notify_Requester_Waiting_on_Support_Req_Submitter_from_24hrs';
        Map<String, String> caseIdToEmailTemplateId = createcaseIdToEmailTemplateIdMap(caseList, defaultEmailTemplate);
        sendEmailNotification(caseList, caseIdToEmailTemplateId, false, 'Is_24_Hours_After_Email_Sent__c');
    }

    public static void handleWaitingOnSupportRequest4Days(List<Case> caseList) {
        String defaultEmailTemplate = 'Notify_Requester_Waiting_on_Support_Req_Submitter_from_4_days';
        Map<String, String> caseIdToEmailTemplateId = createcaseIdToEmailTemplateIdMap(caseList, defaultEmailTemplate);
        sendEmailNotification(caseList, caseIdToEmailTemplateId, false, 'Is_4_Days_After_Email_Sent__c');
    }

    public static void handleWaitingOnSupportRequestSubmitter(List<Case> caseList) {
        String defaultEmailTemplate = 'Notify_Submitter_as_a_final_notifn_to_close_the_support_request';
        Map<String, String> caseIdToEmailTemplateId = createcaseIdToEmailTemplateIdMap(caseList, defaultEmailTemplate);
        sendEmailNotification(caseList, caseIdToEmailTemplateId, true, 'Is_7_Days_After_Email_Sent__c');
        List<Case> updateFirstResponse = new List<Case>();
        for (Case cs : caseList) {
            if (cs.First_Response_Time__c == null) {
                updateFirstResponse.add(new Case(Id = cs.Id, First_Response_Time__c = System.now()));
            }
        }
        if (updateFirstResponse.size() > 0)
            update updateFirstResponse;
    }

    private static Map<String, String> createcaseIdToEmailTemplateIdMap(List<Case> caseList, String defaultEmailTemplate) {
        Map<String, String> emailTemplateNameToId = new Map<String, String>();
        Map<String, String> caseIdToEmailTemplateName = new Map<String, String>();
        Map<String, String> caseIdToEmailTemplateId = new Map<String, String>();

        for (Case cs : caseList) {
            String emailTemplateName = (String.isNotBlank(cs.Contact.Language__c) && !cs.Contact.Language__c.equals('en')) ? defaultEmailTemplate + '_' + cs.Contact.Language__c : defaultEmailTemplate;
            caseIdToEmailTemplateName.put(cs.Id, emailTemplateName);
        }
        for (EmailTemplate eTemp : [
                SELECT Id, DeveloperName
                FROM EmailTemplate
                WHERE DeveloperName IN :caseIdToEmailTemplateName.values() OR DeveloperName = :defaultEmailTemplate
        ]) {
            emailTemplateNameToId.put(eTemp.DeveloperName, eTemp.Id);
        }
        for (String caseId : caseIdToEmailTemplateName.keySet()) {
            String templateId = (emailTemplateNameToId.get(caseIdToEmailTemplateName.get(caseId)) == null) ? emailTemplateNameToId.get(defaultEmailTemplate) : (emailTemplateNameToId.get(caseIdToEmailTemplateName.get(caseId)));
            caseIdToEmailTemplateId.put(caseId, templateId);
        }
        return caseIdToEmailTemplateId;
    }

    private static void sendEmailNotification(List<Case> caseList, Map<String, String> caseIdToEmailTemplateId, Boolean isStatusUpdateReq, String fieldToUpdate) {
        List<trac_EmailNotificationSender.Inputs> inputList = new List<trac_EmailNotificationSender.Inputs>();
        for (Case cs : caseList) {
            trac_EmailNotificationSender.Inputs inp = new trac_EmailNotificationSender.Inputs();
            inp.fromAddress = ORG_WIDE_EMAIL_ADDRESS[0].Id;
            inp.isStatusUpdateReq = isStatusUpdateReq;
            inp.supportRequestId = cs.Id;
            inp.targetObjectId = cs.ContactId;
            inp.templateId = caseIdToEmailTemplateId.get(cs.Id);
            inp.toAddress = cs.Contact.Email;
            inp.fieldToUpdate = fieldToUpdate;
            inputList.add(inp);
        }
        if (inputList.size() > 0)
            trac_EmailNotificationSender.sendEmailNotification(inputList);
    }
}