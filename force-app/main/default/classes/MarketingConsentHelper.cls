/************************************************************************************************************************************
    Author      :   Maciej Miłosz
    Description :   Helper class marketing consent and opt out activities
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           2 Feb 2021         Maciej Miłosz           Trigger refactoring
**************************************************************************************************************************************/
public inherited sharing class MarketingConsentHelper {
    private static Set<Schema.SObjectType> validSObjectTypes = new Set<Schema.SObjectType>{Schema.Contact.getSObjectType(), Schema.Lead.getSObjectType()};
    private static final Id BIG_MARKER_INTEGRATION_USER_ID = Settings.getValidationRuleRestrictionSalesforceId('BigMarker_Integration_User');


    public static void setMarketingConsent(List<SObject> newSObjects){
        if(BIG_MARKER_INTEGRATION_USER_ID == UserInfo.getUserId() || newSObjects == null || newSObjects.isEmpty()){
            return;
        }
        if(!validSObjectTypes.contains(newSObjects[0].getSObjectType())){
            throw new MarketingConsentHelperException('Invalid SObject Type for setting the marketing consent.');
        }
        MetadataSetting__mdt metadataSetting = Settings.getMetadataSettingByDevName('MarketingConsentMetaData');
        if(metadataSetting?.Data__c == null ){
            return;
        }
        Map<String, Object> marketingConsentSettings = (Map<String, Object>) JSON.deserializeUntyped(metadataSetting.Data__c);
        Object leadMarketingConsentSetting = marketingConsentSettings.get(String.valueOf(newSObjects[0].getSobjectType()));
        if(leadMarketingConsentSetting == null){
            return;
        }

        Map<String, Object> leadMarketingConsentSettings = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(leadMarketingConsentSetting));
        Set<String> validProfiles = getSetOfStringsOutOfCustomSettings(leadMarketingConsentSettings, 'Included Profiles');
        Set<String> validRoles = getSetOfStringsOutOfCustomSettings(leadMarketingConsentSettings, 'Role Name');
        Set<String> validNMDSources = getSetOfStringsOutOfCustomSettings(leadMarketingConsentSettings, 'NMDLeadSource');
        Set<String> validCountryCodes = getSetOfStringsOutOfCustomSettings(leadMarketingConsentSettings, 'CountryCode');
        User currentUser = UserUtility.getUserById(UserInfo.getUserId());
        Boolean isValidUserAndRole = validProfiles.contains(currentUser.ProfileId)
                                     && (String.isNotBlank(currentUser.UserRole.Name)
                                        && validRoles.contains(currentUser.UserRole.Name.toLowerCase()));
        for(SObject currentRecord : newSObjects) {
            Boolean isValidLSProfileAndRoleForSource = (isValidUserAndRole
                    && (currentRecord.get('LeadSource') != null
                        && validNMDSources.contains(String.valueOf(currentRecord.get('LeadSource')).toLowerCase())));
            Map<Integer, Boolean> booleanValues = getMapWithValues((List<Object>)leadMarketingConsentSettings.get('fields'), currentRecord);
            BooleanEvaluate booleanEvaluateThingToBeRemoved = new BooleanEvaluate(String.valueOf(leadMarketingConsentSettings.get('expression')), booleanValues);
            Boolean isValidEvaluation = booleanEvaluateThingToBeRemoved.evaluate();
            if(currentRecord.get('Marketing_Consent__c') == false
                && (isValidEvaluation
                    || isValidLSProfileAndRoleForSource
                    || (currentRecord.get('Country_Code__c') != null
                        && validCountryCodes.contains(String.valueOf(currentRecord.get('Country_Code__c')).toLowerCase())))){
                currentRecord.put('Marketing_Consent__c', true);
            }else if(currentRecord.get('Marketing_Consent__c') == false){
                currentRecord.put('HasOptedOutOfEmail', true);
            }
        }
    }

    private static Set<String> getSetOfStringsOutOfCustomSettings(Map<String, Object> leadMarketingConsentSettings, String settingName){
        return leadMarketingConsentSettings.get(settingName) != null ?
            (Set<String>)JSON.deserialize(JSON.serialize(leadMarketingConsentSettings.get(settingName)), Set<String>.class) :
            new Set<String>();
    }

    //not touched - TODO:Get rid of this concept -> BooleanEvaluate class and it's usage.
    public static Map<Integer, Boolean> getMapWithValues(List<Object> lstObjects, sObject objRecord){
        Map<Integer, Boolean> mapBooleanValues = new Map<Integer, Boolean>();
        Map<String, Object> mapData;
        Set<String> setValues;
        for(Object objData : lstObjects){
            mapData = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(objData));
            setValues = (Set<String>) JSON.deserialize(JSON.serialize(mapData.get('values')).toLowerCase(), Set<String>.class);
            if(setValues != NULL && !setValues.isEmpty() && objRecord != NULL){
                mapBooleanValues.put(Integer.valueOf(mapData.get('index')), objRecord.get(String.valueOf(mapData.get('field'))) != NULL && setValues.contains(String.valueOf(objRecord.get(String.valueOf(mapData.get('field')))).toLowerCase()) ? true : false);
            }else{
                mapBooleanValues.put(Integer.valueOf(mapData.get('index')), false);
            }
        }
        return mapBooleanValues;
    }

    public class MarketingConsentHelperException extends Exception{}

}