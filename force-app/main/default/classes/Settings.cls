/* Created by @hemanshu.shah@enzigma.com on 24 Apr 2016
* This class should contain all the triggers related to Settings
* As well as static methods to retreive Settings with Caching for optimized usage.
* 
*/

public class Settings {
    public static List<Product2> lstProducts;
    public static Map<Id,User> mapUserById = UserUtility.idToUser;
    public static Map<String,User> mapUserByName = UserUtility.nameToUser;
    public static Map<String,User> mapUserByEmail = UserUtility.emailToUser;
    public static List<EmailTemplate> lstEmailTemplates;
    public static Map<String,EmailTemplate> mapEmailTemplateByDeveloperName = new Map<String,EmailTemplate>();
    private static Map<String, Id> validationRulesProfileIdsByDeveloperName;
    private static Set<Id> validationRulesAdminProfilesIds;

    public static List<Group> lstQueues;
    public static Map<Id, Group> mapQueueById = new Map<Id, Group>();
    public static Map<String, Group> mapQueueByName = new Map<String, Group>();

    public static List<Building__c> lstBuildings;
    public static Map<Id,Building__c> mapBuildingById = BuildingUtility.idToBuilding;

    public static Map<String, List<Product2>> mapProductsByProductCode = new Map<String, List<Product2>>();
    public static Map<Id, Product2> mapProductsById = new Map<Id, Product2>();

    public static Map<String, MetadataSetting__mdt> mapMetadataSettings;
    public static Map<String, Map<String, Object>> mapMetadataSettingsDeserialized = new Map<String, Map<String, Object>>();
    @TestVisible
    private static BuildingSelector buildingSelector = new BuildingSelector();

    public static Boolean isSystemAdministrator {
        get {
            return UserUtility.isSystemAdministrator;
        }
        private set;
    }

    public static Boolean isMuleSoftUser {
        get {
            return UserUtility.isMuleSoftUser;
        }
        private set;
    }
    /************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method is used to get all metadata by developer name.
      	Created Date  		:   28 Nov 2018 
        Last Modified By    :   Krishana Tupe
    * --------------------------------------------------------------------------------------
    * @author      - Gad Sharon
    * @date        - 28 Aug 2019
    * @description - Changed the method to use only static map.
    * --------------------------------------------------------------------------------------
 	*************************************************************************************************************************************/
    public static MetadataSetting__mdt getMetadataSettingByDevName(String strDevName)
    {
        //Check if we didn't get the custom metadata settings yet.
        if(mapMetadataSettings?.isEmpty() == false) {
            return mapMetadataSettings.get(strDevName.toLowerCase());
        }
        mapMetadataSettings = new Map<String, MetadataSetting__mdt>();
        //Get all metadata settings from the DB.
        List <MetadataSetting__mdt> lstMetadasettings = [SELECT Id, DeveloperName, Data__c FROM MetadataSetting__mdt];

        //If we found metadata settings.
        if(!lstMetadasettings.isEmpty())
        {
            //Add the metadata settings to the static map so it can be used across the transaction.
            for(MetadataSetting__mdt objMetadataSetting : lstMetadasettings)
            {
                mapMetadataSettings.put(objMetadataSetting.DeveloperName.toLowerCase(), objMetadataSetting);
            }
        }
        else //If we didn't find any metadata settings.
        {
            //Put value in the map so we won't query metadata settings again.
            mapMetadataSettings.put('Settings class default value', null);
        }
        return  mapMetadataSettings.get(strDevName.toLowerCase());
    }
    /************************************************************************************************************************************
        Author              :   Chandra Teja
        Description         :   This method returns metadata settings in the form of map after deserialize.
      	Created Date  		:   19 August 2019 
 	*************************************************************************************************************************************/
    public static Map<String, Object> getMetadataSettingByDevNameAsMap(String strDevName){
        MetadataSetting__mdt objMetadataSetting = getMetadataSettingByDevName(strDevName);
        Map<String, Object> mapSetting = new Map<String, Object>();
        if(!mapMetadataSettingsDeserialized.isEmpty() && mapMetadataSettingsDeserialized.containsKey(strDevName)) {
            mapSetting = mapMetadataSettingsDeserialized.get(strDevName);
        }else if((mapMetadataSettingsDeserialized.isEmpty() || (!mapMetadataSettingsDeserialized.isEmpty() && !mapMetadataSettingsDeserialized.containsKey(strDevName)))&& objMetadataSetting != NULL){
            mapSetting = (Map<String, Object>)JSON.deserializeUntyped(objMetadataSetting.Data__c.toLowerCase());
            mapMetadataSettingsDeserialized.put(strDevName, mapSetting);
        }
        return mapSetting;
    }

