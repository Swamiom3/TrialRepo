public with sharing class trac_EmailMessageHandler {

    public static void maskCreditCardNumbers(List<EmailMessage> messages) {
        trac_Utilities.maskCreditCardNumbers(
                (List<SObject>) TLTrigger.filterByFieldCriteria(messages, EmailMessage.Incoming, new List<Object>{
                        true
                }),
                new Set<String>{
                        'Subject', 'TextBody', 'HtmlBody'
                }
        );
    }


    public static void checkCcAddresses(List<EmailMessage> messages) {
        List<EmailServicesAddress> emailServicesAddresses = [SELECT Id, LocalPart FROM EmailServicesAddress WHERE Function.FunctionName = 'EmailToCase'];
        Set<String> ports = TLList.collectStrings(emailServicesAddresses, EmailServicesAddress.LocalPart);
        for (EmailMessage message : messages) {
            if (message.Incoming == false && message.CcAddress != null && message.CcAddress.contains(',')) {
                for (String address : message.CcAddress.split(',')) {
                    for (String port : ports) {
                        if (port + '@we' == address.split('@')[0] + '@we') {
                            message.addError('You cannot CC ' + address + ' because it\'s an internal Salesforce email address');
                        }
                    }
                }
            }
        }
    }

    public static void completeFirstResponseEmail(List<EmailMessage> messages) {

        if (UserInfo.getUserType() == 'Standard') {

            DateTime completionDate = System.now();
            Map<Id, String> emIds = new Map<Id, String>();
            for (EmailMessage em : messages) {
                if (em.Incoming == false)
                    emIds.put(em.ParentId, em.ToAddress);
            }

            if (emIds.isEmpty() == false) {
                Set <Id> emCaseIds = new Set<Id>();
                emCaseIds = emIds.keySet();
                List<Case> caseList = [
                        SELECT c.Id, c.ContactId, c.Contact.Email,
                                c.OwnerId, c.Status,
                                c.EntitlementId,
                                c.SlaStartDate, c.SlaExitDate
                        FROM Case c
                        WHERE c.Id IN :emCaseIds
                ];
                if (caseList.isEmpty() == false) {
                    List<Id> updateCases = new List<Id>();
                    for (Case caseObj : caseList) {
                        if ((emIds.get(caseObj.Id) == caseObj.Contact.Email) &&
                                (caseObj.Status == 'In Progress' || caseObj.Status == 'New' || caseObj.Status == 'Waiting on Submitter' || caseObj.Status == 'Solved') &&
                                (caseObj.EntitlementId != null) &&
                                (caseObj.SlaStartDate <= completionDate) &&
                                (caseObj.SlaStartDate != null) &&
                                (caseObj.SlaExitDate == null))
                            updateCases.add(caseObj.Id);
                    }
                    if (updateCases.isEmpty() == false)
                        milestoneUtils.completeMilestone(updateCases,
                                'First Response Time', completionDate);
                }
            }
        }
    }

    public static void revertCompleteResolutionTimeMilestones(List<EmailMessage> messages){
        List<Id> caseIds = new List<Id>();
        for (EmailMessage em : messages) {
            if (em.Incoming && em.ParentId?.getSObjectType() == Case.sObjectType){
                caseIds.add(em.ParentId);
            }
        }

        if(!caseIds.isEmpty()){
            milestoneUtils.revertCompletion(caseIds, 'Resolution Time (SLA)');
        }
    }
}