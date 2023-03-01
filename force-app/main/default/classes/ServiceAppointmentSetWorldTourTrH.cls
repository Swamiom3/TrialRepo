/************************************************************************************************************************************
Author         :     Mikolaj Juras
Description    :     Service Appointment TrH to set World Tour checkbox
History        :
----------------------------------------------------------------------------------------------------------------------------------
VERSION      DATE                AUTHOR                    DETAIL
1            25 Oct 2021         Mikolaj Juras             Initial Development on orgC and Service appointment object
**************************************************************************************************************************************/
public with sharing class ServiceAppointmentSetWorldTourTrH extends SObjectTriggerHandler{
    
    @TestVisible
    private List<ServiceAppointment> newServiceAppointments;
    @TestVisible
    private Map<Id, ServiceAppointment> oldServiceAppointments;
    @TestVisible
    private Set<String> marketNames = new Set<String>();
    @TestVisible
    private Set<Id> contactIds = new Set<Id>();
    
    public ServiceAppointmentSetWorldTourTrH() {
        this((List<ServiceAppointment>) Trigger.new, (Map<Id, ServiceAppointment>) Trigger.oldMap);        
    }
    
    @TestVisible
    private ServiceAppointmentSetWorldTourTrH(List<ServiceAppointment> newServiceAppointments, 
                                              Map<Id, ServiceAppointment> oldServiceAppointments) {
        this.newServiceAppointments = newServiceAppointments;
        this.oldServiceAppointments = oldServiceAppointments;

    }
    public override void afterInsert() {
        populateMarketAndPrimaryUsersSets();
        if (isDataCompleteToSetWorldTourFlag()) {
            AsyncTourSetWorldTour.checkWorldTourFlag(marketNames, contactIds);
        }
    }

    public override void afterUpdate() {
        populateMarketAndPrimaryUsersSets();
        if (isDataCompleteToSetWorldTourFlag()) {
            AsyncTourSetWorldTour.checkWorldTourFlag(marketNames, contactIds);
        }
    }
    
    @TestVisible
    private void populateMarketAndPrimaryUsersSets() {
        for (ServiceAppointment appointment : newServiceAppointments) {
            if (appointment.ContactId != null && appointment.Portfolio_Name__c != null) {
                marketNames.add(appointment.Portfolio_Name__c);
                contactIds.add(appointment.ContactId);
            }
        }
    }

    @TestVisible
    private Boolean isDataCompleteToSetWorldTourFlag() {
        return !marketNames.isEmpty() && !contactIds.isEmpty();
    }
}