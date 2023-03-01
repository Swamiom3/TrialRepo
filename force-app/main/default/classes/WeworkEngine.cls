global class WeworkEngine
{
    global static String currentSandboxPath{ get; set;}
    global static List<Building__c> listBuildings { get; set;}
    global static SelectOption[] availableTimes {get; set;}
    static Settings.FieldMappings mapContactToJourney;
    static Settings.FieldMappings mapLeadToJourney;
    static Map<String, String>localeToDateTimeFmtMap;
    @TestVisible
    private static UserSelector userSelector = new UserSelector();
    @TestVisible
    private static JourneySelector journeySelector = new JourneySelector();
    global WeworkEngine(){
        //currentSandboxPath = System.URL.getSalesforceBaseURL().toExternalForm();
        currentSandboxPath = System.URL.getSalesforceBaseUrl().getHost().remove('-api' );
    }
    
    @RemoteAction
    global static sObject[] Query(String strQuery) {
        return Database.Query(strQuery);
    }
    
    @RemoteAction
    global static List<List<sObject>> searchQuery(String strSearchQuery) {
        return Search.query(strSearchQuery);
    }
    
    //Retuns all picklist value.
    @RemoteAction
    global static List<String> fetchObjectFields( String objectApiName, String fieldApiName)
    {
        List<String> lstFieldValues = new List<String>();
        Schema.SObjectType targetObjectType = Schema.getGlobalDescribe().get(objectApiName);
        Map<String, Schema.SObjectField> field_map = targetObjectType.getDescribe().fields.getMap();
        for(Schema.PicklistEntry picklistEntry : field_map.get(fieldApiName).getDescribe().getPickListValues())
            lstFieldValues.add(picklistEntry.getLabel());
        return lstFieldValues;
    }
    
    @RemoteAction
    global static User GetLoggedInUserInfo() {
        return userSelector.getUsersWithAdditionalFieldsById(UserInfo.getUserId())[0];
    }
    
    @RemoteAction
    global static List<Contact> GetContactInfo(String EmailId) {
        List<Contact> lstContact = new List<Contact>([SELECT Id, Name, Email FROM Contact WHERE Email =: EmailId]);
        return lstContact;
    }
    
    @RemoteAction
    global static Reports.ReportResults runReport(String reportId) {
        return Reports.ReportManager.runReport(reportId, true);
    }
    
    global class ReportNameSetting{
        String ReportName { get; set;}
        String FolderName { get; set;}
    }
    
    global static sObject ConstructSobject(String sObjectApiName, String jSONSObject)
    {
        try
        {
            Map<String, Object> fieldMap = null;
            fieldMap = (Map<String, Object>)JSON.deserializeUntyped(jSONSObject);
            Schema.SObjectType targetType = Schema.getGlobalDescribe().get(sObjectApiName);
            SObject newSobject = targetType.newSObject();
            Map<String, Schema.sObjectField> targetFields = targetType.getDescribe().fields.getMap();
            System.debug(logginglevel.ERROR, 'fieldMap::'+fieldMap);
            System.debug(logginglevel.ERROR, 'jSONSObject::'+jSONSObject);
            for (String key : fieldMap.keySet()) 
            {
                Object value = fieldMap.get(key);
                Schema.DisplayType valueType = targetFields.get(key).getDescribe().getType();
                System.debug(logginglevel.ERROR, 'valueType::'+valueType);
                System.debug(logginglevel.ERROR, 'value::'+value);
                if (value instanceof String && valueType != null && valueType != Schema.DisplayType.String) 
                {
                    String svalue = (String)value;
                    if (valueType == Schema.DisplayType.Date)
                        newSobject.put(key, Date.valueOf(svalue));
                    else if(valueType == Schema.DisplayType.DateTime)
                        newSobject.put(key, DateTime.valueOfGmt(svalue));
                    else if (valueType == Schema.DisplayType.Percent || valueType == Schema.DisplayType.Currency) 
                        newSobject.put(key, svalue == '' ? null : Decimal.valueOf(svalue));
                    else if (valueType == Schema.DisplayType.Double)
                        newSobject.put(key, svalue == '' ? null : Double.valueOf(svalue));
                    else if (valueType == Schema.DisplayType.Integer)
                        newSobject.put(key, Integer.valueOf(svalue));
                    else if (valueType == Schema.DisplayType.Base64)
                        newSobject.put(key, Blob.valueOf(svalue));
                    else
                        newSobject.put(key, svalue);
                } 
                else
                    newSobject.put(key, value);
            }
            return newSobject;
        }
        catch(Exception ex)
        {
            System.debug(logginglevel.ERROR, 'Exception occured while creating sObject:'+ex.getMessage());
            return null;
        }
    }
    
    @RemoteAction
    global static String getUserName(){
        return UserInfo.getName();
    }
    
    @RemoteAction
    global static Boolean DeleteRecord(String strAPIName, String strJSONObject){
        sObject newSobject = ConstructSobject(strAPIName,strJSONObject);
        
        try{
            Database.delete(String.valueOf(newSobject.get('Id')));
            return true;
        }
        catch(Exception ex){
        }
        return false;
        
    }
    
    @RemoteAction
    global static List<Database.DeleteResult> DeleteRecords(List<Id> lstIds) 
    {   if(!lstIds.isEmpty())
        return Database.delete(lstIds); 
     else
         return null;    
    }
    
    @RemoteAction
    global static List<SaveResult> SaveRecords(List<sObject> lstObj){
        List<sObject> lstUpdateObj = new List<sObject>();
        List<sObject> lstNewObj = new List<sObject>();
        List<SaveResult> lstResult = new List<SaveResult>();
        try{
            for(sObject obj : lstObj){
                if(String.isNotEmpty(obj.Id))
                    lstUpdateObj.add(obj);
                else
                    lstNewObj.add(obj);
            }
            if(lstUpdateObj.size() > 0){
                for(Database.Saveresult newDatabaseUpdateResult : Database.update(lstUpdateObj)){
                    lstResult.add(new SaveResult(Database.update(lstUpdateObj)));
                }
            }
            if(lstNewObj.size() > 0){
                //Database.DMLOptions dmo = new Database.DMLOptions();
                //dmo.assignmentRuleHeader.useDefaultRule = true;
                for(Database.Saveresult newDatabaseSaveResult : Database.insert(lstNewObj)){
                    lstResult.add(new SaveResult(newDatabaseSaveResult));
                }
            }
        }catch(Exception ex){
            lstResult.add(new SaveResult(ex));
        }
        return lstResult;
    }
    
    global class FieldResult{
        public string name { get; set;}
        public string label { get; set;}
        public integer length { get; set;}
        public Schema.Displaytype type { get; set;}
    }
    
    @RemoteAction
    global static List<FieldResult> GetAllFields(String objType){
        Map<String,DescribeFieldResult> fieldsWithDetails = new Map<String,DescribeFieldResult>();
        List<FieldResult> lstFieldResult = new List<FieldResult>();
        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(new String[]{objType});
        for(Schema.DescribeSobjectResult res : results) {
            for(Schema.SObjectField field: res.fields.getMap().values()){
                DescribeFieldResult fieldDescribe = field.getDescribe();
                FieldResult result = new FieldResult ();
                result.name = fieldDescribe.name;
                result.label = fieldDescribe.label;
                result.length = fieldDescribe.length;
                result.type = fieldDescribe.type;
                lstFieldResult.add(result);
                fieldsWithDetails.put(fieldDescribe.name,fieldDescribe);
            }
        }
        return lstFieldResult;
    }
    
    @RemoteAction
    global static Date addBusinessDays( Integer utcYear, Integer utcMonth, Integer utcDate, Integer daysToAdd){
        Date date1 =  Date.newinstance(utcYear, utcMonth, utcDate);
        String dt = date1.format();
        Date givenDate = date.parse(dt);
        return DateUtilities.addBusinessDays(givenDate, daysToAdd);
    }
        
    @RemoteAction
    global static SaveResult extendReference(Id recordId, Date expiryDate, Date referredDate){
        SaveResult sr = ReferenceHandler.ExtendReference(recordId, expiryDate, referredDate);
        return sr;
    }

    
    
    @RemoteAction
    global static Sales_Console_Setting__mdt getSettingsRecord(String settingsName){
        return  SalesConsoleSettings.get(settingsName);
    }
    
    /*
    Comment   : This method will use to map fields from contact to activity.
    Author    : Amol Darekar
    Date      : 16/07/2016 
    */
    public static Settings.FieldMappings Contact2Activity() {
        Settings.FieldMappings contactToActivityMappings = new Settings.FieldMappings();
        contactToActivityMappings.version = 1;
        contactToActivityMappings.mappings = new Map<String, Settings.MappedField>();
        contactToActivityMappings.mappings.put('Phone__c', new Settings.MappedField('Phone'));
        contactToActivityMappings.mappings.put('Locale__c', new Settings.MappedField('Locale__c'));
        contactToActivityMappings.mappings.put('Market__c', new Settings.MappedField('Market__c'));
        contactToActivityMappings.mappings.put('Product_Interests__c', new Settings.MappedField('Product_Interests__c'));
        contactToActivityMappings.mappings.put('Country_Code__c', new Settings.MappedField('Country_Code__c'));
        contactToActivityMappings.mappings.put('Quick_Quote_Location__c', new Settings.MappedField('Quick_Quote_Location__c'));
        //contactToActivityMappings.mappings.put('LeadSource', new Settings.MappedField('LeadSource'));
        contactToActivityMappings.mappings.put('Lead_Source_Detail__c', new Settings.MappedField('Lead_Source_Detail__c'));
        contactToActivityMappings.mappings.put('utm_campaign__c', new Settings.MappedField('utm_campaign__c'));
        contactToActivityMappings.mappings.put('utm_campaign_id__c', new Settings.MappedField('utm_campaign_id__c'));
        contactToActivityMappings.mappings.put('utm_content__c', new Settings.MappedField('utm_content__c'));
        contactToActivityMappings.mappings.put('utm_medium__c', new Settings.MappedField('utm_medium__c'));
        contactToActivityMappings.mappings.put('utm_source__c', new Settings.MappedField('utm_source__c'));
        contactToActivityMappings.mappings.put('utm_term__c', new Settings.MappedField('utm_term__c'));
        return contactToActivityMappings;
    }
        
    public static Settings.FieldMappings Lead2Journey() {
        Settings.FieldMappings leadToJourneyMappings = new Settings.FieldMappings();
        leadToJourneyMappings.version = 1;
        leadToJourneyMappings.mappings = new Map<String, Settings.MappedField>();
        leadToJourneyMappings.mappings.put('Name', new Settings.MappedField('Name'));
        leadToJourneyMappings.mappings.put('Lead_Source__c', new Settings.MappedField('LeadSource'));
        leadToJourneyMappings.mappings.put('Lead_Source_Detail__c', new Settings.MappedField('Lead_Source_Detail__c'));
        leadToJourneyMappings.mappings.put('utm_campaign__c', new Settings.MappedField('utm_campaign__c'));
        leadToJourneyMappings.mappings.put('utm_campaign_id__c', new Settings.MappedField('utm_campaign_id__c'));
        leadToJourneyMappings.mappings.put('utm_content__c', new Settings.MappedField('utm_content__c'));
        leadToJourneyMappings.mappings.put('utm_medium__c', new Settings.MappedField('utm_medium__c'));
        leadToJourneyMappings.mappings.put('utm_source__c', new Settings.MappedField('utm_source__c'));
        leadToJourneyMappings.mappings.put('utm_term__c', new Settings.MappedField('utm_term__c'));
        return leadToJourneyMappings;
    }
    
    public static Settings.FieldMappings Contact2Journey() {
        Settings.FieldMappings contactToJourneyMappings = new Settings.FieldMappings();
        contactToJourneyMappings.version = 1;
        contactToJourneyMappings.mappings = new Map<String, Settings.MappedField>();
        contactToJourneyMappings.mappings.put('Name', new Settings.MappedField('Name'));
        contactToJourneyMappings.mappings.put('Lead_Source_Detail__c', new Settings.MappedField('Lead_Source_Detail__c'));
        contactToJourneyMappings.mappings.put('utm_campaign__c', new Settings.MappedField('utm_campaign__c'));
        contactToJourneyMappings.mappings.put('utm_campaign_id__c', new Settings.MappedField('utm_campaign_id__c'));
        contactToJourneyMappings.mappings.put('utm_content__c', new Settings.MappedField('utm_content__c'));
        contactToJourneyMappings.mappings.put('utm_medium__c', new Settings.MappedField('utm_medium__c'));
        contactToJourneyMappings.mappings.put('utm_source__c', new Settings.MappedField('utm_source__c'));
        contactToJourneyMappings.mappings.put('utm_term__c', new Settings.MappedField('utm_term__c'));
        return contactToJourneyMappings;
    }
    
    /**
    * @author pranay.jadhav@wework.com.dev5
    * @description : Lead To Activity mappings for 'Enterprise Solutions', and EnterpriseLead Settings for Activity Subject Name and Lead's Company Size
    * @date : 23/Aug/2016
    */
    public static Settings.FieldMappings mapLeadToActivity;
    public static EnterpriseSettingsRecord enterpriseSettingsValues;
    public static EnterpriseLeadSettings enterpriseSettings;
    public static Settings.FieldMappings Lead2Activity() {
        Settings.FieldMappings leadToActivityMappings = new Settings.FieldMappings();
        leadToActivityMappings.version = 1;
        leadToActivityMappings.mappings = new Map<String, Settings.MappedField>();
        leadToActivityMappings.mappings.put('Lead_Source__c', new Settings.MappedField('LeadSource'));
        return leadToActivityMappings;
    }
    
    public class EnterpriseSettingsRecord {
        public List<EnterpriseLandingSettings> EnterpriseLandingSettings;
        public EnterpriseLeadSettings EnterpriseLeadSettings;
    }
    
    public class EnterpriseLandingSettings {
        public String LeadSource;
        public String LeadSourceDetail;
    }
    
    public class EnterpriseLeadSettings {
        public String ActivitySubject;
        public Integer CompanySize;
    }
    
    
    public static boolean hasSObjectField(String fieldName, SObject so){
        String s = JSON.serialize(so);
        Map<String,Object> obj = (Map<String,Object>) JSON.deserializeUntyped(s);
        Set<String> fieldsPresent = obj.keyset().clone();
        return fieldsPresent.contains(fieldName);
    }
    
    /**
    * @author pranay.jadhav@wework.com.dev5
    * @Issue : ST-629 Sales Console : VF Page : JourneyAction
    * @description : Change Outreach Stage to 'Marketing Drip' and create task to related contact and lead
    * @date : 26/Aug/2016
    */
    @RemoteAction
    global static JourneyStageUpdateResult changeStageRelatedLeadOrContactOnJourney(string journeyId) {
        JourneyStageUpdateResult stageChangeResult = new JourneyStageUpdateResult(); 
        if(!journeyId.contains(','))
        {
            List<Journey__c> lstJourneyToUpdate;
            List<Task> lstTaskToInsert;
            Journey__c objJourney = new Journey__c();
            //JourneyStageUpdateResult stageChangeResult = new JourneyStageUpdateResult();
            objJourney = Database.Query(journeySelector.getQueryWithJourneyId());
            if(objJourney != null){
                if(hasSObjectField('Primary_Lead__c', objJourney)){
                    List<Lead> lstLeads = [SELECT Id,(SELECT Id,Status__c,Outreach_Stage__c FROM Journeys__r) FROM Lead WHERE Id =:objJourney.Primary_Lead__c];
                    lstJourneyToUpdate = new List<Journey__c>();
                    lstTaskToInsert = new List<Task>();
                    for (Lead l : lstLeads) {
                        if(l.Journeys__r.size() > 0){
                            for(Journey__c obj : l.Journeys__r){
                                 if(obj.Status__c =='Known' && obj.Outreach_Stage__c !='NMD Drip'){
                                    //obj.Status__c = 'Converted';
                                    obj.Outreach_Stage__c ='NMD Drip';
                                    lstJourneyToUpdate.add(obj);
                                }
                            }
                            if(lstJourneyToUpdate.size() > 0){
                                for(Journey__c journeyObj : lstJourneyToUpdate){
                                    Task newTask = new Task();
                                    newTask.WhatId = journeyObj.Id;
                                    //newTask.WhoId = l.Id;
                                    newTask.Type = 'MC Campaign';
                                    newTask.TaskSubtype = 'Call';
                                    newTask.Status = 'Completed';
                                    newTask.Subject = 'Journey Action : Marketing Drip';
                                    newTask.CallDisposition = 'User sent this member to the Marketing Cloud Drip Campaign';
                                    lstTaskToInsert.add(newTask);
                                }
                            }else{
                                stageChangeResult.result = 'No further actions possible as the member is not eligible for Marketing Drip.';
                                stageChangeResult.totalCount = lstJourneyToUpdate.size();
                                stageChangeResult.errorType = 'error';
                                return stageChangeResult;
                            }
                        }
                    }
                    
                    insert lstTaskToInsert;
                    update lstJourneyToUpdate;
                    
                    stageChangeResult.result = 'The member added to the Marketing Drip Campaigns Successfully';
                    stageChangeResult.totalCount = lstJourneyToUpdate.size();
                    stageChangeResult.errorType = 'success';
                    return stageChangeResult;
                    
                }else if(hasSObjectField('Primary_Contact__c', objJourney)){
                    List<Contact> lstContacts = [SELECT Id,(Select Id,Status__c,Outreach_Stage__c FROM Journeys__r) FROM Contact WHERE Id =:objJourney.Primary_Contact__c];
                    lstJourneyToUpdate = new List<Journey__c>();
                    lstTaskToInsert = new List<Task>();
                    for (Contact c : lstContacts) {
                        if(c.Journeys__r.size() > 0){
                            for(Journey__c obj : c.Journeys__r){
                                if(obj.Status__c =='Known' && obj.Outreach_Stage__c !='NMD Drip'){
                                    //obj.Status__c = 'Converted;
                                    obj.Outreach_Stage__c ='NMD Drip';
                                    lstJourneyToUpdate.add(obj);
                                }
                            }
                            if(lstJourneyToUpdate.size() > 0){
                                for(Journey__c journeyObj : lstJourneyToUpdate){
                                    Task newTask = new Task();
                                    newTask.WhatId = journeyObj.Id;
                                    newTask.WhoId = c.Id;
                                    newTask.Type = 'MC Campaign';
                                    newTask.TaskSubtype = 'Call';
                                    newTask.Status = 'Completed';
                                    newTask.Subject = 'Journey Action : Marketing Drip';
                                    newTask.CallDisposition = 'User sent this member to the Marketing Cloud Drip Campaign';
                                    lstTaskToInsert.add(newTask);
                                }
                            }else{
                                stageChangeResult.result = 'No further actions possible as the member is not eligible for Marketing Drip.';
                                stageChangeResult.totalCount = lstJourneyToUpdate.size();
                                stageChangeResult.errorType = 'error';
                                return stageChangeResult;
                            }
                        }
                    }
                    
                    insert lstTaskToInsert;
                    update lstJourneyToUpdate;
                    
                    stageChangeResult.result = 'The member added to the Marketing Drip Campaigns Successfully';
                    stageChangeResult.totalCount = lstJourneyToUpdate.size();
                    stageChangeResult.errorType = 'success';
                    return stageChangeResult;
                }
            }
            stageChangeResult.result = 'Journeys not found for the given Id or Primary Contact/Lead not assigned';
            stageChangeResult.totalCount = 0;
            stageChangeResult.errorType = 'error';
            return stageChangeResult;
        }
        else
        {
            stageChangeResult.errorType = 'success';
            return stageChangeResult;
        }
    }
    global class JourneyStageUpdateResult {
        public String result;
        public Integer totalCount;
        public String errorType;
    }
    
    /*
    *   Created By      : Amol Darekar
    *   Created Date    : 1 Dec 2016
    *   Summary         : This method will return difference between 2 date in hours.
    */
    public static Long dateDiff(DateTime createdDate, DateTime nmdNextNmdDate)
    {
        Long dt1Long = createdDate.getTime();
        Long dt2Long = nmdNextNmdDate.getTime();
        Long milliseconds = dt2Long - dt1Long;
        Long seconds = milliseconds / 1000;
        Long minutes = seconds / 60;
        Decimal rem =  Math.mod(minutes, 60);
        Decimal hours = minutes/ 60;
        system.debug('rem'+rem);
        if(rem > 30)
        {
            Decimal dc = 0.6; 
            hours += dc;
            system.debug('hours'+hours);
        }
        system.debug('hours+rem'+Math.round(hours));
        return Math.round(hours);
    }
    
    public static String getLocaleToDateTimeFmtMap () {
        if (localeToDateTimeFmtMap == null)
            localeToDateTimeFmtMap  = new Map<String,String> {
                'ar'            => 'dd/MM/yyyy',
                    'ar_AE'         => 'dd/MM/yyyy',
                    'ar_BH'         => 'dd/MM/yyyy',
                    'ar_JO'         => 'dd/MM/yyyy',
                    'ar_KW'         => 'dd/MM/yyyy',
                    'ar_LB'         => 'dd/MM/yyyy',
                    'ar_SA'         => 'dd/MM/yyyy',
                    'bg_BG'         => 'yyyy-M-d',
                    'ca'            => 'dd/MM/yyyy',
                    'ca_ES'         => 'dd/MM/yyyy',
                    'ca_ES_EURO'    => 'dd/MM/yyyy',
                    'cs'            => 'd.M.yyyy',
                    'cs_CZ'         => 'd.M.yyyy',
                    'da'            => 'dd-MM-yyyy',
                    'da_DK'         => 'dd-MM-yyyy',
                    'de'            => 'dd.MM.yyyy',
                    'de_AT'         => 'dd.MM.yyyy',
                    'de_AT_EURO'    => 'dd.MM.yyyy',
                    'de_CH'         => 'dd.MM.yyyy',
                    'de_DE'         => 'dd.MM.yyyy',
                    'de_DE_EURO'    => 'dd.MM.yyyy',
                    'de_LU'         => 'dd.MM.yyyy',
                    'de_LU_EURO'    => 'dd.MM.yyyy',
                    'el_GR'         => 'd/M/yyyy',
                    'en_AU'         => 'd/MM/yyyy',
                    'en_B'          => 'M/d/yyyy',
                    'en_BM'         => 'M/d/yyyy',
                    'en_CA'         => 'dd/MM/yyyy',
                    'en_GB'         => 'dd/MM/yyyy',
                    'en_GH'         => 'M/d/yyyy',
                    'en_HK'         => 'dd/MM/yyyy',
                    'en_ID'         => 'dd/MM/yyyy',
                    'en_IE'         => 'dd/MM/yyyy',
                    'en_IE_EURO'    => 'dd/MM/yyyy',
                    'en_IN'         => 'dd/MM/yyyy',
                    'en_NZ'         => 'd/MM/yyyy',
                    'en_SG'         => 'dd/MM/yyyy',
                    'en_UG'         => 'M/d/yyyy',
                    'en_US'         => 'M/d/yyyy',
                    'en_VU'         => 'M/d/yyyy',
                    'en_ZA'         => 'yyyy/MM/dd',
                    'es'            => 'd/MM/yyyy',
                    'es_AR'         => 'dd/MM/yyyy',
                    'es_BO'         => 'dd-MM-yyyy',
                    'es_CL'         => 'dd-MM-yyyy',
                    'es_CO'         => 'd/MM/yyyy',
                    'es_CR'         => 'dd/MM/yyyy',
                    'es_EC'         => 'dd/MM/yyyy',
                    'es_ES'         => 'd/MM/yyyy',
                    'es_ES_EURO'    => 'd/MM/yyyy',
                    'es_GT'         => 'd/MM/yyyy',
                    'es_HN'         => 'MM-dd-yyyy',
                    'es_MX'         => 'd/MM/yyyy',
                    'es_PE'         => 'dd/MM/yyyy',
                    'es_PR'         => 'MM-dd-yyyy',
                    'es_PY'         => 'dd/MM/yyyy',
                    'es_SV'         => 'MM-dd-yyyy',
                    'es_UY'         => 'dd/MM/yyyy',
                    'es_VE'         => 'dd/MM/yyyy',
                    'et_EE'         => 'd.MM.yyyy',
                    'fi'            => 'd.M.yyyy',
                    'fi_FI'         => 'd.M.yyyy',
                    'fi_FI_EURO'    => 'd.M.yyyy',
                    'fr'            => 'dd/MM/yyyy',
                    'fr_BE'         => 'd/MM/yyyy',
                    'fr_CA'         => 'yyyy-MM-dd',
                    'fr_CH'         => 'dd.MM.yyyy',
                    'fr_FR'         => 'dd/MM/yyyy',
                    'fr_FR_EURO'    => 'dd/MM/yyyy',
                    'fr_LU'         => 'dd/MM/yyyy',
                    'fr_MC'         => 'dd/MM/yyyy',
                    'hr_HR'         => 'yyyy.MM.dd',
                    'hu'            => 'yyyy.MM.dd.',
                    'hy_AM'         => 'M/d/yyyy',
                    'ga_IE'         => 'dd/MM/yyyy',
                    'in_ID'         => 'dd/MM/yyyy',
                    'is_IS'         => 'd.M.yyyy',
                    'it'            => 'dd/MM/yyyy',
                    'it_CH'         => 'dd.MM.yyyy',
                    'it_IT'         => 'dd/MM/yyyy',
                    'iw'            => 'dd/MM/yyyy',
                    'iw_IL'         => 'dd/MM/yyyy',
                    'ja'            => 'yyyy/MM/dd',
                    'ja_JP'         => 'yyyy/MM/dd',
                    'kk_KZ'         => 'M/d/yyyy',
                    'km_KH'         => 'M/d/yyyy',
                    'ko'            => 'yyyy. M. d',
                    'ko_KP'         => 'yyyy. M. d',
                    'ko_KR'         => 'yyyy. M. d',
                    'lt_LT'         => 'yyyy.M.d',
                    'lv_LV'         => 'yyyy.d.M',
                    'ms_MY'         => 'dd/MM/yyyy',
                    'nl'            => 'd-M-yyyy',
                    'nl_BE'         => 'd/MM/yyyy',
                    'nl_NL'         => 'd-M-yyyy',
                    'nl_SR'         => 'd-M-yyyy',
                    'no'            => 'dd.MM.yyyy',
                    'no_NO'         => 'dd.MM.yyyy',
                    'pl'            => 'yyyy-MM-dd',
                    'pt'            => 'dd-MM-yyyy',
                    'pt_AO'         => 'dd-MM-yyyy',
                    'pt_BR'         => 'dd/MM/yyyy',
                    'pt_PT'         => 'dd-MM-yyyy',
                    'ro_RO'         => 'dd.MM.yyyy',
                    'ru'            => 'dd.MM.yyyy',
                    'sk_SK'         => 'd.M.yyyy',
                    'sl_SI'         => 'd.M.y',
                    'sv'            => 'yyyy-MM-dd',
                    'sv_SE'         => 'yyyy-MM-dd',
                    'th'            => 'M/d/yyyy',
                    'th_TH'         => 'd/M/yyyy',
                    'tr'            => 'dd.MM.yyyy',
                    'ur_PK'         => 'M/d/yyyy',
                    'vi_VN'         => 'dd/MM/yyyy',
                    'zh'            => 'yyyy-M-d',
                    'zh_CN'         => 'yyyy-M-d',
                    'zh_HK'         => 'dd/M/yyyy',
                    'zh_HK_STROKE'  => 'dd/M/yyyy',
                    'zh_TW'         => 'yyyy/M/d'
                    };
        return localeToDateTimeFmtMap.get(UserInfo.getLocale());
    }
    
    @RemoteAction
    global static Long callDateDiff(DateTime createdDate, DateTime nmdDate, Integer seconds, Integer minuts, Integer hours)
    {
        try
        {
            String dt = nmdDate.format(getLocaleToDateTimeFmtMap());
            DateTime nmdNextContactDate = Date.parse(dt);
            nmdNextContactDate = nmdNextContactDate.addSeconds(seconds);
            nmdNextContactDate = nmdNextContactDate.addMinutes(minuts);
            nmdNextContactDate = nmdNextContactDate.addHours(hours);
            Long diffInHours = dateDiff(createdDate,nmdNextContactDate);
            return Math.round(diffInHours);
        }
        catch(Exception ex)
        {
            ApexDebugLog.logException(ex, 'createdDate ==>'+ JSON.serialize(createdDate), 'WeworkEngine', 'callDateDiff');
            return null;
        }
    }
    
    public static Settings.FieldMappings Journey2Journey() {
        Settings.FieldMappings JourneyToJourneyMappings = new Settings.FieldMappings();
        JourneyToJourneyMappings.version = 1;
        JourneyToJourneyMappings.mappings = new Map<String, Settings.MappedField>();
        JourneyToJourneyMappings.mappings.put('Primary_Contact__c', new Settings.MappedField('Primary_Contact__c'));
        JourneyToJourneyMappings.mappings.put('Primary_Lead__c', new Settings.MappedField('Primary_Lead__c'));
        return JourneyToJourneyMappings;
    }
    public static Settings.FieldMappings mapJourneyToJourney;
    static List<String> lstJourneyFields = null;
    public static List<String> getJourneyFields(){
        mapJourneyToJourney = Settings.getFieldMappings('JourneyToJourney');
        if( mapJourneyToJourney == null ) mapJourneyToJourney = Journey2Journey();
        if( lstJourneyFields == null ){
            Set<String> setJourneyFields = new Set<String>();
            setJourneyFields.add('Primary_Contact__c');
            setJourneyFields.add('Primary_Lead__c');
            for(Settings.MappedField field : mapJourneyToJourney.mappings.values()){
                if(!setJourneyFields.contains(field.fieldname))
                    setJourneyFields.add(field.fieldname.toLowerCase());
            }
            lstJourneyFields = new List<String>();
            lstJourneyFields.addAll(setJourneyFields);
        }
        return lstJourneyFields;
    }
    
    /*
    *   Created By      : Dipak Pawar
    *   Created Date    : 23-09-2016
    *   Summary         : This method will accepts the exception and return it with proper formatting.
    *   Issue No.       : ST-701
    */
    global static String exceptionFormatter(Exception exc) {
        String errorMessage = (exc.getMessage().contains('\'')) ? exc.getMessage().replace('\'', '') :  exc.getMessage();
        if(errorMessage.containsIgnoreCase('first error:') && errorMessage.containsIgnoreCase(': [')) {
            errorMessage = errorMessage.substring(errorMessage.indexOf('first error:')+12,errorMessage.lastIndexOf(': [')).replace('_', ' ');
        }
        errorMessage=errorMessage+'StackTrace :'+exc.getStackTraceString();
        return errorMessage.toLowerCase().trim().capitalize();
    }
    
    public static Settings.FieldMappings Contact2Opportunity() {        
        Settings.FieldMappings contactToActivityMappings = new Settings.FieldMappings();        
        contactToActivityMappings.version = 1;      
        contactToActivityMappings.mappings = new Map<String, Settings.MappedField>();       
        contactToActivityMappings.mappings.put('LeadSource', new Settings.MappedField('LeadSource'));       
        contactToActivityMappings.mappings.put('Lead_Source_Detail__c', new Settings.MappedField('Lead_Source_Detail__c'));                 
        contactToActivityMappings.mappings.put('utm_campaign_id__c', new Settings.MappedField('utm_campaign_id__c'));
        contactToActivityMappings.mappings.put('utm_content__c', new Settings.MappedField('utm_content__c')); 
        contactToActivityMappings.mappings.put('utm_medium__c', new Settings.MappedField('utm_medium__c')); 
        contactToActivityMappings.mappings.put('utm_source__c', new Settings.MappedField('utm_source__c')); 
        return contactToActivityMappings;       
    }
    
    /*
    *   Created By      : Anat Kumar
    *   Modified By     : Amol Darekar 
    *   Created Date    : 10/12/2016
    *   Summary         : This method will return recordtype Id for Object.
    */
    @RemoteAction
    global static string getObjectRecordTypeId(string objectName,string recordtypeName)
    {
        String[] types = new String[]{objectName};
            Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
        Schema.DescribeSObjectResult d = results[0];
        Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
        return rtMapByName.get(recordtypeName).getRecordTypeId();
    }
    
    
    /*
    *   Created By      : Ajaysinh Chauhan
    *   Created Date    : 10/15/2016
    *   Summary         : This method will reassign lead which is having owner as site user.
    */
    @RemoteAction
    global static List<SaveResult> SaveWebsiteLead(List<Lead> lstLead){
        System.debug('save');
        List<SaveResult> lstResult = WeworkEngine.SaveRecords(lstLead);
        //WeworkEngine.reassignGuestUser(lstLead);
        return lstResult;
    }
    
    @InvocableMethod
    global static void reassignGuestUser(List<Lead> objLead){
        System.debug('reassign');
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        Database.update(objLead,dmo);
        
    }
    @RemoteAction
    global static void reassignGuestUserLead(List<Lead> objLead){
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        System.debug('objLead1------'+objLead);
        objLead[0].setOptions(dmo);
        System.debug('objLead------'+objLead);
        Database.update(objLead);        
    }
    
    global class SObjectFieldDescription
    {
        public string fieldLabel{get;set;}
        public string fieldApiName{get;set;}
        public string fieldType{get;set;}
    }
    
    global class CampaignWizardSettings{
        public DefaultJourneyInfoController journeydefaultid{get;set;}
        public SuccessMessage successmessage{get;set;}
    }  
    
    global class SuccessMessage{
        public string message{get;set;}
        public Integer timeout{get;set;}
    }  
    
    global class DefaultJourneyInfoController
    {
        public string Id{get;set;}
        public list<SObjectFieldDescription> fieldAPIs {get;set;}
        public list<string> types{get;set;}
    }
    
    /*
    *   Created By      : Amol Darekar
    *   Created Date    : 16 January 2017
    *   Summary         : This method is return Picklist values
    */
    @RemoteAction
    global static List<String> getPicklistValues(String SObjectApi_name,String SObject_Field_name){ 
        List<String> lstOptionVals=new List<String>();
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(SObjectApi_name);//From the Object Api name retrieving the SObject
        Sobject Object_name = targetType.newSObject();
        Schema.sObjectType sobject_type = Object_name.getSObjectType(); //grab the sobject that was passed
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); //describe the sobject
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject
        List<Schema.PicklistEntry> pick_list_values = field_map.get(SObject_Field_name).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
        for (Schema.PicklistEntry a : pick_list_values) { //for all values in the picklist list
            lstOptionVals.add(a.getValue());//add the value  to our final list
        }
        
        return lstOptionVals;
    }
    
    @RemoteAction
    global static list<string> getAllUpdatableSobjectField(string sobjectName)
    {
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType objectSchema = schemaMap.get('Campaign');
        Map<String, Schema.SObjectField> fieldMap = objectSchema.getDescribe().fields.getMap();
        list<string> lstFields = new list<string>();
        
        for(String fieldName : fieldMap.keySet()) {
            if(fieldMap.get(fieldName).getDescribe().isUpdateable()) {
                lstFields.add(fieldName);
            }
        }
        
        return lstFields;
    }
    
    @RemoteAction
    global static string getResourceURL(string resourceName)
    {
        //Fetching the resource
        string strUrl ='';
        List<StaticResource> resourceList = [SELECT Name, NamespacePrefix, SystemModStamp FROM StaticResource WHERE Name = :resourceName];
        //Checking if the result is returned or not
        if(resourceList.size() == 1)
        {
            //Getting namespace
            String namespace = resourceList[0].NamespacePrefix;
            //Resource URL
            strUrl = '/resource/' + resourceList[0].SystemModStamp.getTime() + '/' + (namespace != null && namespace != '' ? namespace + '__' : '') + resourceName; 
        }
        
        return strUrl;
    }
     
    global class OpportunityCreationSetting {
        global String RecordType;
        global String CompanySize;
    } 
    
    global class ValidResultWithOpp{
        global Boolean isValid {get;set;}
        global Boolean isBillingAccountError {get;set;}
        global Boolean isValidOwner {get;set;}
        global string errorMsg {get;set;}
        global Opportunity objOpportunity {get;set;}
        global List<String> opportunityBuildings {get;set;}
        global string settingData {get;set;}
    }
      
    
  /************************************************************************************************************************************
	Author              : Amol Darekar
	Description         : This function get called from REST API where account is get search using UUID.
	Created Date        : 24-June-2017
	Issue No.           : ST-1156
  ***********************************************************************************************************************************
    Author              : Krishana Tupe
	Description         : Added comment structure
	Modified Date       : 28-July-2018	
   ************************************************************************************************************************************/
   global static String getMasterAccountUUID(string accountUUID) {       
        //Search for UUID in Merge Account object record and return Master Account UUID
        List<Merged_Account__c> lstMergeAccount = [SELECT Id,Master_UUID__c,Merged_Account_UUID__c FROM Merged_Account__c WHERE Merged_Account_UUID__c =: accountUUID LIMIT 1];
        if((!lstMergeAccount.isEmpty()) && lstMergeAccount.size() > 0){
            return lstMergeAccount.get(0).Master_UUID__c; 
        }
        return null;    
    }
    
    @RemoteAction
    global static Integer getLowerCompanySize(String size){
        return WithoutSharingUtilityController.getLowerSize(size);
    }  
  
  /************************************************************************************************************************************
	Author              : Shobhit Gahlot
	Description         : This function is used to generate uuid used in sendpaperwork button on opportunity
	Created Date        : 24-June-2017
	Issue No.           : ST-1298
  ***********************************************************************************************************************************
    Author              : Krishana Tupe
	Description         : Added comment structure
	Modified Date       : 28-July-2018	
   ************************************************************************************************************************************/
    webservice static String getOpportunityEncodedID(Id opportunityId) {
        return EncodingUtil.base64Encode(Blob.valueOf(opportunityId));
    }

    public static Map<String, sObject> getMapFromList(List<sObject> records, String fieldKey){
        Map<String, sObject> recordByFieldValue = new Map<String, sObject>();
        for(sObject record : records){
            if( String.isNotBlank(String.valueOf(record.get(fieldKey))) ){
                recordByFieldValue.put(String.valueOf(record.get(fieldKey)), record);
            }
        }
        return recordByFieldValue;
    }
    
    public static Map<String, Id> getMapObjectRecordTypeId(string objectName){
        String[] types = new String[]{objectName};
            Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
        Schema.DescribeSObjectResult objDescribeSObjectResult = results[0];
        Map<String,Schema.RecordTypeInfo> rtMapByName = objDescribeSObjectResult.getRecordTypeInfosByName();
        Map<String, Id> mapRecordTypeNameAndId =  new Map<String, Id>();
        for(String rtName : rtMapByName.keyset()){
            mapRecordTypeNameAndId.put(rtName, rtMapByName.get(rtName).getRecordTypeId());
        }
        return mapRecordTypeNameAndId;
    }
       
}