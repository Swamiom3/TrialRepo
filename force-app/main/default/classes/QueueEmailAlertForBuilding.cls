/************************************************************************************************************************************
   Author      :   Salesforce
   Description :   This class is the queueable class to send emails fo building.
   ----------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR            DETAIL
    1         16 Nov 2021    Salesforce       TWSPG-5700
 **************************************************************************************************************************************/
public with sharing class QueueEmailAlertForBuilding implements Queueable {
    List<Id> recordIds = new List<Id>();
    Map<Id, List<String>> buildingMapForMismatchEmail = new Map<Id, List<String>>();
    @testVisible
    private static Integer countEmailInvocation = 0;
    private final String EMAIL_TEMPLATE_NAME = 'Salesforce_Currency_Mismatch_Alert';
    private final String CURRENCY_MISMATCH_RECIPIENT_LABEL = 'Currency_Mismatch_Recipient';

    public QueueEmailAlertForBuilding(Map<Id, List<String>> buildingMapForMismatchEmail) {
        this.buildingMapForMismatchEmail = buildingMapForMismatchEmail;
    }

    public void execute(QueueableContext context) {
        try {
            EmailService emailServiceInstance = new EmailService();
            if (buildingMapForMismatchEmail.isEmpty()) {
                return;
            }
            EmailTemplate emailTemplate = EmailService.getEmailTemplateByDeveloperName(EMAIL_TEMPLATE_NAME);
            if (emailTemplate == null) {
                return;
            }
            List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
            for(Id buildingId : buildingMapForMismatchEmail.keySet()) {
                Messaging.SingleEmailMessage singleEmail = new Messaging.SingleEmailMessage();
                List<String> mergeValues = buildingMapForMismatchEmail.get(buildingId);
                Map<String, String> replacementMap = new Map<String, String> { '{TimeStamp}' => String.valueOf(System.now()) };
                for (String value : mergeValues) {
                    replacementMap.put('{' + mergeValues.indexOf(value) + '}', value);
                }
                Sales_Console_Setting__mdt emailRecipient = SalesConsoleSettings.get(CURRENCY_MISMATCH_RECIPIENT_LABEL);
                if (emailRecipient == null) {
                    return;
                }
                singleEmail.setPlainTextBody(emailServiceInstance.replaceText(emailTemplate.Body, replacementMap));
                singleEmail.setSubject(emailTemplate.Subject);
                singleEmail.setOrgWideEmailAddressId(EmailService.getOrganizationWideDefaultAddressId());
                singleEmail.setToAddresses(new List<String> { emailRecipient.Data__c });
                singleEmail.setSaveAsActivity(false);
                emailsToSend.add(singleEmail);
            }
            if(!emailsToSend.isEmpty()) {
                Messaging.sendEmail(emailsToSend);
                countEmailInvocation = Limits.getEmailInvocations();
            }
        } catch(Exception pEx) {
            ApexDebugLog.logException(pEx, recordIds != null ? JSON.serialize(recordIds) : null, 'QueueEmailAlertForBuilding', 'exceute');
        }
    }
}