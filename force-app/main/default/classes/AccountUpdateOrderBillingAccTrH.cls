/************************************************************************************************************************************
    Author      :   Serge Kandukuri
    Description :   Converted flow into Trigger - Account After Handler - V5    
    Issue No    :   -
    History     :  
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR           ISSUE NO    DETAIL
    1          30 Sep 2021     Serge Kandukuri              Initial Developement 
**************************************************************************************************************************************/
public inherited sharing class AccountUpdateOrderBillingAccTrH extends SObjectTriggerHandler { 
    @TestVisible
    private List<Account> newAccounts;
    
    @TestVisible
    private Map<Id, Account> oldAccountsMap;
    
    @TestVisible 
    public AccountUpdateOrderBillingAccTrH(){
        this((List<Account>) Trigger.new, (Map<Id, Account>) Trigger.oldMap);
    }
    
    @TestVisible
    private AccountUpdateOrderBillingAccTrH(List<Account> newAccounts, Map<Id, Account> oldAccountsMap){
        this.newAccounts = newAccounts;
        this.oldAccountsMap = oldAccountsMap;            
    }
    
    public override void afterinsert(){
        executeFlow();
    }
    
    public override void afterUpdate(){
        executeFlow();
    }
    
    @TestVisible
    private void executeFlow(){
        Map<String,Object> accMap = new Map<String, Object>();
        for(Account newAccountRec : newAccounts){
            if(this.context ==  TriggerContext.AFTER_UPDATE){
                if(newAccountRec.Account_Billing_Frequency__c!= oldAccountsMap.get(newAccountRec.Id).Account_Billing_Frequency__c){
                	accMap.put('freqChanged', true);
            	}
                if(newAccountRec.Dedicated_Billing_Support__c== 'Yes' && oldAccountsMap.get(newAccountRec.Id).Dedicated_Billing_Support__c!='Yes'){
                	accMap.put('dedicatedBAChanged', true);
            	}
                if(newAccountRec.Taxation_Status__c== 'Pending Tax Exempt' && oldAccountsMap.get(newAccountRec.Id).Taxation_Status__c!='Pending Tax Exempt'){
                	accMap.put('taxExemptChanged', true);
            	}

            }
        accMap.put('newAccRecord', newAccountRec);
        Flow.Interview.Account_After_Handler_With_Start_New accountFrequencyApprovalHandler = new Flow.Interview.Account_After_Handler_With_Start_New(accMap);
        accountFrequencyApprovalHandler.start();
        }
    }
}