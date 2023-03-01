/************************************************************************************************************************************
   Author      :   Salesforce
   Description :   This class is the queueable class to send emails fo tours.
   ----------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR            DETAIL
    1         16 Nov 2021    Salesforce       TWSPG-5700
 **************************************************************************************************************************************/
public class QueueEmailAlertForTour implements Queueable {
    Map<Id, Id> serviceAppointmentToPreviousOwner = new Map<Id, Id>();
    String templateName;
    public static Integer countEmailInvocation = 0;

    public QueueEmailAlertForTour(Map<Id, Id> serviceAppointmentToPreviousOwner, String templateName) {
        this.serviceAppointmentToPreviousOwner = serviceAppointmentToPreviousOwner;
        this.templateName = templateName;
    }

    public void execute(QueueableContext context) {
        try {
            if (serviceAppointmentToPreviousOwner.isEmpty()) {
                return;
            }
            List<ServiceAppointment> serviceAppointmentWithRecipients = [SELECT Id, OwnerId, Building_Id__r.Email__c, Building_Id__r.Leasing_Manager_Id__c,Building_Id__r.Leasing_Manager_Id__r.ProfileId, 
                                                                        Building_Id__r.Leasing_Manager_Id__r.Email, Building_Id__r.Leasing_Director_Id__c,Building_Id__r.Leasing_Director_Id__r.ProfileId,
                                                                        Building_Id__r.Leasing_Director_Id__r.Email 
                                                                        FROM ServiceAppointment WHERE Id IN : serviceAppointmentToPreviousOwner.keySet() 
                                                                        AND SchedStartTime >= TODAY];
            Id emailTemplateId = [SELECT Id, Name FROM EmailTemplate WHERE DeveloperName = :templateName]?.Id;
            if (emailTemplateId == NULL) {
                return;
            }
            List<String> templateNames = new List<String> { ServiceAppointmentConstants.TEMPLATE_TOUR_BOOKED_NOTIFICATION, ServiceAppointmentConstants.TEMPLATE_TOUR_REASSIGNED_NOTIFICATION, ServiceAppointmentConstants.TEMPLATE_TOUR_RESCHEDULED_NOTIFICATION };
            List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
            for(ServiceAppointment sa : serviceAppointmentWithRecipients) {
                Messaging.SingleEmailMessage singleEmail = new Messaging.SingleEmailMessage();
                singleEmail.setTemplateId(emailTemplateId);
                List<String> emailIds = new List<String>();                
                if (sa.Building_Id__r.Leasing_Manager_Id__c != null && EmailService.isValidUserToSendEmailOnOwnerChange(sa.Building_Id__r.Leasing_Manager_Id__r.ProfileId)) {
                    emailIds.add(sa.Building_Id__r.Leasing_Manager_Id__r.Email);
                }
                if (templateNames.contains(templateName)) {
                    if (sa.Building_Id__r.Leasing_Director_Id__c != null && EmailService.isValidUserToSendEmailOnOwnerChange(sa.Building_Id__r.Leasing_Director_Id__r.ProfileId)) {
                        emailIds.add(sa.Building_Id__r.Leasing_Director_Id__r.Email);
                    }
                    if (sa.Building_Id__r.Email__c != null) {
                        emailIds.add(sa.Building_Id__r.Email__c);
                    }
                }
                if (templateName == ServiceAppointmentConstants.TEMPLATE_TOUR_REASSIGNED_NOTIFICATION) {
                    if (serviceAppointmentToPreviousOwner.containsKey(sa.Id) && serviceAppointmentToPreviousOwner.get(sa.Id) != null) {
                        emailIds.add(serviceAppointmentToPreviousOwner.get(sa.Id));
                    }
                }
                singleEmail.setToAddresses(emailIds);
                singleEmail.setTargetObjectId(sa.OwnerId);
                singleEmail.setWhatId(sa.Id);
                singleEmail.setSaveAsActivity(false);
                emailsToSend.add(singleEmail);
            }
            if(!emailsToSend.isEmpty()) {
                Messaging.sendEmail(emailsToSend);
                countEmailInvocation = Limits.getEmailInvocations();
            }
        } catch(Exception pEx) {
            ApexDebugLog.logException(pEx, serviceAppointmentToPreviousOwner != NULL ? JSON.serialize(serviceAppointmentToPreviousOwner) : NULL, 'QueueEmailAlertForTour', 'exceute');
        }
    }
}