/************************************************************************************************************************************
  Author        : Dipak Pawar
  Description   :

  History:
----------------------------------------------------------------------------------------------------------------------------------
  VERSION       DATE                AUTHOR              DETAIL                  ISSUE
    1           5th June 2018       Dipak Pawar         Initial Developement    ST-
**************************************************************************************************************************************/
public class OpportunityHelper {
    public static List<OpportunityTeamMember> lstOpportunityTeamMembers = new List<OpportunityTeamMember>();
    public static List<Journey__c> lstJourneys;
    private static Map<String, Object> fieldsMap = new Map<String, Object>();
    @TestVisible
    private static JourneySelector journeySelector = new JourneySelector();

    /************************************************************************************************************************************
        Author              :   Dipak Pawar
        Description         :   This method return the latest open Opportunity by given AccountId or Primary ConatactId for the given building
        Created Date        :   05 June 2018
        Issue No            :   ST-2484, ST-2486
    **************************************************************************************************************************************/
    public static Journey__c objPayloadJourney;

    /************************************************************************************************************************************
        Author              :   Dipak Pawar
        Description         :   This method return the latest open Opportunity by given AccountId or Primary ConatactId for the given building
        Created Date        :   05 June 2018
        Issue No            :   ST-2484
        Modify by           :   Ashish Mishra
        Issue No            :   ST-2743
    **************************************************************************************************************************************/
    public static Opportunity getLatestOpenOpportunity(Id accountId, Id contactId, Building__C objBuilding) {//Object buildingName
        Sales_Console_Setting__mdt openOppStages = SalesConsoleSettings.get('OpenOpportunityStages');
        Set<String> setOpenOppStages = new Set<String>();
        List<Opportunity> openOpportunities;
        if (openOppStages != null && openOppStages.Data__c != null) {
            setOpenOppStages = (Set<String>)JSON.deserialize(openOppStages.Data__c, Set<String>.class);
        }
        if (setOpenOppStages != null && accountId != null) {
            openOpportunities = new List<Opportunity>([SELECT Id, RecordTypeId, Building__c, Building__r.Name,
                                                            Primary_Member__c, Building__r.Cluster_Name__c,
                                                            Building__r.Territory_Name__c, Building__r.Region_Name__c,
                                                            Building__r.Portfolio_Name__c, Locations_Interested__c,
                                                            CreatedDate, LastModifiedDate, StageName, Tour_Booked_By__c,
                                                            Journey__c, Interested_in_Number_of_Desks__c
                                                        FROM Opportunity
                                                        WHERE AccountId = :accountId
                                                            AND StageName IN :setOpenOppStages
                                                        ORDER BY LastModifiedDate DESC]);
        }
        if (openOpportunities.size() > 0 ) {
            for (Opportunity objOpportunity : openOpportunities) {
                if (contactId != null && objOpportunity.Primary_Member__c == contactId && objOpportunity.Building__c != null) {
                    if (objOpportunity.Building__r.Name.equalsIgnoreCase(objBuilding.Name)) {return objOpportunity;}
                    else if (String.isNotBlank(objOpportunity.Building__r.Cluster_Name__c) && objOpportunity.Building__r.Cluster_Name__c.equalsIgnoreCase(objBuilding.Cluster_Name__c)) {return objOpportunity;}
                    else if (String.isNotBlank(objOpportunity.Building__r.Portfolio_Name__c) && objOpportunity.Building__r.Portfolio_Name__c.equalsIgnoreCase(objBuilding.Portfolio_Name__c)) {return objOpportunity;}
                }
            }
        }
        return null;
    }

    /************************************************************************************************************************************
        Author              :   Dipak Pawar
        Description         :   This method create an Opportunity for the given contact.
        Created Date        :   05 June 2018
        Issue No            :   ST-2486
    **************************************************************************************************************************************/
    public static Opportunity createOpportunity(Id contactId, String stageName) {
        Opportunity objOpportunity = new Opportunity();
        objOpportunity = (Opportunity)FieldMappingsHelper.getMappings(contactId, objOpportunity, 'FieldMappings_ContactToOpportunity');
        return updateContactDetailsOnOpportunity(contactId, objOpportunity, stageName);
    }

    public static Opportunity createOpportunity(Id journeyId, Id contactId, String stageName) {
        Opportunity objOpportunity = new Opportunity();
        objOpportunity = (Opportunity)FieldMappingsHelper.getMappings(journeyId, objOpportunity, 'FieldMappings_JourneyToOpportunity');
        return updateContactDetailsOnOpportunity(contactId, objOpportunity, stageName);
    }

