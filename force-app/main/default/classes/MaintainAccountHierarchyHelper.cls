/************************************************************************************************************************************
    Author      :   Mayuresh Ghodke	
    Description :   This class is used to update the Account Type, Name and Opportunity Name while Account merging takes place
					or Account reparenting done on the accounts.    				
    Issue No    : 	-
    History		:	
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION		DATE				AUTHOR				ISSUE NO		DETAIL   
    1			05 Oct 2020			Krishana Tupe		ST-3174			Code Optimization and Consolidated with new trigger structure
**************************************************************************************************************************************/
public inherited sharing class MaintainAccountHierarchyHelper {
    private static final String SALES_ACCOUNT_TYPE = 'Sales';
    private static final String ORG_ACCOUNT_TYPE = 'Org';
    
    @future
    public static void updateAccountAndOpportunityNameInFutureForMerge(String masterAccounts){
        List<Account> accountsToProcess = (List<Account>)JSON.deserialize(masterAccounts, List<Account>.class);
        updateAccountAndOpportunityNameInFutureForMerge(accountsToProcess);
    }
    
    private static void updateAccountAndOpportunityNameInFutureForMerge(List<Account> accountsToProcess){  
        if(accountsToProcess == null || accountsToProcess.isEmpty()){
            return;
        }
        Set<Id> accountIds = new Set<Id>();
        Set<String> orgAccountIds = new Set<String>();
        for(Account accRec : accountsToProcess){
            String accType = accRec.Account_Type__c;
            if(String.isBlank(accType)){
                continue;
            }            
            String orgAccountId = String.isBlank(accRec.MasterRecordId) ? getAccountOrgId(accRec.Id) : getAccountOrgId(accRec.MasterRecordId);   
            if(accType == SALES_ACCOUNT_TYPE){
                accountIds.add(orgAccountId); 
            }else if(accType == ORG_ACCOUNT_TYPE){
                accountIds.add(orgAccountId);  
                orgAccountIds.add(orgAccountId);
            }
        }        
        if(accountIds.isEmpty() && orgAccountIds.isEmpty()){
            return;
        }
        List<Account> accountRecordsToUpdate = new AccountSelector().getAccountWithOpportunities(accountIds, orgAccountIds);
        List<Opportunity> childOpportunitiesToUpdate = new List<Opportunity>();
        for(Account accRec : accountRecordsToUpdate){
            if(!accRec.Opportunities.isEmpty()){
                childOpportunitiesToUpdate.addAll(accRec.Opportunities);
            }
        }
        accountRecordsToUpdate = AccountUpdateNameTrH.updateAccountName(accountRecordsToUpdate);        
        update accountRecordsToUpdate;
        if(!childOpportunitiesToUpdate.isEmpty()){           
            OpportunityNamingTrH.forceCalculations();
            update childOpportunitiesToUpdate;
        }
    }
    
    private static String getAccountOrgId(Id accRecId){
        return String.valueOf(accRecId).subString(0, 15);
    }
}