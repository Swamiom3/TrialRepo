/************************************************************************************************************************************
    Author         : Mayuresh Ghodke
    Description    : This class will contain the business logic of ContactTrigger
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL                                ISSUE
    1              27 Jun, 2016    Mayuresh Ghodke    Initial Developement                  ST-420
    2              08 Apr, 2021    Tomasz Sadowski    Migration to new trigger framework    ST-8042
    3              13 Jan, 2022    Pawel Biszczak     Refactor                              ST-9384
**************************************************************************************************************************************/
public class ContactTriggerHandler extends SObjectTriggerHandler {
    @TestVisible
    private List<Contact> newContacts;
    @TestVisible
    private List<Contact> oldContacts;
    @TestVisible
    private Map<Id, Contact> newContactsMap;
    @TestVisible
    private Map<Id, Contact> oldContactsMap;
    @TestVisible
    private static final String DUPLICATE_EMAIL = 'A Contact with this email address already exists.';
    @TestVisible
    private static final String DUPLICATE_NEW_EMAIL = 'Another new contact has the same email address.';
    private static final String BATCH_FROM_CONTACT_TRIGGER = 'FROM_CONTACT_TRIGGER';

    public ContactTriggerHandler() {
        this(
            (List<Contact>) Trigger.new,
            (List<Contact>) Trigger.old,
            (Map<Id, Contact>) Trigger.newMap,
            (Map<Id, Contact>) Trigger.oldMap
        );
    }

    @TestVisible
    private ContactTriggerHandler(List<Contact> newContacts, List<Contact> oldContacts,
                                  Map<Id, Contact> newContactsMap, Map<Id, Contact> oldContactsMap) {
        this.newContacts = newContacts;
        this.oldContacts = oldContacts;
        this.newContactsMap = newContactsMap;
        this.oldContactsMap = oldContactsMap;
    }

    public override void beforeInsert() {
        generateUUID();
        updateActiveReferrerOnContact();
        checkForDuplicateEmail();
        updateCustomCrmUser();
    }
    
    public override void beforeUpdate() {
        checkForDuplicateEmail();
        updateActiveReferrerOnContact();
        //validateMergeLeadSourceAsId();

    }

    public override void afterInsert() {
       convertMatchingLead();
    }

    
    public override void afterUpdate() {
        restartJourney();
    }
    

    @TestVisible
    private void checkForDuplicateEmail() {
        Map<String, Contact> emailToContact = new Map<String, Contact>();
        for (Contact contact : newContacts) {
            Contact oldContact = oldContactsMap?.get(contact.Id);
            if (String.isNotBlank(contact.Email)
                && (context == TriggerContext.BEFORE_INSERT || (oldContact != null
                && Settings.isChanged(contact.Email, oldContact.Email)))) {
                if (!FeatureManagement.checkPermission('Validation_Bypass_User_Integration')
                    && emailToContact.containsKey(contact.Email.toLowerCase())) {
                    contact.Email.addError(DUPLICATE_NEW_EMAIL);
                } else {
                    emailToContact.put(contact.Email.toLowerCase(), contact);
                }
            }
        }
        if (!FeatureManagement.checkPermission('Validation_Bypass_User_Integration')
            && !emailToContact.isEmpty()) {
            for (Contact contact : [SELECT Email
                                    FROM Contact
                                    WHERE Email IN : emailToContact.keySet()]) {
                Contact newContact = emailToContact.get(contact.Email.toLowerCase());
                newContact.Email.addError(DUPLICATE_EMAIL);
            } 
        }
    }
    
    
    @TestVisible
    private void convertMatchingLead() {
        Set<String> uniqueEmails = new Set<String>();
        if (context == TriggerContext.AFTER_INSERT) {
            for (Contact contact : newContacts) {
                if (contact.Convert_Lead__c && String.isNotBlank(contact.Email)) {
                    uniqueEmails.add(contact.Email);
                }
            }
        } else if (context == TriggerContext.AFTER_UPDATE) {
            for (Contact contact : newContacts) {
                Contact oldContact = oldContactsMap?.get(contact.Id);
                if (String.isNotBlank(contact.Email)
                    && TriggerUtility.isFieldValueChanged(contact, oldContact, 'Email')) {
                    uniqueEmails.add(contact.Email);
                }
                if (contact.Convert_Lead__c
                    && TriggerUtility.isFieldValueChanged(contact, oldContact, 'Convert_Lead__c')) {
                    uniqueEmails.add(contact.Email);
                }
            }
        }
        if (uniqueEmails.isEmpty()) {
            return;
        }
        Id holdBackQueueId = (Id)LeadConverterHelper.getHoldBackQueueId();
        List<Lead> leadsToConvert = [SELECT Id, Email, Campaign_Id__c
                                     FROM Lead
                                     WHERE Email IN :uniqueEmails AND
                                           OwnerId <> :holdBackQueueId AND
                                           IsConverted = FALSE];
        if (!leadsToConvert.isEmpty()) {
            if ((Test.isRunningTest() && leadsToConvert.size() <= 10)
                || System.isBatch()
                || (String.isNotBlank(System.Label.Lead_Converter_Threshold)
                    && leadsToConvert.size() <= Integer.valueOf(System.Label.Lead_Converter_Threshold)
                    && !Test.isRunningTest())) {
                LeadConverterHelper.manageJourneyForLead(leadsToConvert,false);
            } else if (System.isQueueable()) {
                convertMatchingLeadInFuture(JSON.serialize(leadsToConvert));
            } else {
                System.enqueueJob(new LeadConversionAsyncQueueable(leadsToConvert, BATCH_FROM_CONTACT_TRIGGER));
            }
        }
    }

