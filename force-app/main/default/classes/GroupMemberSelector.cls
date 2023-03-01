/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class is selector implementation of particular SObject (GroupMember)
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR            DETAIL
    1          9 Apr, 2021    Pawel Biszczak    Initial Deployment
**************************************************************************************************************************************/
public with sharing class GroupMemberSelector extends SObjectSelector {
    private final String GROUP_MEMBER_FIELDS_METADATA = 'GroupMember_Fields_Metadata';
    private static final List<String> DEFAULT_FIELDS = new List<String>{ 'Id',
                                                                         'Group.Name',
                                                                         'GroupId',
                                                                         'UserOrGroupId' };

    public GroupMemberSelector() {
        super(GroupMember.getSObjectType());
    }

    public override Set<String> getDefaultFields(){
        MetadataSetting__mdt metadataRecord = Settings.getMetadataSettingByDevName(GROUP_MEMBER_FIELDS_METADATA);
        if (String.isNotBlank(metadataRecord?.Data__c)) {
            return (Set<String>) (JSON.deserialize(metadataRecord.Data__c, Set<String>.class));
        } else {
            return new Set<String> (DEFAULT_FIELDS);
        }
    }

    public List<GroupMember> getGroupMembersByGroupIds(List<Id> groupIds){
        if (groupIds == null || groupIds.isEmpty()) {
            return null;
        }

        List<String> fields = new List<String>(DEFAULT_FIELDS);
        return (List<GroupMember>) getSObjectByField(fields, 'GroupId', groupIds, false);
    }
}