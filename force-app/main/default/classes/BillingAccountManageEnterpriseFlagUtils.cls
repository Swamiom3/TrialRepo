public with sharing class BillingAccountManageEnterpriseFlagUtils {
    public static final String FIELD_API_NAME_CI_COMPANY = 'CI_Company__c';
    public static final String FIELD_API_NAME_COMPANY_SIZE = 'Size__c';
    public static final String FIELD_API_NAME_ESTIMATED_COUNT = 'Override_Estimated_Headcount__c';
    public static final String FIELD_API_NAME_FULL_TIME_EMPLOYEES = 'Number_of_Full_Time_Employees__c';
    public static final String FIELD_API_NAME_ULTIMATE_PARENT = 'Ultimate_Parent_Org__c';
    public static final String MULTIPICKLIST_SEPARATOR = ';';
    public static final String RECORD_TYPE_BILLING = 'Billing Account';
    public static final String RECORD_TYPE_BUSINESS = 'Business Account';
    public static final String VALUE_ENTERPRISE = 'Enterprise';
    public static final Decimal MIN_FTE_ENTERPRISE = 500;

    public static Account updateCustomerGroup(Account accountRecord, Boolean shallRemoveEnterprise) {
        Set<String> customerGroups = new Set<String>();
        if (String.isNotBlank(accountRecord.Customer_Group__c)) {
            customerGroups = new Set<String> (accountRecord.Customer_Group__c.split(MULTIPICKLIST_SEPARATOR));
        }
        if (shallRemoveEnterprise) {
            customerGroups.remove(VALUE_ENTERPRISE);
        } else {
            customerGroups.add(VALUE_ENTERPRISE);
        }
        accountRecord.Customer_Group__c = String.join(new List<String> (customerGroups), MULTIPICKLIST_SEPARATOR);
        return accountRecord;
    }
}