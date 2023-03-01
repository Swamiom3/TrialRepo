/*************************************************************************************************************************************
    Author      :   Mikolaj Juras
    Description :   This class is selector implementation of particular SObject (ServiceAppointment)
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION         DATE            AUTHOR              DETAIL
    1.0          10 November 2021  Mikolaj Juras      Initial Deployment
**************************************************************************************************************************************/
public inherited sharing class ServiceAppointmentSelector extends SObjectSelector{
    
    private static final List<String> WORLD_TOUR_QUERY_FIELDS = new List<String>{ 'Id', 'ContactId', 'Contact.Name', 'Status', 
                                                                           'Portfolio_Name__c', 'Scheduled_Start_Time__c', 
                                                                           'AppointmentNumber',' Building_Id__r.Name', 'CreatedDate'};

    private static final List<String> WORLD_TOUR_RELATED_LIST_FIELDS = new List<String>{'Id', 'ContactId', 'Contact.Name', 'Status', 
                                                                                        'Portfolio_Name__c', 'Scheduled_Start_Time__c', 
                                                                                        'AppointmentNumber', 'Building_Id__r.Name'};
    
    public ServiceAppointmentSelector() {
        super(ServiceAppointment.getSObjectType());
    }

    public override Set<String> getDefaultFields(){
        return new Set<String> (WORLD_TOUR_QUERY_FIELDS);
    }

    public List<ServiceAppointment> getServiceAppForContactsAndPortfoliosFilteredByWhere(Set<String> portfolioNames, Set<Id> contactIds){
        if (portfolioNames == null || portfolioNames.isEmpty() || contactIds == null || contactIds.isEmpty()) {
            return new List<ServiceAppointment>();
        }
        List<String> fields = new List<String>(WORLD_TOUR_QUERY_FIELDS);
        Set<String> appStatus = new Set<String>{'Scheduled'};
        List<Object> bindings = new List<Object>{contactIds, portfolioNames, appStatus};
        String whereClause = 'ContactId IN :contactIds AND Portfolio_Name__c IN :portfolioNames AND Status IN :appStatus AND CreatedDate = TODAY';
        return (List<ServiceAppointment>) getSObjects(fields, whereClause, bindings);    
    }

    public List<ServiceAppointment> getServiceAppForCurrentConatact(String contactId, Datetime createdDate, String portfolioName){
        if (portfolioName == null || contactId == null || createdDate == null) {
            return new List<ServiceAppointment>();
        }
        Date dateValueOfCreatedDate = Date.valueOf(createdDate);
        Date nextDayDateValueOfCreatedDate = dateValueOfCreatedDate.addDays(1);
        List<String> fields = new List<String>(WORLD_TOUR_RELATED_LIST_FIELDS);
        Set<String> appStatus = new Set<String>{'Scheduled'};
        List<Object> bindings = new List<Object>{dateValueOfCreatedDate, nextDayDateValueOfCreatedDate, portfolioName, appStatus, contactId};
        String whereClause = 'CreatedDate > :dateValueOfCreatedDate ' + 
                             'AND CreatedDate < :nextDayDateValueOfCreatedDate ' +
                             'AND Portfolio_Name__c =: portfolioName '+
                             'AND Status =: appStatus ' +
                             'AND ContactId =: contactId ' + 
                             'AND World_Tour__c = true ';
        return (List<ServiceAppointment>) getSObjects(fields, whereClause, bindings);    
    }

    //temporary method for transition period to get new tour Id based on legacy UUID
    public ServiceAppointment getTourByUUID(String uuid) {
        List<ServiceAppointment> tours = getSObjectByField(new List<String>{ 'Id' }, 'UUID__c', uuid, false);
        return tours.isEmpty() ? null : tours[0];
    }

    public String getBuildingUUIDByTourId(Id tourId) {
        return ((List<ServiceAppointment>) getSObjectByIds(new List<String>{ 'Building_Id__r.UUID__c' }, tourId))[0]?.Building_Id__r.UUID__c;
    }
}