/*************************************************************************************************************************************
 Description :   This class is selector implementation of particular SObject (OpportunityContactRole)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR                   DETAIL
 1               10/19/2021      Oleksandr Liesnik        Initial Deployment
 **************************************************************************************************************************************/
public inherited sharing class OpportunityContactRoleSelector extends SObjectSelector {

    public OpportunityContactRoleSelector() {
        super(OpportunityContactRole.getSObjectType());
    }

    public override Set<String> getDefaultFields(){
        return new Set<String>{ 'Id',
                                'ContactId',
                                'Contact.Email',
                                'Contact.Name',
                                'Contact.Company__c',
                                'IsPrimary',
                                'OpportunityId',
                                'Role' };
    }

    public List<OpportunityContactRole> getOpportunityContactRolesByOppIdsAndRole(Set<Id> opportunitiesIds, String role) {
        if (opportunitiesIds?.isEmpty() != false) {
            return new List<OpportunityContactRole>();
        }
        List<String> fields = new List<String>{};
        fields.addAll(getDefaultFields());
        String whereClause = 'OpportunityId IN: opportunitiesIds AND Role =: role ORDER BY CreatedDate DESC';
        List<Object> bindings = new List<Object>{ opportunitiesIds, role };
        return (List<OpportunityContactRole>) getSObjects(fields, whereClause, bindings);
    }

    public List<OpportunityContactRole> getOpportunityContactRolesByOppIds(Set<Id> opportunitiesIds) {
        if (opportunitiesIds?.isEmpty() != false) {
            return new List<OpportunityContactRole>();
        }
        List<String> fields = new List<String>{};
        fields.addAll(getDefaultFields());
        String whereClause = 'OpportunityId IN: opportunitiesIds';
        List<Object> bindings = new List<Object>{ opportunitiesIds };
        return (List<OpportunityContactRole>) getSObjects(fields, whereClause, bindings);
    }

    public List<OpportunityContactRole> getOpportunityContactRolesByOpportunityAndContact(Id opportunityId, Id contactId) {
        if (String.isBlank(opportunityId) || String.isBlank(contactId)) {
            return new List<OpportunityContactRole>();
        }
        List<String> fields = new List<String>{ 'Id' };
        String whereClause = 'OpportunityId = :opportunityId AND ContactId = :contactId';
        List<Object> bindings = new List<Object>{ opportunityId, contactId };
        return (List<OpportunityContactRole>) getSObjects(fields, whereClause, bindings);
    }
}