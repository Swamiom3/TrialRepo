/*************************************************************************************************************************************
    Author      :   Ishwar Shinde
    Description :   This class is selector implementation of particular SObject (Geography)
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE              AUTHOR            DETAIL
    1          10 March, 2022    Ishwar Shinde     Initial Deployment
**************************************************************************************************************************************/
public with sharing class GeographySelector extends SObjectSelector {
    
    private final String GEOGRAPHY_FIELDS_METADATA = 'Geography_Fields_Metadata';
    private static final List<String> DEFAULT_FIELDS = new List<String>{'Id', 'Name', 'Geocode__Latitude__s', 'Geocode__Longitude__s'};
    public GeographySelector() {
        super(Geography__c.getSObjectType());
    }
    
    public override Set<String> getDefaultFields(){
        return new Set<String> (DEFAULT_FIELDS);
    }
	
    public List<Geography__c> getGeographiesByIdAndNotNullNearestBuilding(List<Id> ids){
        if (ids == null || ids.isEmpty()) {
            return new List<Geography__c>();
        }

        List<String> fields = new List<String>{'Id',
                                               'Nearest_Building__c'};
        List<Object> bindings = new List<Object>{ ids };
        String whereClause = 'Id IN :ids AND Nearest_Building__c <> NULL';
        return (List<Geography__c>) getSObjects(fields, whereClause, bindings);
    }

    public List<Geography__c> getGeographiesByIDs(List<String> ids){
        if (ids == null || ids.isEmpty()) {
            return new List<Geography__c>();
        }

        List<String> fields = new List<String>{'Id',
                                               'Name',
                                               'City__c',
                                               'State__c',
                                               'Country__c'};
        return (List<Geography__c>) getSObjectByField(fields, 'Id', ids, false);
    }
    
    public List<Geography__c> getGeographiesById(Id id){
        if (id == null) {
            return new List<Geography__c>();
        }
        List<String> additionalFields = new List<String>{'Nearest_Building__r.Name', 
                                                         'Nearest_Building__r.Geography__c',
                                                         'Nearest_Building__r.Geography__r.Name',
                                                         'Nearest_Building__r.Geography__r.Geocode__Latitude__s',
                                                         'Nearest_Building__r.Geography__r.Geocode__Longitude__s',
                                                         'Nearest_Building__r.Geography__r.Nearest_Building__c'};
        additionalFields.addAll(DEFAULT_FIELDS);
        return (List<Geography__c>)getSObjectByField(additionalFields, 'Id', id, false);
    }
    
    public List<Geography__c> getGeographiesByNearestBuilding(Id nearestBuilding){
        if (nearestBuilding == null) {
            return new List<Geography__c>();
        }
        return (List<Geography__c>) getSObjectByField(DEFAULT_FIELDS, 'Nearest_Building__c', nearestBuilding, false);
    }
    
    public List<Geography__c> getGeographiesByIdAndNotNullUUIDs(Id id){
        if (id == null) {
            return new List<Geography__c>();
        }

        List<String> fields = new List<String>{ 'Nearest_Building__c',
                                                'Nearest_Building__r.UUID__c',
                                                'Nearest_Building__r.Name',
                                                'Nearest_Building__r.CurrencyISOCode',
                                                'Nearest_Building__r.Building_Price_Book_Id__c'};
        List<Object> bindings = new List<Object>{ id };
        String whereClause = 'Id =: id AND Nearest_Building__r.UUID__c != NULL';

        return (List<Geography__c>) getSObjects(fields, whereClause, bindings);
    }
    
    public List<Geography__c> getGeographiesByCountryCode(String countryCode){
        if (String.isBlank(countryCode)) {
            return new List<Geography__c>();
        }

        List<String> fields = new List<String>{ 'Id',
                                                'Nearest_Building__r.Market__r.Name',
                                                'Nearest_Building__r.Market__r.TerritoryID__r.Name'};
        List<Object> bindings = new List<Object>{ countryCode };
        String whereClause = 'Country_Code__c = :countryCode AND Nearest_Building__r.Market__r.No_Longer_in_Use__c <> TRUE AND  Nearest_Building__r.Market__r.TerritoryID__c != null ORDER BY CreatedDate DESC LIMIT 1';

        return (List<Geography__c>) getSObjects(fields, whereClause, bindings);
    }
    
    public List<Geography__c> getGeographiesByPlaceId(String placeId){
        if (placeId == null) {
            return new List<Geography__c>();
        }
        List<String> fields = new List<String>{'Id', 
                                               'City__c',
                                               'Geocode__Latitude__s',
                                               'Geocode__Longitude__s',
                                               'Place_ID__c'};
        return (List<Geography__c>)getSObjectByField(fields, 'Place_ID__c', placeId, false);
    }
}