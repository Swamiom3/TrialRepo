/*************************************************************************************************************************************
 Author      :   Salesforce
 Description :   This class is selector implementation of particular SObject (ServiceResource)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               18 Oct 2021     Salesforce       Initial Deployment
 **************************************************************************************************************************************/
public with sharing class ServiceResourceSelector extends SObjectSelector {
    public ServiceResourceSelector() {
        super(ServiceResource.getSObjectType());
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
    public List<ServiceResource> getServiceResourcesByUserIds(List<Id> userIds) {
        if(userIds.isEmpty()) {
            return new List<ServiceResource>();
        }
        List<String> fields = new List<String> { 'Id', 'Name', 'IsActive', 'RelatedRecordId' };
        String whereClause = 'RelatedRecordId IN: userIds';
        List<Object> bindings = new List<Object> { userIds};
        return (List<ServiceResource>) getSObjects(fields, whereClause, bindings);
    }

    public ServiceResource getServiceResourceWithUserById(Id serviceResourceId) {
        if(String.isBlank(serviceResourceId)) {
            return new ServiceResource();
        }
        List<String> fields = new List<String> { 'RelatedRecordId' };
        String whereClause = 'Id =: serviceResourceId LIMIT 1';
        List<Object> bindings = new List<Object> { serviceResourceId };
        return ((List<ServiceResource>) getSObjects(fields, whereClause, bindings))[0];
    }
}