/************************************************************************************************************************************
Author      :   Dipak Pawar
Description :   This class contain all aura methods related to Account Selector.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           13 Oct 2018        Dipak Pawar          	Initial Developement
**************************************************************************************************************************************/
global without sharing class AccountSelectorController {
    public class  AccountSelectorControllerException extends Exception{}
    public static Boolean isInvoker = false;
    public static Savepoint sp {get; set;}
    
    static {
        isInvoker = ApexDebugLog.registerRootInvoker(ApexDebugLog.InvokerType.AURA, 'AccountSelectorController' + 'getsObjectPrefix', ApexDebugLog.InvokerType.AURA);        
    }
    
    /************************************************************************************************************************************
      Author              : Dipak Pawar
      Description         : This method gives the matched Accounts for the given Lead record
      Created Date        : 16 Oct 2018
      Issue No            : ST-2783
      LastModified By     : Nikhil      
   **************************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getMatchedAccounts(Lead objLead){
        try{ 
            sp = Database.setSavepoint();
            if(objLead != null ){
                Id leadId = objLead.Id;
                List<Lead> lstLeads = Database.query('SELECT Id, '+String.join(new OrganizationHelperServices().getListFields('lead'), ' ,')+' FROM Lead WHERE Id = :leadId');
                Map<String, Set<String>> mapMatchingAccounts = OrganizationHelperServices.getOrgsByNewCriterias(lstLeads, new Map<Id, Map<String, Set<String>>>()).get(lstLeads[0].Id);
                Set<String> setMatchedLeadIds;
                Boolean isHighConfidenceAccountIds =  false;
                if(mapMatchingAccounts!= NULL && mapMatchingAccounts.get('highConfidenceAccountIds') != NULL){                   
                    setMatchedLeadIds = mapMatchingAccounts.get('highConfidenceAccountIds');
                    isHighConfidenceAccountIds = true;
                }else if(mapMatchingAccounts!= NULL && mapMatchingAccounts.get('lowConfidenceAccountIds') != NULL){                 
                    setMatchedLeadIds = mapMatchingAccounts.get('lowConfidenceAccountIds');
                }
                if(setMatchedLeadIds != NULL && !setMatchedLeadIds.isEmpty()){                    
                    return new DatabaseResult(new Map<String, Object>{'isHighConfidenceAccountIds' => isHighConfidenceAccountIds, 'matchedOrgRecords' => new List<Account>([SELECT Id, Name, Parent_Org_Id__c, Account_Type__c, OwnerId, Owner.Name, ParentId, Parent.Name, Primary_Member__c, Primary_Member__r.Name, Primary_Member__r.Email FROM Account WHERE Id IN :setMatchedLeadIds])});
                }  
            }
            return new DatabaseResult(new Map<String, Object>{'isHighConfidenceAccountIds' => false, 'matchedOrgRecords' => new List<Account>()});
        }catch(Exception pEx){
            LightningComponentController.rollbackTransaction(sp);
            ApexDebugLog.logException(pEx, '', 'AccountSelectorController', 'getMatchedAccounts');
            return new DatabaseResult(pEx);  
        }
    }  
    
     /************************************************************************************************************************************
    Author              : Dipak Pawar
    Description         : This method gives the Sales Accounts related to given Account Id
    Created Date        : 16 Oct 2018
    Issue No            : ST-2783
	LastModified Date   : 8 March 2019
    LastModified By     : Krishana Tupe (Rollback transaction if exception occured)
**************************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getRelatedSalesAccounts(String accountId){
        try{
            sp = Database.setSavepoint();
            Account objAccount = [SELECT Id, Name, Parent_Org_Id__c, Ultimate_Parent_Org__c, Account_Type__c, OwnerId, Owner.Name, ParentId, Parent.Name, Primary_Member__c, Primary_Member__r.Name, Primary_Member__r.Email, (SELECT Id FROM childAccounts WHERE Account_Type__c = 'Sales') FROM Account WHERE Id =: accountId];
            if(objAccount != null && objAccount.Account_Type__c == 'Sales'){
                if(objAccount.ParentId == null){
                    return new DatabaseResult(new List<Account>([SELECT Id, Name, Parent_Org_Id__c, Account_Type__c, OwnerId, Owner.Name, ParentId, Parent.Name, Primary_Member__c, Primary_Member__r.Name, Primary_Member__r.Email FROM Account WHERE (Id =: objAccount.Id OR ParentId =: objAccount.Id OR ParentId =: objAccount.Ultimate_Parent_Org__c OR Ultimate_Parent_Org__c =: objAccount.Ultimate_Parent_Org__c) AND Account_Type__c = 'Sales']));
                } else {
                    return new DatabaseResult(new List<Account>([SELECT Id, Name, Parent_Org_Id__c, Account_Type__c, OwnerId, Owner.Name, ParentId, Parent.Name, Primary_Member__c, Primary_Member__r.Name, Primary_Member__r.Email FROM Account WHERE (Id =: objAccount.Id OR ParentId =: objAccount.Id OR ParentId =: objAccount.ParentId OR ParentId =: objAccount.Ultimate_Parent_Org__c OR Ultimate_Parent_Org__c =: objAccount.Ultimate_Parent_Org__c) AND Account_Type__c = 'Sales']));
                }
            }else if(objAccount != null && objAccount.Account_Type__c == 'Org'){
                return new DatabaseResult(new List<Account>([SELECT Id, Name, Parent_Org_Id__c, Account_Type__c, OwnerId, Owner.Name, ParentId, Parent.Name, Primary_Member__c, Primary_Member__r.Name, Primary_Member__r.Email FROM Account WHERE (Id =: objAccount.Id OR ParentId =: objAccount.Id OR Ultimate_Parent_Org__c =: objAccount.Id) AND Account_Type__c = 'Sales']));
            }
            return null;
        } catch(Exception pEx){
            LightningComponentController.rollbackTransaction(sp);
            ApexDebugLog.logException(pEx, '', 'AccountSelectorController', 'getRelatedSalesAccounts');
            return new DatabaseResult(pEx);
        }
    }

    /************************************************************************************************************************************
	Author              : Dipak Pawar
	Description         : This method gives the complete Account Hierarchy for given Account id
	Created Date        : 16 Oct 2018
	Issue No            : ST-2783
	LastModified Date   : 8 March 2019
    LastModified By     : Krishana Tupe (Rollback transaction if exception occured)
	**************************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getRelatedViewHierarchy(String accountId){
        try{
            sp = Database.setSavepoint();
            Account objAccount = [SELECT Id, Name, Parent_Org_Id__c, Ultimate_Parent_Org__c, Account_Type__c, OwnerId, Owner.Name, ParentId, Parent.Name, Primary_Member__c, Primary_Member__r.Name, Primary_Member__r.Email FROM Account WHERE Id =: accountId];
            if(objAccount != null  && objAccount.Account_Type__c == 'Sales'){
                return new DatabaseResult(new List<Account>([SELECT Id, Name, Parent_Org_Id__c, Account_Type__c, OwnerId, Owner.Name, ParentId, Parent.Name, Primary_Member__c, Primary_Member__r.Name, Primary_Member__r.Email FROM Account WHERE (Id =: objAccount.Id OR ParentId =: objAccount.Id OR Ultimate_Parent_Org__c =: objAccount.Id OR Id =: objAccount.Ultimate_Parent_Org__c OR ParentId = : objAccount.Ultimate_Parent_Org__c OR Ultimate_Parent_Org__c =: objAccount.Ultimate_Parent_Org__c)]));
            }else if(objAccount != null && objAccount.Account_Type__c == 'Org'){
                return new DatabaseResult(new List<Account>([SELECT Id, Name, Parent_Org_Id__c, Account_Type__c, OwnerId, Owner.Name, ParentId, Parent.Name, Primary_Member__c, Primary_Member__r.Name, Primary_Member__r.Email FROM Account WHERE (Id =: objAccount.Id OR ParentId =: objAccount.Id OR Ultimate_Parent_Org__c =: objAccount.Id)]));
            }
            return null;
        }catch(Exception pEx){
            LightningComponentController.rollbackTransaction(sp);
            ApexDebugLog.logException(pEx, '', 'AccountSelectorController', 'getRelatedViewHierarchy');
            return new DatabaseResult(pEx);
        }
    }

    /************************************************************************************************************************************
	Author              : Shivprasad Patil
	Description         : This method used to generate query result for dynamic label.
	Created Date        : 03 December 2018
	Issue No            : ST-3885
	Last Modified By    : Pragalbha Mahajan
    Last Modified Date  : 15 May 2019
	Issue No            : ST-3885
	**************************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getQueryData(String label, Map<String, Object> params){
        try{
            sp = Database.setSavepoint();
            switch on label{
                when 'searchOrgAccounts'{
                    List<Account> lstAccounts = new List<Account>();
                    String accountType = (String)params.get('accountType');
                    String query = 'SELECT Id, Name, OwnerId, Account_SubType__c, Website, Owner.Name, Parent_Org__c, Parent_Org_Id__c, Primary_Member__r.Name, Account_Type__c FROM Account WHERE ';
                    query += accountType == 'Broker' ? ' Account_SubType__c = \'Broker\' ' : accountType == 'Partner' ? ' Account_SubType__c = \'Partner\' ' : (accountType == 'All' ? '( Account_Type__c = \'Org\' OR Account_Type__c = \'Sales\')' : (accountType == 'Org' ? 'Account_Type__c = \'Org\'' : 'Account_Type__c = \'Sales\''));
                    if(params.containsKey('searchAllOrg') && !((Boolean)params.get('searchAllOrg'))){
                        query += ' AND RecordType.Name = \'Enterprise Solutions\' ';
                    }
                    String startWithQuery = query + ' AND Name LIKE \'' + (String)params.get('accountName') + '%\'';
                    lstAccounts.addAll((List<Account>) Database.query(startWithQuery));
                    String searchAllQuery = query + (lstAccounts.isEmpty() ? '': ' AND Id NOT IN :lstAccounts') + ' AND Name LIKE \'%' + (String)params.get('accountName') + '%\'';
                    lstAccounts.addAll((List<Account>) Database.query(searchAllQuery));
                    return new DatabaseResult(lstAccounts);
                }
            }
            return new DatabaseResult(new List<sObject>());
        }catch(Exception pEx){
            LightningComponentController.rollbackTransaction(sp);
            ApexDebugLog.logException(pEx, '', 'AccountSelectorController', 'getQueryData');
            return new DatabaseResult(pEx);
        }
    }
}