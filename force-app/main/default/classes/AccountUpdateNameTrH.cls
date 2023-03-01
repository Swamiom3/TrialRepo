/************************************************************************************************************************************
    Author      :   Krishana Tupe	
    Description :  	Naming Convention for Account Record.
    				For Sales Account==> Org Account Name:suffix:Current Account Nickname
    
    Issue No    : 	-
    History		:	
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION		DATE				AUTHOR				ISSUE NO		DETAIL
    1           17 Jan 2018      	Krishana Tupe	    ST-1773         Initial Developement 
    2			05 Oct 2020			Krishana Tupe		ST-3174			Code Optimization and Consolidated with new trigger structure
**************************************************************************************************************************************/
public inherited sharing class AccountUpdateNameTrH extends SObjectTriggerHandler { 
    private  static MetadataSetting__mdt accountHierarchySuffixMDTSetting = Settings.getMetadataSettingByDevName('Account_Hierarchy_Naming_Convention');
    @TestVisible
    private List<Account> newAccounts;
    
    @TestVisible 
    public AccountUpdateNameTrH(){
        this((List<Account>) Trigger.new);
    }
    
    @TestVisible
    private AccountUpdateNameTrH(List<Account> newAccounts){
        this.newAccounts = newAccounts;                 
    }
    
    public override void beforeInsert(){
        updateAccountName(newAccounts);
    }
    
    public override void beforeUpdate(){
        updateAccountName(newAccounts);
    }
    
    public static List<Account> updateAccountName(List<Account> accountsToUpdateName){     
        MetadataDrivenTriggerHandler.clearLoopCount('AccountUpdateNameTrH');  
        if(accountHierarchySuffixMDTSetting == null){
            return accountsToUpdateName;
        }
        Map<String, String> accountTypeToNameExpression = (Map<String, String>)JSON.deserialize(accountHierarchySuffixMDTSetting.Data__c, Map<String, String>.class);
        if(accountTypeToNameExpression == null){
            return accountsToUpdateName; 
        }
        for(Account newAccount : accountsToUpdateName){
            if(String.isBlank(newAccount.Account_Type__c)){
                continue;
            }
            String accountType = newAccount.Account_Type__c;
            if(accountType.toLowerCase() != 'sales'){
                continue;  
            }            
            String namingConventionExpression = accountTypeToNameExpression.get(accountType);
            List<String> accountFields = getNamingConventionExpressionFields(namingConventionExpression);
            for(String accountField : accountFields){
                String recordFieldValue = newAccount.get(accountField) == null ? '': String.valueOf(newAccount.get(accountField)); 
                namingConventionExpression = namingConventionExpression.replace('{{' + accountField + '}}', recordFieldValue);
            }
            newAccount.Name = namingConventionExpression;
        }
        return accountsToUpdateName;
    }
    
    private static List<String> getNamingConventionExpressionFields(String namingConventionExpression){
        List<String> accountFields = new List<String>();
        while(namingConventionExpression.substringBetween('{{', '}}') != null){
            String exprField = namingConventionExpression.substringBetween('{{', '}}');
            accountFields.add(exprField);
            namingConventionExpression = namingConventionExpression.replace('{{'+exprField+'}}', '');
        }
        return accountFields;
    }
}