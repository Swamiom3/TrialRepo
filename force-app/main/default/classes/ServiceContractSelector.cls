/*************************************************************************************************************************************
 Author      :   Shubham Nandwana
 Description :   This class is selector implementation of particular SObject (ServiceContract)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               11/24/2021      Shubham Nandwana    Initial Deployment
 **************************************************************************************************************************************/
public with sharing class ServiceContractSelector extends SObjectSelector {
    public ServiceContractSelector() {
        super(ServiceContract.getSObjectType());
    }
    
    public override Set<String> getDefaultFields(){
        return new Set<String>{'Id', 'Building_Id__c'};
    }
    
    public List<ServiceContract> getServiceContractsByIds(List<Id> serviceContractIds){
        if (serviceContractIds == null || serviceContractIds.isEmpty()) {
            return null;
        }
        List<String> fields = new List<String>(getDefaultFields());
        return (List<ServiceContract>) getSObjectByIds(fields, serviceContractIds);
    }
    
    public Map<Id,ServiceContract> getServiceContractsMapByIds(List<Id> serviceContractIds){
        if (serviceContractIds == null || serviceContractIds.isEmpty()) {
            return null;
        }
        List<String> fields = new List<String>{'Id','Building_Id__c','SBQQSC__Quote__r.Billing_Account__c','Term','Renewal_Sales_Price__c','Capacity__c','SBQQSC__Quote__r.SBQQ__PrimaryContact__c','Notice_Date__c'};
        List<ServiceContract> serviceContractList = getSObjectByIds(fields, serviceContractIds);
        Map<Id,ServiceContract> serviceContractMap = new Map<Id,ServiceContract>();
        for(ServiceContract serviceContractRecord : serviceContractList){
            serviceContractMap.put(serviceContractRecord.Id,serviceContractRecord);
        }
        return serviceContractMap;
    }
}