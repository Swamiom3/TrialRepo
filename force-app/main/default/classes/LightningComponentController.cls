/************************************************************************************************************************************
    Author      :   Ajaysinh Chauhan
    Description :   This class contain all aura methods that are used in lightning components.

    History     :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           -                   Ajaysinh Chauhan        Initial Developement
    2           03 May 2018         Krishana Tupe           Chnages for exception logging.
    3	        07/18/2019			Nicholas Zozaya		    Add methods for BillingAccountMigrator component.
    4	        02/06/2020			Vaishnavi Khandar		Deletion of methods which is no longer in use.
    5           8 Dec, 2021         Pawel Biszczak          Add Billing Accounts' migration logic
**************************************************************************************************************************************/
global without sharing class LightningComponentController{
    public class LightningComponentControllerException extends Exception{}
    public static Boolean isInvoker = false;
    public static Savepoint sp {get;set;}
    @TestVisible
    private static final BuildingSelector buildingSelector = new BuildingSelector();
    @TestVisible
    private static final GeographySelector geographySelector = new GeographySelector();
    @TestVisible
    private static UserSelector userSelector = new UserSelector();
    @TestVisible
    private static final JourneySelector journeySelector = new JourneySelector();

    static {
        isInvoker = ApexDebugLog.registerRootInvoker(ApexDebugLog.InvokerType.AURA, 'LightningComponentController' + 'getsObjectPrefix', ApexDebugLog.InvokerType.AURA);
    }

   /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method used to delete users Logs.Used in apex Log Lightning component
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getsObjectPrefix(String objName){
        try{
            DatabaseResult result = new DatabaseResult(Schema.getGlobalDescribe().get(objName).getDescribe().getKeyPrefix());
            return result;
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,objName, 'LightningComponentController', 'getsObjectPrefix');
            return (new DatabaseResult(pEx));
        }
    }

    /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method used to get TimezoneOffset.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getTimezoneOffset(){
        try{
            TimeZone tz = UserInfo.getTimeZone();
            DatabaseResult result = new DatabaseResult(tz.getOffset(DateTime.newInstance(2017,04,05)));
            return result;
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,'', 'LightningComponentController', 'getTimezoneOffset');
            return (new DatabaseResult(pEx));
        }
    }

    @AuraEnabled
    public static DatabaseResult getQueryData(String query) {
       return getQueryData(query, null);
    }

    /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is take a query as a argument in string format and processed the result of Query.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getQueryData(String query, Map<String, object> params) {
        try{
            if(params != NULL && params.get('sobjectName') != NULL && String.valueOf(params.get('sobjectName')).toLowerCase() == 'building__c'){
                return new DatabaseResult(getBuildingData(params));
            }else{
                return new DatabaseResult(Database.query(query));
            }
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,query, 'LightningComponentController', 'getQueryData');
            return (new DatabaseResult(pEx));
        }
    }

