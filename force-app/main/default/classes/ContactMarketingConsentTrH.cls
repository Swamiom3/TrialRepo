/************************************************************************************************************************************
    Author     : Pragalbha Mahajan
    Description: This class contains buisness logic of Marketing Consent Update on Contact and Contact object on before insert.
----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE                AUTHOR                  DETAIL                                  ISSUE
    1              21 July 2019        Pragalbha Mahajan       Initial Developement                    ST-4351
    2              25 Oct 2019         Krishana Tupe           [ST-5115, ST-5116, ST-5117]
    3              12 April, 2021      Tomasz Sadowski         Migration to new trigger framework      ST-8042
**************************************************************************************************************************************/
public class ContactMarketingConsentTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Contact> newContacts;
    @TestVisible
    private Map<Id, Contact> oldContactsMap;
    @TestVisible
    private final Id BIG_MARKER_INTEGRATION_USER_ID = Settings.getValidationRuleRestrictionSalesforceId('BigMarker_Integration_User');
    @TestVisible
    private final String WEWORK_CN = 'WeWork.cn';
    @TestVisible
    private Set<String> OPT_OUT_DOMAINS = getOptOutsDomains();

    public ContactMarketingConsentTrH() {
        this(
            (List<Contact>) Trigger.new,
            (Map<Id, Contact>) Trigger.oldMap
        );
    }

    @TestVisible
    private ContactMarketingConsentTrH(List<Contact> newContacts, Map<Id, Contact> oldContactsMap) {
        this.newContacts = newContacts;
        this.oldContactsMap = oldContactsMap;
    }

    public override void beforeInsert(){
        MarketingConsentHelper.setMarketingConsent(newContacts);
        for (Contact contact : newContacts) {
            setSMSOptIn(contact);
            updateDncAndDneOnContact(contact, null);
            updateOptOutForPartnerDomainContact(contact);
        }
    }

    public override void beforeUpdate(){
        for (Contact contact : newContacts) {
            updateDncAndDneOnContact(contact, oldContactsMap?.get(contact.Id));
            //always check as email or settings can be updated
            updateOptOutForPartnerDomainContact(contact);
        }
    }

    private void setSMSOptIn(Contact contact) {
        contact.SMS_Opt_In__c = contact.LeadSource == WEWORK_CN && contact.Marketing_Consent__c ? true : false;
    }

    private void updateDncAndDneOnContact(Contact contact, Contact oldContact) {
        if (contact.LastModifiedById == BIG_MARKER_INTEGRATION_USER_ID && !contact.Contact_Broker__c && !contact.Marketing_Consent__c) {
            contact.HasOptedOutOfEmail = true;
        } else if (contact.Contact_Broker__c && (oldContact == null || (oldContact != null && TriggerUtility.isFieldValueChanged(contact, oldContact, 'Contact_Broker__c')))) {
            contact.DoNotCall = true;
            contact.HasOptedOutOfEmail = true;
        }
    }
    @TestVisible
    private void updateOptOutForPartnerDomainContact(Contact con) {
        if(isValidContactLeadSourceForOptOutDomainCheck(con) && isValidContactEmailDomainForOptOutDomainCheck(con)) {
                con.HasOptedOutOfEmail = true;
                con.Marketing_Consent__c = false;
        }
    }

    @TestVisible
    private Set<String> getOptOutsDomains() {
        MetadataSetting__mdt metadataSetting = Settings.getMetadataSettingByDevName('MarketingConsentMetaData'); 
        if(metadataSetting?.Data__c == null ){
            return new Set<String>();
        }
        Map<String, Object> marketingConsentSettings = (Map<String, Object>) JSON.deserializeUntyped(metadataSetting.Data__c);
        Object contactMarketingConsentSetting = marketingConsentSettings.get('Contact');
        Map<String, Object> contactMarketingConsentSettings = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(contactMarketingConsentSetting));

        return contactMarketingConsentSettings != null 
               ? (Set<String>)JSON.deserialize(JSON.serialize(contactMarketingConsentSettings.get('DomainsForOptOut')), Set<String>.class) 
               : new Set<String>();
    }
    @TestVisible
    private String getDomainFromEmail(Contact contact) {
        if(contact?.Email == null) {
            return '';
        }
        return contact.Email.split('@').get(1);
    }

    @TestVisible
    private Boolean isValidContactLeadSourceForOptOutDomainCheck(Contact contact) {
        return (contact.LeadSource == 'Id' || contact.LeadSource == 'ID');
    }

    @TestVisible
    private Boolean isValidContactEmailDomainForOptOutDomainCheck(Contact contact) {
        String contactEmailDomain = getDomainFromEmail(contact);
        for(String domain : OPT_OUT_DOMAINS) {
            if (contactEmailDomain.contains(domain)) {
                return true;
            }
        }
        return false;
    }
}