    public static Id getValidationRuleRestrictionSalesforceId(String developerName){
        return UserUtility.getValidationRuleRestrictionSalesforceId(developerName);
    }

    public static Id getValidationRuleIdByDeveloperName(String developerName){
        return UserUtility.getValidationRuleIdByDeveloperName(developerName);
    }

    /************************************************************************************************************************************
        Author              :   Shobhit Gahlot
        Description         :   This method is used to get salesforce Id from Salesforce_Id__c of Validation_Rule_Restriction__mdt metadata.
        Created Date  		:   June 19 2020			 
    **************************************************************************************************************************************/
    public static Id getApiUserId(){
        return UserUtility.getApiUserId();
    }

    /************************************************************************************************************************************
         Author              :   Krishana Tupe
         Description         :   This method is used to checktrigger state active or incative from FlowToTriggersSettings custom metadata.
         Created Date  		:   Jan 29 2020
     **************************************************************************************************************************************/
    public static Map<String, Map<String, Boolean>> mapTriggersSettings = NULL;
    public static Boolean getFlowToTriggersSettings(String strFlowTriggerSettingName, String strSobjectName){
        if(String.isNotBlank(strFlowTriggerSettingName) && String.isNotBlank(strSobjectName)){
            strFlowTriggerSettingName = strFlowTriggerSettingName.toLowerCase().trim();
            strSobjectName = strSobjectName.toLowerCase().trim();
            if(mapTriggersSettings == NULL){
                MetadataSetting__mdt objMetaData = settings.getMetadataSettingByDevName('FlowToTriggersSettings');
                if(objMetaData != NULL && String.isNotBlank(objMetaData.Data__c)){
                    mapTriggersSettings = (Map<String, Map<String, Boolean>>)JSON.deserialize(objMetaData.Data__c.toLowerCase(), Map<String, Map<String, Boolean>>.class);
                }
            }
            if(mapTriggersSettings != NULL && mapTriggersSettings.get(strSobjectName) != NULL && mapTriggersSettings.get(strSobjectName).get(strFlowTriggerSettingName) != NULL){
                return mapTriggersSettings.get(strSobjectName).get(strFlowTriggerSettingName);
            }
        }
        return false;
    }

    /************************************************************************************************************************************
     Author 				: 	Pragalbha Mahajan
     Description 		: 	This method is used to get Products by productcode
     Issue No.			:	ST-3076
     Created Date		:	20 November 2018
     **************************************************************************************************************************************/
    public static List<Product2> getProductsByProductCode(String productCode){
        getAllProducts();
        if(mapProductsByProductCode != null && mapProductsByProductCode.containskey(productCode)){
            return mapProductsByProductCode.get(productCode);
        }
        return null;
    }

    /************************************************************************************************************************************
    Author 				: 	Pragalbha Mahajan
    Description 		: 	This method is used to get all Products
    Issue No.			:	ST-3076
	Created Date		:	20 November 2018
    **************************************************************************************************************************************/
    public static List<Product2> getAllProducts(){
        if(lstProducts == null){
            lstProducts  =  [SELECT Id, Name, CurrencyIsoCode, Product_Category__c, Family, Product_Type__c, Default_Product_Category__c, ProductCode FROM Product2 ];
            for(Product2 objProduct : lstProducts){
                mapProductsById.put(objProduct.Id, objProduct);
                if(String.isNotBlank(objProduct.ProductCode)){
                    if(!mapProductsByProductCode.containskey(objProduct.ProductCode)){
                        mapProductsByProductCode.put(objProduct.ProductCode, new List<Product2>());
                    }
                    mapProductsByProductCode.get(objProduct.ProductCode).add(objProduct);
                }
            }
        }
        return lstProducts;
    }

    public static void fetchQueues(){
        if(lstQueues==null){
            lstQueues = [Select Id, Name, Type From Group WHERE Type = 'Queue'];
            for(Group groupRec : lstQueues){
                mapQueueById.put(groupRec.Id, groupRec);
                mapQueueByName.put(groupRec.Name, groupRec);
            }
        }
    }

    public static Group getQueueById(Id queueId){
        fetchQueues();
        if(mapQueueById.containsKey(queueId)){
            return mapQueueById.get(queueId);
        }else{
            return null;
        }
    }

