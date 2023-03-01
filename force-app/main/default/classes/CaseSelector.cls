/*************************************************************************************************************************************
 Author      :   Oleg Krasko
 Description :   This class is selector implementation of particular SObject (Case)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               9/3/2021        Oleg Krasko         Initial Deployment
 2               12/6/2021       Tomasz Sadowski     Migration to OrgC with removal of discontinued fields
 **************************************************************************************************************************************/
public with sharing class CaseSelector extends SObjectSelector {
    private final String CASE_FIELDS_METADATA = 'Case_Fields_Metadata';
    private final Set<String> DEFAULT_FIELDS = new Set<String>{'Id',
                                                               'Priority',
                                                               'Status',
                                                               'Opportunity__c',
                                                               'Origin',
                                                               'Reason',
                                                               'RecordTypeId',
                                                               'Subject',
                                                               'Type'};
    public CaseSelector() {
        super(Case.getSObjectType());
    }

    public override Set<String> getDefaultFields() {
        MetadataSetting__mdt metadataRecord = Settings.getMetadataSettingByDevName(CASE_FIELDS_METADATA);
        if (String.isNotBlank(metadataRecord?.Data__c)) {
            return (Set<String>) (JSON.deserialize(metadataRecord.Data__c, Set<String>.class));
        } else {
            return DEFAULT_FIELDS;
        }
    }

    public List<Case> getCasesById(List<Id> ids) {
        if (ids == null || ids.isEmpty()) {
            return null;
        }

        List<String> fields = new List<String>(DEFAULT_FIELDS);
        return (List<Case>) getSObjectByIds(fields, ids);
    }

    public List<Case> getCasesByOpportunityId(Set<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return null;
        }

        List<String> fields = new List<String>(DEFAULT_FIELDS);
        String whereClause = 'Opportunity__c IN :opportunityIds';
        List<Object> bindings = new List<Object>{opportunityIds};
        return (List<Case>) getSObjects(fields, whereClause, bindings);
    }
}