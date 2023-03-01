/*************************************************************************************************************************************
    Author      :   Tomasz Sadowski
    Description :   This class is selector implementation of particular SObject (User_Attribute__c)
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR             DETAIL
    1          2 Dec, 2021    Tomasz Sadowski    Initial Deployment
**************************************************************************************************************************************/
public with sharing class UserAttributeSelector extends SObjectSelector {
    private final String USERATTRIBUTE_FIELDS_METADATA = 'UserAttribute_Fields_Metadata';
    private static final List<String> DEFAULT_FIELDS = new List<String>{ 'Id', 
                                                                         'User__c',
                                                                         'As_of_Date__c',
                                                                         'End_Date__c',
                                                                         'RecordTypeId',
                                                                         'Gap__c',
                                                                         'Sales_Function__c',
                                                                         'Sales_Team__c',
                                                                         'Building__c',
                                                                         'Building_Team_Role__c'
                                                                          };

    public UserAttributeSelector() {
        super(User_Attribute__c.getSObjectType());
    }

    public override Set<String> getDefaultFields() {
        MetadataSetting__mdt metadataRecord = Settings.getMetadataSettingByDevName(USERATTRIBUTE_FIELDS_METADATA);
        if (String.isNotBlank(metadataRecord?.Data__c)) {
            return (Set<String>) (JSON.deserialize(metadataRecord.Data__c, Set<String>.class));
        } else {
            return new Set<String> (DEFAULT_FIELDS);
        }
    }

    public List<User_Attribute__c> getUserAttributesById(List<Id> ids) {
        if (ids == null || ids.isEmpty()) {
            return null;
        }

        List<String> fields = new List<String>(DEFAULT_FIELDS);
        return (List<User_Attribute__c>) getSObjectByIds(fields, ids);
    }

    public List<User_Attribute__c> getUserAttributesByBuildingId(Set<Id> buildingIds) {
        if (buildingIds == null || buildingIds.isEmpty()) {
            return null;
        }

        List<String> fields = new List<String>(DEFAULT_FIELDS);
        String whereClause = 'Building__c IN :buildingIds';
        List<Object> bindings = new List<Object>{buildingIds};
        return (List<User_Attribute__c>) getSObjects(fields, whereClause, bindings);
    }
}