    public static Group getQueueByName(String name){
        fetchQueues();
        if(mapUserByName.containsKey(name)){
            return mapQueueByName.get(name);
        }else{
            return null;
        }
    }

    public static void fetchUsers(){
        UserUtility.fetchUsers();
    }

    /*****************************************************************************************************************************************
        Author              :   Pragalbha Mahajan
        Description         :   This method is used to fetch all(Active/Inactive) Users.
        Created Date        :   01 October 2018
        Issue No            :   ST-2795
    ******************************************************************************************************************************************/
    public static List<User> fetchAllUsers(){
        return UserUtility.fetchAllUsers();
    }

    public static User getUserById(Id userId){
        return UserUtility.getUserById(userId);
    }

    public static User getUserByName(String userName){
        return UserUtility.getUserByName(userName);
    }

    public static User getUserByEmail(String userEmail){
        return UserUtility.getUserByEmail(userEmail);
    }

    public static Boolean getUserActive(Id userId){
        return UserUtility.getUserActive(userId);
    }

    public static List<User> getAllUsers(){
        return UserUtility.getAllUsers();
    }

    /*****************************************************************************************************************************************
        Author              :   Pragalbha Mahajan
        Description         :   This method is used to fetch email templates.
        Created Date        :   01 October 2018
        Issue No            :   ST-2696
    ******************************************************************************************************************************************/
    public static List<EmailTemplate> fetchEmailTemplates(Set<String> setEmailTemplateByDevName){
        lstEmailTemplates = [SELECT Id, Name, Body, Markup, DeveloperName, IsActive FROM EmailTemplate WHERE DeveloperName IN :setEmailTemplateByDevName];
        for(EmailTemplate objEmailTemplate: lstEmailTemplates){
            mapEmailTemplateByDeveloperName.put(objEmailTemplate.DeveloperName, objEmailTemplate);
        }
        return lstEmailTemplates;
    }

    /*****************************************************************************************************************************************
        Author              :   Pragalbha Mahajan
        Description         :   This method is used to fetch email template by Name.
        Created Date        :   01 October 2018
        Issue No            :   ST-2696
    ******************************************************************************************************************************************/
    public static EmailTemplate getEmailTemplateByDeveloperName(String strDeveloperName){
        if(mapEmailTemplateByDeveloperName.containsKey(strDeveloperName)){
            return mapEmailTemplateByDeveloperName.get(strDeveloperName);
        }else{
            List<EmailTemplate> lstEmailTemplates = getEmailTemplateByDeveloperName(new Set<String>{strDeveloperName});
            if(!lstEmailTemplates.isEmpty()){
                return lstEmailTemplates[0];
            }
        }
        return NULL;
    }

    public static List<EmailTemplate> getEmailTemplateByDeveloperName(Set<String> setEmailTemplateByDevName){
        return fetchEmailTemplates(setEmailTemplateByDevName);
    }

    /*
    *   Created By      : Amol Darekar
    *   Created Date    : 29-Oct-2017
    *   Summary         : This method is use to fetch all building information and store this information into map
    *                     it internally uses cached data to avoid queries.  
    *   Issue No.       : -
    */
    public static void fetchBuildings(){
        BuildingUtility.fetchBuildings();
    }

    /*****************************************************************************************************************************************
       Author              :   Shivprasad Patil
       Description         :   This method is used to get Multiple buildings by ids.
       Created Date        :   19 July 2019
       Issue No            :
   ******************************************************************************************************************************************/
    public static List<Building__c> getBuildingsByIds(Set<Id> setOfBuildingIds){
        return BuildingUtility.getBuildingsByIds(setOfBuildingIds);
    }

    /*
    *   Created By      : Amol Darekar
    *   Created Date    : 29-Oct-2017
    *   Summary         : This method is use to fetch building information by Id from map
    *                     it internally uses cached data to avoid queries.  
    *   Issue No.       : -
    */
    public static Building__c getBuildingById(Id buildingId){
        return BuildingUtility.getBuildingById(buildingId);
    }

    /*
     *   Created By      : Amol Darekar
     *   Created Date    : 29-Oct-2017
     *   Summary         : This method is use to fetch building information by UUID from map
     *                     it internally uses cached data to avoid queries.
     *   Issue No.       : -
     */
    public static Building__c getBuildingByUUID(String buildingUUID){
        return BuildingUtility.getBuildingByUUID(buildingUUID);
    }

    public static List<Building__c> getAllBuildings(){
        return BuildingUtility.getAllBuildings();
    }

