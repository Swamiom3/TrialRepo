/************************************************************************************************************************************
Author      :   Dheeraj Perumalla  
Description :   This class sets building and Billing account on Opportunity based on renewal Service Contract
Issue No    :   -
History     :   
----------------------------------------------------------------------------------------------------------------------------------
VERSION    DATE        AUTHOR        ISSUE NO    DETAIL
1          27/1/2022   Dheeraj    
**************************************************************************************************************************************/
public with sharing class OpportunityUpdateBuildingTrH extends SObjectTriggerHandler { 
    
    @TestVisible
    private List<Opportunity> newOpportunities;
    @TestVisible
    private Map<Id, Opportunity> oldOpportunitiesMap;

    @TestVisible 
    public OpportunityUpdateBuildingTrH(){
        this((List<Opportunity>) Trigger.new, (Map<Id, Opportunity>) Trigger.oldMap);
    }
    
    @TestVisible
    private OpportunityUpdateBuildingTrH(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunitiesMap){
        this.newOpportunities = newOpportunities; 
        this.oldOpportunitiesMap = oldOpportunitiesMap;
    }
    
    public override void beforeInsert(){
        populateBuildingAndBillingAccount();
    }
    
    public override void beforeUpdate(){
        populateBuildingAndBillingAccount();
    }
    
    /************************************************************************************************************************************
        Author              :   Dheeraj Perumalla
        Description         :   This method will update Building and Billing Account on Opportunity based on Renewal Service Contract
        Created Date        :   14 January 2022
        Issue               :   TWSPG-7657
    **************************************************************************************************************************************/
    
    public void populateBuildingAndBillingAccount(){
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
        Map<Id,ServiceContract> serviceContractsrecMap = serviceContractSelectorObj.getServiceContractsMapByIds(New List<Id>(serviceContractIDs));
        for(Opportunity opportunityRec : newOpportunities){
            try{
                if(isBuildingOrBillingAccountChanged(opportunityRec,serviceContractsrecMap) || (this.context == TriggerContext.BEFORE_INSERT && serviceContractsrecMap.containsKey(opportunityRec.SBQQSC__RenewedServiceContract__c))){
                    opportunityRec.Billing_Account__c = serviceContractsrecMap.get(opportunityRec.SBQQSC__RenewedServiceContract__c).SBQQSC__Quote__r.Billing_Account__c;
                    opportunityRec.Competitor_Solution__c ='Did not specify';
                    opportunityRec.Broker_Involvement_Indicated__c= 'No';
                }
            }catch(Exception ex){
                ApexDebugLog.logException(ex,ex.getStackTraceString(), 'BillingCustomNumbering', 'populateBuildingAndBillingAccount');
            }       
        }        
    }
    
    public boolean isBuildingOrBillingAccountChanged(Opportunity opportunityRec, Map<Id,ServiceContract> serviceContractsrecMap){
    Set<String> fieldAPINames = new Set<String>{'Billing_Account__c','SBQQSC__RenewedServiceContract__c'};

        return(this.context == TriggerContext.BEFORE_UPDATE && serviceContractsrecMap.containsKey(opportunityRec.SBQQSC__RenewedServiceContract__c) && 
            (opportunityRec.Billing_Account__c == null  || TriggerUtility.isFieldsValueChanged(opportunityRec,oldOpportunitiesMap.get(opportunityRec.ID),fieldAPINames)));    
        
    }
}