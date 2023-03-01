/*************************************************************************************************************************************
 Author      :   Salesforce
 Description :   This class is selector implementation of particular SObject (ResourceAbsence)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               28 Oct 2021     Salesforce       Initial Deployment
 **************************************************************************************************************************************/
public with sharing class ResourceAbsenceSelector extends SObjectSelector {
    public ResourceAbsenceSelector() {
        super(ResourceAbsence.getSObjectType());
    }

    /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get default fields from Object
     Created Date        : 28 Oct 2021
     *****************************************************************************************************************************/
    public override Set<String> getDefaultFields() {
        return new Set<String> { 'Id', 'AbsenceNumber' };
    }

    /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get resource absence records based on non operating hours Ids
     Created Date        : 28 Oct 2021
     *****************************************************************************************************************************/
    public List<ResourceAbsence> getResourceAbsenceByNonOperatingHoursIds(List<Id> nonOperatingHoursIds) {
        if (nonOperatingHoursIds.isEmpty()) {
            return new List<ResourceAbsence>();
        }
        List<String> fields = new List<String> (getDefaultFields());
        String whereClause = 'Non_Operating_Hours_Id__c IN  :nonOperatingHoursIds';
        List<Object> bindings = new List<Object> { nonOperatingHoursIds };
        return (List<ResourceAbsence>) getSObjects(fields, whereClause, bindings);
    }

    /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get resource absence records based on non operating hours Ids and Service Resource Ids
     Created Date        : 28 Oct 2021
     *****************************************************************************************************************************/
    public List<ResourceAbsence> getResourceAbsenceByNonOperatingHoursAndServiceResourceIds(List<Id> nonOperatingHoursIds, List<Id> serviceResourceIds) {
        if (nonOperatingHoursIds.isEmpty() || serviceResourceIds.isEmpty()) {
            return new List<ResourceAbsence>();
        }
        List<String> fields = new List<String> (getDefaultFields());
        String whereClause = 'Non_Operating_Hours_Id__c IN  :nonOperatingHoursIds AND ResourceId IN :serviceResourceIds';
        List<Object> bindings = new List<Object> { nonOperatingHoursIds, serviceResourceIds };
        return (List<ResourceAbsence>) getSObjects(fields, whereClause, bindings);
    }
}