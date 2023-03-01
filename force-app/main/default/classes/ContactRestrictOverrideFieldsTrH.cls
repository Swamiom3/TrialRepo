/************************************************************************************************************************************
    Author         : Pawel Biszczak
    Description    : This class allows to restrict some fields on Contact to be overridden
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1              19 Jan, 2022    Pawel Biszczak     Initial Deployment
**************************************************************************************************************************************/
public with sharing class ContactRestrictOverrideFieldsTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Contact> newContacts;
    @TestVisible
    private Map<Id, Contact> oldContactsMap;
    @TestVisible
    private List<String> restrictedFields;

    public ContactRestrictOverrideFieldsTrH() {
        this(
                (List<Contact>) Trigger.new,
                (Map<Id, Contact>) Trigger.oldMap
        );
    }

    @TestVisible
    private ContactRestrictOverrideFieldsTrH(List<Contact> newContacts, Map<Id, Contact> oldContactsMap) {
        this.newContacts = newContacts;
        this.oldContactsMap = oldContactsMap;
        getRestrictedFieldsFromMetadata();
    }

    public override void beforeUpdate() {
        restrictOverrideFields();
        restrictLocationChangeFoContactWithinIdRails();
        validateMergeLeadSourceAsId();
    }

    private void getRestrictedFieldsFromMetadata() {
        MetadataSetting__mdt restrictedFieldsMetadataRecord =
                MetadataSetting__mdt.getInstance('ContactFieldsRestrictedToOverrides');
        if(restrictedFieldsMetadataRecord == null) {
            throw new ContactRestrictOverrideFieldsException('\'ContactFieldsRestrictedToOverrides\'' +
                                                             ' MetadataSetting__mdt record is missing');
        }
        restrictedFields = (List<String>) JSON.deserialize(restrictedFieldsMetadataRecord.Data__c, List<String>.class);
    }

    @TestVisible
    private void restrictOverrideFields() {
        for(String fieldAPIName : restrictedFields) {
            for (Contact contact : newContacts) {
                Contact oldContact = oldContactsMap?.get(contact.Id);
                if (String.isNotBlank(String.valueOf(oldContact.get(fieldAPIName)))
                    && TriggerUtility.isFieldValueChanged(contact, oldContact, fieldAPIName)) {
                    contact.put(fieldAPIName, oldContact.get(fieldAPIName));
                }
            }
        }
    }

    @TestVisible
    private void restrictLocationChangeFoContactWithinIdRails() {
        for (Contact contact : newContacts) {
            Contact oldContact = oldContactsMap?.get(contact.Id);
            if ((contact.exists_in_id__c && !TriggerUtility.isFieldValueChanged(contact, oldContact, 'exists_in_id__c')) 
                && TriggerUtility.isFieldValueChanged(contact, oldContact, 'Location__c')) {
                    contact.Location__c = oldContact.Location__c;
            }
        }
    }
    
    @TestVisible
    private void validateMergeLeadSourceAsId(){
        for(Contact contact : newContacts){
            Contact oldContact = oldContactsMap?.get(contact.Id);
            if(contact.LeadSource =='Id' 
               && TriggerUtility.isFieldsValueChanged(contact, oldContact, new Set <String>{'LeadSource_Sub_Type__c','Lead_Source_Detail__c'})){
                  contact.LeadSource_Sub_Type__c = oldContact.LeadSource_Sub_Type__c;
                  contact.Lead_Source_Detail__c = oldContact.Lead_Source_Detail__c;
              }
        }       
    }


    public class ContactRestrictOverrideFieldsException extends Exception{}
}