/*************************************************************************************************************************************
 Author      :   Krishana Tupe
 Description :   This class contains the business logic of Journey, Campaign and Lead conversion.
 --------------------------------------------------------------------------------------------------------------------------------------
    VERSION                 DATE             AUTHOR                          DETAIL
    1                       26 Nov, 2018     Krishana Tupe                   Initial Developement
    2                       19 Mar, 2021     Pawel Biszczak                  Refactor
 **************************************************************************************************************************************/
public without sharing class LeadConverterHelper {
    public static Boolean generateJourney;
    public static Boolean isCreateActivity = true;
    public static Boolean isInsert = true;
    public static Boolean isLeadUpdateFromLeadConverter = false;
    public static Boolean isLeadConverted = false;
    public static Map<Id, Campaign> campaignsByIds;
    public static Map<Id, Id> campaignSettings;
    public static Map<Id, Lead> leadsToDeduplicate;
    public static Map<String, Object> overrideLeadData;
    public static List<Id> leadsToDelete;
    public static Set<Id> leadIds;
    public static Set<Id> gatedWifiCampaignIds = new Set<Id>();
    
    @TestVisible
    static final String ASSIGNMENT_COMPLETE = 'Assignment Complete';
    @TestVisible
    static final String NURTURE_SET_BY_SYSTEM = 'Nurture - Set by System';
    @TestVisible
    static final String MQL_SET_BY_USER =  'MQL - Set by User';
    @TestVisible
    static final String MQL_SET_BY_CAMPAIGN =  'MQL - Set by Campaign';
    // Lead_Assignment_Stage__c on Lead	picklist labels to api names
    static final String STATUS_NEW = '1';
    static final String HOLD_QUEUE = '6';
    static final String ASSIGNMENTS_RUN = '11';
    static final String BYPASS_HOLD_BACK = '1000';

    public static Map<String, Id> manageLead(Lead leadRecord) {
        LeadConverterHelper.generateJourney = true;
        if (String.isBlank(leadRecord?.Email)) {
            return null;
        }
        return manageLead(new List<Lead>{ leadRecord }, null).get(leadRecord.Email);
    }

    public static Map<String, Id> manageLead(RESTAPITourModelsV2.Input tourPayload) {
        LeadConverterHelper.generateJourney = true;
        if (String.isBlank(tourPayload?.email)) {
            return null;
        }
        LeadConverterHelper.isInsert = false;
        tourPayload.email = tourPayload.email.toLowerCase();
        Map<String, Map<String, Id>> convertData = manageLead(new List<Lead>{ new Lead(Email = tourPayload.email) },
                                                              tourPayload);
        return convertData?.get(tourPayload.email);
    }

    public static Map<String, Map<String, Id>> manageLead(List<Lead> leads) {
        return manageJourneyForLead(leads, true);
    }

    public static Map<String, Map<String, Id>> manageJourneyForLead(List<Lead> leads, Boolean generateJourney) {
        if (leads == null || leads.isEmpty()) {
            LeadConverterHelper.generateJourney = true;
            return null;
        }

        LeadConverterHelper.generateJourney = generateJourney != null ? generateJourney : true;
        return manageLead(leads, null);
    }

    public static void markLeadsTasksCompletedOnLeadConversion(List<Lead> leads) {
        if (leads == null || leads?.isEmpty()) {
            return;
        }
        List<Task> tasksToUpdate = new List<Task>();
        for (Lead leadRecord : leads) {
            for (Task taskRecord : leadRecord.Tasks) {
                taskRecord.Status = GlobalConstants.TASK_STATUS_COMPLETED;
                tasksToUpdate.add(taskRecord);
            }
        }
        Database.update(tasksToUpdate, false);
    }

    public static void setLeadGenerateJourney(Lead leadRecord) {
        if (String.isBlank(leadRecord?.Email)) {
            return;
        }
        Boolean generateJourneyAndCreateActivity = ([ SELECT Id
                                                      FROM Contact
                                                      WHERE Email = :leadRecord.Email
                                                    ]).isEmpty();
        LeadConverterHelper.generateJourney = generateJourneyAndCreateActivity;
        LeadConverterHelper.isCreateActivity = generateJourneyAndCreateActivity;
    }

    /************************************************************************************************************************************
        Author         : Prashant Mane.
        Description    : This method used to accept Lead Object to get the TourPayLoad and convert Lead.
        Issue No       : CSI-1105
        Created Date   : 10 Aug 2018
    **************************************************************************************************************************************/
    public static Map<String, Map<String, Id>> convertLeadWithTour(Lead leadRecord) {
        if (String.isBlank(leadRecord?.Email)) {
            return null;
        }
        List<Lead> leads = [SELECT Id,
                                   (SELECT Id, Status, WhoId, WhatId
                                   FROM Tasks
                                   WHERE Status <> :GlobalConstants.TASK_STATUS_COMPLETED)
                            FROM Lead
                            WHERE Id = :leadRecord.Id
        ];
        RESTAPITourModelsV2.Input tourPayload = new RESTAPITourModelsV2.Input();
        tourPayload.email = leadRecord.Email.toLowerCase();
        LeadConverterHelper.isCreateActivity = false;
        LeadConverterHelper.isInsert = false;
        Map<String, Map<String, Id>> convertedLeads = LeadConverterHelper.manageLead(new List<Lead>{ leadRecord },
                                                                                     tourPayload);
        LeadConverterHelper.markLeadsTasksCompletedOnLeadConversion(leads);
        return convertedLeads;
    }

    /************************************************************************************************************************************
           Author              :   Krishana Tupe
           Description         :   This method is used to get the new Lead map by email and Campaign
           Created Date        :   28 Nov 2018
           Last Modified By    :   Krishana Tupe
    *************************************************************************************************************************************/
    public static void getLeadsByEmailsAndLeadsByCampaigns(List<Lead> leads, Map<String, List<Lead>> leadsByEmails, Map<Id, Map<Id, Lead>> leadsByIdsGroupedByCampaigns) {
        for (Lead leadRecord : leads) {
            if (String.isNotBlank(leadRecord.Email)) {
                String lowercaseEmail = leadRecord.Email.toLowerCase();
                if (!leadsByEmails.containsKey(lowercaseEmail)) {
                    leadsByEmails.put(lowercaseEmail, new List<Lead>());
                }
                leadsByEmails.get(lowercaseEmail).add(leadRecord);
            }
            if (String.isNotBlank(leadRecord.Campaign_Id__c)) {
                if (!leadsByIdsGroupedByCampaigns.containsKey(leadRecord.Campaign_Id__c)) {
                    leadsByIdsGroupedByCampaigns.put(leadRecord.Campaign_Id__c, new Map<Id, Lead>());
                }
                leadsByIdsGroupedByCampaigns.get(leadRecord.Campaign_Id__c).put(leadRecord.Id, leadRecord);
            }
        }
    }

    /************************************************************************************************************************************
           Author              :   Krishana Tupe
           Description         :   This method is used to set the exiting contact owner when contact owner is inactive
           Created Date        :   28 Nov 2018
           Last Modified By    :   Krishana Tupe
    *************************************************************************************************************************************/
    public static void setContactOwner(Contact contactRecord, Lead newLeadRecord, String campaignOROwnerId) {
        if (contactRecord.OwnerId == null || (UserUtility.getUserActive(contactRecord.OwnerId) && contactRecord.OwnerId != ApiUsersUtils.apiUserId)) {
            return;
        }

        if (newLeadRecord?.OwnerId != null && newLeadRecord.Campaign_Id__c == null && (UserUtility.getUserActive(newLeadRecord.OwnerId) && !OrganizationHelper.isGroup(newLeadRecord.OwnerId))) {
            contactRecord.OwnerId = newLeadRecord.OwnerId;
        } else if (newLeadRecord?.Campaign_Id__c == null) {
            contactRecord.OwnerId = UserInfo.getUserId();
        }

        if (OrganizationHelper.isUser(campaignOROwnerId)
            && contactRecord.OwnerId != null 
            && (!UserUtility.getUserActive(contactRecord.OwnerId) || contactRecord.OwnerId == ApiUsersUtils.apiUserId) 
            && UserUtility.getUserActive(campaignOROwnerId) 
            && Id.valueOf(campaignOROwnerId) != ApiUsersUtils.apiUserId) {
                contactRecord.OwnerId = campaignOROwnerId;
        }
    }

    /************************************************************************************************************************************
           Author              :   Krishana Tupe
           Description         :   This method is used to map the new Lead field onto Exiting Lead
           Created Date        :   28 Nov 2018
           Last Modified By    :   Krishana Tupe
    *************************************************************************************************************************************/
    public static void mapNewLeadToExistingRecord(SObject existingRecord, Lead newLeadRecord) {
        if(newLeadRecord == null) {
            return;
        }
        Boolean isContact = OrganizationHelper.isContact(existingRecord);
        if (newLeadRecord.Locations_Interested__c != null) {
            Set<String> locationsInterested = new Set<String>();
            String locationsFieldName = isContact ? 'Location_Interested__c' : 'Locations_Interested__c';
            if (OrganizationHelper.isFieldNotNull(existingRecord, locationsFieldName)) { // existingRecord:-> existing lead / contact
                locationsInterested.addAll(OrganizationHelper.getStringValue(existingRecord, locationsFieldName).split(';'));
            }
            locationsInterested.addAll(newLeadRecord.Locations_Interested__c.split(';'));
            existingRecord.put(locationsFieldName, String.join(new List<String>(locationsInterested), ';'));
        }
        
        //Added by Vaishnavi for ST-6258
        String industryFieldName = isContact ? 'Industry__c' : 'Industry';
        if(OrganizationHelper.isFieldBlank(existingRecord, industryFieldName)) {
            existingRecord.put(industryFieldName, newLeadRecord.Industry);
        }

        // ST-3699
        if (newLeadRecord.Description != null) {
            existingRecord.put('Description', newLeadRecord.Description);
        }
        
        if (newLeadRecord.LoyaltyProgram__c != null) {
            existingRecord.put('LoyaltyProgram__c', newLeadRecord.LoyaltyProgram__c);
            existingRecord.put('LoyaltyNumber__c', newLeadRecord.LoyaltyNumber__c);
        }

        if(isContact && OrganizationHelper.isFieldBlank(existingRecord, 'Company__c')) {
            existingRecord.put('Company__c', newLeadRecord.Company);
        }

        updateAddressInformation(existingRecord, newLeadRecord);
        setMarketingInfo(existingRecord, newLeadRecord);
        if(isContact && Boolean.valueOf(existingRecord.get('exists_in_id__c'))) {
            return;
        }
        updateExistingRecordWithNewInformation(existingRecord, newLeadRecord);
    }

    /************************************************************************************************************************************
        Author              :   Jitesh Adwani
        Description         :   This method is used to update existing record based on lead info
    *************************************************************************************************************************************/
    public static void updateExistingRecordWithNewInformation(SObject existingRecord, Lead newLeadRecord) {
        Map<String, Object> overrideLeadData = getOverrideLeadData(OrganizationHelper.getSobjectName(existingRecord));
        Boolean isContact = OrganizationHelper.isContact(existingRecord);
        String companyFieldName = isContact ? 'company__c' : 'company';
        for (String fieldName : overrideLeadData.keySet()) {
            Map<String, Object> fieldData = (Map<String, Object>) overrideLeadData.get(fieldName);
            String field = String.valueOf(fieldData.get('fieldname'));
            Set<String> containsPatterns = getPattern(fieldData.get('containspattern'));
            Set<String> equalsPatterns = getPattern(fieldData.get('equalspattern'));

            if (String.isBlank(field) || OrganizationHelper.isFieldNull(existingRecord, field)
                || OrganizationHelper.isFieldNull(newLeadRecord, fieldName)
                || containsPatterns.contains(OrganizationHelper.getStringValueLowerCase(newLeadRecord, fieldName))) {
                continue;
            }
            String oldFullName;
            String firstName;

            Boolean companyFieldCheck = false;
            String oldMatchPattern = OrganizationHelper.getStringValueLowerCase(existingRecord, field);
            String newMatchPattern = OrganizationHelper.getStringValueLowerCase(newLeadRecord, fieldName);
            if (field == companyFieldName) {
                firstName =  OrganizationHelper.isFieldNotNull(existingRecord, 'FirstName' ) ? OrganizationHelper.getStringValueLowerCase(existingRecord, 'FirstName') : null;
                oldFullName = (OrganizationHelper.getStringValue(existingRecord, 'FirstName') + ' ' + OrganizationHelper.getStringValue(existingRecord, 'LastName')).toLowerCase();
                companyFieldCheck =
                        isContact ? (oldFullName != null && ((firstName != newMatchPattern || oldFullName != newLeadRecord.Company) && (containsPatterns.contains(oldMatchPattern) || (oldMatchPattern != newLeadRecord.Company && (oldFullName == oldMatchPattern || firstName == oldMatchPattern)))))
                                  : (oldFullName != null && ((firstName != newMatchPattern || oldFullName != newMatchPattern) && (containsPatterns.contains(oldMatchPattern) || (oldMatchPattern != newMatchPattern && (oldFullName == oldMatchPattern || firstName == oldMatchPattern)))));
            }
            if ((equalsPatterns.contains(oldMatchPattern) && !equalsPatterns.contains(newMatchPattern)) || companyFieldCheck) {
                existingRecord.put(field, newLeadRecord.get(fieldName));
            } else {
                for (String pattern : containsPatterns) {
                    if ((oldMatchPattern.contains(pattern) && !newMatchPattern.contains(pattern))) {
                        existingRecord.put(field, newLeadRecord.get(fieldName));
                    }
                }
            }
        }
    }

    public static void updateAddressInformation(SObject existingRecord, Lead newLeadRecord) {
        if (!updateNewAddressValues(newLeadRecord)) {
            return;
        }
        existingRecord.put('Personal_Mailing_Street__c', getFieldValue(newLeadRecord.Personal_Mailing_Street__c));
        existingRecord.put('Personal_Mailing_PostalCode__c', getFieldValue(newLeadRecord.Personal_Mailing_PostalCode__c));
        existingRecord.put('Personal_Mailing_City__c', getFieldValue(newLeadRecord.Personal_Mailing_City__c));
        existingRecord.put('Personal_Mailing_State__c', getFieldValue(newLeadRecord.Personal_Mailing_State__c));
        existingRecord.put('Personal_Mailing_Country__c', getFieldValue(newLeadRecord.Personal_Mailing_Country__c));
    }

    /************************************************************************************************************************************
        Author              :   Jitesh Adwani
        Description         :   This method get and returns the Metadata settings 
        Created Date        :   3rd August 2019
        Issue Number        :   ST-4281
    *************************************************************************************************************************************/
    public static Map<String, Object> getOverrideLeadData(String objectName) {
        if (overrideLeadData == null) {
            overrideLeadData = getOverrideLeanData();
        }
        return (Map<String, Object>) overrideLeadData.get(objectName);
    }

    public static Set<String> getPattern(Object pattern) {
        if (pattern == null) {
            return new Set<String>();
        }
        return (Set<String>) JSON.deserialize(JSON.serialize(pattern), Set<String>.class);
    }

    /************************************************************************************************************************************
        Author              :   Jitesh Adwani
        Description         :   This method check whether Null value.
        Created Date        :   18 Feb 2019
        Issue Number        :   ST-3409
 *************************************************************************************************************************************/
    public static String getFieldValue(String fieldValue) {
        return String.isNotBlank(fieldValue) ? fieldValue : '';
    }

    /************************************************************************************************************************************
          Author              :   Jitesh Adwani
          Description         :   This method check whether to map Address fileds.
          Created Date        :   18 Feb 2019
          Issue Number        :   ST-3409
   *************************************************************************************************************************************/
    public static Boolean updateNewAddressValues(Lead newLeadRecord) {
        return String.isNotBlank(newLeadRecord.Personal_Mailing_Street__c)
                || String.isNotBlank(newLeadRecord.Personal_Mailing_PostalCode__c)
                || String.isNotBlank(newLeadRecord.Personal_Mailing_City__c)
                || String.isNotBlank(newLeadRecord.Personal_Mailing_State__c)
                || String.isNotBlank(newLeadRecord.Personal_Mailing_Country__c);
    }

    /************************************************************************************************************************************
           Author              :   Krishana Tupe
           Description         :   This method is used to get the journey created for a lead
           Created Date        :   28 Nov 2018
           Last Modified By    :   Krishana Tupe
    *************************************************************************************************************************************/
    public static Id getJourneyByLeadId(Id leadId, List<Journey__c> journeys) {
        if (String.isBlank(leadId)) {
            return null;
        }
        for (Journey__c journeyRecord : journeys) {
            if (journeyRecord.Lead_Id__c == leadId) {
                return journeyRecord.Id;
            }
        }
        return null;
    }

    public static CampaignAssignmentSetting getCampaignAssigmentSetting() {
        MetadataSetting__mdt metadataRecord = Settings.getMetadataSettingByDevName('CampaignOwnerSetting');
        if (metadataRecord?.Data__c == null) {
            return null;
        }
        return (CampaignAssignmentSetting) JSON.deserialize(metadataRecord.Data__c, CampaignAssignmentSetting.class);
    }

    public static Map<String, Object> getOverrideLeanData() {
        MetadataSetting__mdt metadataRecord = Settings.getMetadataSettingByDevName('OverrideLeadData');
        if (metadataRecord?.Data__c == null) {
            return null;
        }
        return (Map<String, Object>) JSON.deserializeUntyped(metadataRecord.Data__c.toLowerCase());
    }

    public static String getHoldBackQueueId() {
        MetadataSetting__mdt metadataRecord = Settings.getMetadataSettingByDevName('Hold_Back_Queue');
        return String.valueOf(metadataRecord?.Data__c);
    }

    /************************************************************************************************************************************
        Author              :   Rohit Nimase
        Description         :   This method is used to create the map of Campaigns.
        Created Date        :   26 June 2019
        Issue No.           :   STL-638
   *************************************************************************************************************************************/
    public static void createCampaignsByIdsFromIdsAndSetting(Set<Id> campaignIds) {
        CampaignAssignmentSetting campaignAssignmentSettingRecord = getCampaignAssigmentSetting();
        campaignSettings = campaignAssignmentSettingRecord?.campaigns;
        if (campaignSettings != null && !campaignSettings.isEmpty()) {
            campaignIds.addAll(campaignSettings.keySet());
        }
        campaignsByIds = new Map<Id, Campaign>([
                SELECT Id, Name, Lead_Owner__c, By_Pass_Campaign_Assignment__c
                FROM Campaign
                WHERE Id IN :campaignIds
        ]);
    }

    /************************************************************************************************************************************
       Author              : Krishana Tupe
       Description         : This method contains the business logic of Lead/Journey insertion and assignment with Dedup/Conversion
       Issue No            : -
       LastModfied By      : Krishana Tupe
    **************************************************************************************************************************************/
    public static Map<String, Map<String, Id>> manageLead(List<Lead> leads, RESTAPITourModelsV2.Input tourPayload) {
        String holdBackQueueId = LeadConverterHelper.getHoldBackQueueId();
        Map<String, List<Lead>> leadsByEmails = new Map<String, List<Lead>>();
        leadsToDeduplicate = new Map<Id, Lead>();
        Map<Id, Map<Id, Lead>> leadsByIdsGroupedByCampaigns = new Map<Id, Map<Id, Lead>>();
        LeadConverterHelper.getLeadsByEmailsAndLeadsByCampaigns(leads, leadsByEmails, leadsByIdsGroupedByCampaigns);

        Set<Id> campaignIds = new Set<Id>(leadsByIdsGroupedByCampaigns.keySet());
        createCampaignsByIdsFromIdsAndSetting(campaignIds);
        
        Set<String> emails = leadsByEmails.keySet();
       
        Map<Id, Lead> leadsEmailChanged = LeadTriggerHandler.mapLeadsEmailChanged;
        if (emails.isEmpty()) {
            isLeadUpdateFromLeadConverter = false;
            return null;
        }

        Set<Id> gatedWifiCampaignIds = String.isNotBlank(Label.GuestWiFiCampaignIds) 
                                        ? new Set<Id>((List<Id>)Label.GuestWiFiCampaignIds.trim().split(',')) 
                                        : new Set<Id>();

        //SOQL on Lead and Contact for get existing Lead and Contact info
        Map<String, List<Contact>> contactsByEmail = LeadRoutingHelper.getExistingContactsByEmail(emails, campaignSettings);
        Map<String, List<Lead>> existingLeadsByEmails = LeadRoutingHelper.getLeadsByEmail(emails);
        //get or create Org for Lead and Contact
        Map<Id, Id> orgIds = LeadRoutingHelper.getMapLeadContactOrgIds(emails, existingLeadsByEmails, contactsByEmail, tourPayload);
        Map<String, Map<String, Id>> afterConversionData = new Map<String, Map<String, Id>>();
        Map<String, Map<String, Object>> convertData = new Map<String, Map<String, Object>>();
        leadsToDelete = new List<Id>();
        List<Map<String, sObject>> journeyParents = new List<Map<String, sObject>>();
        List<CampaignMember> campaignMembers = new List<CampaignMember>();
        Map<Id, SObject> recordsToUpdate = new Map<Id, SObject>();
        Map<Id, Lead> leadsToMap = new Map<Id, Lead>();
        Map<Id, Contact> contactsToMap = new Map<Id, Contact>();
        Map<Id, Lead> destinationLeads = new Map<Id, Lead>();
        Map<Id, Id> journeyWithLeadOrContactIds = new Map<Id, Id>();
        Database.DMLOptions dmlOptionsRecord = new Database.DMLOptions();
        dmlOptionsRecord.assignmentRuleHeader.useDefaultRule = true;
        leadIds = new Set<Id>();

        List<Lead> leadsToProcess = new List<Lead>();

        for (String leadEmail : emails) {
            leadsToProcess.addAll(leadsByEmails.get(leadEmail));
        }
        for (Lead leadRecordFromEmails : leadsToProcess) {
            String leadEmail = leadRecordFromEmails.Email;
            if (String.isNotBlank(tourPayload?.email)) {
                isInsert = false;
            }
            if (contactsByEmail.containsKey(leadEmail)) {
                Boolean isAllowConvert = true;
                Contact contactRecord;
                Lead newLeadRecord;
                //for Tour payload
                if (String.isNotBlank(tourPayload?.contact_uuid)) {
                    isInsert = false;
                    contactRecord = getContactByUUID(contactsByEmail.get(leadEmail), tourPayload.contact_uuid);
                    
                    contactRecord = LeadRoutingHelper.setExitingAccountStructureForTour(leadEmail, contactRecord, orgIds, contactsByEmail, recordsToUpdate, tourPayload);
                    
                } else {
                    contactRecord = contactsByEmail.get(leadEmail)[0];
                    newLeadRecord = getLeadById(existingLeadsByEmails.get(leadEmail), leadRecordFromEmails.Id);
                    if (String.isNotBlank(newLeadRecord?.Id)) {
                    isAllowConvert = LeadRoutingHelper.updateLeadAssignmentStageForContact(newLeadRecord, isAllowConvert, isInsert, tourPayload, dmlOptionsRecord, holdBackQueueId);
                        contactRecord.AccountId = orgIds.containsKey(contactRecord.Id) ? orgIds.get(contactRecord.Id) : null;
                        Boolean isCheckCampiagnAssignment = true;
                        String campaignOROwnerId = LeadRoutingHelper.getValidCampaignOwnerORCampaignId(contactRecord, contactRecord.CampaignMembers, campaignSettings);
                        
                        if (String.isNotBlank(campaignOROwnerId) && isInsert) {
                            if (OrganizationHelper.isUser(campaignOROwnerId) || OrganizationHelper.isGroup(campaignOROwnerId)) {
                                newLeadRecord.OwnerId = campaignOROwnerId;
                                isAllowConvert = true;
                                isCheckCampiagnAssignment = false;

                                setNewLeadRoutingQualificationResult(newLeadRecord, gatedWifiCampaignIds, holdBackQueueId);
                                addCampaignMembers(newLeadRecord, contactRecord, campaignMembers);
                                setContactOwner(contactRecord, newLeadRecord, campaignOROwnerId);

                                recordsToUpdate.put(newLeadRecord.Id, newLeadRecord);

                            } else if (OrganizationHelper.isCampaign(campaignOROwnerId)) {
                                recordsToUpdate.put(newLeadRecord.Id, newLeadRecord);
                            }
                        } else if (String.isBlank(campaignOROwnerId) && newLeadRecord.Campaign_Id__c != null && newLeadRecord.Processing_Stage__c != ASSIGNMENT_COMPLETE) {
                            newLeadRecord.OwnerId = holdBackQueueId;
                        }
                        if (System.isBatch() && newLeadRecord.By_Pass_Journey_Creation_Criteria__c && isInsert) {
                            setContactOwner(contactRecord, newLeadRecord, null);
                        }
                        
                        Id existingCampaignId = (String.isNotBlank(campaignOROwnerId) && OrganizationHelper.isCampaign(campaignOROwnerId)) ? campaignOROwnerId : null;
                        
                        if ((newLeadRecord.Campaign_Id__c != null || String.isNotBlank(existingCampaignId)) && isInsert && isCheckCampiagnAssignment) {
                            String leadOwnerId = LeadRoutingHelper.getLeadOwnerForCampaign(campaignsByIds, (String.isNotBlank(existingCampaignId) ? existingCampaignId : newLeadRecord.Campaign_Id__c), holdBackQueueId);
                            
                            if (String.isNotBlank(leadOwnerId)) {
                                if (OrganizationHelper.isUser(leadOwnerId) && !UserUtility.getUserActive(contactRecord.OwnerId)) {
                                    contactRecord.OwnerId = leadOwnerId;
                                }
                                if (Id.valueOf(leadOwnerId) != Id.valueOf(holdBackQueueId)) {
                                    newLeadRecord.OwnerId = leadOwnerId; //Lead owner according to Campaign Assignment
                                    isAllowConvert = true;
                                }

                                setNewLeadRoutingQualificationResult(newLeadRecord, gatedWifiCampaignIds, holdBackQueueId);
                            }

                            addCampaignMembers(newLeadRecord, contactRecord, campaignMembers);

                            if (String.isNotBlank(leadOwnerId)) {
                                if (OrganizationHelper.isUser(leadOwnerId) 
                                    && contactRecord.OwnerId != null 
                                    && (!UserUtility.getUserActive(contactRecord.OwnerId) || contactRecord.OwnerId == ApiUsersUtils.apiUserId)) {
                                        contactRecord.OwnerId = leadOwnerId;
                                }
                                if (Id.valueOf(leadOwnerId) != Id.valueOf(holdBackQueueId)) {
                                    newLeadRecord.OwnerId = leadOwnerId; //Lead owner according to Campaign Assignment
                                    isAllowConvert = true;
                                }

                                setNewLeadRoutingQualificationResult(newLeadRecord, gatedWifiCampaignIds, holdBackQueueId);
                            }
                            addCampaignMembers(newLeadRecord, contactRecord, campaignMembers);
                        }

                        Boolean isAddJourneyParents = isInsert 
                            && (leadsEmailChanged == null || (leadsEmailChanged != null && !leadsEmailChanged.containsKey(newLeadRecord.Id)))
                            && LeadConverterHelper.generateJourney != null 
                            && LeadConverterHelper.generateJourney;
                        
                        if (isAddJourneyParents) {
                            journeyParents.add(new Map<String, sObject> {
                                'contact' => contactRecord, 
                                'newlead' => newLeadRecord
                            });
                        }
                    }
                }
                
                if (isInsert && newLeadRecord != null) {
                    if (contactRecord?.Id != null) {
                        LeadConverterHelper.mapNewLeadToExistingRecord(contactRecord, newLeadRecord);
                    }
                    if (isPopulateLeadMaps(newLeadRecord, holdBackQueueId)) {
                        newLeadRecord.OwnerId = (System.isBatch()) ? UserInfo.getUserId() : ApiUsersUtils.apiUserId;
                        populateLeadMaps(newLeadRecord, leadsToMap, destinationLeads);
                    }
                }
                if (newLeadRecord != null) {
                    contactsToMap.put(newLeadRecord.Id, contactRecord);
                }
                if (existingLeadsByEmails.containsKey(leadEmail) && !existingLeadsByEmails.get(leadEmail).isEmpty()) {
                    if (isInsert) {
                        for (Lead existingLead : existingLeadsByEmails.get(leadEmail)) {
                            if (existingLead?.OwnerId != Id.valueOf(holdBackQueueId) && !UserUtility.getUserActive(existingLead.OwnerId) && !OrganizationHelper.isGroup(existingLead.OwnerId)) {
                                existingLead.OwnerId = ApiUsersUtils.apiUserId;
                                populateLeadMaps(existingLead, leadsToMap, destinationLeads);
                            }
                        }
                    }
                    if (isAllowConvert && !convertData.containsKey(leadEmail)) {
                        convertData.put(leadEmail, new Map<String, Object>{
                                'accountId' => orgIds.get(contactRecord.Id), 'contactId' => contactRecord.Id, 'leads' => existingLeadsByEmails.get(leadEmail)
                        });
                    }
                }
                if (isAllowConvert && !afterConversionData.containsKey(leadEmail)) {
                    afterConversionData.put(leadEmail, new Map<String, Id>{
                            'accountId' => contactRecord?.AccountId,
                            'contactId' => contactRecord?.Id
                    });
                }
                
                Boolean isLeadToConvert = (isAllowConvert || (String.isNotBlank(tourPayload?.contact_uuid)));
                
                if (isLeadToConvert && existingLeadsByEmails.containsKey(leadEmail)) {
                    for (Lead existingLead : existingLeadsByEmails.get(leadEmail)) {
                        if (isLeadToConvert && existingLead.Lead_Assignment_Stage__c == HOLD_QUEUE) {
                            existingLead.Lead_Assignment_Stage__c = ASSIGNMENTS_RUN;
                        }
                        setJourneyWithLeadOrContactIds(newLeadRecord, existingLead, contactRecord, leadsToMap, holdBackQueueId, recordsToUpdate, journeyWithLeadOrContactIds);

                    }
                } else if (String.isNotBlank(newLeadRecord?.Id) && !leadsToMap.containskey(newLeadRecord.Id)) {
                    recordsToUpdate.put(newLeadRecord.Id, newLeadRecord);
                }
            } else if (existingLeadsByEmails?.containsKey(leadEmail)) {

                Lead leadRecord = LeadRoutingHelper.sortLeadByCreatedDate(existingLeadsByEmails.get(leadEmail));
                
                if (tourPayload != null) {
                    isInsert = false;
                    Map<String, Id> accountStructure = createAccountStructure(tourPayload, leadRecord.Id, orgIds.get(leadRecord.Id));
                    if (leadRecord?.OwnerId != null && !UserUtility.getUserActive(leadRecord.OwnerId) && !OrganizationHelper.isGroup(leadRecord.OwnerId)) {
                        leadRecord.OwnerId = ApiUsersUtils.apiUserId;
                        populateLeadMaps(leadRecord, leadsToMap, destinationLeads);
                        
                    }
                    for (Lead existingLead : existingLeadsByEmails.get(leadEmail)) {
                        setJourneyWithLeadOrContactIds(leadRecord, existingLead, null, leadsToMap, holdBackQueueId, recordsToUpdate, journeyWithLeadOrContactIds);
                    }
                    convertData.put(leadEmail, new Map<String, Object>{
                            'accountId' => accountStructure.get('accountId'), 
                            'contactId' => accountStructure.get('contactId'), 
                            'leads' => existingLeadsByEmails.get(leadEmail)
                    });
                } else {
                    if (existingLeadsByEmails.get(leadEmail).size() > 1) {
                        Lead newLeadRecord = getLeadById(existingLeadsByEmails.get(leadEmail), leadRecordFromEmails.Id);
                        if (newLeadRecord != null) {
                            if (newLeadRecord.Campaign_Id__c != null && isInsert) {
                                
                                String leadOwnerId = LeadRoutingHelper.getLeadOwnerForCampaign(campaignsByIds, newLeadRecord.Campaign_Id__c, holdBackQueueId);
                                LeadRoutingHelper.setCampaignAssignment(newLeadRecord, leadOwnerId, holdBackQueueId, leadsToDeduplicate, dmlOptionsRecord, ApiUsersUtils.apiUserId);
                                campaignMembers.add(new CampaignMember(LeadId = leadRecord.Id, CampaignId = newLeadRecord.Campaign_Id__c));
                            }
                            LeadRoutingHelper.updateLeadAssignmentStage(newLeadRecord, leadsToDeduplicate, isInsert, holdBackQueueId, dmlOptionsRecord);
                            LeadConverterHelper.mapNewLeadToExistingRecord(leadRecord, newLeadRecord);
                            if (isInsert && (leadsEmailChanged == null || (leadsEmailChanged != null && !leadsEmailChanged.containsKey(newLeadRecord.Id)))) {
                                journeyParents.add(new Map<String, sObject>{
                                        'lead' => leadRecord, 'newlead' => newLeadRecord
                                });
                            } else if (!isInsert && (newLeadRecord.Lead_Assignment_Stage__c != '1' && newLeadRecord.Lead_Assignment_Stage__c != '1000')) {
                                if (!journeyWithLeadOrContactIds.containsKey(leadRecord.Id)) {
                                    journeyWithLeadOrContactIds.put(leadRecord.Id, newLeadRecord.Id);
                                }
                                journeyWithLeadOrContactIds.put(newLeadRecord.Id, LeadConverterHelper.getJourneyByLeadId(newLeadRecord.Id, leadRecord.Journeys__r));
                            }
                            if (leadRecord.Id != newLeadRecord.Id && (isValidToDelete(newLeadRecord, holdBackQueueId) || newLeadRecord.Fire_Lead_Assignement__c)) {
                                leadsToDelete.add(newLeadRecord.Id);
                            }
                            if (System.isBatch() && isInsert) {
                                if (leadRecord?.OwnerId != null && ((!UserUtility.getUserActive(leadRecord.OwnerId) && !OrganizationHelper.isGroup(leadRecord.OwnerId)) || leadRecord.OwnerId == ApiUsersUtils.apiUserId)) {
                                    if (newLeadRecord?.OwnerId != null && newLeadRecord.Campaign_Id__c == null && (UserUtility.getUserActive(newLeadRecord.OwnerId) || OrganizationHelper.isGroup(newLeadRecord.OwnerId))) {
                                        leadRecord.OwnerId = newLeadRecord.OwnerId;
                                    } else if (newLeadRecord == null || (newLeadRecord != null && newLeadRecord?.Campaign_Id__c == null)) {
                                        leadRecord.OwnerId = UserInfo.getUserId();
                                    }
                                }
                                leadsToDeduplicate.put(newLeadRecord.Id, newLeadRecord);
                            }
                            if (isInsert) {
                                if (!leadsToMap.containsKey(leadRecord.Id)) {
                                    leadsToMap.put(leadRecord.Id, newLeadRecord);
                                }
                                if (!destinationLeads.containsKey(leadRecord.Id)) {
                                    destinationLeads.put(leadRecord.Id, leadRecord);
                                }
                            }
                            if (recordsToUpdate != null && !recordsToUpdate.containsKey(newLeadRecord.Id)) {
                                if (!leadsToMap.isEmpty() && leadsToMap.containsKey(leadRecord.Id)) {
                                    if (leadRecord.Id != newLeadRecord.Id) {
                                        recordsToUpdate.put(newLeadRecord.Id, newLeadRecord);
                                    }
                                } else if (leadsToMap.isEmpty()) {
                                    recordsToUpdate.put(newLeadRecord.Id, newLeadRecord);
                                }
                            }
                        }
                    } else {
                        Lead newLeadRecord = getLeadById(existingLeadsByEmails.get(leadEmail), leadRecordFromEmails.Id);
                        if (newLeadRecord != null) {
                            if (newLeadRecord.Campaign_Id__c != null && isInsert) {
                                
                                String leadOwnerId = LeadRoutingHelper.getLeadOwnerForCampaign(campaignsByIds, newLeadRecord.Campaign_Id__c, holdBackQueueId);
                                LeadRoutingHelper.setCampaignAssignment(newLeadRecord, leadOwnerId, holdBackQueueId, leadsToDeduplicate, dmlOptionsRecord, ApiUsersUtils.apiUserId);
                                campaignMembers.add(new CampaignMember(LeadId = newLeadRecord.Id, CampaignId = newLeadRecord.Campaign_Id__c));
                            }
                            LeadRoutingHelper.updateLeadAssignmentStage(newLeadRecord, leadsToDeduplicate, isInsert, holdBackQueueId, dmlOptionsRecord);
                            if (System.isBatch() && OrganizationHelper.isUser(newLeadRecord.OwnerId) && !leadIds.contains(newLeadRecord.Id)) {
                                newLeadRecord.Status = 'Working';
                            }
                            recordsToUpdate.put(newLeadRecord.Id, newLeadRecord);
                            if (isInsert && (leadsEmailChanged == null || (leadsEmailChanged != null && !leadsEmailChanged.containsKey(newLeadRecord.Id)))) {
                                journeyParents.add(new Map<String, sObject>{
                                        'lead' => newLeadRecord
                                });
                            } else if (!isInsert && (newLeadRecord.Lead_Assignment_Stage__c != '1' && newLeadRecord.Lead_Assignment_Stage__c != '1000')) {
                                journeyWithLeadOrContactIds.put(newLeadRecord.Id, LeadConverterHelper.getJourneyByLeadId(newLeadRecord.Id, newLeadRecord.Journeys__r));
                            }
                        }
                    }
                }
            } else if (tourPayload != null) {
                afterConversionData.put(leadEmail, createAccountStructure(tourPayload, null, null));
            }
            
        }
        if (!contactsToMap.isEmpty()) {
            recordsToUpdate.putAll(FieldMappingsHelper.getMappings(contactsToMap, 'FieldMappings_LeadToContact').values());
        }
        //Map new lead information on Old lead that are blank on old lead
        if (!leadsToMap.isEmpty()) {
            LeadRoutingHelper.mapNewLeadFieldsToOldLead(leadsToMap, recordsToUpdate, destinationLeads);
        }
        Boolean isInsertOperation = isInsert;
        recordsToUpdate.remove(null);
        if (!recordsToUpdate.isEmpty()) {
            isLeadUpdateFromLeadConverter = true;
            DmlConsolidatorDefault.getInstance().add(recordsToUpdate.values(), DmlConsolidator.Operation.FOR_UPDATE);
        }

        DmlConsolidatorDefault.getInstance().run();
        DmlConsolidatorPartialSuccess.getInstance().run();
        LeadRoutingHelper.manageLeadRelatedRecords(isInsertOperation, journeyParents, leadsToDelete, campaignMembers, journeyWithLeadOrContactIds);
        if (!convertData.isEmpty()) {
            Map<String, Map<String, Id>> convertResultData = convertLead(convertData);
            for (String leadEmail : convertResultData.keySet()) {
                if (!afterConversionData.containsKey(leadEmail)) {
                    afterConversionData.put(leadEmail, convertResultData.get(leadEmail));
                }
            }
        }
        isLeadUpdateFromLeadConverter = false;
        return afterConversionData;
    }

    public static List<Id> manageDuplicateLeads(List<Id> leadsToDelete) {
        if(leadsToDelete.isEmpty()) {
            return leadsToDelete;
        }
        List<Id> leadToDeletesForIsInsert = new List<Id>();
        for (Id deleteLeadId : leadsToDelete) {
            if (leadsToDeduplicate.containsKey(deleteLeadId)) {
                leadToDeletesForIsInsert.add(deleteLeadId);
            }
        }
        return leadToDeletesForIsInsert;
    }

    public static Boolean isValidToDelete(Lead newLeadRecord, Id holdBackQueueId) {
        if (newLeadRecord.OwnerId != Id.valueOf(holdBackQueueId) && newLeadRecord.Send_For_Forcefully_Lead_Assignments__c == true) {
            return false;
        } else if (newLeadRecord.OwnerId == Id.valueOf(holdBackQueueId)) {
            return false;
        } else if (newLeadRecord.Send_For_Forcefully_Lead_Assignments__c == true) {
            return false;
        }
        return true;
    }

    public static void deleteLeads(List<Id> leadsToDelete) {
        if (leadsToDelete == null || leadsToDelete.isEmpty()){
            return;
        }
        List<sObject> leadsObjectsToDelete = new List<sObject>();
        for (Id item : leadsToDelete) { 
            leadsObjectsToDelete.add(item.getSObjectType().newSObject(item)); 
        }
        DmlConsolidatorDefault.getInstance().add(leadsObjectsToDelete, DmlConsolidator.Operation.FOR_DELETE);
    }

    public static Lead getLeadById(List<Lead> leads, String leadId) {
        if (leads != null && String.isNotBlank(leadId)) {
            return new Map<Id, Lead>(leads).get(leadId);
        }
        return null;
    }

    public static Contact getContactByUUID(List<Contact> contacts, String contactUUID) {
        if (String.isBlank(contactUUID)) {
            return null;
        }
        for (Contact contactRecord : contacts) {
            if (contactRecord.UUID__c == contactUUID) {
                return contactRecord;
            }
        }
        return null;
    }

    public static Map<String, Id> createAccountStructure(RESTAPITourModelsV2.Input tourPayload, Id leadId, Id accountId) {
        if (String.isBlank(tourPayload.email)) {
            return null;
        }

        Map<String, Id> accountStructure = new Map<String, Id>();
        Contact contactRecord = getContactByWeb(tourPayload);
        if (leadId != null) {
            contactRecord = (Contact) FieldMappingsHelper.getMappings(leadId, contactRecord, 'FieldMappings_LeadToContact');
            contactRecord.Contact_Lead_Status__c = 'Converted';
        }
        if (accountId != null) {
            contactRecord.AccountId = accountId;
        }
        contactRecord.Convert_Lead__c = false;
        // if (String.isNotBlank(tourPayload.Promo_Code)) {
        //     contactRecord.Promo_Code__c = tourPayload.Promo_Code;
        // }
        if (!ConvertBrokerLeadController.mapContactTypeValue.isEmpty() && ConvertBrokerLeadController.mapContactTypeValue.containsKey('Type__c')) { // This map is used to map type field at the time of lead handoff
            contactRecord.Type__c = ConvertBrokerLeadController.mapContactTypeValue.get('Type__c');
        }
        insert contactRecord;
        if (accountId == null) {
            contactRecord = [SELECT Id, Phone, Lead_Source_Detail__c, CI_Company__c, CI_Updated_DateTime__c, FirstName, LastName, Name, OwnerId, Email_Domain_Text__c, Account_Name__c, AccountId, Account.Account_Type__c,Email, Unomy_Company_ID_Formula__c, UUID__c, Location__c, Location__r.City__c, LeadSource, Cleansed_Company_Name__c, Unomy_Company_Phone_Formula__c, Unomy_Company_Website_Formula__c FROM Contact WHERE Id = :contactRecord.Id];
            contactRecord.AccountId = OrganizationHelperServices.findOrCreateOrgByNewCriteria(contactRecord);
            PersonEndpointHelper.updateCICompany(contactRecord);
            DmlConsolidatorDefault.getInstance().add(new List<SObject>{contactRecord}, DmlConsolidator.Operation.FOR_UPDATE);
        }
        accountStructure.put('contactId', contactRecord.Id);
        accountStructure.put('accountId', contactRecord.AccountId);
        return accountStructure;
    }

    public static Contact getContactByWeb(RESTAPITourModelsV2.Input tourPayload) {
        return new Contact(
                FirstName = tourPayload.first_name,
                LastName = tourPayload.last_name,
                Company__c = tourPayload.company_name,
                Convert_Lead__c = false,
                Phone = tourPayload.phone,
                Email = tourPayload.email,
                Locale__c = tourPayload.locale,
                Product_Interests__c = tourPayload.product_interests != null ? String.join(tourPayload.product_interests, ';') : null,
                Country_Code__c = tourPayload.country_code,
                Product_Line__c = tourPayload.product_line,
                UUID__c = tourPayload.contact_uuid,
                //Marketing_Consent__c = ((tourPayload.marketing_consent != null && tourPayload.marketing_consent == 'true') ? true : false),
                Ts_and_Cs_Consent__c = ((tourPayload.t_and_cs_consent != null && tourPayload.t_and_cs_consent == 'true') ? true : false)
        );
    }

    public static List<Lead> getDefaultLeadMappings(Map<Id, Lead> leadsByIds) {
       Set<String> fields = LeadRoutingHelper.getListofLeadFields();
       Set<Id> leadIds = leadsByIds.keySet();
        String query = 'SELECT Id,' + String.join(new List<String>(fields), ',') + ' FROM Lead WHERE Id IN:leadIds';
        List<Lead> destinations = Database.query(query);
        for (Lead destinationRecord : destinations) {
            if (destinationRecord.Id != leadsByIds.get(destinationRecord.Id).Id) {
                Map<String, Object> destinationsByFieldNames = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(destinationRecord));
                Map<String, Object> sourcesByFieldNames = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(leadsByIds.get(destinationRecord.Id)));
                Set<String> setDateTimeFields = new Set<String>{
                        'Submission_Timestamp__c'
                };
                for (String fieldName : sourcesByFieldNames.keySet()) {
                    if (fields.contains(fieldName) && destinationsByFieldNames.get(fieldName) == null && sourcesByFieldNames.get(fieldName) != null) {
                        if (setDateTimeFields.contains(fieldName)) {
                            SObject newLeadRecord = leadsByIds.get(destinationRecord.Id);
                            DateTime newLeadDateTime = DateTime.valueOf(newLeadRecord.get(fieldName));
                            destinationRecord.put(fieldName, newLeadDateTime);
                        } else if (fieldName == 'LeadSource_Sub_Type__c' || fieldName == 'LeadSource' || fieldName == 'Lead_Source_Detail__c') {
                            if (destinationsByFieldNames.get('LeadSource') == null && destinationsByFieldNames.get('Lead_Source_Detail__c') == null && destinationsByFieldNames.get('LeadSource_Sub_Type__c') == null) {
                                destinationRecord.put(fieldName, sourcesByFieldNames.get(fieldName));
                            }
                        } else {
                            destinationRecord.put(fieldName, sourcesByFieldNames.get(fieldName));
                        }
                    }
                }
            }
        }
        return destinations;
    }

    public static Map<String, Map<String, Id>> convertLead(Map<String, Map<String, Object>> convertData) {
        system.debug('Inside convert Lead');
        Id accountId;
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        Map<String, Map<String, Id>> convertedRecordsInfoByEmails = new Map<String, Map<String, Id>>();
        Id holdBackQueueId = (Id) LeadConverterHelper.getHoldBackQueueId();
        List<Lead> convertedLeads = new List<Lead>();
        for (Map<String, Object> convertElement : convertData.values()) {
            for (Lead leadRecord : (List<Lead>) convertElement.get('leads')) {
                if (leadRecord?.OwnerId != holdBackQueueId) {
                    accountId = String.valueOf(convertElement.get('accountId'));
                    Database.LeadConvert leadConvertRecord = new Database.LeadConvert();
                    leadConvertRecord.setLeadId(leadRecord.Id);
                    leadConvertRecord.setAccountId(accountId);
                    leadConvertRecord.setContactId(String.valueOf(convertElement.get('contactId')));
                    leadConvertRecord.setConvertedStatus('Converted');
                    leadConvertRecord.doNotCreateOpportunity = true;
                    leadConvertRecord.overwriteLeadSource = false;
                    leadConvertRecord.setOwnerId( (OrganizationHelper.isGroup(leadRecord.OwnerId)
                                                   || !UserUtility.getUserActive(leadRecord.OwnerId)) ? ApiUsersUtils.apiUserId
                                                                                                   : leadRecord.OwnerId);
                    leadConverts.add(leadConvertRecord);
                    convertedLeads.add(leadRecord);
                } else {
                    convertedRecordsInfoByEmails.put(leadRecord.Email.toLowerCase(),
                                                     new Map<String, Id>{
                                                        'accountId' => String.valueOf(convertElement.get('accountId')),
                                                        'contactId' => String.valueOf(convertElement.get('contactId')),
                                                        'leadId' => leadRecord.Id });
                }
            }
        }

        isLeadConverted = true;
        MetadataDrivenTriggerHandler.clearLoopCount('LeadTriggerHandler');
        List<Database.LeadConvertResult> convertResults = Database.convertLead(leadConverts);
        isLeadConverted = false;

        Map<Id, Database.LeadConvertResult> convertResultByIds = new Map<Id, Database.LeadConvertResult>();
        for (Database.LeadConvertResult convertResultRecord : convertResults) {
            convertResultByIds.put(convertResultRecord.getLeadId(), convertResultRecord);
        }
        for (Lead leadRecord : convertedLeads) {
            Database.LeadConvertResult result = convertResultByIds.get(leadRecord.Id);
            if (result.isSuccess()) {
                convertedRecordsInfoByEmails.put(leadRecord.Email.toLowerCase(), new Map<String, Id>{
                        'accountId' => result.getAccountId(), 'contactId' => result.getContactId(), 'leadId' => result.getLeadId()
                });
            }
        }
        return convertedRecordsInfoByEmails;
    }

    //ST-7158
    private static void setMarketingInfo(SObject existingRecord, Lead newLeadRecord) {
        if (newLeadRecord.LastModifiedById != Settings.getValidationRuleRestrictionSalesforceId('BigMarker_Integration_User')) {
            return;
        }
        if (!(Boolean) existingRecord.get('HasOptedOutOfEmail') && !newLeadRecord.Marketing_Consent__c) {
            existingRecord.put('HasOptedOutOfEmail', true);
            existingRecord.put('Marketing_Consent__c', false);
        } else if ((Boolean) existingRecord.get('Marketing_Consent__c') && (Boolean) existingRecord.get('HasOptedOutOfEmail')
                   && !newLeadRecord.Marketing_Consent__c) {
            existingRecord.put('Marketing_Consent__c', false);
        }
    }

    
    @TestVisible
    private static void setNewLeadRoutingQualificationResult(Lead newLeadRecord, Set<Id> gatedWifiCampaignIds, String holdBackQueueId) {
        if(gatedWifiCampaignIds.contains(newLeadRecord.Campaign_Id__c)){
            newLeadRecord.Routing_Qualification_Result__c = NURTURE_SET_BY_SYSTEM;  
        } else if(newLeadRecord.OwnerId == holdBackQueueId && LeadRoutingHelper.routeToInsideSales) {
            newLeadRecord.Routing_Qualification_Result__c = MQL_SET_BY_USER;
        } else {            
            newLeadRecord.Routing_Qualification_Result__c = MQL_SET_BY_CAMPAIGN;
        }
    }

    @TestVisible
    private static void populateLeadMaps(Lead leadRecord, Map<Id, Lead> leadsToMap, Map<Id, Lead> destinationLeads) {
        leadsToMap.put(leadRecord.Id, leadRecord);
        destinationLeads.put(leadRecord.Id, leadRecord);
    }

    @TestVisible
    private static Boolean isPopulateLeadMaps(Lead leadRecord, String holdBackQueueId) {
        return leadRecord?.OwnerId != Id.valueOf(holdBackQueueId)
            && !UserUtility.getUserActive(leadRecord.OwnerId)
            && !OrganizationHelper.isGroup(leadRecord.OwnerId);
    }

    @TestVisible
    private static void addCampaignMembers(Lead newLeadRecord, Contact contactRecord, List<CampaignMember> campaignMembers) {
        if (String.isNotBlank(newLeadRecord.Campaign_Id__c)) {
            campaignMembers.add(new CampaignMember(ContactId = contactRecord.Id, CampaignId = newLeadRecord.Campaign_Id__c));
        }
    }

    @TestVisible
    private static void setJourneyWithLeadOrContactIds(Lead newLeadRecord, Lead existingLead, Contact contactRecord, Map<Id, Lead> leadsToMap, String holdBackQueueId, Map<Id, SObject> recordsToUpdate, Map<Id, Id> journeyWithLeadOrContactIds) {
        if (newLeadRecord == null || (newLeadRecord != null && !leadsToMap.containskey(newLeadRecord.Id))) {
            if (existingLead.OwnerId == Id.valueOf(holdBackQueueId)) {
                List<Journey__c> journeys = contactRecord != null ? contactRecord.Journeys__r : newLeadRecord.Journeys__r;
                journeyWithLeadOrContactIds.put(existingLead.Id, LeadConverterHelper.getJourneyByLeadId(existingLead.Id, journeys));
            }
            recordsToUpdate.put(existingLead.Id, existingLead);
        }
    }

    @TestVisible
    private static void setjourneyParents(Boolean isInsert, Map<Id, Lead> leadsEmailChanged, Lead newLeadRecord, List<Map<String, sObject>> journeyParents,
                                            Lead leadRecord, Map<Id, Id> journeyWithLeadOrContactIds, Boolean isAddLeadToJourneyParents) {
    
        if (isInsert && (leadsEmailChanged == null || (leadsEmailChanged != null && !leadsEmailChanged.containsKey(newLeadRecord.Id)))) {
            if (isAddLeadToJourneyParents) {
                journeyParents.add(new Map<String, SObject>{
                    'lead' => leadRecord, 
                    'newlead' => newLeadRecord
                });
            } else {
                journeyParents.add(new Map<String, SObject>{
                    'lead' => newLeadRecord
                });
            }
        } else if (!isInsert && (newLeadRecord.Lead_Assignment_Stage__c != STATUS_NEW && newLeadRecord.Lead_Assignment_Stage__c != BYPASS_HOLD_BACK)) {
            if (!journeyWithLeadOrContactIds.containsKey(leadRecord.Id) && isAddLeadToJourneyParents) {
                journeyWithLeadOrContactIds.put(leadRecord.Id, newLeadRecord.Id);
            }
            journeyWithLeadOrContactIds.put(newLeadRecord.Id, LeadConverterHelper.getJourneyByLeadId(newLeadRecord.Id, leadRecord.Journeys__r));
        }
    }

    public class CampaignAssignmentSetting {
        public Map<Id, Id> campaigns ;
    }

    private class LeadConvertException extends Exception {
    }

}