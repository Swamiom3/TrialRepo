/*****************************************************************************************************************************
    Author      :  Krishana Tupe  
    Description :  This Utility class contains the utility methods related to Journey Helper
    History     :  --
    
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION                 DATE            ISSUE       AUTHOR                          DETAIL
    1                       28 Nov 2018      -          Krishana Tupe                   Initial Developement
    2                       12 Dec 2021      -          Pawel Biszczak                  Fixes and small refactor
******************************************************************************************************************************/
public class JourneyHelperUtility {
    private static Set<String> journeyMatchingFieldsSet;
    @TestVisible
    private static JourneySelector journeySelector = new JourneySelector();
    @TestVisible
    private static BuildingSelector buildingSelector = new BuildingSelector();
    @TestVisible
    private static PortfolioSelector portfolioSelector = new PortfolioSelector();

    public static void createJourney(List<Map<String, sObject>> parents, List<Id> leadsToBeDeleted) {
        if (parents != null && (parents[0].get('contact') != null || parents[0].get('newlead') != null || parents[0].get('lead') != null)) {
            Set<Id> newParentIds = new Set<Id>();
            for (Map<String, sObject> parentToObject : parents) {
                Lead primaryParentRecord = (Lead) (parentToObject.containsKey('newlead') ? parentToObject.get('newlead') : parentToObject.get('lead'));
                newParentIds.add(primaryParentRecord.Id);
            }
            Map<Id, sObject> journeysToIds = FieldMappingsHelper.getMappings(newParentIds, 'FieldMappings_LeadToJourney');
            Map<String, Map<String, Journey__c>> journeyCriteriaMap = checkJourneyCreationCriteria(parents, journeysToIds);
            Map<Id, Map<String, sObject>> journeysWithAssignmentMap = new Map<Id, Map<String, sObject>>();
            Map<Id, Map<String, sObject>> journeysParentsForToIdsMap = new Map<Id, Map<String, sObject>>();
            for (Map<String, sObject> parentToObject : parents) {
                Lead primaryParentRecord = (Lead) (parentToObject.containsKey('newlead') ? parentToObject.get('newlead') : parentToObject.get('lead'));
                if (primaryParentRecord.Generate_Journey__c) {
                    sObject parent = parentToObject.containsKey('contact') ? parentToObject.get('contact') : parentToObject.get('lead');
                    Map<String, Journey__c> mapCriteriaResult = journeyCriteriaMap.get(parent.Id);
                    Boolean isCreateNew = mapCriteriaResult.containsKey('createNew');
                    if (isCreateNew || (isCreateNew && primaryParentRecord.By_Pass_Journey_Creation_Criteria__c)) {
                        journeysWithAssignmentMap.put(primaryParentRecord.Id, parentToObject);
                    } else if (!isCreateNew) {
                        journeysParentsForToIdsMap.put(String.valueOf(parent.get('Id')), parentToObject);
                    }
                }
            }
            Map<Id, Journey__c> journeysForUpsertToIdsMap = new Map<Id, Journey__c>();
            Map<Id, Id> mapAssignments = new Map<Id, Id>();

            //within 1 day reuse journey
            if (!journeysParentsForToIdsMap.isEmpty()) {
                updateExistingJourneys(journeysParentsForToIdsMap, journeysForUpsertToIdsMap, mapAssignments, journeyCriteriaMap);
            }
            //beyond 1 day create new journey
            if (!journeysWithAssignmentMap.isEmpty()) {
                JourneyHelper.createJourneyWithAssignment(journeysWithAssignmentMap, journeysForUpsertToIdsMap, mapAssignments, journeysToIds);
            }
            if (!journeysForUpsertToIdsMap.isEmpty()) {
                //commented until Lead creation bug fix
                //updateJourneyRegionAndTerritory(journeysForUpsertToIdsMap);
                upsert journeysForUpsertToIdsMap.values();
                for (Id newLeadId : journeysForUpsertToIdsMap.keySet()) {
                    if (mapAssignments.containsKey(newLeadId) && mapAssignments.get(newLeadId) == null) {
                        mapAssignments.put(newLeadId, journeysForUpsertToIdsMap.get(newLeadId).Id);
                    }
                }
            }

            if (LeadRoutingHelper.mapJourneysWithLeadOrContactIds.size() > 0) {
                mapAssignments.putAll(LeadRoutingHelper.mapJourneysWithLeadOrContactIds);
            }
            if ((!System.isBatch() || (UserInfo.getUserId() == Id.valueOf(Label.LeanData_API_User))) && mapAssignments.size() > 0) {
                JourneyHelper.updateJourneyOwner(JSON.serialize(mapAssignments), JSON.serialize(leadsToBeDeleted));
            } else if ((!System.isBatch() || (UserInfo.getUserId() == Id.valueOf(Label.LeanData_API_User))) && leadsToBeDeleted.size() > 0) {
                Database.delete(leadsToBeDeleted, false);
            }
        }
    }

