/*************************************************************************************************************************************
 Author      :   Silpa Putti
 Description :   This class is selector implementation of particular SObject (Opportunity)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               7/9/2021       Silpa Putti        Initial Deployment
 **************************************************************************************************************************************/
public inherited sharing class OpportunitySelector extends SObjectSelector {
    private final String OPPORTUNITY_CHILD_REFERRALS_SUBQUERY = '(SELECT Id, Opportunity__c, IsRenewalOpportunity__c, Agency_Broker_Company__c, Agency_Broker_Email__c, '
                                                                    + 'Agency_Broker_Name__c, Agency_Broker_Role__c FROM Referrals__r)';
    private final String OPPORTUNITY_CHILD_TEAMMEMBERS_SUBQUERY = '(SELECT Id, OpportunityId, UserId, TeamMemberRole, OpportunityAccessLevel, ' 
                                                                    + 'Primary_Tour_Assist__c, User_Attribute__c, Assigned_Date__c FROM OpportunityTeamMembers)';
    private final String OPPORTUNITY_CHILD_TASKS_SUBQUERY = '(SELECT Id, Subject, CreatedDate, LastModifiedDate FROM Tasks ' + 
                                                            'WHERE Type NOT IN (\'' + String.escapeSingleQuotes(GlobalConstants.TASK_TYPE_SALES_INQUIRY)  + '\', \'' + String.escapeSingleQuotes(GlobalConstants.TASK_TYPE_PROACTIVE_CHECKIN) + '\'' + ') ORDER BY LastModifiedDate DESC)';
    private final String OPPORTUNITY_CHILD_EVENTS_SUBQUERY = '(SELECT Id, CreatedDate, LastModifiedDate FROM Events ORDER BY LastModifiedDate DESC)';
    private final String OPPORTUNITY_CHILD_OPPCONTACTROLES_SUBQUERY = '(SELECT OpportunityId, ContactId, Role, IsPrimary FROM OpportunityContactRoles)';
       
                                                                    
                                                                    
    public OpportunitySelector() {
        super(Opportunity.getSObjectType());
    }
    
    /****************************************************************************************************************************
     Author              : Silpa Putti
     Description         : This method is used to get default fields from Object
     Created Date        : 7/9/2021
     *****************************************************************************************************************************/
    public override Set<String> getDefaultFields(){
        return new Set<String>{'Id', 'Name'};
    }
    
    /****************************************************************************************************************************
     Author              : Silpa Putti
     Description         : This method is used to get product records from product name
     Created Date        : 14/7/2021
     *****************************************************************************************************************************/
    public List<Opportunity> getCancellationOpportunities(String amendmentOpportunityType,Set<Id> closedReplacementOppIds,String stage){
        if(closedReplacementOppIds.isEmpty() || amendmentOpportunityType == null || stage == null){
            return null;
        }
        List<String> fields = new List<String>{'Id',
                                'StageName'
                                };
        String whereClause = 'Amendment_Opportunity_Type__c =: amendmentOpportunityType AND Replacement_Opportunity__c IN :closedReplacementOppIds AND StageName !=: stage';
        List<Object> bindings = new List<Object>{amendmentOpportunityType,closedReplacementOppIds, stage};
        return (List<Opportunity>) getSObjects(fields, whereClause, bindings);
    }

    public List<Opportunity> getOppsWithRelatedReferrals(Set<Id> opportunitiesIds) {
        if (opportunitiesIds == null || opportunitiesIds.isEmpty()) {
            return new List<Opportunity>();
        }
        List<String> fields = new List<String>{ 'Id', OPPORTUNITY_CHILD_REFERRALS_SUBQUERY };
        return (List<Opportunity>) getSObjectByIds(fields, new List<Id>(opportunitiesIds));
    }

    public List<Opportunity> getOpportunitiesWithTeamMembers(Set<Id> opportunitiesIds) {
        if (opportunitiesIds == null || opportunitiesIds.isEmpty()) {
            return new List<Opportunity>();
        }
        List<String> fields = new List<String>{'Id'};
        fields.add(OPPORTUNITY_CHILD_TEAMMEMBERS_SUBQUERY);
        String whereClause = 'Id IN :opportunitiesIds';
        List<Object> bindings = new List<Object>{ opportunitiesIds };
        return (List<Opportunity>) getSObjects(fields, whereClause, bindings);
    }


    public List<Opportunity> getOpportunitiesWithRelatedActivities(Set<Id> opportunitiesIds) {
        if (opportunitiesIds == null || opportunitiesIds.isEmpty()) {
            return new List<Opportunity>();
        }
        List<String> fields = new List<String>{'Id', 'First_Activity_Date__c', 'Days_Since_Last_Activity__c', 'Last_Related_Activity_Modified_Date__c'};
        fields.add(OPPORTUNITY_CHILD_TASKS_SUBQUERY);
        fields.add(OPPORTUNITY_CHILD_EVENTS_SUBQUERY);
        List<Id> bindings = new List<Id>(opportunitiesIds);
        return (List<Opportunity>) getSObjectByField(fields, 'Id', bindings, false, false);
    }

    public List<Opportunity> getOpportunityLocationFieldsById(Id opportunityId) {
        if (String.isBlank(opportunityId)) {
            return new List<Opportunity>();
        }
        List<String> fields = new List<String>{ 'Building__c', 'Locations_Interested__c' };
        return (List<Opportunity>) getSObjectByIds(fields, opportunityId);

    }

    public List<Opportunity> getOpportunitiesWithContactRolesByBuildIds(Set<Id> buildingIds, List<String> oppStages){
        if (buildingIds?.isEmpty() != false) {
            return new List<Opportunity>();
        }
        List<String> fields = new List<String>{'Id', 'Building__c', 'Opportunity_Creation_Source__c'};
        fields.add(OPPORTUNITY_CHILD_OPPCONTACTROLES_SUBQUERY);
        String whereClause = 'Building__c IN :buildingIds AND StageName NOT IN :oppStages';
        List<Object> bindings = new List<Object>{buildingIds, oppStages};
        return (List<Opportunity>) getSObjects(fields, whereClause, bindings, 50000);
    }
    
    public Opportunity getOppParentAccount(String oppRecordId) {
        List<String> fields = new List<String>{'Id','AccountId'};
        String whereClause = 'Id =: oppRecordId';
        List<Object> bindings = new List<Object>{oppRecordId};
        List<Opportunity> oppList = getSObjects(fields, whereClause, bindings, 1);
        if(oppList.isEmpty()) {
            return null;
        }
        return oppList[0]; 
    }
    
    public List<Opportunity> getOpportunitiesByIds(Set<Id> oppIds, List<String> fields) {
        if (oppIds == null || oppIds.isEmpty()) {
            return new List<Opportunity>();
        }
        return (List<Opportunity>) getSObjectByField(fields, 'Id', oppIds, false);
    }

    public Opportunity getOpportunityById(String opportunityId, List<String> fields) {
        String whereClause = 'Id =: opportunityId';
        List<Object> bindings = new List<Object>{opportunityId};
        List<Opportunity> oppList = getSObjects(fields, whereClause, bindings, 1);
        if(oppList.isEmpty()) {
            return null;
        }
        return oppList[0]; 
    }

    public List<Opportunity> getSelfServeOppsByAccountIds(Set<Id> relatedAccIds) {
        if (relatedAccIds == null || relatedAccIds.isEmpty()) {
            return new List<Opportunity>();
        }
        String oppLeadSourceDetail = 'Self Serve';
        List<String> fields = new List<String>{ 'Id', 'AccountId', 'Promo_Code__c' };
        String whereClause = 'AccountId IN :relatedAccIds AND Lead_Source_Detail__c = :oppLeadSourceDetail';
        List<Object> bindings = new List<Object>{relatedAccIds, oppLeadSourceDetail};
        return (List<Opportunity>) getSObjects(fields, whereClause, bindings);
    }
}