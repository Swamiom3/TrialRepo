/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class is selector implementation of particular SObject (Referral__c)
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR            DETAIL
    1          23 Jun, 2021    Pawel Biszczak    Initial Deployment
    2          04 March 2022   Krishna Somwanshi Implement Selector
**************************************************************************************************************************************/
public with sharing class ReferralSelector extends SObjectSelector {
    private final String REFERRAL_FIELDS_METADATA = 'Referral_Fields_Metadata';
    private static final List<String> DEFAULT_FIELDS = new List<String>{ 'Id',
                                                                         'IsActive__c',
                                                                         'Lead__c',
                                                                         'Opportunity__c',
                                                                         'Referrer__c'};

    public ReferralSelector() {
        super(Referral__c.getSObjectType());
    }

    public override Set<String> getDefaultFields(){
        MetadataSetting__mdt metadataRecord = Settings.getMetadataSettingByDevName(REFERRAL_FIELDS_METADATA);
        if (String.isNotBlank(metadataRecord?.Data__c)) {
            return (Set<String>) (JSON.deserialize(metadataRecord.Data__c, Set<String>.class));
        } else {
            return new Set<String> (DEFAULT_FIELDS);
        }
    }

    public List<Referral__c> getReferralsByLeadsIds(List<Id> leadsIds){
        if (leadsIds == null || leadsIds.isEmpty()) {
            return null;
        }
        List<String> fields = new List<String>(DEFAULT_FIELDS);
        return (List<Referral__c>) getSObjectByField(fields, 'Lead__c', leadsIds, false);
    }
    
    public List<Referral__c> getReferralsByReferralEmail(Set<String> referralEmails){
        if (referralEmails.isEmpty()) {
            return null;
        }
        List<String> fields = new List<String>{'Id',
                                               'Name',
                                               'Referral_Email__c',
                                               'CreatedDate'
                                              };
        List<Object> bindings = new List<Object>{referralEmails};
        String whereClause = 'Referral_Email__c IN :referralEmails AND IsActive__c = true';
        return (List<Referral__c>) getSObjects(fields, whereClause, bindings);
    }
    
    public Referral__c getReferralByRecordId(Id recordId){
        if (recordId == null) {
            return new Referral__c();
        }
        List<String> fields = new List<String>{'Id',
                                               'Expires_On__c', 
                                               'Referred_Date__c',
                                               'Referrer__c',
                                               'IsActive__c'
                                              };
        List<Object> recordIds = new List<Object>{recordId};                                                  
        String whereClause = 'Id =: recordId AND IsActive__c = true Limit 1';
        List<Referral__c> referrals = (List<Referral__c>)getSObjects(fields, whereClause, recordIds);
        Referral__c referral = new Referral__c();
        for(Referral__c ref : referrals){
            referral.Id = ref.Id;
            referral.Expires_On__c = ref.Expires_On__c;
            referral.Referred_Date__c = ref.Referred_Date__c;
            referral.Referrer__c = ref.Referrer__c;
            referral.IsActive__c = ref.IsActive__c;
        }
        return referral;
     
    }
    
    public List<Referral__c> getReferralsByReferralEmails(Set<String> referralEmails){
        if (referralEmails.isEmpty()) {
            return new List<Referral__c>();
        }

        List<String> fields = new List<String>{'Id',
                                               'Name',
                                               'Referral_Email__c',
                                               'Referrer_Email__c',
                                               'Referrer__c',
                                               'CreatedDate'
                                              };
        List<Object> referrals = new List<Object>{referralEmails};
        String whereClause = 'Referral_Email__c IN :referralEmails AND IsActive__c = true ORDER BY CreatedDate DESC';
        return (List<Referral__c>) getSObjects(fields, whereClause, referrals);
    }
    
    public List<Referral__c> getReferralsByReferralEmail(String referralEmails){
        if (referralEmails == null) {
            return new List<Referral__c>();
        }

        List<String> fields = new List<String>{'Id',
                                               'Name',
                                               'Referral_Email__c',
                                               'Referrer_Email__c',
                                               'Referrer__c',
                                               'CreatedDate'
                                              };
        List<Object> referrals = new List<Object>{referralEmails};
        String whereClause = 'Referral_Email__c = :referralEmails AND IsActive__c = true';  
        return (List<Referral__c>) getSObjects(fields, whereClause, referrals);
    }
    
    public List<Referral__c> getReferralsByLeadId(Map<Id, Id> convertedLeadIdToContactId){
        if (convertedLeadIdToContactId.isEmpty()) {
            return new List<Referral__c>();
        }
        List<String> fields = new List<String>{'Id',
                                               'Name',
                                               'Lead__c', 
                                               'Opportunity__c', 
                                               'Referrer__c'
                                              };
        Set<Id> leadIds = convertedLeadIdToContactId.keyset();
        String whereClause = 'Lead__c IN: leadIds';
        return (List<Referral__c>) getSObjects(fields, whereClause, new List<Object>{leadIds});
    }
}