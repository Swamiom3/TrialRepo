/************************************************************************************************************************************
   Author      :   Alex Vashchenko
   Description :   This class contain method to set the opportunity names.
   ----------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE        AUTHOR            DETAIL
    1         14/10/2020   Alex Vashchenko   ST-7089, ST-5999
 **************************************************************************************************************************************/
public with sharing class OpportunityNamingTrH extends SObjectTriggerHandler {
    public static final Integer MAX_NAME_LENGTH = 120;

    private static final String SEPARATOR = '-';
    private static final String ALL_ACCESS_SUFFIX = 'AA';
    private static final String SAAS_SUFFIX = 'SS';
    private static final String PRIVATE_EVENTS = 'Private Events';
    private static final String RENEWAL_OPPORTUNITY_PREFIX = 'REN';
    private static final String OPPORTUNITY_RENEWAL_RECORD_TYPE_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Renewal').getRecordTypeId();
    private static Boolean isForcedCalculation = false;

    @TestVisible
    private final List<Opportunity> newOpportunities;
    @TestVisible
    private final Map<Id, Opportunity> newOpportunitiesMap;
    @TestVisible
    private final Map<Id, Opportunity> oldOpportunitiesMap;
    @TestVisible
    private GeographySelector geographySelector = new GeographySelector();

    public OpportunityNamingTrH() {
        this((List<Opportunity>) Trigger.new,
             (Map<Id, Opportunity>) Trigger.newMap,
             (Map<Id, Opportunity>) Trigger.oldMap);
    }

    @TestVisible
    private OpportunityNamingTrH(List<Opportunity> newOpportunities,
                                 Map<Id, Opportunity> newOpportunitiesMap,
                                 Map<Id, Opportunity> oldOpportunitiesMap){
        this.newOpportunities = newOpportunities;
        this.newOpportunitiesMap = newOpportunitiesMap;
        this.oldOpportunitiesMap = oldOpportunitiesMap;
        if (isForcedCalculation) {
            this.forceExecution();
        }
    }

    public static void forceCalculations(){
        isForcedCalculation = true;
    }
    public override void beforeInsert() {
        this.populateNames(this.newOpportunities);
    }

    public override void beforeUpdate() {
        List<Opportunity> oppWithUpdatedFields = new List<Opportunity>();
        for (Opportunity item : this.newOpportunities) {
            if (isForcedExecution() || TriggerUtility.isFieldsValueChanged(item,
                                                                           oldOpportunitiesMap.get(item.Id),
                                                                           new Set<String> {'AccountId',
                                                                                            'Type__c',
                                                                                            'Building__c',
                                                                                            'Geography__c',
                                                                                            'CloseDate'})) {
                oppWithUpdatedFields.add(item);
            }
        }
        this.populateNames(oppWithUpdatedFields);
        MetadataDrivenTriggerHandler.clearLoopCount(OpportunityNamingTrH.class.getName());
    }

    public void populateNames(List<Opportunity> records){
        if (records == null || records.isEmpty()) {
            return;
        }
        Map<Id, Building__c> buildings = getRelatedBuildings(records);
        Map<Id, Geography__c> geographies = getRelatedGeography(records);
        for (Opportunity item: records) {
            String accName = item.Opportunity_Account_Name__c;
            String buildingName = '';
            if (item.Building__c != null && buildings.containsKey(item.Building__c)) {
                buildingName = buildings.get(item.Building__c).Name;
            }
            String geographyName = '';
            if (item.Geography__c != null && geographies.containsKey(item.Geography__c)) {
                geographyName = this.getGeographyText(geographies.get(item.Geography__c));
            }
            List<Object> nameValues = this.buildNameValues(item, accName, buildingName, geographyName);
            item.Name = buildOppName(nameValues, accName);
        }
    }

    private List<Object> buildNameValues(Opportunity opportunity, String accName, String buildingName, String geographyName){
        List<Object> nameValues = new List<Object>();
        //Check if opportunity is of Renewal type
        if(opportunity.RecordTypeId == OPPORTUNITY_RENEWAL_RECORD_TYPE_ID){
            nameValues.add(RENEWAL_OPPORTUNITY_PREFIX);
        }
        if (String.isNotBlank(accName)) {
            nameValues.add(accName);
        }
        String market = null;
        if (String.isNotBlank(geographyName)) {
            market = geographyName; 
        }else if (String.isNotBlank(buildingName)) {
            market = buildingName;
        } 
        if (String.isBlank(opportunity.Type__c) && String.isNotBlank(market)) {
            // If no type and has MARKET
            nameValues.add(market);
        } else if (opportunity.Type__c == GlobalConstants.MIXED_TYPE) {
            // AccountName - MIXED - DATE
            nameValues.add(GlobalConstants.MIXED_TYPE);
        } else if (opportunity.Type__c == GlobalConstants.WEWORK) {
            // AccountName - MARKET - WW - NUMBER - DATE
            if (String.isNotBlank(market)) {
                nameValues.add(market);
            }
        } else if (opportunity.Type__c == GlobalConstants.SAAS_TYPE) {
            // AccountName - MARKET - SS - DATE
            if (String.isNotBlank(market)) {
                nameValues.add(market);
            }
            nameValues.add(SAAS_SUFFIX);
        } else if (opportunity.Type__c == GlobalConstants.PX_WE) {
            // AccountName - MARKET - PxWe - DATE
            if (String.isNotBlank(geographyName)) {
                nameValues.add(geographyName);
            }
        } else if (opportunity.Type__c == GlobalConstants.ALL_ACCESS) {
            // AccountName - GEOGRAPHY - AA - NUMBER_DESKS - DATE
            if (String.isNotBlank(market)) {
                nameValues.add(market);
            }
        } 
        nameValues.add(opportunity.CloseDate == null ? '' : DateFormatter.monthDayYear(opportunity.CloseDate));
        return nameValues; 
    }

    private String buildOppName(List<Object> nameValues, String accName){
        String result = String.join(nameValues, SEPARATOR);
        if (result.length() > MAX_NAME_LENGTH) {
            Integer accNameMaxLength = MAX_NAME_LENGTH - result.length() + accName.length();
            result = accName.substring(0, accNameMaxLength).substringBeforeLast(' ') +
                     result.removeStartIgnoreCase(accName);
        }
        return result;
    }

    private String getGeographyText(Geography__c geography) {
        if(String.isNotBlank(geography.City__c)) {
            return geography.City__c;
        } else if(String.isNotBlank(geography.State__c)) {
            return geography.State__c;
        } else if(String.isNotBlank(geography.country__c)) {
            return geography.country__c;
        }
        return '';
    }

    private Map<Id, Building__c> getRelatedBuildings(List<Opportunity> records){
        Set<Id> buildingIds = new Set<Id>();
        for (Opportunity item : records) {
            buildingIds.add(item.Building__c);
        }
        return new Map<Id, Building__c> (BuildingUtility.getBuildingsByIds(buildingIds));
    }

    private Map<Id, Geography__c> getRelatedGeography(List<Opportunity> records){
        Set<Id> geographyIds = new Set<Id>();
        for (Opportunity item : records) {
            geographyIds.add(item.Geography__c);
        }
        if (geographyIds.isEmpty()) {
            return new Map<Id, Geography__c>();
        }
        return new Map<Id, Geography__c>(geographySelector.getGeographiesByIDs(new List<Id>(geographyIds)));
    }
}