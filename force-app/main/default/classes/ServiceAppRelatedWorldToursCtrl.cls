/************************************************************************************************************************************
    Author       :   Mikolaj Juras    
    @Description :   Controller clas for worldTour logic retrive service appointments
    Issue No     :     ST-7574
    History      :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO        DETAIL
    1           28 Oct 2021     Mikolaj Juras           ST-9214         Initial Developement 
**************************************************************************************************************************************/
public with sharing class ServiceAppRelatedWorldToursCtrl {

    @TestVisible
    private static ServiceAppointmentSelector servAppSelector = new ServiceAppointmentSelector();
    @AuraEnabled
    public static List<ServiceAppointment> getServiceAppointmentsMarkedAsWorldTour(String contactId, Datetime createdDate, String portfolioName){
    return  servAppSelector.getServiceAppForCurrentConatact(contactId, createdDate, portfolioName);
    }
}