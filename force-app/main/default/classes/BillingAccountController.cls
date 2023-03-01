/************************************************************************************************************************************
    Author      :   Salesforce
    Description :   This class contains all methods related to Billing Account Selector Component .
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           5 July 2021         Salesforce              Initial Development
**************************************************************************************************************************************/
public without sharing class BillingAccountController {

    @TestVisible
    private static AccountContactRelationSelector acrs = new AccountContactRelationSelector();

    /*****************************************************************************************************************************************
        Author              :   Salesforce
        Description         :   This method is used to get all the billing accounts under ultimate parent of account on opportunity
        Created Date        :   5 July 2021
    ******************************************************************************************************************************************/
    @AuraEnabled
    public static List<BillAccountWrapper> getBillAccountsOfAccountHierarchy(String oppId){
        List<BillAccountWrapper> billAccountList = new List<BillAccountWrapper>();
        Id oppAccountId =  [SELECT AccountId FROM Opportunity WHERE Id=:oppId]?.AccountId;
        String ultimateOrgId;
        if (oppAccountId == null) {
            return null;
        }
        Map<Id, Id> accountParentMap = OrganizationHelper.getUltimateParents(new Set<Id>{oppAccountId});
        ultimateOrgId = accountParentMap.get(Id.valueOf(oppAccountId));
        if (ultimateOrgId == null) {
            return null;
        }

        for (Account acc : new AccountSelector().getAccountWithAccContactRelations(new Set<String>{'Primary Member'}, new Set<String>{'Billing_Account'}, new Set<Id>{ultimateOrgId})) {
            BillAccountWrapper billAccount = new BillAccountWrapper();
            billAccount.AccountId = acc.Id;
            billAccount.accountName = acc.Name;
            billAccount.accountLink = '/' + acc.Id;
            billAccount.primaryMemberName = acc.AccountContactRelations?.Contact?.Name;
            billAccount.primaryMemberLink = (acc.AccountContactRelations?.ContactId != null) ? '/' + acc.AccountContactRelations?.ContactId : null;
            billAccount.primaryMemberEmail = acc.AccountContactRelations?.Contact?.Email;
            billAccount.ultimateAccountName = acc.ultimate_Parent_Org__r?.Name;
            billAccount.ultimateAccountLink = (acc.Ultimate_Parent_Org__c != null) ? '/' + acc.Ultimate_Parent_Org__c : null;
            billAccount.ultimateAccountOwner = acc.Ultimate_Business_Account_Owner__c;
            billAccount.ultimateAccountOwnerLink = (acc.Ultimate_Parent_Org__r != null) ? '/' + acc.Ultimate_Parent_Org__r.OwnerId : null;
            billAccountList.add(billAccount);
        }
        return billAccountList;
    }


    /*****************************************************************************************************************************************
        Author              :   Salesforce
        Description         :   This method is used to populate newly created billing account on opporutnity
        Created Date        :   5 July 2021
    ******************************************************************************************************************************************/
    @AuraEnabled
    public static String updateOpportunityAndPrimaryQuote(String oppId, String accountId, String mainContactId) {
        try {
            List<SObject> recordsToInsert = new List<SObject>();
            List<SObject> recordsToUpdate = new List<SObject>();
            Opportunity oppToUpdate = [SELECT Id, Billing_Account__c, SBQQ__PrimaryQuote__c FROM Opportunity WHERE Id =: oppId];
            oppToUpdate.Billing_Account__c = accountId;
            recordsToUpdate.add(oppToUpdate);
            if (oppToUpdate.SBQQ__PrimaryQuote__c != null) {
                recordsToUpdate.add(new SBQQ__Quote__c(Id = oppToUpdate.SBQQ__PrimaryQuote__c, Billing_Account__c = accountId));
            }
            if (String.isNotBlank(mainContactId)) {
                recordsToInsert.add(new AccountContactRelation(ContactId = mainContactId,
                                                                AccountId = accountId,
                                                                Roles = GlobalConstants.ACCOUNT_CONTACT_RELATION_ROLE_PRIMARY_MEMBER,
                                                                IsActive = true));
            }
            DmlConsolidatorDefault.getInstance()
                                  .add(recordsToInsert, DmlConsolidator.Operation.FOR_INSERT)
                                  .add(recordsToUpdate, DmlConsolidator.Operation.FOR_UPDATE)
                                  .run();
            return 'success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*****************************************************************************************************************************************
        Author              :   Salesforce
        Description         :   This method is used to get ultimate parent of account on an opporutnity
        Created Date        :   5 July 2021
    ******************************************************************************************************************************************/
    @AuraEnabled
    public static OpportunityData getOppUltimateParentAccount(String oppId) {
        OpportunityData od = new OpportunityData();
        Opportunity opp = [SELECT AccountId, Primary_Member__c FROM Opportunity WHERE Id =: oppId];
        Id oppAccountId = opp?.AccountId;
        od.mainContact = opp?.Primary_Member__c;
        String ultimateOrgId;
        if (oppAccountId != null) {
            Map <Id, Id> accountParentMap = OrganizationHelper.getUltimateParents(new Set <Id>{oppAccountId});
            od.parentAccountId = accountParentMap.get(Id.valueOf(oppAccountId));
        }
        return od;
    }

    @AuraEnabled
    public static Id getOppParentAccountId(String oppRecordId) {
        OpportunitySelector oppSelector = new OpportunitySelector();
        Id accountId;
        try{
            accountId = oppSelector.getOppParentAccount(oppRecordId).AccountId;
            return accountId;
        }
        catch(Exception exe) {
            throw new AuraHandledException(exe.getMessage());
        }
    }

    public class BillAccountWrapper {
        @AuraEnabled public String accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String accountLink;
        @AuraEnabled public String primaryMemberName;
        @AuraEnabled public String primaryMemberLink;
        @AuraEnabled public String primaryMemberEmail;
        @AuraEnabled public String ultimateAccountName;
        @AuraEnabled public String ultimateAccountLink;
        @AuraEnabled public String ultimateAccountOwner;
        @AuraEnabled public String ultimateAccountOwnerLink;
    }

    public class OpportunityData {
        @AuraEnabled public String parentAccountId;
        @AuraEnabled public String mainContact;
    }
}