/********************************************************************************************************************************
 Author      :   Vipul Chaudhdari
 Description :   This class is selector implementation of particular SObject (Interest__c)
 --------------------------------------------------------------------------------------------------------------------------------
 VERSION          DATE             AUTHOR                   DETAIL
 1              23/9/2021      Vipul Chaudahari         Initial Deployment
 *******************************************************************************************************************************/
public inherited sharing class InterestSelector extends SObjectSelector{
    private List<String> DEFAULT_FIELDS = new List<String>{'Building__c', 
                                                           'Opportunity__c', 
                                                           'Primary_Building__c', 
                                                           'Inventory_Id__c'
    };

    public InterestSelector() {
    	super(Interest__c.getSObjectType());
    }
    
    public override Set<String> getDefaultFields() {
        return new Set<String>(DEFAULT_FIELDS);
    }
    
    public List<Interest__c> getInterestByOpportunity(Set<Id> interestIds, Set<Id> opportunityIds) {
        if(interestIds.isEmpty() && opportunityIds.isEmpty()) {
            return null;
        }
        List<String> fields = new List<String>{'Id', 
                                               'Name',
                                               'Opportunity__c',
                                               'Building__c',
                                               'Inventory_Id__c'    
        };
        String whereClause = '(Id NOT IN :interestIds  AND Opportunity__c IN :opportunityIds)';
        return (List<Interest__c>) getSobjects(fields, whereClause, new List<Object>{interestIds, opportunityIds});
    }
}