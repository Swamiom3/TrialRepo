/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class is selector implementation of particular SObject (Lead)
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR            DETAIL
    1          9 Apr, 2021    Pawel Biszczak    Initial Deployment
**************************************************************************************************************************************/
public with sharing class LeadSelector extends SObjectSelector {
    private final String LEAD_FIELDS_METADATA = 'Lead_Fields_Metadata';
    private static final List<String> DEFAULT_FIELDS = new List<String>{ 'Id',
                                                                         'City',
                                                                         'Email',
                                                                         'OwnerId',
                                                                         'State' };

    public LeadSelector() {
        super(Lead.getSObjectType());
    }

    public override Set<String> getDefaultFields(){
        MetadataSetting__mdt metadataRecord = Settings.getMetadataSettingByDevName(LEAD_FIELDS_METADATA);
        if (String.isNotBlank(metadataRecord?.Data__c)) {
            return (Set<String>) (JSON.deserialize(metadataRecord.Data__c, Set<String>.class));
        } else {
            return new Set<String> (DEFAULT_FIELDS);
        }
    }

    public List<Lead> getLeadsById(List<Id> ids){
        if (ids == null || ids.isEmpty()) {
            return null;
        }

        List<String> fields = new List<String>(DEFAULT_FIELDS);
        return (List<Lead>) getSObjectByIds(fields, ids);
    }

    public List<Lead> getLeadsByIdAndNotNullEmail(List<Id> ids){
        if (ids == null || ids.isEmpty()) {
            return null;
        }

        List<String> fields = new List<String>(DEFAULT_FIELDS);
        List<Object> bindings = new List<Object>{ ids };
        String whereClause = 'Id IN :ids AND Email <> NULL';
        return (List<Lead>) getSObjects(fields, whereClause, bindings);
    }
}