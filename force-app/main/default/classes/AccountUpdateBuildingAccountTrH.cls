/************************************************************************************************************************************
    Author      :   Rohit Nimase    
    Description :   This class is used to Map Legal Entity Name and Address from Billing Account to Building Account.                     
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE                AUTHOR             ISSUE NO        DETAIL
    1           10 May 2022          Rohit Nimase        TWSPG-10451     Initial Developement 
**************************************************************************************************************************************/
public inherited sharing class AccountUpdateBuildingAccountTrH extends SObjectTriggerHandler { 
    @TestVisible
    private List<Account> newAccounts;
    @TestVisible
    private Map<Id, Account> oldAccountsMap;
    private static final  Id BILLING_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(
                                                              GlobalConstants.ACCOUNT_BILLING_ACCOUNT_RECORD_TYPE_DEV_NAME).getRecordTypeId();
    
    @TestVisible 
    public AccountUpdateBuildingAccountTrH(){
        this((List<Account>) Trigger.new, (Map<Id, Account>) Trigger.oldMap);
    }
    
    @TestVisible
    private AccountUpdateBuildingAccountTrH(List<Account> newAccounts, Map<Id, Account> oldAccountsMap){
        this.newAccounts = newAccounts; 
        this.oldAccountsMap = oldAccountsMap;
    }
    
    public override void beforeUpdate(){
        updateLegalNameAndBuildingAddressOnBuildingAccounts();
    }
    
    private void updateLegalNameAndBuildingAddressOnBuildingAccounts(){
        Map<Id, Account> updatedBillingAccounts = new Map<Id, Account>();
        List<Building_Account__c> buildingAccountsToUpdate = new List<Building_Account__c>();
        
        for(Account newAccount : newAccounts){
            Account oldAccount = oldAccountsMap.get(newAccount.Id);
            if(newAccount.RecordTypeId != BILLING_ACCOUNT_RECORD_TYPE_ID){
                continue ;
            }  
            if(TriggerUtility.isFieldsValueChanged(newAccount, oldAccount, new Set<String>{'Legal_Name__c', 'BillingCity', 'BillingPostalCode', 'BillingState', 'BillingStreet', 'BillingCountry', 'BillingLongitude', 'BillingLatitude'})){
                updatedBillingAccounts.put(newAccount.Id, newAccount);
            }
        }
        
        if(updatedBillingAccounts.isEmpty()){
            return ;
        }
        
        buildingAccountsToUpdate = [SELECT Id, Billing_Account_Id__c, Billing_Account_Id__r.BillingStreet, 
                                    Billing_Account_Id__r.BillingCity, Billing_Account_Id__r.BillingState,
                                    Billing_Account_Id__r.BillingCountry,  Billing_Account_Id__r.BillingPostalCode,
                                    Billing_Account_Id__r.BillingLatitude, Billing_Account_Id__r.BillingLongitude 
                                    FROM Building_Account__c WHERE Billing_Account_Id__c IN :updatedBillingAccounts.keySet()];
        
        If(buildingAccountsToUpdate.isEmpty()){
            return;
        }
        updateBuildingAccounts(buildingAccountsToUpdate, updatedBillingAccounts);
    }
    
    private void updateBuildingAccounts(List<Building_Account__c> buildingAccountsToUpdate, Map<Id, Account> updatedBillingAccounts){
        List<Building_Account__c> buildingAccountToUpdate = new List<Building_Account__c>();
        for(Building_Account__c buildingAccount : buildingAccountsToUpdate){
            if(updatedBillingAccounts.keySet().contains(buildingAccount.Billing_Account_Id__c)){
                Account billingAccount = updatedBillingAccounts.get(buildingAccount.Billing_Account_Id__c);
                buildingAccount.Legal_Entity_Name__c = billingAccount.Legal_Name__c;
                buildingAccount.Billing_Street__c = billingAccount.BillingStreet;
                buildingAccount.Billing_City__c = billingAccount.BillingCity;
                buildingAccount.Billing_State__c = billingAccount.BillingState;
                buildingAccount.Billing_Country__c = billingAccount.BillingCountry;
                buildingAccount.Billing_Postal_Code__c = billingAccount.BillingPostalCode;
                buildingAccount.Billing_Geolocation__Latitude__s = billingAccount.BillingLatitude;
                buildingAccount.Billing_Geolocation__Longitude__s = billingAccount.BillingLongitude;
                buildingAccountToUpdate.add(buildingAccount);
            }
        }
        if(buildingAccountToUpdate.isEmpty()){
            return;
        }
        this.dml.add(buildingAccountToUpdate, DmlConsolidator.Operation.FOR_UPDATE);
    }  
}