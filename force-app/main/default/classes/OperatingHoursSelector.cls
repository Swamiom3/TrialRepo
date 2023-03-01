/*************************************************************************************************************************************
 Author      :   Salesforce
 Description :   This class is selector implementation of particular SObject (OperatingHours)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               18 Oct 2021     Salesforce       Initial Deployment
 **************************************************************************************************************************************/
public with sharing class OperatingHoursSelector extends SObjectSelector  {
    public OperatingHoursSelector() {
        super(OperatingHours.getSObjectType());
    }

    /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get default fields from Object
     Created Date        : 18 Oct 2021
     *****************************************************************************************************************************/
    public override Set<String> getDefaultFields() {
        return new Set<String> { 'Id', 'Name' };
    }

    /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get service resources based on user Ids
     Created Date        : 18 Oct 2021
     *****************************************************************************************************************************/
    public List<OperatingHours> getBuildingOperatingHours(Id buildingId) {
        if(String.isBlank(buildingId)) {
            return new List<OperatingHours>();
        }
        List<String> fields = new List<String> { 'Id', 'Name', 'Building_Id__c', 'Building_Id__r.Name', 'TimeZone', '(SELECT Id, OperatingHoursId, DayOfWeek, StartTime, EndTime FROM TimeSlots)' };
        String whereClause = 'Building_Id__c = :buildingId AND Host_Id__c = null';
        List<Object> bindings = new List<Object> { buildingId };
        return (List<OperatingHours>) getSObjects(fields, whereClause, bindings);
    }
}