    /* Created by hemanshu.shah@enzigma.com on 24 Apr 2016
     * This method caches queried setttings so for subsequent usage it does not query it again.
     */
    static Map<String,Sales_Console_Setting__mdt> mapSettingsToName = new Map<String, Sales_Console_Setting__mdt>();
    public static Sales_Console_Setting__mdt getTest(String strName){
        strName = strName.toLowerCase();
        if( !mapSettingsToName.containsKey(strName) ){
            Sales_Console_Setting__mdt[] settings = [SELECT Id, DeveloperName, Unique_Key__c, MasterLabel, Data__c, Source_Object__c, Destination_Object__c FROM Sales_Console_Setting__mdt where DeveloperName=:strName];
            if(settings.size() > 0){
                mapSettingsToName.put(strName.toLowerCase(), settings[0]);
                return settings[0];
            }
            return null;
        }
        return mapSettingsToName.get(strName);
    }

    // New Code    
    static Set<String> settingNames = new Set<String>();
    public static Sales_Console_Setting__mdt get(String strName){
        strName = strName.toLowerCase();
        if( !mapSettingsToName.containsKey(strName)){
            Sales_Console_Setting__mdt[] settings = new List<Sales_Console_Setting__mdt>();
            settings = [SELECT Id, DeveloperName, Unique_Key__c, MasterLabel, Data__c, Source_Object__c, Destination_Object__c FROM Sales_Console_Setting__mdt];
            if(settings.size() > 0){
                for(Sales_Console_Setting__mdt setting : settings){
                    mapSettingsToName.put(setting.DeveloperName.toLowerCase() , setting);
                }
            }
            if(mapSettingsToName.containsKey(strName))
                return mapSettingsToName.get(strName);
            else{
                if(Test.isRunningTest()){
                    settingNames.add(strName);
                }
            }
            return null;
        }
        return mapSettingsToName.get(strName);
    }

    /* Created by hemanshu.shah@enzigma.com on 24 Apr 2016
     * This method caches all given settings using one query so
     * query is not fired for each setting
     */

    public static object get(string strName, Type type){
        Sales_Console_Setting__mdt setting = get(strName);
        if(setting != null){
            return JSON.deserialize(setting.Data__c, type);
        }
        return null;
    }

    /* Created by hemanshu.shah@enzigma.com on 24 Apr 2016
     * This method caches all given settings using one query so
     * query is not fired for each setting
     */
    public static void LoadSettings(String[] names){
        Sales_Console_Setting__mdt[] settings = [SELECT Id, DeveloperName, Unique_Key__c, MasterLabel, Data__c, Source_Object__c, Destination_Object__c FROM Sales_Console_Setting__mdt Where DeveloperName in :names];
        for(Sales_Console_Setting__mdt setting : settings){
            mapSettingsToName.put(setting.DeveloperName.toLowerCase(), setting);
        }
    }


    /* Created by hemanshu.shah@enzigma.com on 24 Apr 2016
     * This method caches all given field mappings settings using one query so
     * query is not fired for each setting
     */
    public static void LoadFieldMappings(){
        Sales_Console_Setting__mdt[] settings = [SELECT Id, DeveloperName, Unique_Key__c, MasterLabel, Data__c, Source_Object__c, Destination_Object__c FROM Sales_Console_Setting__mdt Where DeveloperName Like 'FieldMappings_%'];
        for(Sales_Console_Setting__mdt setting : settings){
            mapSettingsToName.put(setting.DeveloperName.toLowerCase(), setting);
        }
    }

    /* Created by hemanshu.shah@enzigma.com on 24 Apr 2016
     * Use this method to load field mapping which always returns map of string of string
     * it internally uses cached data to avoid queries
     */

    static Map<String, FieldMappings> mapFieldMappings = new Map<String, FieldMappings>();
    public static FieldMappings getFieldMappings(String strName){
        if(mapFieldMappings.containsKey(strName)){
            return mapFieldMappings.get(strName);
        }
        Sales_Console_Setting__mdt setting = get('FieldMappings_' + strName);
        if(setting == null){
            return null;
        }
        Settings.FieldMappings fieldMappings = (Settings.FieldMappings)JSON.deserialize(setting.Data__c, Settings.FieldMappings.class);
        mapFieldMappings.put(strName, fieldMappings);
        return fieldMappings;
    }

    public class FieldMappings {
        public integer version {get; set;}
        public Map<String, MappedField> mappings{get; set;}
    }

