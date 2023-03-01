/************************************************************************************************************************************
    Author      :   Krishana Tupe 	
    Description :   This class will contain buisness logic of Account trigger which updates the CI_Company__c Lookup on Contact.
    Issue No    : 	ST-3672
    History		:
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO    	DETAIL
    1           25 March 2019    	Krishana Tupe           			Initial Developement
    2			30 Sept 2020		Krishana Tupe		ST-3174			Code Optimization and Consolidated with new trigger structure
**************************************************************************************************************************************/
public without sharing class AccountUpdateCIUnomyCompanyTrH extends SObjectTriggerHandler{  
    
    @TestVisible
    private List<Account> newAccounts;
    @TestVisible
    private Map<Id, Account> oldAccountsMap;
    
    @TestVisible 
    public AccountUpdateCIUnomyCompanyTrH(){
        this((List<Account>) Trigger.new, (Map<Id, Account>) Trigger.oldMap);
    }
    
    @TestVisible
    private AccountUpdateCIUnomyCompanyTrH(List<Account> newAccounts, Map<Id, Account> oldAccountsMap){
        this.newAccounts = newAccounts;
        this.oldAccountsMap = oldAccountsMap;            
    }
    
    public override void afterUpdate(){
        updateCIUnomyCompanyOnContact();
    }
    
    private void updateCIUnomyCompanyOnContact(){         
        Set<Id> unomyInfoChangedAccountIds = new Set<Id>();
        for(Account newAccountRec : newAccounts){
            Account oldAccountRec = oldAccountsMap.get(newAccountRec.Id);
            if(String.isBlank(newAccountRec.CI_Company__c)){
                continue;
            }
            if(String.isBlank(oldAccountRec.CI_Company__c)){
                unomyInfoChangedAccountIds.add(newAccountRec.Id);    
            }                   
        }
        if(unomyInfoChangedAccountIds.isEmpty()){
            return;
        }        
        List<Contact> contactsToUpdateCICompany = new List<Contact>();        
        for(Contact contactRec : [SELECT Id, CI_Updated_DateTime__c, CI_Company__c, AccountId, Account.CI_Company__c
                                  FROM Contact WHERE AccountId IN : unomyInfoChangedAccountIds AND
                                  CI_Company__c = null]){
            contactsToUpdateCICompany.add(getContactRecord(contactRec));
        }                
        if(!contactsToUpdateCICompany.isEmpty()){
            Database.update(contactsToUpdateCICompany, false);
        }                
    }
    
    private Contact getContactRecord(Contact contactRec){
        return new Contact(Id = contactRec.Id, CI_Company__c = contactRec.Account.CI_Company__c, 
                           CI_Updated_DateTime__c = System.now());            
    }
}