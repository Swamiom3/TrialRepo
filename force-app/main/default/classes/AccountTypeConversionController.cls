/************************************************************************************************************************************
    Author      :   Prashant Mane
    Description :   This controller class for Account Type Conversion functionality.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           28 Aug 2018         Prashant Mane           Initial Developement
**************************************************************************************************************************************/
public without sharing class AccountTypeConversionController {
    public static Boolean isInvoker = false;
    public static Boolean isMaintainAccountHierarchyFutureMethodCalled = false;
    private static final String ORG_ACCOUNT_TYPE = 'Org';
    static {
        isInvoker = ApexDebugLog.registerRootInvoker(ApexDebugLog.InvokerType.AURA, 'AccountTypeConversionController' + 'getsObjectPrefix', ApexDebugLog.InvokerType.AURA);    	
    }
    
	/************************************************************************************************************************************
        Author        	:   Prashant Mane
		Description   	:   This method is used to get AccountTypeConversion data
        Created Date  	:   28 Aug 2018
        Issue No    	:   ST-2715
    **************************************************************************************************************************************/
    public static void setMaintainAccountHierarchyFutureMethodCalledFlag(){
        isMaintainAccountHierarchyFutureMethodCalled = true;       
    }
    
    @AuraEnabled
    public static DatabaseResult changeAccountType(Account objAccount) {        
        Savepoint sp = Database.setSavepoint(); 
        try {           
            List<Account> lstAccountsToUpdate = new List<Account>();
            lstAccountsToUpdate.add(objAccount);
            for (Account objChildAccount : new AccountSelector().getAccountsByParentAccount(new Set<Id>{objAccount.Id})) {
                if(objAccount.Account_Type__c == 'Sales' && objChildAccount.Account_Type__c == 'Org') {
                    objChildAccount.ParentId = objAccount.ParentId;
                    lstAccountsToUpdate.add(objChildAccount);
                }
            }             
            Database.update(lstAccountsToUpdate);
            if(!isMaintainAccountHierarchyFutureMethodCalled){
                List<Account> accountNeedsToProcessForMaintainOrgHierarchy = getAccountsToMaintainOrgHieararchy(objAccount);              
                if(!accountNeedsToProcessForMaintainOrgHierarchy.isEmpty()){
                    setMaintainAccountHierarchyFutureMethodCalledFlag();                   
                    MaintainAccountHierarchyHelper.updateAccountAndOpportunityNameInFutureForMerge(JSON.serialize(accountNeedsToProcessForMaintainOrgHierarchy));
                }
            }          
            return new DatabaseResult(JSON.serialize(objAccount));
        }catch(Exception pEx){
            if(sp != null){
                Database.rollback(sp);
            }
            ApexDebugLog.logException(pEx, JSON.serialize(objAccount), 'AccountTypeConversionController', 'changeAccountType');                      
            return new DatabaseResult(pEx);  
        } 
    } 
    
    @TestVisible
    private static List<Account> getAccountsToMaintainOrgHieararchy(Account accountRec){
        List<Account> accountNeedsToProcessForMaintainOrgHierarchy = new  List<Account>();

        Account accRec = new AccountSelector().getSalesAccountsById(new Set<Id>{accountRec.Id})?.get(0);
        if(accRec == null){
            return accountNeedsToProcessForMaintainOrgHierarchy;
        }
        if(accRec.Parent_Org__c != null){                  
            accountNeedsToProcessForMaintainOrgHierarchy.add(new Account(Id = accRec.Parent_Org__c, Account_Type__c = ORG_ACCOUNT_TYPE));
        }
        if(accRec.Parent_Org_Id__c != null){
            accountNeedsToProcessForMaintainOrgHierarchy.add(new Account(Id = accRec.Parent_Org_Id__c, Account_Type__c = ORG_ACCOUNT_TYPE));
        }
        accountNeedsToProcessForMaintainOrgHierarchy.add(accRec);
        return accountNeedsToProcessForMaintainOrgHierarchy;
    }
    
}