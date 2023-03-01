public with sharing class CiCompanyManageBillingEnterpriseTrH extends SObjectTriggerHandler {
    @TestVisible
    private final List<CI_Company__c> newCiCompanies;
    @TestVisible
    private final Map<Id, CI_Company__c> oldCiCompaniesMap;

    public CiCompanyManageBillingEnterpriseTrH() {
        this((List<CI_Company__c>) Trigger.new, (Map<Id, CI_Company__c>) Trigger.oldMap);
    }

    @TestVisible
    private CiCompanyManageBillingEnterpriseTrH(List<CI_Company__c> newCiCompanies, Map<Id, CI_Company__c> oldCiCompaniesMap){
        this.newCiCompanies = newCiCompanies;
        this.oldCiCompaniesMap = oldCiCompaniesMap;
    }

    public override void afterUpdate() {
        updateEnterpriseFlag();
    }

    private void updateEnterpriseFlag() {
        Set<Id> ciCmpanyIds = new Set<Id>();
        for (CI_Company__c ci : newCiCompanies) {
            if (TriggerUtility.isFieldValueChanged(ci, oldCiCompaniesMap.get(ci.Id), BillingAccountManageEnterpriseFlagUtils.FIELD_API_NAME_ESTIMATED_COUNT)) {
                ciCmpanyIds.add(ci.Id);
            } else if (TriggerUtility.isFieldValueChanged(ci, oldCiCompaniesMap.get(ci.Id), BillingAccountManageEnterpriseFlagUtils.FIELD_API_NAME_COMPANY_SIZE)) {
                ciCmpanyIds.add(ci.Id);
            }
        }
        AccountSelector accountSelector = new AccountSelector();
        Map<Id, Account> businessAccounts = new Map<Id, Account> (accountSelector.getAccountsByUnomyCompany(new List<Id> (ciCmpanyIds)));
        List<Account> accountsToUpdate = new List<Account>();
        for (Account a : accountSelector.getAccountsByUltimateParent(new List<Id> (businessAccounts.keySet()))) {
            if (a.Ultimate_Parent_Org__r.Account_FTE__c >= BillingAccountManageEnterpriseFlagUtils.MIN_FTE_ENTERPRISE) {
                accountsToUpdate.add(BillingAccountManageEnterpriseFlagUtils.updateCustomerGroup(a, false));
            }
            else if ((a.Ultimate_Parent_Org__r.Account_FTE__c < BillingAccountManageEnterpriseFlagUtils.MIN_FTE_ENTERPRISE) && String.isNotBlank(a.Customer_Group__c)) {
                accountsToUpdate.add(BillingAccountManageEnterpriseFlagUtils.updateCustomerGroup(a, true));
            }
        }
        if (!accountsToUpdate.isEmpty()) {
            dml.add(accountsToUpdate, DmlConsolidator.Operation.FOR_UPDATE);
        }
    }
}