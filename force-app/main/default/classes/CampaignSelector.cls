/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class is selector implementation of particular SObject (Campaign)
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR            DETAIL
    1          4 Feb, 2022    Pawel Biszczak    Initial Deployment
**************************************************************************************************************************************/
public with sharing class CampaignSelector extends SObjectSelector {
    private final String CAMPAIGN_FIELDS_METADATA = 'Campaign_Fields_Metadata';
    private static final List<String> DEFAULT_FIELDS = new List<String>{ 'Id',
                                                                         'City__c',
                                                                         'Name',
                                                                         'Region__c',
                                                                         'StartDate',
                                                                         'State__c',
                                                                         'Status',
                                                                         'Type' };

    public CampaignSelector() {
        super(Campaign.getSObjectType());
    }

    public override Set<String> getDefaultFields(){
        MetadataSetting__mdt metadataRecord = Settings.getMetadataSettingByDevName(CAMPAIGN_FIELDS_METADATA);
        if (String.isNotBlank(metadataRecord?.Data__c)) {
            return (Set<String>) (JSON.deserialize(metadataRecord.Data__c, Set<String>.class));
        } else {
            return new Set<String> (DEFAULT_FIELDS);
        }
    }

    public List<Campaign> getCampaignsById(List<Id> ids){
        if (ids == null || ids.isEmpty()) {
            return new List<Campaign>();
        }

        List<String> fields = new List<String>(DEFAULT_FIELDS);
        return (List<Campaign>) getSObjectByIds(fields, ids);
    }
}