    /* public static void updateJourneyRegionAndTerritory(Map<Id, Journey__c> journeysForUpsertToIdsMap){
        if (journeysForUpsertToIdsMap.isEmpty()) {
            return;
        }
        Set<Id> buildingIds = new Set<Id>();
        Set<Id> marketIds = new Set<Id>();
        Map<Id, Building__c> buildings = new  Map<Id, Building__c>();
        Map<Id, Market__c> markets = new  Map<Id, Market__c>();
        for (Journey__c journey : journeysForUpsertToIdsMap.values()) {
            if(String.isNotBlank(journey.Building_Interested_In__c)) {
                buildingIds.add(journey.Building_Interested_In__c);
            }
            if(String.isNotBlank(journey.Portfolio_Interested_In__c)) {
                marketIds.add(journey.Portfolio_Interested_In__c);
            }
        }
        if (!buildingIds.isEmpty()) {
            buildings = new Map<Id, Building__c>(buildingSelector.getBuildingRegionAndTerritory(buildingIds)); 
        } else if (!marketIds.isEmpty()) {
            markets = new Map<Id, Market__c>(portfolioSelector.getPortfolioRegionAndTerritory(marketIds));
        } else {
            return;
        }
        for (Journey__c journey : journeysForUpsertToIdsMap.values()) {
            Building__c journeyRelatedBuilding = buildings.get(journey.Building_Interested_In__c);
            Market__c journeyRelatedMarket = markets.get(journey.Portfolio_Interested_In__c);
            if (journeyRelatedMarket != null && String.isNotBlank(journeyRelatedMarket.Region__c) && String.isNotBlank(journeyRelatedMarket.Territory__c)) {
                journey.Region__c = journeyRelatedMarket.Region__c;
                journey.Territory__c = journeyRelatedMarket.Territory__c;
                continue;
            }
            if (journeyRelatedBuilding != null && String.isNotBlank(journeyRelatedBuilding.Market__c)) {
                journey.Portfolio_Interested_In__c = journeyRelatedBuilding.Market__c;
            } else {
                continue;
            }
            if (String.isNotBlank(journeyRelatedBuilding.Market__r.Region__c)) {
                journey.Region__c = journeyRelatedBuilding.Market__r.Region__c;
            }
            if (String.isNotBlank(journeyRelatedBuilding.Market__r.Territory__c)) {
                journey.Territory__c = journeyRelatedBuilding.Market__r.Territory__c;
            }
        } 
    } */

    public static void updateJourneyOwner(Set<Id> leadsIdsSet, List<Id> leadsIdsList) {
        List<Journey__c> journeysToUpdate = prepareJourneysToUpdate(leadsIdsSet);
        if (!journeysToUpdate.isEmpty()) {
            Database.update(journeysToUpdate, false);
        }
        if (leadsIdsList != null && !leadsIdsList.isEmpty()) {
            Database.delete(leadsIdsList, false);
        }
    }

    public static List<Journey__c> prepareJourneysToUpdate(Set<Id> leadsIdsSet) {
        if (leadsIdsSet == null || leadsIdsSet.isEmpty()) {
            return new List<Journey__c>();
        }
        Map<Id, Lead> leadsMap = new Map<Id, Lead>([ SELECT Id, OwnerId
                                                     FROM Lead
                                                     WHERE Id IN :leadsIdsSet ]);
        List<String> fields = new List<String>{'Id', 'Lead_Id__c', 'OwnerId'};
        List<Journey__c> journeys = journeySelector.getJourneysCreatedTodayByLeadIds(fields, new List<Id>(leadsIdsSet));
        return (!journeys.isEmpty()) ? prepareJourneys(journeys, leadsMap) :
                new List<Journey__c>();
    }

