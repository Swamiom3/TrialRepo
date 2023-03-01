/************************************************************************************************************************************
   Author      :   Salesforce
   Description :   This class contain method to send emails when tour is created or updated.
   ----------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR            DETAIL
    1         16 Nov 2021    Salesforce       TWSPG-5700
 **************************************************************************************************************************************/
public class ServiceAppointmentSendEmailTrH extends SObjectTriggerHandler {
    @TestVisible
    private final List<ServiceAppointment> newServiceAppointments;
    @TestVisible
    private final Map<Id, ServiceAppointment> oldServiceAppointmentsMap;
    private final String STATUS_FIELD_API_NAME = 'Status';

    public ServiceAppointmentSendEmailTrH() {
        this((List<ServiceAppointment>) Trigger.new,
            (Map<Id, ServiceAppointment>) Trigger.oldMap);
    }

    @TestVisible
    private ServiceAppointmentSendEmailTrH(List<ServiceAppointment> newServiceAppointments, Map<Id, ServiceAppointment> oldServiceAppointmentsMap){
        this.newServiceAppointments = newServiceAppointments;
        this.oldServiceAppointmentsMap = oldServiceAppointmentsMap;
    }

    public override void afterInsert() {
        sendTourBookedEmail();
    }

    public override void afterUpdate() {
        sendEmailAlertForTourStatusChange();
    }

    private void sendEmailAlertForTourStatusChange() {
        Map<Id, Id> tourMapToSendForCompletedEmail = new Map<Id, Id>();
        Map<Id, Id> tourMapToSendForRescheduledEmail = new Map<Id, Id>();
        Map<Id, Id> tourMapToSendForReassignedEmail = new Map<Id, Id>();
        List<String> completedEmailStatus = new List<String> { ServiceAppointmentConstants.STATUS_COMPLETED, ServiceAppointmentConstants.STATUS_CANCELLED, ServiceAppointmentConstants.STATUS_NO_SHOW };
        for (ServiceAppointment sa : newServiceAppointments) {
            ServiceAppointment oldRecord = oldServiceAppointmentsMap.get(sa.Id);
            if (TriggerUtility.isFieldValueChanged(sa, oldServiceAppointmentsMap.get(sa.Id), ServiceAppointmentConstants.FIELD_API_NAME_STATUS)) {
                if (completedEmailStatus.contains(sa.Status)) {
                    tourMapToSendForCompletedEmail.put(sa.Id, oldRecord.OwnerId);
                }
            } else {
                if (sa.Status == ServiceAppointmentConstants.STATUS_SCHEDULED && TriggerUtility.isFieldValueChanged(sa, oldRecord, ServiceAppointmentConstants.FIELD_API_NAME_SCHEDULED_START) && TriggerUtility.isFieldValueChanged(sa, oldRecord, ServiceAppointmentConstants.FIELD_API_NAME_RESCHEDULE_COUNT)) {
                    tourMapToSendForRescheduledEmail.put(sa.Id, oldRecord.OwnerId);
                } else if (TriggerUtility.isFieldValueChanged(sa, oldRecord, ServiceAppointmentConstants.FIELD_API_NAME_OWNER)) {
                    tourMapToSendForReassignedEmail.put(sa.Id, oldRecord.OwnerId);
                }
            }
        }
        if (!tourMapToSendForCompletedEmail.isEmpty()) {
            ID jobId = System.enqueueJob(new QueueEmailAlertForTour(tourMapToSendForCompletedEmail, ServiceAppointmentConstants.TEMPLATE_TOUR_COMPLETED_NOTIFICATION));
        }
        if (!tourMapToSendForRescheduledEmail.isEmpty()) {
            ID jobId = System.enqueueJob(new QueueEmailAlertForTour(tourMapToSendForRescheduledEmail, ServiceAppointmentConstants.TEMPLATE_TOUR_RESCHEDULED_NOTIFICATION));
        }
        if (!tourMapToSendForReassignedEmail.isEmpty()) {
            ID jobId = System.enqueueJob(new QueueEmailAlertForTour(tourMapToSendForReassignedEmail, ServiceAppointmentConstants.TEMPLATE_TOUR_REASSIGNED_NOTIFICATION));
        }
    }

    private void sendTourBookedEmail() {
        Map<Id, Id> serviceAppointmentIdsToSend = new Map<Id, Id>();
        for (ServiceAppointment sa : newServiceAppointments) {
            if (sa.Status == ServiceAppointmentConstants.STATUS_SCHEDULED) {
                serviceAppointmentIdsToSend.put(sa.Id, null);
            }
        }
        if (!serviceAppointmentIdsToSend.isEmpty()) {
            ID jobID = System.enqueueJob(new QueueEmailAlertForTour(serviceAppointmentIdsToSend, ServiceAppointmentConstants.TEMPLATE_TOUR_BOOKED_NOTIFICATION));
        }
    }
}