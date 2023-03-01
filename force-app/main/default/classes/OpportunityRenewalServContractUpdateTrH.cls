public with sharing class OpportunityRenewalServContractUpdateTrH extends SObjectTriggerHandler {
    private static final String COMMITMENT_TERM = 'Commitment Term';
    private static final String RENEWAL = 'Renewal';
    private static final String USER_API_ID = 'Susie_Romero_API_User';
    
    @TestVisible
    private List<Opportunity> newOpportunities;

    @TestVisible 
    public OpportunityRenewalServContractUpdateTrH(){
        this((List<Opportunity>) Trigger.new);
    }
    
    @TestVisible
    private OpportunityRenewalServContractUpdateTrH(List<Opportunity> newOpportunities){
        this.newOpportunities = newOpportunities; 
    }
    
    public override void beforeInsert(){
        populateRenewalOpportunityFields();
    }

    public void populateRenewalOpportunityFields(){
        Set<Id> serviceContractIDs = new Set<ID>();
        for(Opportunity opportunityRec : newOpportunities){
            if(opportunityRec.SBQQSC__RenewedServiceContract__c != null){
                serviceContractIDs.add(opportunityRec.SBQQSC__RenewedServiceContract__c);
            }
        }
        if(serviceContractIDs.isEmpty()){
           return; 
        }
        ServiceContractSelector serviceContractSelectorObj = new ServiceContractSelector();
        Map<Id,ServiceContract> serviceContractsRecMap = serviceContractSelectorObj.getServiceContractsMapByIds(New List<Id>(serviceContractIDs));
        for(Opportunity opportunityRec : newOpportunities){
            try{
                if(serviceContractsRecMap.containsKey(opportunityRec.SBQQSC__RenewedServiceContract__c)){
                    renewalOpportunityUpdate(opportunityRec, serviceContractsRecMap.get(opportunityRec.SBQQSC__RenewedServiceContract__c));
                }
            }catch(Exception exe){
                ApexDebugLog.logException(exe, JSON.serialize(newOpportunities), 'OpportunityRenewalServiceContractUpdateTrH', 'populateRenewalOpportunityFields');
            }       
        }
    }

    private void renewalOpportunityUpdate(Opportunity opportunityRec, ServiceContract serviceContractsRec){
        Id opptyRenewalRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(RENEWAL).getRecordTypeId();
        Id userApiId = Id.valueOf(Settings.getValidationRuleRestrictionSalesforceId(USER_API_ID));        
        opportunityRec.Building__c = serviceContractsRec.Building_Id__c;
        opportunityRec.Billing_Account__c = serviceContractsRec.SBQQSC__Quote__r.Billing_Account__c;
        opportunityRec.Sales_Price__c = serviceContractsRec.Renewal_Sales_Price__c;
        opportunityRec.Interested_in_Number_of_Desks__c = serviceContractsRec.Capacity__c;
        opportunityRec.Desired_Term_Length_in_months__c = serviceContractsRec.Term;
        opportunityRec.Primary_Member__c = serviceContractsRec.SBQQSC__Quote__r.SBQQ__PrimaryContact__c;
        opportunityRec.CreatedById = userApiId;
        opportunityRec.RecordTypeId = opptyRenewalRecTypeId;
        opportunityRec.CloseDate = serviceContractsRec.Notice_Date__c == null ? serviceContractsRec.EndDate : serviceContractsRec.Notice_Date__c;
    }
}