/****************************************************************************************************************************
        Author              : Jitesh Adwani
        Description         : This method is used to fetch the Building Data.
        Created Date        : 7th,August 2020
*****************************************************************************************************************************/
    public static List<Building__c> getBuildingData(Map<String, object> params){
        if(params == null){
            return null;
        }
        if(String.isBlank((String)params.get('sfRecordId'))){
            return buildingSelector.getBuildingsByKeywordWithLimit(String.valueOf(params.get('keyWord')),
                                                                   Integer.valueOf(params.get('addLimit')));
        }else{
            return buildingSelector.getBuildingsById((Id)params.get('sfRecordId'));
        }
    }

    webservice static String getQueryDataService(String query) {
        return JSON.serialize(getQueryData(query));
    }

    /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is take list of query as a argument in string format and processed the result of Queries.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getListQueryData(List<String> arrQuery) {
        try{
            List<List<sObject>> lstData = new List<List<sObject>>();
            for(String s : arrQuery){
                lstData.add(Database.query(s));
            }
            DatabaseResult result = new DatabaseResult(lstData);
            return result;
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,arrQuery != NULL ? String.join(arrQuery,','): '', 'LightningComponentController', 'getListQueryData');
            return (new DatabaseResult(pEx));
        }
    }

  /************************************************************************************************************************************
    Author              : Rupesh Patil
    Description         : This method is used to get data by SOSL queries.
    Created Date        : 15 May 2018
    Issue No.           : ST-2379
   **************************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getListQueryDataBySOSL(List<String> arrQuery) {
        try{
            List<List<sObject>> lstData = new List<List<sObject>>();
            for(String s:arrQuery){
                lstData.add(Search.query(s)[0]);
            }
            DatabaseResult result = new DatabaseResult(lstData);
            return result;
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,arrQuery != NULL ? String.join(arrQuery,','): '', 'LightningComponentController', 'getListQueryDataBySOSL');
            return (new DatabaseResult(pEx));
        }
    }

    /*******************************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is takes list of Records as a argument and save newly inserted record and updated record in salesforce.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   ********************************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult saveRecords(List<sObject> records) {
        try{
            sp = Database.setSavepoint();
            List<sObject> lstInsert = new List<sObject>();
            List<sObject> lstUpdate = new List<sObject>();
            for(sObject record : records){
                if(String.isBlank(record.Id)){
                    lstInsert.add(record);
                }else{
                    lstUpdate.add(record);
                }
            }
            Map<String,Object> response = new Map<String,Object>();
            response.put('insertedRecords',Database.insert(lstInsert));
            response.put('updatedRecords',Database.update(lstUpdate));
            return new DatabaseResult(JSON.serialize(response));
        }catch(Exception pEx){
            if(sp != NULL){
                Database.rollback(sp);
            }
            ApexDebugLog.logException(pEx,records != NULL ? JSON.serialize(records) : '', 'LightningComponentController', 'saveRecords');
            return (new DatabaseResult(pEx));
        }
    }

    /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is takes single Records as a argument and save newly inserted record and updated record in salesforce.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult saveRecord(sObject record) {
        try{
            sp = Database.setSavepoint();
            if(String.isBlank(record.Id)){
                DatabaseResult result = new DatabaseResult(JSON.serialize(Database.insert(record)));
                return result;
            }else{
                DatabaseResult result = new DatabaseResult(JSON.serialize(Database.update(record)));
                return result;
            }
        }catch(Exception pEx){
            if(sp != NULL){
                Database.rollback(sp);
            }
            ApexDebugLog.logException(pEx,JSON.serialize(record), 'LightningComponentController', 'saveRecord');
            return (new DatabaseResult(pEx));
        }
    }

   /****************************************************************************************************************************
        Author              : Krishna Tupe
        Description         : This method is use to delete single record.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult deleteRecord(String recordToDelete) {
        try{
            sp = Database.setSavepoint();
            Id deleteRecord=(Id)recordToDelete;
            DatabaseResult result = new DatabaseResult(JSON.serialize(Database.delete(deleteRecord)));
            return result;
        }catch(Exception pEx){
            if(sp != NULL){
                Database.rollback(sp);
            }
            ApexDebugLog.logException(pEx,recordToDelete, 'LightningComponentController', 'deleteRecord');
            return (new DatabaseResult(pEx));
        }
    }

   /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is use to delete list of records.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult deleteRecords(List<String> recordsToDelete) {
        try{
            sp = Database.setSavepoint();
            DatabaseResult result = new DatabaseResult(JSON.serialize(Database.delete(recordsToDelete)));
            return result;
        }catch(Exception pEx){
            if(sp != NULL){
                Database.rollback(sp);
            }
            ApexDebugLog.logException(pEx,recordsToDelete != NULL ? String.join(recordsToDelete,','): '', 'LightningComponentController', 'deleteRecords');
            return (new DatabaseResult(pEx));
        }
    }

   /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is use to get Object field metadate by using getDescribe().
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getFieldsMetadata(String sObjectName,List<String> fields) {
        try{
            Map<String,Object> mapFields = new Map<String,Object>();
            for(String fieldName : fields){
                mapFields.put(fieldName,Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap().get(fieldName).getDescribe());
            }
            DatabaseResult result = new DatabaseResult(JSON.serialize(mapFields));
            return result;
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,'sObjectName==>'+sObjectName+' fields==>'+String.join(fields, ','), 'LightningComponentController', 'getFieldsMetadata');
            return (new DatabaseResult(pEx));
        }
    }

    /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is use to get Relation Fields Metadata metadate by using getDescribe().
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getRelationFieldsMetadata(List<String> fields) {
        try{
            Map<String,Object> mapFields = new Map<String,Object>();
            for(String field:fields){
                String name = field.split(':')[0];
                String relation = field.split(':')[1];
                String sObjectName = relation.substring(0,relation.indexOf('.'));
                String fieldName = relation.substring(relation.indexOf('.')+1,relation.length());
                mapFields.put(name,Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap().get(fieldName).getDescribe());
            }
             DatabaseResult result = new DatabaseResult(JSON.serialize(mapFields));
            return result;
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,fields != NULL ? String.join(fields,','): '', 'LightningComponentController', 'getRelationFieldsMetadata');
            return (new DatabaseResult(pEx));
        }
    }
    /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is use to get field Metadata by using getDescribe().
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getFieldMetadata(String sObjectName,String fieldName) {
        try{
            DatabaseResult result = new DatabaseResult(JSON.serialize(Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap().get(fieldName).getDescribe()));
            return result;
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,'sObjectName==>'+sObjectName+' fields==>'+fieldName, 'LightningComponentController', 'getFieldMetadata');
            return (new DatabaseResult(pEx));
        }
    }

   /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is takes sobject name as a argument and get All the Fields.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getAllFields(String sObjectName) {
        try{
            Map<String,Object> mapFields = new Map<String,Object>();
            List<Schema.DescribeFieldResult> lstFields = new List<Schema.DescribeFieldResult>();
            Schema.SObjectType objSchemaSobjectType = Schema.getGlobalDescribe().get(sObjectName);
            Map<String, Schema.SobjectField> mapFieldDescribe = objSchemaSobjectType.getDescribe().fields.getMap();
            for(String fieldName: mapFieldDescribe.keyset()){
                Schema.DescribeFieldResult fieldResult = mapFieldDescribe.get(fieldName).getDescribe();
                if(fieldResult.isCreateable()){
                    lstFields.add(fieldResult);
                }
            }
            mapFields.put('name',sObjectName);
            mapFields.put('label',objSchemaSobjectType.getDescribe().getLabel());
            mapFields.put('fields',lstFields);
            DatabaseResult result = new DatabaseResult(JSON.serialize(mapFields));
            return result;
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,sObjectName, 'LightningComponentController', 'getAllFields');
            return (new DatabaseResult(pEx));
        }
    }
 /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is used to get query/table data.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getTableData(String query) {
        try{
            String resultedQuery = escapeSpecialChars(query);
            String countQuery = query.split(' LIMIT')[0];
            // Modified by Dipak Pawar for handler exception
            if(countQuery.containsAny(' Offset 0')){
                countQuery = countQuery.replace(' Offset 0','');
            }
            Map<String,Object> tableData = new Map<String,Object>();
            tableData.put('totalRecords',Database.query(countQuery+' LIMIT 2000').size());
            tableData.put('records',Database.query(query));
            DatabaseResult result = new DatabaseResult( tableData );
        return result;
        } catch(Exception pEx){
            ApexDebugLog.logException(pEx,'getTableData==>'+query, 'LightningComponentController', 'getTableData');
            return (new DatabaseResult(pEx));
        }
    }

    /****************************************************************************************************************************
        Author              : Shivprasad Patil
        Description         : This method is used to get Page Layout for creating new record.
        Created Date        : 17 Oct 2018
        Last Modified By    :
        Last Modified Date  :
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getLayoutForNewRecord(String sObjectName) {
        try{
            Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(sObjectName).getDescribe();
            String masterRecordTypeId = describeResult.getRecordTypeInfosByName().get('Master').getRecordTypeId();
            DatabaseResult result = LightningComponentController.executeRestQuery(false,'GET',( URL.getSalesforceBaseUrl().toExternalForm()+'/services/data/v37.0/sobjects/'+sObjectName+'/describe/layouts/'+masterRecordTypeId ),new Map<String,String>{'Authorization'=>'Standard'},'');
            if(result.success){
                Map<String,Object> mapLayout = new Map<String,Object>();
                mapLayout.put('sObjectName',sObjectName);
                mapLayout.put('label',describeResult.getLabel());
                mapLayout.put('layout',result.data);
                return new DatabaseResult(JSON.serialize(mapLayout));
            }
            return result;
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,'sObjectName==>'+sObjectName, 'LightningComponentController', 'getLayoutForNewRecord');
            return (new DatabaseResult(pEx));
        }
    }

   /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is used to get Page Layout according to record type.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
     @AuraEnabled
    public static DatabaseResult getLayout(Id recordId) {
        try{
            String sessionId = UserInfo.getSessionId();
            HttpRequest request = new HttpRequest();
            request.setHeader('Authorization', 'Bearer ' + sessionId);
            request.setHeader('Content-Length', '0');
            request.setMethod('GET');
            String sObjectName = recordId.getSobjectType().getDescribe().getName();
            List<sObject> lstRecordTypes = [SELECT Id,Name FROM RecordType WHERE SObjectType =:sObjectName];
            List<sObject> lstRecord;
            if(lstRecordTypes.size()>0){
                lstRecord = Database.query('SELECT Id,Name,RecordTypeId,RecordType.Name,CreatedDate,CreatedBy.Name,LastModifiedDate,LastModifiedBy.Name FROM '+sObjectName+' WHERE Id=\''+recordId+'\'');
                String recordTypeId;
                if(lstRecord != NULL && lstRecord.size()>0){
                    recordTypeId = String.valueOf(lstRecord[0].get('RecordTypeId'));
                }
                if(recordTypeId != NULL){
                    request.setEndPoint(URL.getSalesforceBaseUrl().toExternalForm()+'/services/data/v37.0/sobjects/'+sObjectName+'/describe/layouts/'+recordTypeId);
                }else{
                    recordTypeId = recordId.getSobjectType().getDescribe().getRecordTypeInfosByName().get('Master').getRecordTypeId();
                    request.setEndPoint(URL.getSalesforceBaseUrl().toExternalForm()+'/services/data/v37.0/sobjects/'+sObjectName+'/describe/layouts/'+recordTypeId);
                }
            }else{
                lstRecord = Database.query('SELECT Id,Name,CreatedDate,CreatedBy.Name,LastModifiedDate,LastModifiedBy.Name FROM '+sObjectName+' WHERE Id=\''+recordId+'\'');
                request.setEndPoint(URL.getSalesforceBaseUrl().toExternalForm()+'/services/data/v37.0/sobjects/'+sObjectName+'/describe/layouts');
            }
            Http req = new Http();
            HttpResponse response = req.send(request);
            Map<String,Object> mapLayout = new Map<String,Object>();
            mapLayout.put('sObjectName',sObjectName);
            mapLayout.put('label',recordId.getSobjectType().getDescribe().getLabel());
            mapLayout.put('layout',response.getBody());
            if(lstRecord != NULL && lstRecord.size()>0)
            {
                if(lstRecordTypes.size()>0){
                    if(lstRecord[0].get('RecordTypeId') != NULL){
                        mapLayout.put('recordTypeId',lstRecord[0].get('RecordTypeId'));
                        mapLayout.put('recordTypeName',lstRecord[0].getSObject('RecordType').get('Name'));
                    }else{
                        mapLayout.put('recordTypeId',recordId.getSobjectType().getDescribe().getRecordTypeInfosByName().get('Master').getRecordTypeId());
                        mapLayout.put('recordTypeName',recordId.getSobjectType().getDescribe().getRecordTypeInfosByName().get('Master').getName());
                    }
                }
                mapLayout.put('recordName',lstRecord[0].get('Name'));
            }
            mapLayout.put('lstRecordTypes',lstRecordTypes);
            return new DatabaseResult( JSON.serialize(mapLayout) );
       }catch(Exception pEx){
            ApexDebugLog.logException(pEx,'recordId==>'+recordId, 'LightningComponentController', 'getLayout');
            return (new DatabaseResult(pEx));
        }
    }


   /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is used to get Page Layout with mapping.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getLayoutWithMapping(String sObjectName) {
        try{
            String sessionId = UserInfo.getSessionId();
            HttpRequest request = new HttpRequest();
            request.setHeader('Authorization', 'Bearer ' + sessionId);
            request.setHeader('Content-Length', '0');
            request.setMethod('GET');
            List<sObject> lstRecordTypes = [SELECT Id,Name FROM RecordType WHERE SObjectType =:sObjectName];
            Map<String,Object> mapResponse = new Map<String,Object>();
            Map<String,Object> tempMap = new Map<String,Object>();
            if(lstRecordTypes.size()==0){
                tempMap.put('recordTypeId','default');
                tempMap.put('recordTypeName','Default');
                request.setEndPoint(URL.getSalesforceBaseUrl().toExternalForm()+'/services/data/v37.0/sobjects/'+sObjectName+'/describe/layouts');
                Http req = new Http();
                HttpResponse response = req.send(request);
                tempMap.put('layout',response.getBody());
                mapResponse.put('default',tempMap);
            }else{
                for(sObject rec:lstRecordTypes){
                    tempMap = new Map<String,Object>();
                    tempMap.put('recordTypeId',rec.get('Id'));
                    tempMap.put('recordTypeName',rec.get('Name'));
                    request.setEndPoint(URL.getSalesforceBaseUrl().toExternalForm()+'/services/data/v37.0/sobjects/'+sObjectName+'/describe/layouts/'+rec.Id);
                    Http req = new Http();
                    HttpResponse response = req.send(request);
                    tempMap.put('layout',response.getBody());
                    mapResponse.put(String.valueOf(rec.get('Id')),tempMap);
                }
            }
            mapResponse.put('recordTypes',lstRecordTypes);
            DatabaseResult result = new DatabaseResult( mapResponse );
      return result;
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,'sObjectName==>'+sObjectName, 'LightningComponentController', 'getLayoutWithMapping');
            return (new DatabaseResult(pEx));
        }
    }

   /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is used to describe By Id.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult describeById(List<Id> lstIds) {
        try{
            Map<Id,String> mapResponse = new Map<Id,String>();
            for(Id rec:lstIds){
                mapResponse.put(rec,rec.getSobjectType().getDescribe().getLabel());
            }
            DatabaseResult result = new DatabaseResult( mapResponse );
      return result;
        } catch(Exception pEx){
            ApexDebugLog.logException(pEx,'lstIds==>'+lstIds, 'LightningComponentController', 'describeById');
            return (new DatabaseResult(pEx));
        }
    }

   /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is used to get Sobject name by record Id.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getSobjectNameById(Id recordId) {
        try{
            Schema.SObjectType sobjectType = recordId.getSObjectType();
            DatabaseResult result = new DatabaseResult( sobjectType.getDescribe().getName());
            return result;
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,'recordId==>'+recordId, 'LightningComponentController', 'getSobjectNameById');
            return (new DatabaseResult(pEx));
        }
    }

   /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is used to get all record types by record Id.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getAllRecordTypesById(Id recordId) {
        try{
            Schema.SObjectType sobjectType = recordId.getSObjectType();
            List<RecordType> lstRecordTypes = [SELECT Id,Name FROM RecordType WHERE SobjectType=:sobjectType.getDescribe().getName()];
            DatabaseResult result = new DatabaseResult( lstRecordTypes );
     		return result;
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,'recordId==>'+recordId, 'LightningComponentController', 'getAllRecordTypesById');
            return (new DatabaseResult(pEx));
        }
    }

   /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is used to get User Information.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getUserInfo() {
        try{
            DatabaseResult result = new DatabaseResult( JSON.serialize([SELECT Id,Name,Email,SmallPhotoUrl,Profile.Name,TimeZoneSidKey,Home_Building__c FROM User WHERE Id=:UserInfo.getUserId()]) );
            return result;
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,'', 'LightningComponentController', 'getUserInfo');
            return (new DatabaseResult(pEx));
        }
    }

   /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is used to get UI Theme.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getUITheme() {
        try{
            DatabaseResult result = new DatabaseResult( UserInfo.getUiTheme() );
            return result;
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,'', 'LightningComponentController', 'getUITheme');
            return (new DatabaseResult(pEx));
        }
    }

   /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is used to get Record Type Information.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getRecordTypeInfo(String objName) {
        try{
            Map<Id,String> recTypeNameWithIdMap= new Map<Id,String>();
            if(objName!= NULL){
                for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(objName).getDescribe().getRecordTypeInfosByName().values()){
                    recTypeNameWithIdMap.put(recInfo.getRecordTypeId(),recInfo.getName());
                }
            }
            DatabaseResult result = new DatabaseResult( recTypeNameWithIdMap );
            return result;
        } catch(Exception pEx){
            ApexDebugLog.logException(pEx,'sObjectName==>'+objName, 'LightningComponentController', 'getRecordTypeInfo');
            return (new DatabaseResult(pEx));
        }
    }
    /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : Class for SendPaperwork data.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    global class SendPaperwork {
        @AuraEnabled
        public List<OpportunityCreationSetting> OpportunityCreationSetting;
        @AuraEnabled
        public String URL;
        @AuraEnabled
        public List<String> ExcludedProfiles;
    }

    /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : Class for OpportunityCreationSetting.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    public class OpportunityCreationSetting {
        @AuraEnabled
        public String RecordType;
        @AuraEnabled
        public String CompanySize;
    }

   /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is used to check Oppourtunity is valid for SendProposal.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult describeTable(String sObjectName,List<String> fields){
        try{
            Map<String,Object> mapFields = new Map<String,Object>();
            for(String field:fields){
                if(field.contains('.')){
                    String objectName = sObjectName;
                    String fieldName;
                    Schema.DescribeFieldResult fResult;
                    for(Integer i=0;i<field.split('\\.').size();i++){
                        if(i==field.split('\\.').size()-1){
                            mapFields.put(field,Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(field.split('\\.')[i]).getDescribe());
                        }else{
                            if(field.split('\\.')[i].contains('__r')){
                                fieldName = field.split('\\.')[i].split('__r')[0]+'__c';
                            }else{
                                fieldName = field.split('\\.')[i]+'Id';
                            }
                            fResult = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldName).getDescribe();
                            objectName = fResult.getReferenceTo()[0]+'';
                        }
                    }
                }
                else{
                    mapFields.put(field,Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap().get(field).getDescribe());
                }
            }
            DatabaseResult result = new DatabaseResult( JSON.serialize(mapFields) );
            return result;
        } catch(Exception pEx){
            ApexDebugLog.logException(pEx,'sObjectName==>'+sObjectName+'fields==>'+string.join(fields, ','), 'LightningComponentController', 'describeTable');
            return (new DatabaseResult(pEx));
        }
    }

   /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is used to get today Date.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getTodaysDate(){
        return new DatabaseResult(System.today());
    }

   /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         :
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult executeRest(String method,String endPointUrl,Map<String,String> headers,String body){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPointUrl);
        req.setMethod(method);
        for(String header:headers.keyset()){
            req.setHeader(header, headers.get(header));
        }
        if(method.toLowerCase()!='get'){
            req.setbody(body);
        }
        Http http = new Http();
        HTTPResponse response = http.send(req);
        return new DatabaseResult(response.getBody());
    }

    /****************************************************************************************************************************
        Author              : Milanjeet
        Description         : Overload executeRest for GET Method to set correct EndpointURL and Session Id
        Created Date        : 2:50 AM 7/6/2017
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult executeRestQuery(Boolean setUrl,String method,String endPointUrl,Map<String,String> headers,String body){
        String endPoint_Url;
            Object response;
            if(setUrl){
                String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
                baseUrl = baseUrl.replace('--c.', '.');
                baseUrl = baseUrl.replace('visual.force', 'my.salesforce');
                endPoint_Url = baseUrl+endPointUrl;
            }else{
                endPoint_Url = endPointUrl;
            }
            if(headers.containsKey('Authorization') && headers.get('Authorization')=='Standard'){
                headers.put('Authorization','Bearer '+userInfo.getSessionId());
            }
            if(!headers.containsKey('Content-type') && method.equalsIgnoreCase('post')){
                headers.put('Content-type','application/json');
            }
            if(method.equalsIgnoreCase('post')){
                response = executeRest(method, endPoint_Url, headers, body).data;
            }else{
               response = executeRest(method, endPoint_Url, headers, '').data;
            }
            return new DatabaseResult(response);
    }

   /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is used to get Session Id.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getSessionId(){
        try{
            return new DatabaseResult(UserInfo.getSessionId());
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,'', 'LightningComponentController', 'getSessionId');
            return (new DatabaseResult(pEx));
        }
    }

   /****************************************************************************************************************************
        Author              : Sunil Bhosale
        Description         : this method is used to add BusinessDays.
        Created Date        : 02/07/2017
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult addBusinessDays(Integer utcYear, Integer utcMonth, Integer utcDate, Integer daysToAdd){
        try{
            Date date1 =  Date.newinstance(Integer.valueOf(utcYear+''),Integer.valueOf(utcMonth+'') ,Integer.valueOf(utcDate+'') );
            String dt = date1.format();
            Date givenDate = date.parse(dt);
            return new DatabaseResult(DateUtilities.addBusinessDays(givenDate,Integer.valueOf(daysToAdd+'') ));
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,'utcYear==>'+utcYear+'utcMonth==>'+utcMonth+'utcDate==>'+utcDate+'daysToAdd==>'+daysToAdd, 'LightningComponentController', 'getUserProfileInfo');
            return (new DatabaseResult(pEx));
        }
    }
    /*************************************************************************************************************************************************************
        Author              : Shobhit Galot
        Description         : This method is used for GenerateJourney Lightning Component it is used to return a wrapper of setting 'User/Queue Journey Creation'
        Created Date        : -
        Issue No            : ST-1316
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   **************************************************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getJourneyUserQueue(string settingId){
        try{
            List<Sales_Console_Setting__mdt> settings = new List<Sales_Console_Setting__mdt>();
            set<Id> setUsersIds = new set<Id>();
            set<Id> setQueueIds = new set<Id>();
            UserQueueJourneyWrap objUserQueueJourneyWrap = new UserQueueJourneyWrap();
            if(string.isNotBlank(settingId)){
                settings = [SELECT Id, DeveloperName, Data__c FROM Sales_Console_Setting__mdt WHERE Id =: settingId LIMIT 1];
                UserQueueJourneySettings wrap = (UserQueueJourneySettings)JSON.deserialize(settings[0].Data__c, UserQueueJourneySettings.class);
                for(AllowedUsersSettings user : wrap.allowedUsers){
                    setUsersIds.add(user.Id);
                }
                for(AllowedQueueSettings queue : wrap.allowedQueues){
                    setQueueIds.add(queue.Id);
                }
                if(setUsersIds.size() > 0 && setUsersIds != NULL){
                	objUserQueueJourneyWrap.lstactiveUsers = userSelector.getActiveUsersByIdWithOrderByName(setUsersIds);
                }
                if(setQueueIds.size() > 0 && setQueueIds != NULL){
                    objUserQueueJourneyWrap.lstQueues =  [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Id IN : setQueueIds ORDER BY Name Asc];
                }
                objUserQueueJourneyWrap.settings =  JSON.serialize(settings);
            }
            return new DatabaseResult(JSON.serialize(objUserQueueJourneyWrap));
        } catch(Exception pEx){
            ApexDebugLog.logException(pEx,'settingId==>'+settingId, 'LightningComponentController', 'getJourneyUserQueue');
            return (new DatabaseResult(pEx));
        }
    }
     /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is used to convert leads to existing lead and create account,contact and opportunity.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/


    @AuraEnabled
    public static DatabaseResult convertLeadsToExisting(Lead objLead){
        try{
            update objLead;
            List<Lead> lstLeads = checkChangeInLeadForFTE(objLead);
            RESTAPITourModelsV2.Input objTourPayload = new RESTAPITourModelsV2.Input();
            objTourPayload.email = String.isNotBlank(objLead.Email) ? objLead.Email.toLowerCase() : NULL;
            LeadConverterHelper.setLeadGenerateJourney(objLead);
            Map<String,Map<String,Id>> mapConvertedLead = LeadConverterHelper.manageLead(new List<Lead>{objLead},objTourPayload);
            LeadConverterHelper.markLeadsTasksCompletedOnLeadConversion(lstLeads);
            return new DatabaseResult(String.isNotBlank(objLead.Email) ? JSON.serialize(mapConvertedLead.get(objLead.Email.toLowerCase())) : NULL);
        } catch(Exception pEx){
            ApexDebugLog.logException(pEx,JSON.serializePretty(objLead), 'LightningComponentController', 'convertLeadsToExisting');
            return (new DatabaseResult(false,pEx,pEx.getMessage()));
        }
    }

    public Static List<Lead> checkChangeInLeadForFTE(Lead objlead){
        List<Lead> lstLeads = [SELECT Id, Email, Account__c, Account__r.Unomy_Company_Size__c, Account__r.RecordType.Name, Account__r.Number_of_Full_Time_Employees__c, Account__r.RecordType.Id, (SELECT Id, Status, WhoId, WhatId FROM Tasks WHERE Status <> 'Completed') From Lead WHERE Id =: objLead.Id];
        if(lstLeads.size() > 0 && String.isBlank(lstLeads[0].Account__r.Unomy_Company_Size__c) &&  lstLeads[0].Account__r.RecordType.Name != 'Referral' && lstLeads[0].Account__r.Number_of_Full_Time_Employees__c == NULL && objLead.Number_of_Full_Time_Employees__c != NULL){
            if(AccountAssignmentHelper.getRecordTypeIdFromCompanySize(new Account(Number_of_Full_Time_Employees__c = objLead.Number_of_Full_Time_Employees__c, Unomy_Company_Size__c = NULL)) != String.valueOf(lstLeads[0].Account__r.RecordType.Id)){
                Account objAccount = new Account(Id = lstLeads[0].Account__c, Number_of_Full_Time_Employees__c = objLead.Number_of_Full_Time_Employees__c);
                update objAccount;
            }
        }
        return lstLeads;
    }

    /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This class is for AllowedUsersSettings data.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    global class AllowedUsersSettings {
        @AuraEnabled
        public String userName;
        @AuraEnabled
        public String Id;
    }
    /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This class is for AllowedQueueSettings data.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    global class AllowedQueueSettings {
        @AuraEnabled
        public String queueName;
        @AuraEnabled
        public String Id;
    }

    /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This class is for UserQueueJourneySettings data.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    global class UserQueueJourneySettings{
        @AuraEnabled
        public AllowedUsersSettings[] allowedUsers;
        @AuraEnabled
        public AllowedQueueSettings[] allowedQueues;
    }

    /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This class is for UserQueueJourneyWrap data.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    global class UserQueueJourneyWrap{
        @AuraEnabled
        public List<Group> lstQueues;
        @AuraEnabled
        public List<User> lstactiveUsers;
        @AuraEnabled
        public string settings;
    }

  /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is used for getUserProfileInfo.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getUserProfileInfo(){
        try{
            return new DatabaseResult(JSON.serialize([SELECT Id, Name FROM profile WHERE Id=:UserInfo.getProfileId()]));
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,'', 'LightningComponentController', 'getUserProfileInfo');
            return (new DatabaseResult(pEx));
        }
    }


   /****************************************************************************************************************************
        Author              : Milanjeet
        Description         : This function is used to send csv file to current user.
        Created Date        : 27-sept-2017
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    global static DatabaseResult SendMail(string csvSettingBackUp){
        try{
            User objUser = UserUtility.getUserById(UserInfo.getUserId());
            Messaging.SingleEmailMessage emailsuccess =new Messaging.SingleEmailMessage();
            emailsuccess.setHtmlBody('Hello '+objUser.Name+', <br/>Setting has been successfuly updated on your instance from preprod.<br/> Backup for old setting has been attached to this mail for backup purpose.<br/>  Thank you.');

            String[] toAllAddresses = new list<string>();
            toAllAddresses.add(objUser.Email);
            String subject ='Setting Backup Data Before Updation from Pre-Prod';
            emailsuccess.setSubject(subject);
            emailsuccess.setTargetObjectId(objUser.Id);
            emailsuccess.setSaveAsActivity(false);

            Messaging.EmailFileAttachment csvAttcSettingBackUp = new Messaging.EmailFileAttachment();

            List<Messaging.Emailfileattachment> lstAttachments = new List<Messaging.Emailfileattachment>();
            if(String.isNotBlank(csvSettingBackUp)){
                blob csvBlob = Blob.valueOf(csvSettingBackUp);
                string csvname= 'Settings Backup.csv';
                csvAttcSettingBackUp.setFileName(csvname);
                csvAttcSettingBackUp.setBody(csvBlob);
                lstAttachments.add(csvAttcSettingBackUp);
            }
            if(lstAttachments.size()>0 && lstAttachments != NULL){
                emailsuccess.setFileAttachments(lstAttachments );
            }
            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {emailsuccess});
            return new DatabaseResult('done');
     } catch(Exception pEx){
            ApexDebugLog.logException(pEx,'csvSettingBackUp==>'+csvSettingBackUp, 'LightningComponentController', 'SendMail');
            return (new DatabaseResult(pEx));
        }
    }


   /**************************************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This is a Class to Wrappe Account and Contact Details.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   ***************************************************************************************************************************************************/
    public class WrapperAccountContact{
        @AuraEnabled
        public String Name;
        @AuraEnabled
        public String UUID;
        @AuraEnabled
        public String PrimaryMemberName;
        @AuraEnabled
        public String PrimaryMemberEmail;
        @AuraEnabled
        public String PrimaryMemberPhone;
        @AuraEnabled
        public String PrimaryMemberUUID;

    }

   /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is used to escape Special Character.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    public static String escapeSpecialChars(String target){
        Map<String,String> mapRegExp = new Map<String,String>{'\''=>'\\\\\'','\\\\'=>'\\\\\\\\'};
        String regExp;
        List<String> lstStr = new List<String>(mapRegExp.keySet());
        String res = String.join(lstStr,'');
        if(target.containsAny(res))
        {
            if( target.indexOf('\\') !=-1 && mapRegExp.containsKey('\\\\') )
            {
                regExp =  '[\\\\]';
                target = target.replaceAll(regExp,mapRegExp.get('\\\\'));
                mapRegExp.remove('\\\\');
            }

            for(String strKey : mapRegExp.keySet())
            {
                if(target.indexOf(strKey) !=-1)
                {
                    regExp =  '['+strKey+']';
                    target = target.replaceAll(regExp,mapRegExp.get(strKey));
                }
            }
        }
        return target;
    }

   /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is used to get Object Fields.we should just pass a object name in string format.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    public static DatabaseResult getObjectFields(String sObjectName){
        try{
            List<String> listSObjectFields = new List<String>();
            Map<String, Schema.SObjectField> mapSObjectDesc = Schema.getGlobalDescribe().get(sObjectName.toLowerCase()).getDescribe().Fields.getMap();
            for(Schema.SObjectField field : mapSObjectDesc.values()){
                if (field.getDescribe().isCreateable()){
                    listSObjectFields.add(field.getDescribe().getName());
                }
            }
            return new DatabaseResult(listSObjectFields);
        } catch(Exception pEx) {
            ApexDebugLog.logException(pEx,sObjectName, 'LightningComponentController', 'getObjectFields');
            return (new DatabaseResult(pEx));
        }
    }
    @AuraEnabled
    public static DatabaseResult getSalesConsoleSetting(String salesConsoleSettingName ){
        DatabaseResult result = new DatabaseResult(JSON.serialize(SalesConsoleSettings.get(salesConsoleSettingName)));
        return result;
    }

    /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is used to get API SessionId.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    global static  DatabaseResult getAPISessionId(){
        try{
            PageReference pr = new PageReference('/apex/LightningEval');
            String body = pr.getContent().toString();
            Integer startIndex = body.indexOf('START_OF_SESSION_ID_FOR_LIGHTNING')+33;
            Integer endIndex = body.indexOf('END_OF_SESSION_ID_FOR_LIGHTNING');
            String sessionId = body.substring(startIndex, endIndex);
            DatabaseResult result = new DatabaseResult(sessionId);
            return result;
        } catch(Exception pEx){
            ApexDebugLog.logException(pEx,'', 'LightningComponentController', 'getAPISessionId');
            return (new DatabaseResult(pEx));
        }
    }

   /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is used to get REST CalloutData.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    global static DatabaseResult getRESTCalloutData(){
        try{
            RESTCalloutData objRESTCalloutData = new RESTCalloutData();
            objRESTCalloutData.apiSessionId = String.valueOf(LightningComponentController.getAPISessionId().data);
            objRESTCalloutData.endPointUrl = URL.getSalesforceBaseUrl().toExternalForm();
            objRESTCalloutData.userId = UserInfo.getUserId();
            DatabaseResult result = new DatabaseResult(JSON.serialize(objRESTCalloutData));
            return result;
        } catch(Exception pEx){
            ApexDebugLog.logException(pEx,'', 'LightningComponentController', 'getRESTCalloutData');
            return (new DatabaseResult(pEx));
        }
    }
   /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This Class is created to hold REST CalloutData data.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    global Class RESTCalloutData {
        @AuraEnabled
        public String apiSessionId {get;set;}
        @AuraEnabled
        public String endPointUrl {get;set;}
        @AuraEnabled
        public Id userId {get;set;}
    }

    /************************************************************************************************************************************
        Author         : Ajaysinh Chauhan
        Description     : This method upserts geolocation records with place id.
        Created Date    : 19 March 2018
  **************************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult upsertGeolocation(Geography__c objGeography){
        try{
            upsert objGeography Place_ID__c;
            List<Geography__c> geographies = geographySelector.getGeographiesByPlaceId(objGeography.Place_ID__c);
        	return new DatabaseResult(geographies[0].Id);
        } catch(Exception pEx) {
            ApexDebugLog.logException(pEx,'objGeography==>'+objGeography, 'LightningComponentController', 'upsertGeolocation');
            return (new DatabaseResult(pEx));
        }
    }

/****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is used to get Record Type Information.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
   *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getRecordTypeInfos(List<String> objectNames){
        Map<String, Map<String, Id>> mapRecordTypes = new Map<String, Map<String, Id>>();
        if(objectNames != NULL && objectNames.size() > 0) {
            for(String objName : objectNames) {
                Map<String, Id> recTypeNameWithIdMap = new Map<String, Id>();
                for(Schema.RecordTypeInfo recInfo : Schema.getGlobalDescribe().get(objName).getDescribe().getRecordTypeInfosByName().values()){
                    recTypeNameWithIdMap.put(recInfo.getName(), recInfo.getRecordTypeId());
                }
                mapRecordTypes.put(objName, recTypeNameWithIdMap);
            }
        }
        return new DatabaseResult(mapRecordTypes);
    }

     /****************************************************************************************************************************
        Author              : Shivprasad Patil
        Description         : This method used to retrive users Logs.Used in apex Log Lightning component
        Created Date        : 27,April 2018
        Last Modified By    : Shivprasad Patil
        Last Modified Date  : 27,April 2018
    *****************************************************************************************************************************/
   @AuraEnabled
    public static DatabaseResult getUserLogs(List<String> users,String startDate,String endDate,String size,String searchTerm,List<String> operations,String startTime,String endTime){
        try{
            String query;
            Set<String> setOfOperations = new set<String>(operations);
            Set<String> setOfUsers = new Set<String>(users);
            String[] arrOfStartDate = startDate.split('-');
            String[] arrOfStartTime = startTime.split(':');
            String[] arrOfendDate = endDate.split('-');
            String[] arrOfEndTime = endTime.split(':');
            DateTime startDateTime = DateTime.newInstance(Integer.valueOf(arrOfStartDate[0]), Integer.valueOf(arrOfStartDate[1]), Integer.valueOf(arrOfStartDate[2]), Integer.valueOf(arrOfStartTime[0]), Integer.valueOf(arrOfStartTime[1]), 0);
            DateTime endDateTime = DateTime.newInstance(Integer.valueOf(arrOfendDate[0]), Integer.valueOf(arrOfendDate[1]), Integer.valueOf(arrOfendDate[2]),Integer.valueOf(arrOfEndTime[0]), Integer.valueOf(arrOfEndTime[1]), 0);
            query = 'SELECT Id,LogUser.name,operation,startTime,status FROM ApexLog WHERE LogUserId IN :setOfUsers AND startTime >= :startDateTime AND startTime <= :endDateTime '+ (setOfOperations.size() > 0 ? 'AND operation IN :setOfOperations ' : '') +'  LIMIT '+size;//
            List<apexLog> lstApexLog = (List<apexLog>)Database.query(query);
            if(searchTerm != NULL && searchTerm!='' && lstApexLog.size() > 0){
                List<apexLog> lstApexLogToReturn = new List<apexLog>();
                HttpRequest req;
                DatabaseResult result;
                String baseURL = URL.getSalesforceBaseUrl().toExternalForm();
                for(ApexLog itrApexLog : lstApexLog){
                    result = LightningComponentController.executeRestQuery(false,'GET',( baseURL+'/services/data/v40.0/sobjects/ApexLog/'+itrApexLog.Id+'/Body/'),new Map<String,String>{'Authorization'=>'Standard'},'');
                    if( (String.valueOf(result.data)).toLowerCase().contains(searchTerm.toLowerCase()) ){
                        lstApexLogToReturn.add(itrApexLog);
                    }
                }
                return new DatabaseResult(lstApexLogToReturn);
            }
            return new DatabaseResult(lstApexLog);
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,'startDate==>'+startDate, 'LightningComponentController', 'getListQueryDataBySOSL');
            return (new DatabaseResult(pEx));
        }
    }
    /****************************************************************************************************************************
        Author              : Shivprasad Patil
        Description         : This method used to delete users Logs.Used in apex Log Lightning component
        Created Date        : 27,April 2018
        Last Modified By    : Shivprasad Patil
        Last Modified Date  : 27,April 2018
    *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult deleteLogs(List<Id> lstLogIds){
        List<String> lstResponse = new List<String>();
        DatabaseResult result;
        for(Id logId:lstLogIds){
            result = LightningComponentController.executeRestQuery(true,'DELETE',('/services/data/v40.0/sobjects/ApexLog/'+logId+'?HttpMethod=DELETE'),new Map<String,String>{'Authorization'=>'Standard'},'');
            lstResponse.add(String.valueOf(result.data));
        }
        return new DatabaseResult(lstResponse);
    }

 /****************************************************************************************************************************
	Author              :   Samadhan kadam
	Description         :   This method is used to create table of object which is inserted by Lead/Journey importer and send to
                        user by email template.
	Created Date        :   12 June 2018
 *********************************************************************************************************************************/
    public static string getTableBody(set<string> setTblFields,map<string,list<sObject>> mapSobjectRecords){
        String htmlBody = '';
        List<sObject> myList = new List<sObject>();
        //open table..
        map<string,map<string,string>> mapObjectAndFields = new map<string,map<string,string>>();
        mapObjectAndFields.put('New Journeys',new map<string,string>{'Primary_Email__c' =>'Email','Id'=>'Id'});
        mapObjectAndFields.put('Existing Journeys',new map<string,string>{'Primary_Email__c' =>'Email','Id'=>'Id'});
        mapObjectAndFields.put('Existing Leads',new map<string,string>{'Email' =>'Email of Lead','Id'=>'Id'});
        mapObjectAndFields.put('New Leads',new map<string,string>{'Email' =>'Email of Lead','Id'=>'Id'});
        mapObjectAndFields.put('Existing Contacts',new map<string,string>{'Email' =>'Email of Contact','Id'=>'Id'});

        for(string currentObject : mapSobjectRecords.keySet()){
            myList = mapSobjectRecords.get(currentObject);
            if(myList != NULL && myList.size()>0){
                htmlBody += '<table border="1" style="border-collapse: collapse;width:60%;text-align: center;"><caption style="text-align: left;margin: 4px 0px 2px 0px;"><b>'+currentObject+'</b></caption>';
                htmlBody+= '<tr style="height: 25px;background:#563d7c;color:white;"><th>Sr.no</th>';

                map<string,string> mapFieldsWithLabel =  mapObjectAndFields.get(currentObject);
                for(string currentField : mapFieldsWithLabel.keySet())
                {
                    htmlBody+= '<th>' + mapFieldsWithLabel.get(currentField) + '</th>';
                }
                htmlBody+= '</tr>';
                Integer index = 0;
                string background = '';
                for(sObject l : myList){
                    if(math.mod(index, 2) == 0){
                        background = '#d5e9e5';
                    }
                    else{
                        background = '#ffffff';
                    }
                    htmlBody+= '<tr style="height:25px;background-color:'+background+'"><td>'+ ++Index +'</td>';
                    for(string currentField :  mapFieldsWithLabel.keySet())
                    {
                        htmlBody+= '<td>' + l.get(currentField) + '</td>';
                    }
                    htmlBody+= '</tr>';
                }
                //close table...
                htmlBody += '</table><br></br><br></br>';
            }
        }
        return htmlBody;
    }

    public class MetaFields {
        public String name;
        public String label;
    }

    public class ReturnValidResults{
        public boolean isSuccess;
        public String message;
    }

  /****************************************************************************************************************************
        Author              : Rohit Nimase
        Description         : This method will rollback the transaction if exception is occured in AURA
        Created Date        : 16/01/2019
  *****************************************************************************************************************************/
    public static void rollbackTransaction(Savepoint savePoint){
        if(savePoint != NULL){
            Database.rollback(savePoint);
        }
    }

    webservice static WebServiceWrapper validateLeadforWebService(Id recordId){
        try{
            DatabaseResult result = validateLead(recordId);
            return new WebServiceWrapper(result.success,JSON.serialize(result.data),result.message);
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,'', 'LightningComponentController', 'validateLeadforWebService');
            return new WebServiceWrapper(false, NULL, pEx.getMessage());
        }
    }

    @AuraEnabled
    public static DatabaseResult validateLead(Id recordId){
        return validateLead(recordId, NULL);
    }

    @AuraEnabled
    public static DatabaseResult validateLead(Id recordId, String strSource){
        try{
            if(String.isNotBlank(recordId)){
                Set<String> setOfLeadSource = new Set<String>{'Broker Referral','Member Referral','Employee Referral','Affiliate Referral','Partner Referral'};
                List<sObject> lstRecords = new List<sObject>();
                String query;
                String objName = recordId.getSObjectType().getDescribe().getName();
                if(objName=='Lead'){
                    query = 'SELECT id,LeadSource,Referrer__c FROM Lead WHERE id = :recordId AND LeadSource IN :setOfLeadSource AND Referrer__c = NULL';
                }else if(objName=='Journey__c'){
                    query = journeySelector.getQueryWithIdAndLeadAndContact();
                }
                lstRecords = Database.query(query);
                if(!lstRecords.isEmpty()){
                    return new DatabaseResult(false,NULL,'Referrer is blank. Add a referrer in the referrer lookup field.');
                }
                return new DatabaseResult(true,NULL,NULL);
            }
            return new DatabaseResult(false,NULL,'record id is blank.');
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,'', 'LightningComponentController', 'validateLead');
            return (new DatabaseResult(pEx));
        }
    }

    public static Map<String, Integration_Data__mdt> getExternalSystemEndPoints(set<String> setEndPointNames){
        String environmentName = getEnvironmentName();
        Map<String, Integration_Data__mdt> mapEndpointData = new Map<String, Integration_Data__mdt>();
        for(Integration_Data__mdt endPoint : [SELECT Label, DeveloperName, ApiKey__c, EndPoint__c, Headers__c, Method__c FROM Integration_Data__mdt where Label In : setEndPointNames AND Environment__c =: environmentName]){
            mapEndpointData.put(endPoint.Label.toLowerCase(), endPoint);
        }
        return mapEndpointData;
    }

    public static string getEnvironmentName(){
        String environmentName = URL.getSalesforceBaseUrl().getHost().SubStringBefore('.').toLowerCase().substringAfter('--');
        Boolean isSandBox = runningInASandbox();
        if(!isSandBox){
            return 'wework';
        }else if(environmentName.containsIgnoreCase('staging') && isSandBox){
            return 'staging';
        }else if(environmentName.containsIgnoreCase('venus') && isSandBox){
            return 'venus';
        }else{
            return 'staging';
        }
    }

    @AuraEnabled
    public static Boolean checkUserPermission(Id userId, String permissionSetName){
        List<PermissionSetAssignment> lstPermissionSetAssignment = [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name=: permissionSetName AND AssigneeId =:userId];
        return !lstPermissionSetAssignment.isEmpty();
    }

    @AuraEnabled
    public static Map<Id, Integer> getBillingAccountMemberCount(List<sObject> billingAccounts){
        Map<Id, Account> billingAccountsToIdsMap = new Map<Id, Account>((List<Account>) billingAccounts);
        Map<Id, Integer> billingAccountsMembersToIdsMap = new Map<Id, Integer>();
        for(Account accountRecord : (List<Account>) billingAccounts) {
            billingAccountsMembersToIdsMap.put(accountRecord.Id, 0);
        }
        for(AggregateResult billingAccountGrouped : [ SELECT AccountId, COUNT(Id)
                                                      FROM Contact
                                                      WHERE AccountId IN: billingAccountsToIdsMap.keySet()
                                                      GROUP BY AccountId ]){
            billingAccountsMembersToIdsMap.put((Id) billingAccountGrouped.get('AccountId'), (Integer) billingAccountGrouped.get('expr0'));
        }
        return billingAccountsMembersToIdsMap;
    }

    @AuraEnabled
    public static List<SObject> getRelatedRecords(Map<String, String> mapFilterFieldToFilterValue, Map<String, Map<String, String>> mapFieldApiNameToSettings, String objName){
        return BillingAccountMigratorServices.getRelatedRecords(mapFilterFieldToFilterValue, mapFieldApiNameToSettings, objName);
    }

    @AuraEnabled
    public static Map<String, Map<String,String>> getFieldLabels(String objName, List<String> fieldApiNames, Map<String, String> mapReplacement, Map<String, String> mapLinkFields){
        return BillingAccountMigratorServices.getFieldLabels(objName, fieldApiNames, mapReplacement, mapLinkFields);
    }

    @AuraEnabled
    public static List<Account> getTransferAccounts(String name, List<String> types, Map<String, Map<String, String>> mapFieldApiNameToSettings){
        return BillingAccountMigratorServices.getTransferAccounts(name, types, mapFieldApiNameToSettings);
    }

    public static Boolean runningInASandbox() {
            return [SELECT IsSandbox FROM Organization].IsSandbox;
    }

    global class WebServiceWrapper{
        webservice Boolean success;
        webservice String message;
        webservice String data;
        public WebServiceWrapper(Boolean success, String data, String message){
            this.success = success;
            this.data 	 = data;
            this.message = message;
        }
    }

    @AuraEnabled
    public static DatabaseResult getReferenceData(String keyword, List<String> lstSobjectNames, String fields, List<String> lstSearchFields, String criteria, String recordId, Integer intLIMIT){
	    return new DatabaseResult(getRecordsData(keyword, lstSobjectNames, fields, lstSearchFields, criteria, recordId, intLIMIT));
    }

    public static List<SObject> getRecordsData(String keyword, List<String> lstSobjectNames, String fields, List<String> lstSearchFields, String criteria, String recordId, Integer intLIMIT){
        if(lstSobjectNames == NULL || lstSobjectNames.isEmpty()){
            return null;
        }
        intLIMIT = intLIMIT != NULL ? intLIMIT : 10 ;
        List<sObject> lstRecords = new List<sObject>();
        List<sObject> records;
        try{
            if(String.isNotBlank(recordId)){
                return getDataWithRecordId(recordId, lstSobjectNames, fields);
            }
            if(String.isBlank(keyword)){
                return null;
            }
            for(String sObjectName : lstSobjectNames){
                if(String.isBlank(sObjectName)){
                    continue;
                }
                if(sObjectName.toLowerCase() == 'building__c'){
                    lstRecords.addAll((List<SObject>)getBuildingData(new Map<String, Object>{'keyWord'=>keyword, 'addLimit'=>intLIMIT}));
                }else{
                    records = new List<sObject>();
                    String query = 'SELECT Id, Name';
                    String startWithQuery;
                    String searchAllQuery;
                    if(String.isNotBlank(fields)){
                        query = query + ' , ' + fields;
                    }
                    query += (' FROM ' + sObjectName + ' WHERE ');
                    if(String.isNotBlank(criteria)){
                        query += (criteria + ' AND ');
                    }
                    if(lstSearchFields == NULL || lstSearchFields.isEmpty()){
                        startWithQuery = query + 'Name Like \''+ keyword +'%\' LIMIT ' + intLIMIT;
                        searchAllQuery = query + 'Name Like \'%'+ keyword +'%\'';
                    }else{
                        startWithQuery = query + '(' + String.join(lstSearchFields, ' Like \''+ keyword +'%\' OR ') + ' Like \''+ keyword +'%\''+ ')' +' LIMIT ' + intLIMIT;
                        searchAllQuery = query + '(' + String.join(lstSearchFields, ' Like \'%'+ keyword +'%\' OR ') + ' Like \'%'+ keyword +'%\''+ ')';
                    }
                    records.addAll(Database.query(startWithQuery));
                    if(records.size() < 10){
                        searchAllQuery += (records.isEmpty() ? '' : ' AND Id NOT IN :records') +' LIMIT ' + (intLIMIT - records.size());
                        records.addAll(Database.query(searchAllQuery));
                    }
                    lstRecords.addAll(records);
                }
            }
        }catch(Exception pEx){
            LightningComponentController.rollbackTransaction(sp);
            ApexDebugLog.logException(pEx,(String.isNotBlank(keyword) ? 'keyword==>'+keyword: 'recordId==>'+recordId) + String.valueOf(lstSobjectNames), 'LightningComponentController', 'getReferrenceData');
        }
        return lstRecords;
    }

    private static List<SObject> getDataWithRecordId(String recordId, List<String> lstSobjectNames, String fields){
        if(lstSobjectNames[0].toLowerCase() == 'building__c'){
            return getBuildingData(new Map<String, Object>{'sfRecordId'=>recordId});
        }
        String query = 'SELECT Id, Name';
        if(String.isNotBlank(fields)){
            query += ' , ' + fields;
        }
        query += (' FROM ' + lstSobjectNames[0] + ' WHERE Id =:recordId');
        return Database.query(query);
    }

    @AuraEnabled
    public static string migrateBillingAccounts(Id accountId, List<Id> billingAccountIds){
        return BillingAccountMigratorServices.migrateBillingAccounts(new Map<Id, List<Id>>{accountId => billingAccountIds});
    }

    @AuraEnabled
    public static DatabaseResult getPickListBasedOnRecordType(String objectName, Id recordTypeId, String fieldName) {
        String method = 'GET';
        String endpoint = '/services/data/v47.0/ui-api/object-info/'+objectName+'/picklist-values/'+recordTypeId+'/'+fieldName;
        String host = System.Url.getSalesforceBaseURL().toExternalForm();
        HttpRequest request = new HttpRequest();
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        request.setEndpoint(host+endPoint);
        request.setMethod(method);

        HTTPResponse response = (new Http()).send(request);
        if(response.getStatusCode() == 200) {
            return new DatabaseResult(response.getBody());
        }else{
            return new DatabaseResult('Error');
        }
    }

    @AuraEnabled
    public static Map<String, Map<String, Map<Id, String>>> getRegionalTerritoryNames(){
        Map<String, Map<String, Map<Id, String>>> mapRegionIdToTerritories = new Map<String, Map<String, Map<Id, String>>>();
        for(Territory__c t : [SELECT Id, Name, RegionID__r.Name, RegionID__c FROM Territory__c]){
            if(mapRegionIdToTerritories.containsKey(t.RegionID__c)){
                mapRegionIdToTerritories.get(t.RegionID__c).get(t.RegionID__r.Name).put(t.Id, t.Name);
            }else{
                mapRegionIdToTerritories.put(t.RegionID__c, new Map<String, Map<Id, String>>{t.RegionID__r.Name => new Map<Id, String>{t.Id => t.Name}});
            }
        }
        return mapRegionIdToTerritories;
    }

    @AuraEnabled
    public static DatabaseResult getRevStarAPIPrice(String recordId, Integer quantity, Opportunity opportunity){
            String buildingName;
            Id relatedRecordId;
            String sObjectName;
            Id buildingId;
            String building_uuid;
            String buildingPriceBookId;
            String buildingCurrency;
            Map<String, Object> mapRevstarResult = new Map<String, Object>();
            Map<Id, List<String>> buildingMapForEmailMismatch = new Map<Id, List<String>>();
            if(String.isNotBlank(recordId)){
                relatedRecordId = Id.valueOf(recordId);
                sObjectName = relatedRecordId.getSObjectType().getDescribe().getName();
                switch on sObjectName {
                    when 'Building__c' {
                        List<Building__c> buildings = buildingSelector.getBuildingsById(relatedRecordId);
                        if(!buildings.isEmpty()){
                            buildingId = relatedRecordId;
                            building_uuid = buildings[0].UUID__c;
                            buildingName = buildings[0].Name;
                            buildingPriceBookId = buildings[0].Building_Price_Book_Id__c;
                            buildingCurrency = buildings[0].CurrencyISOCode;
                        }
                    }
                    when 'Geography__c' {
                  		List<Geography__c> geographies = (geographySelector.getGeographiesByIdAndNotNullUUIDs(relatedRecordId));
                        if(!geographies.isEmpty()){
                            buildingId = geographies[0].Nearest_Building__c;
                            building_uuid = geographies[0].Nearest_Building__r?.UUID__c;
                            buildingName = geographies[0].Nearest_Building__r?.Name;
                            buildingPriceBookId = geographies[0].Nearest_Building__r.Building_Price_Book_Id__c;
                            buildingCurrency = geographies[0].Nearest_Building__r.CurrencyISOCode;
                        }
                    }
                }
                if(opportunity != null && opportunity.Type__c?.contains(GlobalConstants.ALL_ACCESS)){
                    opportunity = setAllAccessDetails(opportunity,buildingPriceBookId);
                    mapRevstarResult.put('RevStar_Price', opportunity.Sales_Price__c);
                    mapRevstarResult.put('Success', true);
                    mapRevstarResult.put('Currency', opportunity.CurrencyIsoCode);
                }else{
                    mapRevstarResult = RevstarUtils.makeCalloutForRevstarPrice(building_uuid, quantity);
                    if(mapRevstarResult.isEmpty()){
                        mapRevstarResult.put('Currency', buildingCurrency);
                    } else if (mapRevstarResult.get('Currency') != buildingCurrency) {
                        buildingMapForEmailMismatch.put(buildingId, new List<String> { buildingName, building_uuid, buildingCurrency, (String)mapRevstarResult.get('Currency') });
                    }
                }
                mapRevstarResult.put('BuildingName', buildingName);
            }
            if (!buildingMapForEmailMismatch.isEmpty()) {
                Id jobId = System.enqueueJob(new QueueEmailAlertForBuilding(buildingMapForEmailMismatch));
            }
        	return new DatabaseResult(mapRevstarResult);
    }

    private static Opportunity setAllAccessDetails(Opportunity opportunity, String buildingPriceBookId){
        if(String.isNotBlank(buildingPriceBookId)){
            OpportunityPriceService priceService = new OpportunityPriceService();
            Map<String,String> productNameToProductCode = priceService.getProductToProductCode(new Set<String>{opportunity.Type__c});
            Map<String,OpportunityPriceService.PriceBookEntryDetails> productToCurrency = priceService.getAllAccessPrice(
                new Set<String>{opportunity.Type__c}, new List<String>{buildingPriceBookId});
            String key = priceService.getProdPricebookCurrKey(
                 productNameToProductCode.get(opportunity.Type__c), buildingPriceBookId);
            if(productToCurrency != null && productToCurrency.containsKey(key)){
                OpportunityPriceService.PriceBookEntryDetails priceBookDetails = productToCurrency.get(key);
                opportunity.Sales_Price__c = priceBookDetails.unitPrice;
                opportunity.CurrencyIsoCode = priceBookDetails.currencyVal;
            }else{
                opportunity.Sales_Price__c = GlobalConstants.DEFAULT_OPP_SALES_PRICE;
                opportunity.CurrencyIsoCode = GlobalConstants.DEFAULT_OPP_CURRENCY;
            }
        }else{
            opportunity.Sales_Price__c = GlobalConstants.DEFAULT_OPP_SALES_PRICE;
            opportunity.CurrencyIsoCode = GlobalConstants.DEFAULT_OPP_CURRENCY;
        }
        return opportunity;
    }
    
    @AuraEnabled
    public static DatabaseResult getOzonetelKey() {
        Ozonetel__c data = Ozonetel__c.getOrgDefaults();
        return new DatabaseResult(data.Api_Key__c);
    }
}