    public static Opportunity updateContactDetailsOnOpportunity(Id contactId, Opportunity objOpportunity, String stageName) {
        List<Contact> objContact = new List<Contact>([SELECT Id, RecordType.Name, AccountId,Account.Name, Account.RecordType.Name, Account.OwnerId, Account.Interested_in_Number_of_Desks__c FROM Contact WHERE Id = :contactId LIMIT 1]);
        if (objContact.size() > 0 && objOpportunity != null) {
            // Contact To Opportunity field mappings ST-2490
            objOpportunity.StageName = stageName;
            objOpportunity.AccountId = objContact[0].AccountId;
            objOpportunity.CloseDate = System.today();
            objOpportunity.Name = 'New Opportunity';
            objOpportunity.Primary_Member__c = objContact[0].Id;
            if (objContact[0].Account != null && objContact[0].Account.RecordType != null && Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(objContact[0].Account.RecordType.Name) != null ) {
                objOpportunity.RecordTypeId = (objContact[0].Account.RecordType.Name != 'Referral') ? Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(objContact[0].Account.RecordType.Name).getRecordTypeId() : Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Consumer').getRecordTypeId();
            }
        }
        return objOpportunity;
    }

    /************************************************************************************************************************************
        Author              : Rupesh Patil
        Description         : This method is used to create Opportunity in the Community View page
        Issue No            : ST-2385
        Created Date        : 19 May 2018
    **************************************************************************************************************************************/
   
    public static opportunity createOpportunity(Id contactId, object noOfDesks, Id buildingID) {
            Opportunity newOpportunity = new Opportunity();
            newOpportunity = (Opportunity)FieldMappingsHelper.getMappings(contactId, newOpportunity, 'FieldMappings_ContactToOpportunity');
            Contact objContact = [SELECT Id, Name, AccountId, Account.OwnerId, Account.Primary_Member__r.Name, Promo_Code__c FROM Contact WHERE Id =: contactId];
            newOpportunity.Name = 'Community View Opportunity';
            if (objContact.Account.OwnerId != null) {
                newOpportunity.OwnerId = objContact.Account.OwnerId;
            }
            newOpportunity.StageName = GlobalConstants.OPPORTUNITY_STAGE_QUALIFYING;
            newOpportunity.AccountId = objContact.AccountId;
            newOpportunity.Primary_Member__c = objContact.Id;
            newOpportunity.CloseDate = System.today();
            newOpportunity.Interested_in_Number_of_Desks__c = newOpportunity.Interested_in_Number_of_Desks__c != null ? newOpportunity.Interested_in_Number_of_Desks__c : (String.isNotBlank(String.valueOf(noOfDesks)) && Integer.valueOf(noOfDesks) > 0) ? Integer.valueOf(noOfDesks) : null;
            newOpportunity.Building__c = buildingID;
            newOpportunity.Promo_Code__c = objContact.Promo_Code__c;
            insert newOpportunity;
            return newOpportunity;
    }

    /************************************************************************************************************************************
        Author              :   Dipak Pawar
        Description         :   This method create an Enterprise Opportunity for the given contact.
        Created Date        :   07 June 2018
        Issue No            :   ST-2486
        Modified by         :   Ashish Mishra
        Modified Date       :   7 July 2018
    **************************************************************************************************************************************/
    public static Opportunity createOpportunity(Opportunity objOpportunity) {
        objOpportunity.Name = 'Opportunity Name';
        if (objOpportunity.get('AccountId') != null && String.isNotBlank(String.valueOf(objOpportunity.get('AccountId')))) {
            // Opportunity record type = Account record type
            Account account = new AccountSelector().getAccountsById(new List<Id>{(Id)objOpportunity.get('AccountId')})?.get(0);
            if (account != null && account.RecordType != null && Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(account.RecordType.Name) != null) {
                objOpportunity.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(account.RecordType.Name).getRecordTypeId();
            }
        }
         if (String.isNotBlank(objOpportunity.Journey__c)) {
            objOpportunity = (Opportunity)FieldMappingsHelper.getMappings(objOpportunity.Journey__c, objOpportunity, 'FieldMappings_JourneyToOpportunity');
        }
        // Contact To Opportunity field mappings ST-2491
        else {
            Id contactId = objOpportunity.Primary_Member__c != null ? objOpportunity.Primary_Member__c : objOpportunity.Decision_Maker__c != null ? objOpportunity.Decision_Maker__c : null;
            if (contactId != null) {
            objOpportunity = (Opportunity)FieldMappingsHelper.getMappings(contactId, objOpportunity, 'FieldMappings_ContactToOpportunity');
        }
        }
        // Bypass the Opportunity auto owner assignments for profiles mentioned in "AccountMergeSettings" settings
        Map<String, Set<String>> accountMergeSettings = (Map<String, Set<String>>)JSON.deserialize(SalesConsoleSettings.get('AccountMergeSettings').Data__c.toLowerCase(), Map<String, Set<String>>.class);
        Set<String> setProfiles = accountMergeSettings.get('profiles');

        List<Profile> lstProfile = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
        String myProflieName = lstProfile[0].Name;
        //if (!setProfiles.contains(String.valueOf(UserUtility.getUserById(UserInfo.getUserId()).profile.Name).toLowerCase())) {
        if (!setProfiles.contains(myProflieName.toLowerCase())) {
            objOpportunity.OwnerId = UserInfo.getUserId();
        }
        return objOpportunity;
    }

