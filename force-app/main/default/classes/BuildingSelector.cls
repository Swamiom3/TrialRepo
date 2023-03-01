/*************************************************************************************************************************************
 Author      :   Oleg Krasko
 Description :   This class is selector implementation of particular SObject (Building__c)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               7/9/2020        Oleg Krasko         Initial Deployment
 **************************************************************************************************************************************/
public inherited sharing class BuildingSelector extends SObjectSelector{
    private String buildngFieldsMetadata = 'Building_Fields_Metadata';
    private final String NO_LONGER_IN_USE_FIELD_NAME = 'No_Longer_in_Use__c';
    private List<String> fields = new List<String>{'Id',
            'Name',
            'UUID__c',
            'Time_Zone__c',
            'Market__r.Name',
            'Responsible_CM__c'};

    private final List<String> TOUR_RELATED_FIELDS = new List<String>{
        'Id',
        'Name',
        'Address__c',
        'Gate__c',
        'Responsible_CM__c',
        'City__c',
        'UUID__c',
        'Time_Zone__c',
        'GMT_Offset__c',
        'Is_Tourable__c',
        'Leasing_Manager_Id__c',
        'Postal_Code__c',
        'Country__c',
        'State__c',
        'Cluster_Name__c',
        'Portfolio_Name__c'
    };        
   // private final String TOUR_SCHEDULE_SUBQUERY = '(SELECT Id, Product_Line__c, Tour_Spacing__c FROM Tour_Schedules__r)';


    public BuildingSelector() {
        super(Building__c.getSObjectType());
    }
    /****************************************************************************************************************************
     Author              : Oleg Krasko
     Description         : This method is used to get default fields from CustomMetadata Type
     Created Date        : 7/9/2020
     *****************************************************************************************************************************/
    public override Set<String> getDefaultFields(){
        MetadataSetting__mdt objMetaData = Settings.getMetadataSettingByDevName(buildngFieldsMetadata);
        if (objMetaData != null && String.isNotBlank(objMetaData.Data__c)) {
            return (Set<String>) (JSON.deserialize(objMetaData.Data__c, Set<String>.class));
        } else {
            return new Set<String>{'Id', 'Name'};
        }
    }
    /****************************************************************************************************************************
     Author              : Oleg Krasko
     Description         : This method is used to add required filter
     Created Date        : 7/9/2020
     *****************************************************************************************************************************/
    public override String addRequiredFilters(Boolean isThereWhereClause){
        return (isThereWhereClause ? ' AND ' : ' WHERE ') + NO_LONGER_IN_USE_FIELD_NAME + ' = false';
    }
    /****************************************************************************************************************************
     Author              : Chandra Teja
     Description         : This method is used to get Building__c records by passing String as Name filter
     Created Date        : 7/8/2020
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingsByName(String name, Boolean isLikeOperator){
        if (String.isBlank(name)) {
            return new List<Building__c>();
        }
        List<String> fields = new List<String>{'Id'};
        return (List<Building__c>)getSObjectByField(fields, 'Name', name, isLikeOperator);
    }
    /****************************************************************************************************************************
     Author              : Chandra Teja
     Description         : This method is used to get Building__c records by passing list of Strings as Name filter
     Created Date        : 7/8/2020
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingsByName(List<String> names, Boolean isLikeOperator){
        return getBuildingsByName(new Set<String>(names), isLikeOperator);
    }
    /****************************************************************************************************************************
     Author              : Chandra Teja
     Description         : This method is used to get Building__c records by passing set of Strings as Name filter
     Created Date        : 7/8/2020
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingsByName(Set<String> names, Boolean isLikeOperator){
        if (names == null || names.isEmpty()) {
            return new List<Building__c>();
        }
        List<String> fields = new List<String>{'Id', 'UUID__c'};
        return (List<Building__c>)getSObjectByField(fields, 'Name', names, isLikeOperator);
    }

    /****************************************************************************************************************************
     Author              : Oleg Krasko
     Description         : This method is used to get Building__c records with using no filters
     Created Date        : 8/11/2020
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingsWithoutFilters(){
        List<String> fields = new List<String>{'Id',
                'Name',
                'City__c',
                'State__c',
                'Country__c',
                'UUID__c',
                'Opening_Date__c',
                'Community_Sales_Lead__c',
                'Community_Sales_Lead__r.Name',
                'Cluster__c',
                'Cluster__r.Id',
                'Cluster__r.Sales_Lead__c',
                'Cluster__r.Sales_Lead__r.Id',
                'Cluster__r.Sales_Lead__r.Name',
                'Responsible_CM__c',
                'Responsible_CM__r.Name',
                'No_Longer_in_Use__c'};
        return (List<Building__c>) getSObjectsWithoutFilters(fields);
    }

    /****************************************************************************************************************************
     Author              : Oleg Krasko
     Description         : This method is used to get Building__c records with using no filters (huge set of fields to query)
     Created Date        : 8/11/2020
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingsWithoutFiltersHugeSetOfFields(){
        List<String> fields = new List<String>{
            'Id',
            'Name',
            'Email__c',
            'UUID__c',
            'Address__c',
            'City__c',
            'State__c',
            'Country__c',
            'Postal_Code__c',
            'Time_Zone__c',
            'Associate_Director_Market_Sales__c',
            'Associate_Director_Portfolio_Sales__c',
            'Senior_Associate_Market_Sales__c',
            'Senior_Director_Territory_Sales__c',
            'Director_Portfolio_Sales__c',
            'Geography__r.geocode__c',
            'Geography__r.city__c',
            'Geography__r.state__c',
            'Geography__r.country__c',
            'Community_sales_lead__c',
            'Responsible_cm__c',
            'Market__c',
            'Market__r.name',
            'Market__r.territoryid__c',
            'Market__r.territoryid__r.regionid__c',
            'Market__r.enterprise_assignment_override__c',
            'Market__r.sub_territory__c',
            'Market__r.sub_territory__r.cluster_sales_manager__c',
            'Market__r.TerritoryId__r.Territory_Sales_Manager__c',
            'Cluster__c',
            'Portfolio_name__c',
            'Cluster_name__c',
            'Territory_name__c',
            'Region_name__c',
            'Cluster__r.sales_lead__c',
            'Community_Lead__c',
            'Sub_Territory__c',
            'Sub_Territory__r.Name',
            'Sub_Territory__r.Cluster_Sales_Manager__c',
            'Associate_Director_Market_Sales__r.Name',
            'Senior_Associate_Market_Sales__r.Name',
            'Associate_Director_Portfolio_Sales__r.Name',
            'Director_Portfolio_Sales__r.Name',
            'Senior_Director_Territory_Sales__r.Name',
            'Inside_Sales_Rep__c',
            'Inside_Sales_Rep__r.Name',
            'Inside_Sales_Renewals_Rep__c',
            'Inside_Sales_Renewals_Rep__r.Name',
            'Agency_Broker__c',
            'Leasing_Manager_Id__c',
            'Leasing_Director_Id__c ',
            'Cluster_Group__c',
            'Cluster_Group__r.Sales_Lead__c',
            'Cluster__r.Leasing_Manager__c',  
            'Territory_Sales_Manager_Name__c', 
            'Leasing_Portfolio_Director_Id__c',
            'Is_Tourable__c'
        };
        String whereClause = ' WHERE (Market__r.No_Longer_in_Use__c = false)';
        return (List<Building__c>) getSObjects(fields, whereClause);
    }

    /****************************************************************************************************************************
     Author              : Oleg Krasko
     Description         : This method is used to get Building__c records by passing list of Id fields as filter
     Created Date        : 8/11/2020
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingsById(List<Id> ids){
        if (ids == null || ids.isEmpty()) {
            return new List<Building__c>();
        }
        List<String> fields = new List<String>{'Id',
                'Name',
                'State__c',
                'City__c',
                'Country__c',
                'Opening_Date__c',
                'UUID__c',
                'Community_Sales_Lead__c',
                'Community_Sales_Lead__r.Name',
                'Cluster__c',
                'Cluster__r.Id',
                'Cluster__r.Sales_Lead__c',
                'Cluster__r.Sales_Lead__r.Id',
                'Cluster__r.Sales_Lead__r.Name',
                'Responsible_CM__c',
                'Responsible_CM__r.Name',
                'Community_Lead__c',
                'Community_Lead__r.Name',
                'Market__c',
                'Time_Zone__c'};
        return (List<Building__c>) getSObjectByIds(fields, ids);
    }

    /****************************************************************************************************************************
     Author              : Chandra Teja
     Description         : This method is used to get Building records with tour schedules of community manager
     Created Date        : 7/8/2020
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingByCommunityManagerWithTourSchedules(Id communityManagerId){
        if (communityManagerId == null) {
            return new List<Building__c>();
        }
        return (List<Building__c>) getSObjectByField(TOUR_RELATED_FIELDS, 'Responsible_CM__c', communityManagerId, false);
    }

    /****************************************************************************************************************************
     Author              : Chandra Teja
     Description         : This method is used to get Building records with tour schedules by passing Id field as filter
     Created Date        : 10/8/2020
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingsByIdWithTourSchedules(Id id){
        if (id == null) {
            return new List<Building__c>();
        }
        return (List<Building__c>) getSObjectByField(TOUR_RELATED_FIELDS, 'Id', id, false);
    }
    /****************************************************************************************************************************
     Author              : Chandra Teja
     Description         : This method is used to get Building__c records with tour schedules by passing UUID__c field as filter
     Created Date        : 10/8/2020
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingsByUuidWithTourSchedules(String uuid){
        if (String.isBlank(uuid)) {
            return new List<Building__c>();
        }
        return (List<Building__c>) getSObjectByField(TOUR_RELATED_FIELDS, 'UUID__c', uuid, false);
    }

    /****************************************************************************************************************************
     Author              : Oleg Krasko
     Description         : This method is used to get Building__c records by passing Id as filter
     Created Date        : 8/11/2020
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingsById(Id id){
        if (id == null) {
            return new List<Building__c>();
        }
        List<String> fields = new List<String>{'Id', 
                                               'Name',
                                               'State__c',
                                               'City__c',
                                               'Country__c',
                                               'Opening_Date__c',
                                               'UUID__c',
                                               'Building_Price_Book_Id__c',
                                               'Community_Sales_Lead__c',
                                               'Community_Sales_Lead__r.Name',
                                               'Cluster__c',
                                               'Cluster__r.Id',
                                               'Cluster__r.Sales_Lead__c',
                                               'Cluster__r.Sales_Lead__r.Id',
                                               'Cluster__r.Sales_Lead__r.Name',
                                               'CurrencyISOCode',
                                               'Responsible_CM__c',
                                               'Responsible_CM__r.Name',
                                               'Time_Zone__c'};
        return (List<Building__c>)getSObjectByField(fields, 'Id', id, false);
    }

    /****************************************************************************************************************************
     Author              : Chandra Teja
     Description         : This method is used to get all Building with tour schedule records
     Created Date        : 10/8/2020
     *****************************************************************************************************************************/
    public List<Building__c> getAllBuildingsWithTourSchedules(){
        return (List<Building__c>)getSObjectsWithoutFilters(TOUR_RELATED_FIELDS);
    }
    /****************************************************************************************************************************
     Author              : Oleg Krasko
     Description         : This method is used to get Building__c records by passing list of Name fields as filter
     Created Date        : 8/11/2020
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingsByName(List<String> names){
        if (names == null || names.isEmpty()) {
            return new List<Building__c>();
        }
        List<String> fields = new List<String>{ 'Name', 'UUID__c' };
        return (List<Building__c>) getSObjectByName(fields, names, false);
    }

    /****************************************************************************************************************************
     Author              : Oleg Krasko
     Description         : This method is used to get Building__c records by passing list of UUID__c fields as filter
     Created Date        : 7/9/2020
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingsByUuid(List<String> uuids){
        return getBuildingsByUuid(new Set<String>(uuids));
    }

    /****************************************************************************************************************************
     Author              : Oleg Krasko
     Description         : This method is used to get Building__c records by passing UUID__c field as filter
     Created Date        : 7/9/2020
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingsByUuid(String uuid){
        if (String.isBlank(uuid)) {
            return new List<Building__c>();
        }
        return (List<Building__c>) getSObjectByField(fields, 'UUID__c', uuid, false);
    }

    /****************************************************************************************************************************
     Author              : Chandra Teja
     Description         : This method is used to get Building__c records by passing set of UUID__c fields as filter
     Created Date        : 6/8/2020
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingsByUuid(Set<String> uuids){
        if (uuids == null || uuids.isEmpty()) {
            return new List<Building__c>();
        }
        return (List<Building__c>) getSObjectByField(fields, 'UUID__c', uuids, false);
    }

    /****************************************************************************************************************************
     Author              : Oleg Krasko
     Description         : This method is used to get Building__c records where UUID__c field is not empty
     Created Date        : 7/9/2020
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingsByUuidPopulated(){
        String whereClause = ' WHERE (UUID__c <> null)';
        return (List<Building__c>) getSObjects(fields, whereClause);
    }

    /****************************************************************************************************************************
     Author              : Oleg Krasko
     Description         : This method is used to get Building__c records by passing list of Ids as Cluster__c filter
     Created Date        : 7/9/2020
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingsByCluster(List<Id> clusterIds){
        if (clusterIds == null || clusterIds.isEmpty()) {
            return new List<Building__c>();
        }
        List<String> fields = new List<String>{
                'Id',
                'Cluster__r.Name',
                'Cluster__r.Cluster_Sales_Manager__r.Name',
                'Cluster__r.Cluster_Sales_Manager__r.Email',
                'Cluster__r.Sales_Lead__r.Name',
                'Cluster__r.Sales_Lead__r.Email'};
        String whereClause = 'Cluster__c IN :clusterIds';
        List<Object> bindings = new List<Object>{clusterIds};
        return (List<Building__c>) getSObjects(fields, whereClause, bindings);
    }

    /****************************************************************************************************************************
     Author              : Oleg Krasko
     Description         : This method is used to get Building__c records by passing list of Strings as City__c filter or as Geography__r.City__c filter;
     list of Strings as State__c filter or as Geography__r.State__c filter;
     list of Strings as Country__c filter or as Geography__r.Country__c filter
     Created Date        : 7/9/2020
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingsByAddresses(List<String> cities, List<String> states, List<String> countries){
        if ((cities == null || states == null || countries == null) || (cities.isEmpty() && states.isEmpty() && countries.isEmpty())) {
            return new List<Building__c>();
        }
        List<String> fields = new List<String>{'Market__r.Sub_Territory__c',
                'Id',
                'Name',
                'City__c',
                'State__c',
                'Country__c',
                'Geography__r.Geocode__c',
                'Geography__r.City__c',
                'Geography__r.State__c',
                'Geography__r.Country__c'};
        String whereClause = '(City__c IN :cities OR State__c IN :states OR Country__c IN :countries OR Geography__r.City__c IN :cities OR Geography__r.State__c IN :states OR Geography__r.Country__c IN :countries)';
        String orderbyClause = 'Geography__c ASC NULLS Last';
        List<Object> bindings = new List<Object>{cities, states, countries, cities, states, countries};
        return (List<Building__c>) getSObjects(fields, whereClause, bindings, orderByClause);
    }

    /****************************************************************************************************************************
     Author              : Oleg Krasko
     Description         : This method is used to get Building__c records by passing list of Ids as Market__c filter
     Created Date        : 7/9/2020
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingsByMarkets(List<Id> marketIds){
        if (marketIds == null || marketIds.isEmpty()) {
            return new List<Building__c>();
        }
        List<String> fields = new List<String>{'Market__r.Sub_Territory__c',
                'Id',
                'Market__r.Name',
                'Market__r.Portfolio__c',
                'Market__r.Portfolio_Sales_Manager__r.Name',
                'Market__r.Portfolio_Sales_Manager__r.Email',
                'Market__r.TerritoryId__r.Territory__c',
                'Market__r.TerritoryId__r.Territory_Sales_Manager__r.Name',
                'Market__r.TerritoryId__r.Territory_Sales_Manager__r.Email',
                'Market__r.TerritoryId__r.RegionId__r.Region__c',
                'Market__r.TerritoryId__r.RegionId__r.Regional_Sales_Manager__r.Name',
                'Market__r.TerritoryId__r.RegionId__r.Regional_Sales_Manager__r.Email'};
        String whereClause = 'Market__c IN :marketIds';
        List<Object> bindings = new List<Object>{marketIds};
        return (List<Building__c>) getSObjects(fields, whereClause, bindings);
    }

    /****************************************************************************************************************************
     Author              : Oleg Krasko
     Description         : This method is used to get Building__c records by passing list of Ids as Market__r.TerritoryId__r.RegionId__c filter
     Created Date        : 7/9/2020
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingsByRegions(List<Id> regionIds){
        if (regionIds == null || regionIds.isEmpty()) {
            return new List<Building__c>();
        }
        List<String> fields = new List<String>{'Id',
                'Market__r.TerritoryId__r.RegionId__r.Region__c',
                'Market__r.TerritoryId__r.RegionId__r.Regional_Sales_Manager__r.Name',
                'Market__r.TerritoryId__r.RegionId__r.Regional_Sales_Manager__r.Email'};
        List<Object> bindings = new List<Object>{regionIds};
        String whereClause = 'Market__r.TerritoryId__r.RegionId__c IN :regionIds AND Market__r.No_Longer_in_Use__c != true';
        return (List<Building__c>) getSObjects(fields, whereClause, bindings);
    }

    /****************************************************************************************************************************
     Author              : Oleg Krasko
     Description         : This method is used to get Building__c records by passing list of Strings as Email__c filter
     Created Date        : 7/9/2020
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingsByEmails(List<String> emails){
        return getBuildingsByEmails(new Set<String>(emails));
    }

    /****************************************************************************************************************************
     Author              : Chandra Teja
     Description         : This method is used to get Building__c records by passing set of Strings as Email__c filter
     Created Date        : 6/8/2020
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingsByEmails(Set<String> emails){
        if (emails == null || emails.isEmpty()) {
            return new List<Building__c>();
        }
        List<String> fields = new List<String>{'Id',
                'Email__c'};
        return (List<Building__c>) getSObjectByField(fields, 'Email__c', emails, false);
    }

    /****************************************************************************************************************************
     Author              : Oleg Krasko
     Description         : This method is used to get Building__c records by passing Region_Name__c field as filter
     Created Date        : 7/9/2020
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingsByRegionName(String regionName){
        if (String.isBlank(regionName)) {
            return new List<Building__c>();
        }
        List<String> fields = new List<String>{'Id',
                'Name',
                'Region_Name__c'};
        List<Object> bindings = new List<Object>{regionName};
        String whereClause = 'Region_Name__c = :regionName';
        String orderByClause = 'Name ASC';
        return (List<Building__c>) getSObjects(fields, whereClause, bindings, orderByClause);
    }

    /****************************************************************************************************************************
     Author              : Oleg Krasko
     Description         : This method is used to get Building__c records by passing list of Ids as Market__r.TerritoryId__c filter
     Created Date        : 7/9/2020
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingsByTerritories(List<Id> territoryIds){
        if (territoryIds == null || territoryIds.isEmpty()) {
            return new List<Building__c>();
        }
        List<String> fields = new List<String>{'Id',
                'Market__r.TerritoryId__r.Territory__c',
                'Market__r.TerritoryId__r.Territory_Sales_Manager__r.Name',
                'Market__r.TerritoryId__r.Territory_Sales_Manager__r.Email',
                'Market__r.TerritoryId__r.RegionId__r.Region__c',
                'Market__r.TerritoryId__r.RegionId__r.Regional_Sales_Manager__r.Name',
                'Market__r.TerritoryId__r.RegionId__r.Regional_Sales_Manager__r.Email'};
        List<Object> bindings = new List<Object>{territoryIds};
        String whereClause = 'Market__r.TerritoryId__c IN :territoryIds AND Market__r.No_Longer_in_Use__c <> true';
        return (List<Building__c>) getSObjects(fields, whereClause, bindings);
    }

    /****************************************************************************************************************************
     Author              : Jitesh Adwani
     Description         : This method is used to get Building__c records by passing keyWord.
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingsByKeywordWithLimit(String keyWord, Integer addLimit){
        List<String> fields = new List<String>{'Id',
                'Name'};
        String whereClause = 'Name';
        String keyWordToSearch = '%'+keyWord+'%';
        return (List<Building__c>) getSObjects(fields, whereClause, (Object)keyWordToSearch, true, addLimit);
    }


    /****************************************************************************************************************************
     Author              : Oleg Krasko
     Description         : Set building fields metadata
     *****************************************************************************************************************************/
    @TestVisible
    private void setBuildingFieldsMetadata(String input){
        if (String.isNotBlank(input)) {
            buildngFieldsMetadata = input;
        }
    }
    
    /****************************************************************************************************************************
    Author              : Roshan Kankrayane
    Description         : This method is used to get query string for query locator in BatchToUpdateGMTOffsetOnBuilding class
    Created Date        : 31/12/2020
    *****************************************************************************************************************************/
    public String getQueryLocatorForGMTOffset(Set<String> dSTTimezones, Set<String> noDSTTimezones){
        String query = 'SELECT Id, Time_Zone__c, GMT_Offset__c FROM Building__c ';
        if(!dSTTimezones.isEmpty() && !noDSTTimezones.isEmpty()){
            query += 'WHERE Time_Zone__c IN : dSTTimezones OR Time_Zone__c IN : noDSTTimezones';  
        }else if (!dSTTimezones.isEmpty()){
            query += 'WHERE Time_Zone__c IN : dSTTimezones';
        }else {
            query += 'LIMIT 0';
        }
        return query;
    }

    /****************************************************************************************************************************
     Author              : Silpa Putti
     Description         : This method is used to get building records by passing Building UUID
     Created Date        : 7/14/2021
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingsByBuildingUUId(String uuid){
        if(uuid == null){
            return new List<Building__c>();
        }
        List<String> fields = new List<String>{'Id',
                'Building_ID__c',
                'UUID__c'};
        return (List<Building__c>) getSObjectByField(fields, 'UUID__c', uuid, false);
    }
    
    /****************************************************************************************************************************
     Author              : Salesforce
     Description         : This method is used to get building records by passing Building UUID
     Created Date        : 7/14/2021
     *****************************************************************************************************************************/
    public List<Building__c> getBuildingById(String buildingId){
        if(buildingId == null){
            return new List<Building__c>();
        }
        List<String> fields = new List<String>{'Id',
                'Building_ID__c',
                'Time_Zone__c',
                'UUID__c'};
        return (List<Building__c>) getSObjectByField(fields, 'Id', buildingId, false);
    }

    public List<Building__c> getBuildingsWithLocationNoCityAndNotNullUuid(){
        List<String> fields = new List<String>{ 'Id',
                                                'Name',
                                                'Location_No_City__c',
                                                'UUID__c'};
        String whereClause = 'WHERE UUID__c != null';
        return (List<Building__c>) getSObjects(fields, whereClause);
    }

    public List<Building__c> getBuildingsWithTimeZoneByIds(Set<Id> buildingIds){
        if (buildingIds == null || buildingIds.isEmpty()) {
            return new List<Building__c>();
        }
        List<String> fields = new List<String>{'Id', 'Time_Zone__c'};
        return (List<Building__c>) getSObjectByIds(fields, new List<Id>(buildingIds));
    }

    public List<Building__c> getBuildingsWithPriceBookAndCurrencyByIds(Set<Id> buildingIds){
        if (buildingIds == null || buildingIds.isEmpty()) {
            return new List<Building__c>();
        }
        List<String> fields = new List<String>{ 'Id', 
                                                'Building_Price_Book_Id__c', 
                                                'CurrencyIsoCode'};
        return (List<Building__c>) getSObjectByIds(fields, new List<Id>(buildingIds));
    }

    public Building__c getBuildingTourabilityById(String buildingId){
        if (String.isBlank(buildingId)) {
            return new Building__c();
        }
        List<String> fields = new List<String>{ 'Id', 
                                                'Name', 
                                                'Is_Tourable__c'};
        return ((List<Building__c>) getSObjectByIds(fields, Id.valueOf(buildingId)))[0];
    }
    public List<Building__c> getBuildingHoursId(String buildingId){
        if (String.isBlank(buildingId)) {
            return new List<Building__c>();
        }
        List<String> fields = new List<String>{'Business_Hours_Id__c'};
        return (List<Building__c>) getSObjectByIds(fields,Id.valueOf(buildingId));
             
    }
    public List<Building__c> getBuildingHoursIdList(List<Id> buildingIds){
        if (buildingIds == null || buildingIds.isEmpty()) {
            return new List<Building__c>();
        }
        List<String> fields = new List<String>{'Id','Business_Hours_Id__c'}; 
        return (List<Building__c>) getSObjectByIds(fields, buildingIds);
            
    }
   
    public List<Building__c> getBuildingRegionAndTerritory(Set<Id> buildingIds) {
        if (buildingIds == null || buildingIds.isEmpty()) {
            return new List<Building__c>();
        }
        List<String> fields = new List<String>{ 'Id', 
                                                'Market__c', 
                                                'Market__r.Territory__c',
                                                'Market__r.Region__c'};
        List<Object> bindings = new List<Object>{buildingIds};
        return (List<Building__c>) getSObjectByIds(fields, new List<Id>(buildingIds));
    }
}