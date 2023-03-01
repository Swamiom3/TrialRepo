public with sharing class BillingAccountManageEnterpriseFlagTrH extends SObjectTriggerHandler {
    @TestVisible
    private final List<Account> newAccounts;
    @TestVisible
    private final Map<Id, Account> oldAccountsMap;


    public BillingAccountManageEnterpriseFlagTrH() {
        this((List<Account>) Trigger.new, (Map<Id, Account>) Trigger.oldMap);
    }

    @TestVisible
    private BillingAccountManageEnterpriseFlagTrH(List<Account> newAccounts, Map<Id, Account> oldAccountsMap){
        this.newAccounts = newAccounts;
        this.oldAccountsMap = oldAccountsMap;
    }

    public override void afterInsert() {
        updateEnterpriseFlag();
    }

    public override void afterUpdate() {
        updateEnterpriseFlag();
    }

    private void updateEnterpriseFlag() {
        List<Id> billingAccountIds = new List<Id>();
        List<Id> businessAccountIds = new List<Id>();
        List<Account> accountsToUpdate = new List<Account>();
        Id billingRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(BillingAccountManageEnterpriseFlagUtils.RECORD_TYPE_BILLING).getRecordTypeId();
        Id businessRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(BillingAccountManageEnterpriseFlagUtils.RECORD_TYPE_BUSINESS).getRecordTypeId();
        for (Account acc : newAccounts) {
            if (acc.RecordTypeId == billingRecordTypeId) {
                billingAccountIds = updateBillingAccountIds(acc, billingAccountIds);
            }
            else if (oldAccountsMap != null && acc.RecordTypeId == businessRecordTypeId) {
                businessAccountIds = updateBusinessAccountIds(acc, businessAccountIds);
            }
        }
        AccountSelector accountSelector = new AccountSelector();
        for (Account acc : accountSelector.getAccountsByIdOrUltimateParent(billingAccountIds, businessAccountIds)) {
            if (acc.Ultimate_Parent_Org__r.Account_FTE__c >= BillingAccountManageEnterpriseFlagUtils.MIN_FTE_ENTERPRISE) {
                accountsToUpdate.add(BillingAccountManageEnterpriseFlagUtils.updateCustomerGroup(acc, false));
            } else if ((acc.Ultimate_Parent_Org__r.Account_FTE__c < BillingAccountManageEnterpriseFlagUtils.MIN_FTE_ENTERPRISE) && String.isNotBlank(acc.Customer_Group__c)) {
                accountsToUpdate.add(BillingAccountManageEnterpriseFlagUtils.updateCustomerGroup(acc, true));
            }
        }
        if (!accountsToUpdate.isEmpty()) {
            dml.add(accountsToUpdate, DmlConsolidator.Operation.FOR_UPDATE);
        }
    }

    private List<Id> updateBillingAccountIds(Account acc, List<Id> billingAccountIds) {
        if (oldAccountsMap == null && acc.Ultimate_Parent_Org__c != null) {
            billingAccountIds.add(acc.Id);
        } else if (oldAccountsMap != null && TriggerUtility.isFieldValueChanged(acc, oldAccountsMap.get(acc.Id), BillingAccountManageEnterpriseFlagUtils.FIELD_API_NAME_ULTIMATE_PARENT)) {
            billingAccountIds.add(acc.Id);
        }
        return billingAccountIds;
    }

    private List<Id> updateBusinessAccountIds(Account acc, List<Id> businessAccountIds) {
        if (acc.CI_Updated_DateTime__c == null &&
            TriggerUtility.isFieldValueChanged(acc, oldAccountsMap.get(acc.Id), BillingAccountManageEnterpriseFlagUtils.FIELD_API_NAME_FULL_TIME_EMPLOYEES)) {

            businessAccountIds.add(acc.Id);
        } else if (acc.CI_Updated_DateTime__c != null && TriggerUtility.isFieldValueChanged(acc, oldAccountsMap.get(acc.Id), BillingAccountManageEnterpriseFlagUtils.FIELD_API_NAME_CI_COMPANY)) {
            businessAccountIds.add(acc.Id);
        }
        return businessAccountIds;
    }
}