    /************************************************************************************************************************************
        Author              :   Shobhit Gahlot
        Description         :   This method returns a set of values for picklist.
        Created Date        :   11 June 2018
        Issue No            :
    **************************************************************************************************************************************/
    public static Set<String> getUniquePickListValues(String pickList, Set<String> newValues) {
        Set<String> setOldPickListValues;
        if (newValues.size() > 0) {
            if (String.isNotBlank(pickList)) {
                List<String> lstOldPickListValues = pickList.Split(';');
                setOldPickListValues = new Set<String>(lstOldPickListValues);
                for (String newPickListValue: newValues) {
                    if (!setOldPickListValues.contains(newPickListValue)) {
                        setOldPickListValues.add(newPickListValue);
                    }
                }
            }
        }
        return setOldPickListValues;
    }

    /************************************************************************************************************************************
        Author              :   Dipak Pawar
        Description         :   This method is used to get lower size from company size range.
        Created Date        :   21 June 2018
    **************************************************************************************************************************************/
    public static Integer getLowerSize(String strCompanySize) {
        if (String.isNotBlank(strCompanySize)) {
            Integer lowerSize;
            strCompanySize = strCompanySize.replace(',','');
            strCompanySize = strCompanySize.replace('desks','');
            strCompanySize = strCompanySize.replace('desk','');
            strCompanySize = strCompanySize.replace('<','');
            strCompanySize = strCompanySize.deleteWhitespace();
            if (strCompanySize.contains('-')) {
                lowerSize = Integer.valueOf(strCompanySize.split('-')[0]);
            } else if (strCompanySize.contains('+')) {
                lowerSize = Integer.valueOf(strCompanySize.split('\\+')[0]);
            } else {
                lowerSize = Integer.valueOf(strCompanySize);
            }
            return lowerSize;
        }
        return 0;
    }

    /*****************************************************************************************************************************************
        Author              :   Pragalbha Mahajan
        Description         :   This method is used to return appropriate journey according to building, contact and status
        Created Date        :   25 June 2019
    ******************************************************************************************************************************************/
    public static Journey__c getJourneyForMapping(Building__c objBuilding, Id contactId, Boolean isMappingToOpportunity) {
        Journey__c objOppJourney;
        Set<String> setJourneyCloseStages = JourneyHelper.getJourneyCloseStages();
        Map<Id, Set<String>> mapJourneyIdToLocationInterested = new Map<Id, Set<String>>();
        if (OpportunityHelper.lstJourneys == null) {
            lstJourneys = new List<Journey__c>(journeySelector.getOpenJourneysByPrimaryContact(contactId, new List<String>(setJourneyCloseStages)));
        }
        Journey__c objLatestModifiedJourney = LeadTriggerHandler.objLatestModifiedJourney;
        if (objBuilding != null) {
            for (Journey__c objJourney : OpportunityHelper.lstJourneys) {
                if (objBuilding != null && objJourney.Building_Interested_In__c == objBuilding.Id) {
                    if (objLatestModifiedJourney != null && objLatestModifiedJourney.Building_Interested_In__c == objBuilding.Id) {
                        objOppJourney = objLatestModifiedJourney;
                    } else {
                        objOppJourney = objJourney;
                    }
                    break;
                }
            }
        }
        return objOppJourney;
    }

    public static void updateDataFromRelatedObject(sObject sourceObject, sObject destinationObject) {
        if(fieldsMap.isEmpty()) {
            getBuildingsToOpportunityMapping();
        }
        if(fieldsMap.isEmpty()){
            return;
        }
        for(String destinationField : fieldsMap.keySet()) {
            String sourceField = String.valueOf(fieldsMap.get(destinationField));
            if(sourceObject == null){
                destinationObject.put(destinationField, null);
                continue;
            }
            if (String.isNotBlank(sourceField)) {
                if (sourceField.contains('.')) {
                    destinationObject.put(destinationField, Settings.getParentFieldValue(sourceObject, sourceField));
                } else {
                    destinationObject.put(destinationField, sourceObject.get(sourceField));
                }
            }
        }
    }

    private static void getBuildingsToOpportunityMapping() {
        MetadataSetting__mdt metadataRecord = Settings.getMetadataSettingByDevName('Map_Building_Data_To_Opportunity');
        if(metadataRecord != null && String.isNotBlank(metadataRecord.Data__c)) {
            fieldsMap = (Map<String, Object>)JSON.deserializeUntyped(metadataRecord.Data__c);
        }
    }
}