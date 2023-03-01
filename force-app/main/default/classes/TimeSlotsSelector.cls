/*************************************************************************************************************************************
 Author      :   Salesforce
 Description :   This class is selector implementation of particular SObject (TimeSlot)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               18 Nov 2021     Salesforce       Initial Deployment
 **************************************************************************************************************************************/
public with sharing class TimeSlotsSelector extends SObjectSelector {
    public TimeSlotsSelector() {
        super(TimeSlot.getSObjectType());
    }

    /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get default fields from Object
     Created Date        : 18 Nov 2021
     *****************************************************************************************************************************/
    public override Set<String> getDefaultFields() {
        return new Set<String> { 'Id', 'StartTime', 'EndTime' };
    }

    /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get time slots based on operating hours ids
     Created Date        : 18 Oct 2021
     *****************************************************************************************************************************/
    public List<TimeSlot> getTimeSlotsByOPeratingHoursIds(List<Id> operatingHoursIds) {
        if(operatingHoursIds.isEmpty()) {
            return new List<TimeSlot>();
        }
        List<String> fields = new List<String> (getDefaultFields());
        String whereClause = 'OperatingHoursId IN :operatingHoursIds';
        List<Object> bindings = new List<Object> { operatingHoursIds };
        return (List<TimeSlot>) getSObjects(fields, whereClause, bindings);
    }
}