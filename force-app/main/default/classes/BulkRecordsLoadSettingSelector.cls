/************************************************************************************************************************************
    Author      :   Liubomyr Mishchykha
    Description :   Selector for Bulk Records Load Setting custom metadata type
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           Aug 26, 2020        Liubomyr Mishchykha     Initial version
**************************************************************************************************************************************/
public inherited sharing class BulkRecordsLoadSettingSelector extends SObjectSelector {

    public BulkRecordsLoadSettingSelector() {
        super(Bulk_Records_Load_Setting__mdt.getSObjectType());
    }

    protected override Set<String> getDefaultFields() {
        return new Set<String>{ 'Id' };
    }

    public List<Bulk_Records_Load_Setting__mdt> getBulkRecordsLoaSettiingsBySObjectType(String sObjectType) {
        if (String.isBlank(sObjectType)) {
            return null;
        }
        List<String> fields = new List<String>{ 'Field__c' };
        List<Object> bindings = new List<Object>{ sObjectType };
        String whereClause = 'Active__c = true AND SObject_Type__c = :sObjectType';
        String orderByClause = 'Field__c ASC';
        return (List<Bulk_Records_Load_Setting__mdt>) getSObjects(fields, whereClause, bindings, orderByClause);
    }
}