    public class MappedField {
        public MappedField(String strValue){
            this(strValue, false);
        }
        public MappedField(String strValue, Boolean isValue){
            this.isvalue = isValue;
            if(isValue){
                this.value = strValue;
            }
            else{
                this.fieldname = strValue;
            }
            this.overwrite = false;
        }
        public boolean isvalue {get; set;}
        public String value{get; set;}
        public String fieldname {get;set;}
        public boolean overwrite {get; set;}
    }

    /************************************************************************************************************************************
    Author 				: 	Pragalbha Mahajan
    Description 		: 	This method is used to get fields from custom metadata settings.
	Created Date		:	20 November 2018
    **************************************************************************************************************************************/
    public static List<sObject> getFieldsFromMDT(String metadataType, String developerName, Set<String> setFields){
        List<sObject> records;
        if(setFields == null || setFields.isEmpty() || String.isBlank(metadataType)){
            return records;
        }
        List<String> lstFields = new List<String>(setFields);
        String strQuery = 'SELECT Id, ' + String.join(lstFields, ',');
        strQuery += ' FROM ' + metadataType + (String.isNotBlank(developerName) ? ' WHERE DeveloperName =: developerName' : '');
        records = Database.query(strQuery);
        return records;
    }

    /************************************************************************************************************************************
    Author 				: 	Milanjeet Singh
    Description 		: 	This method is used to split string value by splitor (e.g. ';' ',' or'.' etc) to set of values
						: 	String value = 'Name;Label;DeveloperName' will split to set(Name,Label,DeveloperName)
	Created Date		:	20 November 2018
    **************************************************************************************************************************************/
    public static Set<String> splitStringToSet(String stringValue, String splitor){
        Set<String> setValues = new Set<String>();
        if(String.valueOf(stringValue).contains(splitor)){
            setValues.addAll(String.valueOf(stringValue).split(splitor));
        }else{
            setValues.add(stringValue.trim());
        }
        return setValues;
    }

    public static MetadataSetting__mdt getMetadataSetting(String devloperName){
        return getMetadataSettingByDevName(devloperName);
    }

    /************************************************************************************************************************************
         Author              :   Krishana Tupe
         Description         :   This method is usde to check is record value changed.
         Created Date  		:   12 December 2018
     **************************************************************************************************************************************/
    public static Boolean isChanged(String newValue, String oldValue){
        if((String.isBlank(newValue) && String.isNotBlank(oldValue)) || (String.isNotBlank(newValue) && String.isBlank(oldValue))){
            return true;
        }
        if(String.isNotBlank(newValue) && String.isNotBlank(oldValue) && !newValue.equalsIgnoreCase(oldValue)){
            return true;
        }
        return false;
    }

    /************************************************************************************************************************************
        Author              :   Ashish Sharma
        Description         :   This method will fetch the field value from multi level relationship.
        Created Date        :   4 April 2020
        Issue               :   ST-5916
    **************************************************************************************************************************************/
    public static Object getParentFieldValue(sObject sObjectSource, String strSourceField) {
        if(sObjectSource != NULL) {
            List<String> splitedFields = strSourceField.split('\\.');
            for(Integer i = 0; i < splitedFields.size()-1; i++){
                sObjectSource = sObjectSource.getSobject(splitedFields[i]);
                if(sObjectSource == NULL) {
                    return NULL;
                }
            }
            return sObjectSource.get(splitedFields[splitedFields.size()-1]);
        }
        return NULL;
    }

    /************************************************************************************************************************************
           Author              :   Krishana Tupe
           Description         :   This method is used to get the Team Role configuration setting which is used to get configured Team Role.
           Created Date        :   4 April 2020
           Issue               :   ST-6179
    **************************************************************************************************************************************/
    public static Map<String, String> mapTeamRoleConfig;
    public static String getTeamRoleConfigSettings(String strkey){
        if(String.isBlank(strkey)){
            return NULL;
        }
        if(mapTeamRoleConfig == NULL || mapTeamRoleConfig.isEmpty()){
            mapTeamRoleConfig = new Map<String, String>();
            MetadataSetting__mdt objMetadataSetting  = Settings.getMetadataSettingByDevName('Team_Role_Configuration_Settings');
            if(objMetadataSetting != NULL && String.isNotBlank(objMetadataSetting.Data__c)){
                mapTeamRoleConfig = (Map<String, String>)JSON.deserialize(objMetadataSetting.Data__c.toLowerCase(), Map<String, String>.class);
            }
        }
        return mapTeamRoleConfig.get(strkey.toLowerCase());
    }

    public static void refreshUsers() {
        UserUtility.refreshUsers();
    }
}