    public static List<Journey__c> prepareJourneys(List<Journey__c> journeys, Map<Id, Lead> leadsMap) {
        MetadataSetting__mdt metadataRecord = Settings.getMetadataSettingByDevName('Unassigned_NMD_US_Queue');
        String unassignedQueueId = String.valueOf(metadataRecord.Data__c);
        Id strHoldBackQueueId = LeadConverterHelper.getHoldBackQueueId();
        List<Journey__c> journeysToUpdate = new List<Journey__c>();

        for (Journey__c journeyRecord : journeys) {
            Lead primaryLead = leadsMap.containsKey(journeyRecord.Lead_Id__c) ? leadsMap.get(journeyRecord.Lead_Id__c) : null;
            Id apiUserId = ApiUsersUtils.apiUserId;
            if (primaryLead != null) {
                if ((primaryLead.OwnerId != apiUserId) && UserUtility.getUserActive(primaryLead.OwnerId)) {
                    journeyRecord.OwnerId = primaryLead.OwnerId;
                } else if ((primaryLead.OwnerId == apiUserId) && !UserUtility.getUserActive(journeyRecord.OwnerId)) {
                    journeyRecord.OwnerId = unassignedQueueId;
                } else if (journeyRecord.OwnerId == strHoldBackQueueId || journeyRecord.OwnerId == apiUserId) {
                    journeyRecord.OwnerId = unassignedQueueId;
                }
                if (journeyRecord.OwnerId != null && OrganizationHelper.isUser(journeyRecord.OwnerId)) {
                    journeyRecord.Status__c = 'Accepted';
                }
                journeysToUpdate.add(journeyRecord);
            }
        }
        return journeysToUpdate;
    }

    public static void updateExistingJourneys(Map<Id, Map<String, sObject>> mapParents, Map<Id, Journey__c> journeysForUpsertToIdsMap, Map<Id, Id> mapAssignments, Map<String, Map<String, Journey__c>> journeyCriteriaMap) {
        Map<Id, Journey__c> journeyWithLeadOrContactMap = new Map<Id, Journey__c>();
        Map<Id, Id> journeyWithLeadOrContactIdsMap = new Map<Id, Id>();
        Id apiUserId = ApiUsersUtils.apiUserId;
        for (Map<String, sObject> parentToObject : mapParents.values()) {
            sObject parent = parentToObject.containsKey('contact') ? parentToObject.get('contact') : parentToObject.containsKey('lead') ? parentToObject.get('lead') : null;
            sObject newParent = parentToObject.containsKey('newlead') ? parentToObject.get('newlead') : parentToObject.get('lead');
            Journey__c journeyRecord = journeyCriteriaMap.get(String.valueOf(parent.get('Id'))).get('reUse');
            journeyRecord = JourneyHelper.getDefaultMappings(parentToObject, journeyRecord);
            if (System.isBatch()) {
                if (journeyRecord != null && journeyRecord.OwnerId != null && !UserUtility.getUserActive(journeyRecord.OwnerId) && !String.valueOf(journeyRecord.OwnerId).toLowerCase().startsWith('00g')) {
                    if (newParent != null && newParent.get('OwnerId') != null && (UserUtility.getUserActive(Id.valueOf(String.valueOf(newParent.get('OwnerId')))) || String.valueOf(newParent.get('OwnerId')).toLowerCase().startsWith('00g'))) {
                        journeyRecord.OwnerId = (Id) newParent.get('OwnerId');
                    } else {
                        journeyRecord.OwnerId = UserInfo.getUserId();
                    }
                }
            }
            journeyWithLeadOrContactMap.put(Id.valueOf(String.valueOf(newParent.get('Id'))), journeyRecord);
            if (journeyRecord.get('OwnerId') != null
                && (journeyRecord.OwnerId == apiUserId
                    || (!UserUtility.getUserActive(journeyRecord.OwnerId)
                        && !OrganizationHelper.isGroup(journeyRecord.OwnerId)))) {
               journeyWithLeadOrContactIdsMap.put(Id.valueOf(String.valueOf(newParent.get('Id'))), journeyRecord.Id);
            }
            if (parent != null
                && parent.get('OwnerId') != null
                && (parent.get('OwnerId') == apiUserId
                    || (!UserUtility.getUserActive(Id.valueOf(String.valueOf(parent.get('OwnerId'))))
                        && !OrganizationHelper.isGroup(String.valueOf(parent.get('OwnerId')))))) {
               journeyWithLeadOrContactIdsMap.put(Id.valueOf(String.valueOf(parent.get('Id'))), Id.valueOf(String.valueOf(newParent.get('Id'))));
            }
        }
        if (journeyWithLeadOrContactMap.size() > 0) {
            journeysForUpsertToIdsMap.putAll(journeyWithLeadOrContactMap);
            mapAssignments.putAll(journeyWithLeadOrContactIdsMap);
        }
    }

