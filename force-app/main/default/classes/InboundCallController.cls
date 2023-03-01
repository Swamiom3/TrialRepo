/************************************************************************************************************************************
    Author      :   Dipak Pawar
    Description :   This class contain all aura methods related to Inbound Call.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     ISSUE NUMBER    DATE                AUTHOR                  DETAIL
    1           ST-2864         7 January 2019      Dipak Pawar             Initial Developement
**************************************************************************************************************************************/
public without sharing class InboundCallController {
    public static Boolean isInvoker = false;
    @TestVisible
    private static JourneySelector journeySelector = new JourneySelector();
    public static Savepoint objSavePoint {get; set;}
    static sObject objParent;

    static {
        isInvoker = ApexDebugLog.registerRootInvoker(ApexDebugLog.InvokerType.AURA, 'InboundCallController' + 'getsObjectPrefix', ApexDebugLog.InvokerType.AURA);
    }

    /************************************************************************************************************************************
        Author         : Shivprasad PAtil
        Description    : This method checks that if current user is NMD.
        Created Date   : 25 April 2019
        Issue No.      : ST-2864
    **************************************************************************************************************************************/
   
    @AuraEnabled
    public static DatabaseResult checkCurrentUserProfile(){
        try{
            Sales_Console_Setting__mdt objNMDProfiles = SalesConsoleSettings.get('NMDProfiles');

            Map<String, Set<String>> mapOfNMDSetting = (Map<String, Set<String>>)JSON.deserialize(objNMDProfiles.Data__c, Map<String, Set<String>>.class);
            Set<String> setOfNMDProfiles = mapOfNMDSetting.get('AllowedProfiles');
            String strUserProfileId = UserInfo.getProfileId().substring(0, 15);
            for (String strNMDProfileId : setOfNMDProfiles) {
                if (strNMDProfileId.substring(0, 15) == strUserProfileId){
                    return new DatabaseResult(true);
                }
            }
            return new DatabaseResult(false);
        } catch(Exception pEx) {
            ApexDebugLog.logException(pEx, '', 'InboundCallController', 'checkCurrentUserProfile');
            return new DatabaseResult(pEx);
        }
    }

    /************************************************************************************************************************************
        Author         : Dipak Pawar
        Description    : This method takes searchKeyword as a parameter and return matched Lead and Contact records
        Created Date   : 7 January 2019
        Issue No.      : ST-2864
    **************************************************************************************************************************************/
   
    @AuraEnabled
    public static DatabaseResult searchDataByKeyword(string searchKeyword, string searchPhoneOnly){
        try{
            String tenDigitNumber = searchPhoneOnly, filterKeyWord = '';
            List<sObject> searchResult  = new List<sObject>();
            List<sObject> lstJourneys  = new List<sObject>();

            if(!string.isBlank(searchPhoneOnly)){
                if(searchPhoneOnly != null && searchPhoneOnly.length() >= 10) {
                    tenDigitNumber = searchPhoneOnly.right(10);
                    String phoneFormat1 = tenDigitNumber.substring(0, 3) + '-' + tenDigitNumber.substring(3, 6) + '-' + tenDigitNumber.substring(tenDigitNumber.length() - 4) + '*';
                    Boolean isOnlyClosingOrOpeningBracketPresent = false;
                    if((phoneFormat1.split('[()]')).size() > 1){
                        if(!((phoneFormat1.split('[(]')).size() == (phoneFormat1.split('[)]')).size())){
                            isOnlyClosingOrOpeningBracketPresent = true;
                        }
                    }
                    if(!isOnlyClosingOrOpeningBracketPresent) {
                        filterKeyWord += '("' + phoneFormat1 + '")' + ' OR ';
                        filterKeyWord += '("' + phoneFormat1.replace('-', '*') +'")' + ' OR ';
                        filterKeyWord += '("' + phoneFormat1.replace('*', ' ') +'")';
                    }

                    isOnlyClosingOrOpeningBracketPresent = false;
                    if((tenDigitNumber.split('[()]')).size() > 1) {
                        if(!((tenDigitNumber.split('[(]')).size() == (tenDigitNumber.split('[)]')).size())){
                            isOnlyClosingOrOpeningBracketPresent = true;
                        }
                    }
                    if(!isOnlyClosingOrOpeningBracketPresent) {
                        filterKeyWord += (String.isBlank(filterKeyWord) ? '' : ' OR ') +'("' + '(' + tenDigitNumber.substring(0, 3) + ')' + tenDigitNumber.substring(3, 6) + '-' + tenDigitNumber.substring(tenDigitNumber.length() - 4) + '*")' + ' OR ';
                        filterKeyWord += '("' + tenDigitNumber + '*")';
                    }
                } else if(searchPhoneOnly != null) {
                    filterKeyWord = searchPhoneOnly;
                }
            }

            filterKeyWord += ((String.isBlank(filterKeyWord) ? '' : ' OR ') + '("' + searchKeyword + '*")');
            String searchQuery = 'FIND :filterKeyWord IN ALL FIELDS RETURNING Contact(Id, ' + String.join(getObjectFields('Contact'), ', ') + '), Lead(Id, ' + String.join(getObjectFields('Lead'), ', ') + ' WHERE IsConverted = false )';
            List<List<SObject>> lstSObjects = new List<List<SObject>>(Search.query(searchQuery));

            if(!lstSObjects.isEmpty()){
                searchResult.addAll(lstSObjects[0]);
                searchResult.addAll(lstSObjects[1]);
                Map<Id, sObject> mapOfRecords = new  Map<Id, sObject>(searchResult);
                if(!mapOfRecords.isEmpty()){
                    Sales_Console_Setting__mdt objJourneyCloseStages = SalesConsoleSettings.get('JourneyCloseStages');

                    Set<String> setOfJourneyCloseStages = (Set<String>)JSON.deserialize(objJourneyCloseStages.Data__c, Set<String>.class);
                    lstJourneys = journeySelector.getOpenJourneysByLeadOrContact(new List<Id>(mapOfRecords.keySet()), new List<String>(setOfJourneyCloseStages));
                }

            }
            return new DatabaseResult(new Map<String, List<sObject>>{'searchResult'=>searchResult, 'lstJourneys'=>lstJourneys});
        } catch(Exception pEx) {
            ApexDebugLog.logException(pEx, searchKeyword, 'InboundCallController', 'searchDataByKeyword');
            return new DatabaseResult(pEx);
        }
    }


    /************************************************************************************************************************************
        Author         : Dipak Pawar
        Description    : This method takes recordId as a parameter and returns the record details
        Created Date   : 7 January 2019
        Issue No.      : ST-2864
    **************************************************************************************************************************************/
   
    @AuraEnabled
    public static DatabaseResult getRecordById(Id recordId){
        try{
            String strObjectType = recordId.getSObjectType().getDescribe().getName();
            String strQuery = 'SELECT Id, ' + String.join(getObjectFields(strObjectType), ', ') + ' FROM ' + strObjectType + ' WHERE Id =: recordId';
            List<SObject> lstSObject = new List<SObject>(Database.query(strQuery));
            if(!lstSObject.isEmpty()){
                return new DatabaseResult(lstSObject[0]);
            }
            return null;
        }catch(Exception pEx) {
            ApexDebugLog.logException(pEx, recordId, 'InboundCallController', 'getRecordById');
            return new DatabaseResult(pEx);
        }
    }

    /************************************************************************************************************************************
        Author         : Dipak Pawar
        Description    : This method returns the object fields based on the given object type as a parameter
        Created Date   : 7 January 2019
        Issue No.      : ST-2864
    **************************************************************************************************************************************/
  
    public static List<String> getObjectFields(String objectType){
        Set<String> setFields = new Set<String>();
        switch on objectType {
            when 'Lead' {
                setFields.add('FirstName');
                setFields.add('LastName');
                setFields.add('Name');
                setFields.add('Email');
                setFields.add('Phone');
                setFields.add('Company');
                setFields.add('Number_of_Full_Time_Employees__c');
                setFields.add('Interested_in_Number_of_Desks__c');
                setFields.add('LeadSource');
                setFields.add('LeadSource_Sub_Type__c');
                setFields.add('Lead_Source_Detail__c');
                setFields.add('Building_Interested_In__c');
                setFields.add('Street');
                setFields.add('City');
                setFields.add('State');
                setFields.add('PostalCode');
                setFields.add('Country');
                setFields.add('RecordType.Name');
                setFields.add('Locations_Interested__c');
                setFields.add('Portfolio_Interested_In__c');
                setFields.add('Lead_Market__c');
                setFields.add('Lead_Market__r.Name');
                setFields.add('recordTypeId');
                setFields.add('Referrer__c');
            }
            when 'Contact' {
                setFields.add('AccountId');
                setFields.add('FirstName');
                setFields.add('LastName');
                setFields.add('Name');
                setFields.add('Email');
                setFields.add('Phone');
                setFields.add('Company__c');
                setFields.add('LeadSource');
                setFields.add('LeadSource_Sub_Type__c');
                setFields.add('Lead_Source_Detail__c');
                setFields.add('Location__c');
                setFields.add('MailingStreet');
                setFields.add('MailingCity');
                setFields.add('MailingState');
                setFields.add('MailingCountry');
                setFields.add('MailingPostalCode');
                setFields.add('RecordType.Name');

                //setFields.add('Location_Interested__c');
                //setFields.add('Number_of_Full_Time_Employees__c');
                //setFields.add('Interested_in_Number_of_Desks__c');
                //setFields.add('Portfolio_Interested_In__c');
                //setFields.add('Contact_Market__c');
                //setFields.add('Contact_Market__r.Name');
                setFields.add('Account.Name');
                setFields.add('recordTypeId');
                setFields.add('Referrer__c');
            }
            when 'Journey' {
                setFields.add('Name');
                setFields.add('NMD_Next_Contact_Date__c');
                setFields.add('Status__c');
                setFields.add('Primary_Phone__c');
                setFields.add('Referrer__c');
            }
        }
        return new List<String>(setFields);
    }

    /************************************************************************************************************************************
        Author         : Dipak Pawar
        Description    : This method returns the all Open and Closed Journeys related to Primary Lead/Contact
        Created Date   : 7 January 2019
        Issue No.      : ST-2864
    **************************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getJourneys(Id recordId){
        try{
            Set<String> setJourneyCloseStages = JourneyHelper.getJourneyCloseStages();
            String strQuery = journeySelector.getQueryWithLeadOrContact();

            Map<String, List<Journey__c>> mapJourneys = new Map<String, List<Journey__c>>();

            String strOpenJourneyQuery = strQuery + ' AND Status__c NOT IN :setJourneyCloseStages';
            mapJourneys.put('openJourneys', Database.query(strOpenJourneyQuery));

            String strClosedJourneyQuery = strQuery + ' AND Status__c IN :setJourneyCloseStages';
            mapJourneys.put('closedJourneys', Database.query(strClosedJourneyQuery));

            return new DatabaseResult(mapJourneys);
        }catch(Exception pEx) {
            ApexDebugLog.logException(pEx, recordId, 'InboundCallController', 'getJourneys');
            return new DatabaseResult(pEx);
        }
    }

    /************************************************************************************************************************************
        Author         : Dipak Pawar
        Description    : Method to create/re-use Journey for Primary Lead/Contact
        Created Date   : 7 January 2019
        Issue No.      : ST-2864
    **************************************************************************************************************************************/
   
    public static Lead objLeadToUpdate;
    public static Contact objContactToUpdate;
    @AuraEnabled
    public static DatabaseResult createOrUpdateJourney(Journey__c objJourney, Id primaryRecordId, sObject objJourneyRelatedRecord){
        try{
            objSavePoint = Database.setSavepoint();
            Journey__c objNewJourney = getDefaultMappings(objJourney, primaryRecordId);
            if(objParent != null){
                List<sObject> lstParentObject = new List<sObject>(getParentRecordOwner(objParent));
                Map<Id, Map<String, Journey__c>> mapJourneyCriterias = new Map<Id, Map<String, Journey__c>>();
                if(objParent.getSObjects('Journeys__r') != null && objParent.getSObjects('Journeys__r').size() > 0){
                    Map<String, Journey__c> mapUniqueJourneyResult = JourneyHelperUtility.checkIsUniqueJourney(objNewJourney, (List<Journey__c>)objParent.getSObjects('Journeys__r'));
                    mapJourneyCriterias.put(objParent.Id, mapUniqueJourneyResult);
                } else {
                    mapJourneyCriterias.put(objParent.Id, new Map<String, Journey__c>{'createNew' => null});
                }
                if(mapJourneyCriterias.containsKey(objParent.Id) && mapJourneyCriterias.get(objParent.Id) != null){
                    Map<String, Journey__c> mapCriteriaResult = mapJourneyCriterias.get(String.valueOf(objParent.get('Id')));
                    if(mapCriteriaResult.containsKey('createNew')){
                        objNewJourney.Status__c = 'Accepted';
                        objNewJourney.OwnerId = UserInfo.getUserId();
                    } else if(mapCriteriaResult.containsKey('reUse')){
                        objNewJourney =  mapCriteriaResult.get('reUse');
                    }
                    //This will be overrided by Field Mapping thats why we explicitly set it as NULL
                    if(objJourney.LeadSource_Sub_Type__c == null){
                        objNewJourney.LeadSource_Sub_Type__c = null;
                    }
                    if(objJourney.Referrer__c != null){
                        objNewJourney.Referrer__c = objJourney.Referrer__c;
                    }
                }
                if(!lstParentObject.isEmpty()){
                    Database.update(lstParentObject, false);
                }
                Database.UpsertResult journeySaveResult =  Database.upsert(objNewJourney);
                if (objJourneyRelatedRecord != null) {
                    UPDATE objJourneyRelatedRecord;
                }
                return new DatabaseResult(JSON.serialize(journeySaveResult));
            }
            return null;
        } catch(Exception pEx) {
            Database.rollback(objSavePoint);
            ApexDebugLog.logException(pEx, JSON.serialize(objJourney) + ', ' + primaryRecordId, 'InboundCallController', 'createOrUpdateJourney');
            return new DatabaseResult(pEx);
        }
    }

    /************************************************************************************************************************************
        Author         : Dipak Pawar
        Description    : Method for default mapping of Journey object
        Created Date   : 7 January 2019
        Issue No.      : ST-2864
    **************************************************************************************************************************************/
 
    public static Journey__c getDefaultMappings(Journey__c objJourney, Id primaryRecordId){
        try{
            Contact objContact;
            Lead objLead;
            Journey__c objNewJourney = new Journey__c();
            String strQuery, buildingCity;
            Map<String, Object> defaultMapping = new Map<String, Object>();

            List<String> lstJourneyFields = new List<String>(LeadRoutingHelper.getJourneyFields());
            Set<String> setJourneyClosedStages  = LeadRoutingHelper.getJourneyClosedStages();

            if(String.valueOf(primaryRecordId).startsWith('00Q')){
               List<String> lstLeadFields = new List<String>(LeadRoutingHelper.getLeadFields());
               strQuery = 'SELECT ' + String.join(lstLeadFields, ', ') + ', (SELECT '+ String.join(lstJourneyFields, ', ') +' FROM Journeys__r WHERE Status__c NOT IN : setJourneyClosedStages AND CreatedDate = TODAY ORDER BY LastModifiedDate DESC),(SELECT Id, Status, WhoId, WhatId FROM Tasks WHERE Status <> \'Completed\') From Lead WHERE IsConverted = false AND Id =: primaryRecordId ORDER BY CreatedDate';
                List<Lead> lstLeads = (List<Lead>)Database.query(strQuery);
                if(!lstLeads.isEmpty()){
                    objParent = lstLeads[0];
                    objLead = lstLeads[0];
                    objNewJourney = (Journey__c)FieldMappingsHelper.getMappings(objParent.Id, objJourney, 'FieldMappings_LeadToJourney');
                    objNewJourney.Primary_Lead__c = objLead.Id;
                    objNewJourney.Lead_Id__c = objLead.Id;
                    objNewJourney.Name = objLead.Name + '-' + getJourneyBuildingCity(objJourney.Building_Interested_In__c) + objJourney.Lead_Source__c;

                    if(objLead.Building_Interested_In__c != null){

                       //org objNewJourney.Locations_Interested__c = getLocationInterested(BuildingUtility.getBuildingById(objLead.Building_Interested_In__c) != null ? BuildingUtility.getBuildingById(objLead.Building_Interested_In__c).Name : null, BuildingUtility.getBuildingById(objJourney.Building_Interested_In__c) != null ? BuildingUtility.getBuildingById(objJourney.Building_Interested_In__c).Name : null);
                    } else {

                       //org objNewJourney.Locations_Interested__c = objJourney.Building_Interested_In__c;
                    }
                }
            } else if(String.valueOf(primaryRecordId).startsWith('003')){
                List<String> lstContactFields = new List<String>(LeadRoutingHelper.getContactFields());
                strQuery = 'SELECT ' + String.join(lstContactFields, ', ') + ', (SELECT '+ String.join(lstJourneyFields, ', ') +' FROM Journeys__r WHERE Status__c NOT IN : setJourneyClosedStages AND CreatedDate = TODAY ORDER BY LastModifiedDate DESC) FROM Contact WHERE Id =: primaryRecordId ORDER BY LastModifiedDate DESC';
                List<Contact> lstContacts = (List<Contact>)Database.query(strQuery);
                if(!lstContacts.isEmpty()){
                    objParent =  lstContacts[0];
                    objContact = lstContacts[0];
                    objNewJourney = (Journey__c)FieldMappingsHelper.getMappings(objParent.Id, objJourney, 'FieldMappings_ContactToJourney');

                    objNewJourney.Primary_Contact__c = objContact.Id;
                    objNewJourney.Name = objContact.Name + '-' + getJourneyBuildingCity(objJourney.Building_Interested_In__c) + objJourney.Lead_Source__c;

                    /*org if(String.isNotBlank(objContact.Location__c)){
                        objNewJourney.Locations_Interested__c = getLocationInterested(objContact.Location_Interested__c, BuildingUtility.getBuildingById(objJourney.Building_Interested_In__c) != null ? BuildingUtility.getBuildingById(objJourney.Building_Interested_In__c).Name : null);
                    }*/
                }
            }

            objNewJourney.NMD_Next_Contact_Date__c = getJourneyNMDContactDate();
            return objNewJourney;
        } catch(Exception pEx) {
            ApexDebugLog.logException(pEx, JSON.serialize(objJourney), 'InboundCallController', 'getDefaultMappings');
            return null;
        }
    }

    /************************************************************************************************************************************
        Author         : Dipak Pawar
        Description    : Method to get Building City for given buildingId a a parameter
        Created Date   : 7 January 2019
        Issue No.      : ST-2864
    **************************************************************************************************************************************/
 
    public static String getJourneyBuildingCity(Id journeyRelatedBuildingId){
        try{
            String buildingCity;
            Building__c journeyBuilding = BuildingUtility.getBuildingById(journeyRelatedBuildingId);
            if(journeyBuilding != null){
                return journeyBuilding.City__c + '-';
            }
            return '';
        } catch(Exception pEx) {
            ApexDebugLog.logException(pEx, journeyRelatedBuildingId, 'InboundCallController', 'getDefaultMappings');
            return null;
        }
    }

    /************************************************************************************************************************************
        Author         : Dipak Pawar
        Description    : Method for map the owner of Journey Primary Lead/Contact(If Lead/Contact owner is API user)
        Created Date   : 7 January 2019
        Issue No.      : ST-2864
    **************************************************************************************************************************************/
   
    public static List<sObject> getParentRecordOwner(sObject objParent){
        try{
            Sales_Console_Setting__mdt objSetting = SalesConsoleSettings.get('APIUserContactInfo');

            Map<String, String> apiUserSettings = new Map<String, String>();
            List<sObject> lstParentRecord;
            if(objSetting != null){
                apiUserSettings = (Map<String, String>)JSON.deserialize(objSetting.Data__c, Map<String, String>.class);
                lstParentRecord = new List<sObject>();
                Id apiUserId = apiUserSettings.containsKey('UserId') ? Id.valueOf(apiUserSettings.get('UserId')) : null;
                if(String.valueOf(objParent.getSObjectType()).equalsIgnoreCase('Lead') && Id.valueOf(String.valueOf(objParent.get('OwnerId'))) == apiUserId){
                    lstParentRecord.add(new Lead(Id = String.valueOf(objParent.get('Id')), OwnerId = UserInfo.getUserId()));
                } else if(String.valueOf(objParent.getSObjectType()).equalsIgnoreCase('Contact') && Id.valueOf(String.valueOf(objParent.get('OwnerId'))) == apiUserId){
                    lstParentRecord.add(new Contact(Id = String.valueOf(objParent.get('Id')), OwnerId = UserInfo.getUserId()));
                }
            }
            return lstParentRecord;
        } catch(Exception pEx) {
            ApexDebugLog.logException(pEx, JSON.serialize(objParent), 'InboundCallController', 'getParentRecordOwner');
            return null;
        }
    }

    /************************************************************************************************************************************
        Author         : Dipak Pawar
        Description    : Method to get Next NMD contact Date for Journey
        Created Date   : 7 January 2019
        Issue No.      : ST-2864
    **************************************************************************************************************************************/
  
    public static Date getJourneyNMDContactDate(){
        try{
            Date journeyNMDContactDate = Date.today();
            MetadataSetting__mdt objMetadataSetting = Settings.getMetadataSettingByDevName('JourneyNextNMDDateCriteria');
            if(objMetadataSetting != null){
                Map<String, Integer> mapNextNMDNDays = (Map<String, Integer>)JSON.deserialize(objMetadataSetting.Data__c, Map<String, Integer>.class);
                if(mapNextNMDNDays.containsKey('NextCallINDaysFromLeadCreation')){
                    journeyNMDContactDate = DateUtilities.addBusinessDays(Date.today(), mapNextNMDNDays.get('NextCallINDaysFromLeadCreation'));
                }
            }
            return journeyNMDContactDate;
        } catch(Exception pEx) {
            ApexDebugLog.logException(pEx, '', 'InboundCallController', 'getJourneyNMDContactDate');
            return null;
        }
    }

    /************************************************************************************************************************************
        Author         : Jitesh Adwani
        Description    : Method to save Lead/Contact from Inbound Call page
        Created Date   : 28 January 2019
        Issue No.      : ST-2864
    **************************************************************************************************************************************/
   
    @AuraEnabled
    public static DatabaseResult saveLead(Lead objLead) {
        try{
            objSavePoint = Database.setSavepoint();
            if(String.isNotBlank(objLead.Building_Interested_In__c)){
                objLead.Locations_Interested__c = getLocationInterested(objLead.Locations_Interested__c, BuildingUtility.getBuildingById(objLead.Building_Interested_In__c).Name);
            }
            Database.UpsertResult upsertResult = Database.upsert(objLead);
            return new DatabaseResult(upsertResult.isSuccess());
        } catch(Exception pEx) {
            if(objSavePoint != null){
                Database.rollback(objSavePoint);
            }
            ApexDebugLog.logException(pEx, JSON.serialize(objLead), 'InboundCallController', 'saveLead');
            return new DatabaseResult(pEx);
        }
    }

    /************************************************************************************************************************************
        Author         : Jitesh Adwani
        Description    : Method to save Lead/Contact from Inbound Call page
        Created Date   : 28 January 2019
        Issue No.      : ST-2864
		Modified By	   : Rupesh Patil
    **************************************************************************************************************************************/
  
    @AuraEnabled
    public static DatabaseResult saveContact(Contact objContact) {
        try{
            objSavePoint = Database.setSavepoint();
            Boolean isSuccess = false, isAccountToUpdate = false;
            /*if(String.isNotBlank(objContact.Location__c)){
                //objContact.Location_Interested__c = getLocationInterested(objContact.Location_Interested__c, BuildingUtility.getBuildingById(objContact.Location__c).Name);
            }*/

            Database.SaveResult saveresult = Database.update(objContact);
            isSuccess = saveresult.isSuccess();

            Account objAccount = new Account(Id = objContact.AccountId);
            /*if(objContact.Number_of_Full_Time_Employees__c != null){
                objAccount.Number_of_Full_Time_Employees__c = objContact.Number_of_Full_Time_Employees__c;
                isAccountToUpdate = true;
            }
            if(objContact.Interested_in_Number_of_Desks__c != null){
                objAccount.Interested_in_Number_of_Desks__c = objContact.Interested_in_Number_of_Desks__c;
                isAccountToUpdate = true;
            }*/
            if(String.isNotBlank(objContact.MailingStreet)){
                objAccount.BillingStreet = objContact.MailingStreet;
                isAccountToUpdate = true;
            }
            if(String.isNotBlank(objContact.MailingCity)){
                objAccount.BillingCity = objContact.MailingCity;
                isAccountToUpdate = true;
            }
            if(String.isNotBlank(objContact.MailingState)){
                objAccount.BillingState = objContact.MailingState;
                isAccountToUpdate = true;
            }
            if(String.isNotBlank(objContact.MailingCountry)){
                objAccount.BillingCountry = objContact.MailingCountry;
                isAccountToUpdate = true;
            }
            if(String.isNotBlank(objContact.MailingPostalCode)){
                objAccount.BillingPostalCode = objContact.MailingPostalCode;
                isAccountToUpdate = true;
            }
            List<Account> lstAccounts = new List<Account> ();
            if(isAccountToUpdate){
                lstAccounts = [SELECT Id, Number_of_Full_Time_Employees__c, Interested_in_Number_of_Desks__c, BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode FROM Account Where Id =: objContact.AccountId];           
            }
            if(!lstAccounts.isEmpty()){
                Account objTempAcc = lstAccounts[0];
                if(
                   Settings.isChanged((String)objContact.get('MailingStreet'), (String)objTempAcc.get('BillingStreet')) || 
                   Settings.isChanged((String)objContact.get('MailingCity'), (String)objTempAcc.get('BillingCity')) || 
                   Settings.isChanged((String)objContact.get('MailingState'), (String)objTempAcc.get('BillingState')) || 
                   Settings.isChanged((String)objContact.get('MailingCountry'), (String)objTempAcc.get('BillingCountry')) ||
                   Settings.isChanged((String)objContact.get('MailingPostalCode'), (String)objTempAcc.get('BillingPostalCode'))){
                       objAccount.FTE_and_HQ_Updated_From__c = 'Inbound Lead - Edit Contact Modal'; // Requirement of ST-4906. Used only to bypass 'Restrict_FTE_and_HQ_Address_Updates' validation   
                   }                  
            } 
            if(isAccountToUpdate){
                saveresult = Database.update(objAccount);
                isSuccess = saveresult.isSuccess();
            }
            return new DatabaseResult(isSuccess);
        } catch(Exception pEx) {
            if(objSavePoint != null){
                Database.rollback(objSavePoint);
            }
            ApexDebugLog.logException(pEx, JSON.serialize(objContact), 'InboundCallController', 'saveContact');
            return new DatabaseResult(pEx);
        }
    }

/************************************************************************************************************************************
        Author         : Jitesh Adwani
        Description    : This method is used to create set of location interested with ; seprated
        Created Date   : 28 January 2019
        Issue No.      : ST-2864
**************************************************************************************************************************************/

static String getLocationInterested(String strOldLocations, String strNewLocation){
        if(String.isNotBlank(strOldLocations)){
            Set<String> setLocationInterested = new Set<String>(strOldLocations.split(';'));
            setLocationInterested.add(strNewLocation);
            return String.join(new List<String>(setLocationInterested), ';');
        }
        return strNewLocation;
}

/************************************************************************************************************************************
        Author         : Jitesh Adwani
        Description    : This method is use to call Ligtningcomponentcontroller for Search logic
        Created Date   : 12 July 2019
        Issue No.      : ST-4117
**************************************************************************************************************************************/

    @AuraEnabled
    public static DatabaseResult getReferrerRecords(String keyword){
        return getReferrerRecords(keyword, null);
    }
    @AuraEnabled
    public static DatabaseResult getReferrerRecords(String keyword, String recordId){
        Map<Id, sObject> mapRecords = new  Map<Id, sObject>();
        mapRecords.putAll(LightningComponentController.getRecordsData(keyword, new List<String>{'Contact'}, 'Email, Account.Name, Type__c', new List<String>{'Name', 'Email'}, 'Type__c = \'Broker\'', '', 10));
        if(mapRecords.size() < 10){
            mapRecords.putAll(LightningComponentController.getRecordsData(keyword, new List<String>{'Contact'}, 'Email, Account.Name, Type__c', new List<String>{'Name', 'Email'}, '', '', 10));
        }
        List<Contact> lstContact = new List<Contact>();
        for(Contact objCon : (List<Contact>)mapRecords.values()){
            if(lstContact.size() < 10){
                if(String.isBlank(recordId) || (String.isNotBlank(recordId) && recordId.startsWith('003') && Id.valueOf(recordId) != objCon.Id)){
                    lstContact.add(objCon);
                }
            }else{
                break;
            }
        }
        return new DatabaseResult(lstContact);
    }

    /************************************************************************************************************************************
        Author         : Rohit Nimase
        Description    : This method is use to check is contact present with email or not
        Created Date   : 3 March 2020
        Issue No.      : ST-5985
	**************************************************************************************************************************************/
    @AuraEnabled
    public static Boolean isContactPresentWithEmail(String contactEmail){
        List<Contact> lstContact = [SELECT Id FROM Contact WHERE Email =: contactEmail];
        return !lstContact.isEmpty();
    }
}