    @future
    public static void convertMatchingLeadInFuture(String strLeads) {
        List<Lead> leadsToConvert = (List<Lead>)JSON.deserialize(strLeads, List<Lead>.class);
        LeadConverterHelper.manageJourneyForLead(leadsToConvert,false);
    }




    @TestVisible
    private void updateCustomCrmUser() {
        Set<String> uniqueEmails = new Set<String>();
        Set<String> allowedDomains = new Set<String>();
        Map<String, Id> emailsToIdsMap = new Map<String, Id>();
        UserRoleUpdate userRoleUpdateFromSettings = new UserRoleUpdate();
        Sales_Console_Setting__mdt userRoleUpdateSettingRecord = SalesConsoleSettings.get('UserRoleUpdate');
        if (userRoleUpdateSettingRecord != null) {
            userRoleUpdateFromSettings = (UserRoleUpdate)JSON.deserialize(userRoleUpdateSettingRecord.Data__c,
                                                                          UserRoleUpdate.class);
            allowedDomains.addAll(userRoleUpdateFromSettings.allowedDomains);
        }
        if (allowedDomains.isEmpty()) {
            return;
        }
        for (Contact contact : newContacts) {
            if (String.isNotBlank(contact.Email)) {
                if (allowedDomains.contains(contact.Email.split('@')[1])) {
                    uniqueEmails.add(contact.Email);
                }
            }
        }
        if (uniqueEmails.isEmpty()) {
            return;
        }
        for (User user : UserUtility.getAllUsers()) {
            if (uniqueEmails.contains(user.Email)) {
                emailsToIdsMap.put(user.Email, user.Id);
            }
        }
        for (Contact contact : newContacts) {
            if (String.isNotBlank(contact.Email) && emailsToIdsMap.containsKey(contact.Email)) {
                contact.Custom_CRM_User__c = emailsToIdsMap.get(contact.Email);
            }
        }
    }

    public class UserRoleUpdate {
        List<String> allowedDomains {get; set;}
    }


    @TestVisible
    private void generateUUID() {
        for (Contact currentContact : newContacts) {
            if (String.isBlank(currentContact.UUID__c)) {
                currentContact.UUID__c = UUIDHandler.generateVersion4();
            }
        }
    }

    @TestVisible
    private void updateActiveReferrerOnContact() {
        Set<String> contactsEmails = new Set<String>();
        Map<String, Id> activeReferenceMap = new Map<String, Id>();
        for (Contact contact : newContacts) {
            if (String.isNotBlank(contact.Email)) {
                contactsEmails.add(contact.Email.toLowerCase());
            }
        }
        if (!contactsEmails.isEmpty()) {
            activeReferenceMap = ReferenceHandler.getActiveReference(contactsEmails);
        }
        if (!activeReferenceMap.isEmpty()) {
            for (Contact contact : (newContacts)) {
                if (String.isNotBlank(contact.Email) && activeReferenceMap.containsKey(contact.Email)
                    && activeReferenceMap.get(contact.Email.toLowerCase()) != contact.Id) {
                    contact.Referrer__c = activeReferenceMap.get(contact.Email.toLowerCase());
                }
            }
        }
    }

    @TestVisible
    private void restartJourney(Set<Id> contactIds) {
        if (contactIds.isEmpty()) {
            return;
        }
        new JourneyRestartService().setDmlConsolidator(dml).restartJourneyForContact(contactIds);
    }
    
    @future
    public static void restartJourneyInFuture(Set<Id> contactIds) {
        new JourneyRestartService().restartJourneyForContact(contactIds);
    }

    @TestVisible
    private void restartJourney() {
        Set<Id> contactIds = new Set<Id>();
        if (!oldContactsMap.isEmpty()) {
            for (Contact contactRec : newContacts) {
                if (contactRec.Restart_Journey__c == true && oldContactsMap.get(contactRec.Id).Restart_Journey__c != contactRec.Restart_Journey__c) {
                    contactIds.add(contactRec.Id);
                } 
            }
            if (!contactIds.isEmpty()) {
                if ((Test.isRunningTest() && contactIds.size() <= 10) || (System.isBatch()) || (String.isNotBlank(System.Label.LeadAsync_Restart_Journey_Threshold) && contactIds.size() <= Integer.valueof(System.Label.LeadAsync_Restart_Journey_Threshold) && !Test.isRunningTest())) {
                    restartJourney(contactIds);
                } else if (System.isQueueable()) {
                    restartJourneyInFuture(contactIds);
                } else {
                    AsyncsExecutor asyncsExecutor = new AsyncsExecutor(
                                                            RestartJourneyQueueable.class,
                                                            'contacts',
                                                            new Map<String, Object>{'contactIds'=> contactIds,
                                                                                    'source'=> BATCH_FROM_CONTACT_TRIGGER});
                    asyncsExecutor.execute();
                }
            }
        }
        
    }

    /*@TestVisible
    private void validateMergeLeadSourceAsId(){
        if(!newContacts.isEmpty()){
            for(Contact contactRec : newContacts){
                    if(contactRec.LeadSource =='Id' 
                        && contactRec.LeadSource_Sub_Type__c != oldContactsMap?.get(contactRec.Id).LeadSource_Sub_Type__c
                        && contactRec.Lead_Source_Detail__c != oldContactsMap?.get(contactRec.Id).Lead_Source_Detail__c
                    ){
                        contactRec.LeadSource_Sub_Type__c = oldContactsMap?.get(contactRec.Id).LeadSource_Sub_Type__c;
                        contactRec.Lead_Source_Detail__c = oldContactsMap?.get(contactRec.Id).Lead_Source_Detail__c;
                    }
                }       
            }
    }   */
}