    public static Map<String, Map<String, Journey__c>> checkJourneyCreationCriteria(List<Map<String, sObject>> parents, Map<Id, sObject> journeysToIds) {
        Map<String, Map<String, Journey__c>> journeyCriteriaMap = new Map<String, Map<String, Journey__c>>();
        for (Map<String, sObject> parentToObject : parents) {
            sObject parent = parentToObject.containsKey('contact') ? parentToObject.get('contact') : parentToObject.get('lead');
            sObject newParent = parentToObject.containsKey('newlead') ? parentToObject.get('newlead') : parentToObject.get('lead');
            if (parent.getSObjects('Journeys__r') != null && parent.getSObjects('Journeys__r').size() > 0) {
                Journey__c objNewJourney = (Journey__c) journeysToIds.get(String.valueOf(newParent.get('Id')));
                objNewJourney = JourneyHelper.getDefaultMappings(parentToObject, objNewJourney);
                Map<String, Journey__c> mapResult = checkIsUniqueJourney(objNewJourney, (List<Journey__c>) parent.getSObjects('Journeys__r'));
                journeyCriteriaMap.put(String.valueOf(parent.get('Id')), mapResult);
            } else {
                journeyCriteriaMap.put(String.valueOf(parent.get('Id')), new Map<String, Journey__c>{
                        'createNew' => null
                });
            }
        }
        return journeyCriteriaMap;
    }

    public static Map<String, Journey__c> checkIsUniqueJourney(Journey__c objNewJourney, List<Journey__c> lstJourneys) {
        setupJourneyMatchingFieldsSet();
        if (!journeyMatchingFieldsSet.isEmpty()) {
            for (Journey__c journeyRecord : lstJourneys) {
                Boolean isSameJourney = checkUniqueKey(objNewJourney, journeyRecord);
                if (isSameJourney) {
                    return new Map<String, Journey__c>{
                            'reUse' => journeyRecord
                    };
                }
            }
        }
        return new Map<String, Journey__c>{
                'createNew' => null
        };
    }

    public static void setupJourneyMatchingFieldsSet() {
        if (journeyMatchingFieldsSet == null) {
            journeyMatchingFieldsSet = getJourneyMatchingFields();
        }
    }

    public static Boolean checkUniqueKey(sObject objNewJourney, sObject journeyRecord) {
        for (String strField : journeyMatchingFieldsSet) {
            if (objNewJourney.get(strField) == null || objNewJourney.get(strField) == '') {
                objNewJourney.put(strField, null);
            }
            if (journeyRecord.get(strField) == null || journeyRecord.get(strField) == '') {
                journeyRecord.put(strField, null);
            }
            if (objNewJourney.get(strField) != journeyRecord.get(strField)) {
                return false;
            }
        }
        return true;
    }

    public static String getJourneyModeofAssignment(Lead objNewLead) {
        if (objNewLead.Campaign_Id__c != null) {
            return 'Campaign Assignment';
        } else if (System.isBatch() && objNewLead.By_Pass_Journey_Creation_Criteria__c) {
            return 'Kickbox Importer';
        } else if (RESTInboundLeadAPIHelper.isLeadFromWeb && objNewLead.Lead_Assignment_Stage__c == '11') {
            return 'Lead Assignment';
        } else if ((RESTInboundLeadAPIHelper.isLeadFromWeb && objNewLead.Lead_Assignment_Stage__c == '6') || (!System.isBatch() && objNewLead.Lead_Assignment_Stage__c == '1000')) {
            return 'Manual Creation';
        }
        return null;
    }

    public static Set<String> getJourneyMatchingFields() {
        Set<String> setJourneyFields = new Set<String>();
        MetadataSetting__mdt objJourneyCreationMDT = Settings.getMetadataSettingByDevName('UniqueJourneyCriteria');
        if (String.isNotBlank(objJourneyCreationMDT.Data__c)) {
            Map<String, Set<String>> mapJourneyMatchingData = (Map<String, Set<String>>) JSON.deserialize(objJourneyCreationMDT.Data__c.toLowerCase(), Map<String, Set<String>>.class);
            if (mapJourneyMatchingData != null && mapJourneyMatchingData.get('uniquejourneycriteria') != null) {
                setJourneyFields.addAll(mapJourneyMatchingData.get('uniquejourneycriteria'));
            }
        }
        return setJourneyFields;
    }
}