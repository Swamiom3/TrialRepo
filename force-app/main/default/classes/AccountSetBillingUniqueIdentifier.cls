/************************************************************************************************************************************
    Author       :  Shubham Nandwana   
    @Description :  Create unique shortcode for Billing Account
    Issue No     :  TWSPG-711
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO        DETAIL
    1           20 August 2021      Shubham Nandwana    TWSPG-711       Initial Developement              
**************************************************************************************************************************************/
public with sharing class AccountSetBillingUniqueIdentifier extends SObjectTriggerHandler {

    private List<Account> newAccounts;
    
    public AccountSetBillingUniqueIdentifier() {
        this((List<Account>) Trigger.new);
    }
    
    @TestVisible
    private AccountSetBillingUniqueIdentifier(List<Account> newAccounts) {
        this.newAccounts = newAccounts; 
    }
    
    public override void beforeInsert() {
        updateShortCodeValue(filterBillingAccount());
    }
    
    public override void beforeUpdate() {
        updateShortCodeValue(filterBillingAccount());
    }
    
    private List<Account> filterBillingAccount() {
        List<Account> filteredBillingAccountRecords = new List<Account>();
        Id billRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();
        for (Account account : newAccounts) {
            if(account.recordTypeId == billRecTypeId){
                filteredBillingAccountRecords.add(account);
            }
        }
        return filteredBillingAccountRecords;
    }

    private void updateShortCodeValue(List<Account> billingAccounts){
        try{
            for (Account account : billingAccounts){
                if (String.isNotBlank(account.Member_Short_Code__c) || String.isBlank(account.UUID__c)) {
                    continue;
                }
                String uniqueCode = new ShortcodeGenerator().getMessageShortCode(account.UUID__c);
                if(uniqueCode == null){
                    account.addError(Label.AccountDuplicateMemberCodeErrorMessage );
                }
                account.Member_Short_Code__c = uniqueCode;
            }
        }catch(DmlException pEx){
            ApexDebugLog.logException(pEx, JSON.serialize(billingAccounts), 'AccountSetBillingUniqueIdentifier', 'updateShortCodeValue');
        }
    }
}