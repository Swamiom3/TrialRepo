/************************************************************************************************************************************
    Author      : Urvi Tanna
    Description : This class contains methods for Billing Accounts' migration
    History     :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR         DETAIL
    1           23 July 2019    Urvi Tanna         Initial Developement
    2           8 Dec, 2021     Pawel Biszczak     Align Billing Accounts' migration logic to q2c data model
**************************************************************************************************************************************/
public with sharing class BillingAccountMigratorServices {

    public static String migrateBillingAccounts(Map<Id,List<Id>> mapNewParentAccountIdToBillingAccounts) {
        Map<Id,Account> idsToBillingAccountsToBeUpdatedMap = new Map<Id,Account>();
        for(Id  newParentAccountId : mapNewParentAccountIdToBillingAccounts.keySet()) {
            for(Id billingAccountId : mapNewParentAccountIdToBillingAccounts.get(newParentAccountId)) {
                Account billingAccount = new Account(Id = billingAccountId);
                billingAccount.ParentId = newParentAccountId;
                idsToBillingAccountsToBeUpdatedMap.put(billingAccount.Id, billingAccount);
            }
        }
        List<Opportunity> relatedOpportunities = [ SELECT Id, Billing_Account__c
                                                   FROM Opportunity
                                                   WHERE Billing_Account__c IN :idsToBillingAccountsToBeUpdatedMap.keySet()];
        setParentAccountId(relatedOpportunities, idsToBillingAccountsToBeUpdatedMap,
                           'Billing_Account__c', 'AccountId');
        String result = '';
        Savepoint savepointRecord = Database.setSavepoint();
        if(!relatedOpportunities.isEmpty()) {
            try {
                update relatedOpportunities;
            } catch (Exception exp) {
                Database.rollback(savepointRecord);
                ApexDebugLog.logException(exp, JSON.serialize(mapNewParentAccountIdToBillingAccounts),
                                          'BillingAccountMigratorServices', 'migrateBillingAccounts');
                throw new AuraHandledException(Label.Billing_Account_Transfer_Error_Opportunity + exp.getMessage());
            }
        }
        try{
            update idsToBillingAccountsToBeUpdatedMap.values();
        }catch(Exception exp){
            Database.rollback(savepointRecord);
            ApexDebugLog.logException(exp, JSON.serialize(mapNewParentAccountIdToBillingAccounts),
                                      'BillingAccountMigratorServices', 'migrateBillingAccounts');
            throw new AuraHandledException(Label.Billing_Account_Transfer_Error_BA + exp.getMessage());
        }
		result = 'SUCCESS';
        return result;
    }

    private static void setParentAccountId(List<SObject> relatedSObjects,  Map<Id,Account> mapIdToBillingAccounts, String billingAccountField, String parentAccountField) {
        for(SObject sObjectRecord : relatedSObjects) {
            Id billingAccountId = (Id)sObjectRecord.get( billingAccountField);
            sObjectRecord.put(parentAccountField, mapIdToBillingAccounts.get(billingAccountId).ParentId);
        }
    }

    public static Map<String, Map<String,String>> getFieldLabels(String objName, List<String> fieldApiNames, Map<String, String> mapReplacement, Map<String, String> mapLinkFields){
        Map<String, Map<String,String>> fieldNameToFieldSettingsMap = new Map<String, Map<String,String>>();
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType selectedObjectSchema = schemaMap.get(objName);
        Map<String, Schema.SObjectField> fieldsSchemaMap = selectedObjectSchema.getDescribe().fields.getMap();
        for (String fieldApiName : fieldApiNames){
            Map<String, String> fieldLabelAndLinkMap = new Map<String, String>{'label'=>'', 'link'=>''};
            try{
                fieldLabelAndLinkMap.put('label', fieldsSchemaMap.get(fieldApiName).getDescribe().getLabel());
            }catch(Exception exp){
                if(!mapReplacement.isEmpty() && mapReplacement.get(fieldApiName) != null){
                    fieldLabelAndLinkMap.put('label', mapReplacement.get(fieldApiName));
                }else{
                    throw new ObjectSelectTableControllerException('fieldApiName wasn\'t found on object or in mapReplacement parameter in ObjectSelectTableController.getFieldLabels');
                }
            }
            if(!mapLinkFields.isEmpty() && mapLinkFields.get(fieldApiName) != null){
                fieldLabelAndLinkMap.put('link', mapLinkFields.get(fieldApiName).remove('"'));
            }
            fieldNameToFieldSettingsMap.put(fieldApiName, fieldLabelAndLinkMap);
        }
        return fieldNameToFieldSettingsMap;
    }


    public static List<Account> getTransferAccounts(String name, List<String> types, Map<String, Map<String, String>> mapFieldApiNameToSettings){
        List<Account> transferAccounts = new List<Account>();
        String filterString = 'Name LIKE \'' + String.escapeSingleQuotes(name+'%') + '\'';
        Map<String, List<String>> accountTypeMapping = (Map<String, List<String>>) JSON.deserialize(Settings.getMetadataSettingByDevName('Account_Type_Filter_Settings').Data__c, Map<String, List<String>>.class);
        Boolean foundType = false;
        for(String key : accountTypeMapping.keyset()){
            for(String value : accountTypeMapping.get(key)){ 
                if(types.contains(value)){
                    if(!foundType){
                        filterString += ' AND ('+key+' = \'' + String.escapeSingleQuotes(value) + '\'';
                        foundType = true;
                    }else{
                        filterString += ' OR '+key+' = \'' + String.escapeSingleQuotes(value) + '\'';
                    }
                } 
            }
        }
        if(foundType) {
            filterString += ')';
        }
        String selectStatement = constructSelectStatement(mapFieldApiNameToSettings);
        String query = 'SELECT ' + selectStatement + ' FROM Account WHERE ' + filterString;
        try{
            transferAccounts = Database.query(query);
        }catch(Exception exp){
            throw new ObjectSelectTableControllerException('error stack trace: ' + exp.getStackTraceString() +
                                                           ' ==> error message: ' + exp.getMessage());
        }
        return transferAccounts;
    }

    public static List<SObject> getRelatedRecords(Map<String, String> mapFilterFieldToFilterValue, Map<String, Map<String, String>> mapFieldApiNameToSettings, String objName){
        if(mapFilterFieldToFilterValue == null || mapFilterFieldToFilterValue.isEmpty()) {
            throw new ObjectSelectTableControllerException('please filter your results');
        }
        try{
            DescribeSObjectResult describeInfo = ((SObject)(Type.forName('Schema.'+objName).newInstance())).getSObjectType().getDescribe();
            List<SObject> lstReturnRecords = new List<SObject>();
            String selectStatement = constructSelectStatement(mapFieldApiNameToSettings);
            String query = 'SELECT '+selectStatement+' FROM ' + objName + ' WHERE ' + constructQueryFilter(mapFilterFieldToFilterValue, describeInfo);
            System.debug('query ==> '+query);
            if(!mapFilterFieldToFilterValue.isEmpty()) {
                lstReturnRecords = Database.query(query);
            }
            return lstReturnRecords;
        }catch(Exception exp){
            throw new ObjectSelectTableControllerException('error stack trace: ' + exp.getStackTraceString() +
                                                           ' ==> error message: ' + exp.getMessage());
        }
    }

    private static String constructSelectStatement(Map<String, Map<String, String>> mapFieldApiNameToSettings){
        List<String> fieldsToQuery = new List<String>();
        if(!mapFieldApiNameToSettings.isEmpty()) fieldsToQuery = new List<String>(mapFieldApiNameToSettings.keyset());
        String selectStatement = '';
        for(Integer i = 0; i < fieldsToQuery.size(); i++){
            if(mapFieldApiNameToSettings.get(fieldsToQuery[i]) != null && mapFieldApiNameToSettings.get(fieldsToQuery[i]).get('link') != '') {
                selectStatement += mapFieldApiNameToSettings.get(fieldsToQuery[i]).get('link').remove('"') + ',';
            }
            selectStatement += (i == (fieldsToQuery.size() - 1)) ? fieldsToQuery[i] : fieldsToQuery[i]+',';
        }
        return selectStatement;
    }

    private static String constructQueryFilter(Map<String, String> mapFilterFieldToFilterValue, DescribeSObjectResult describeInfo){
        String filterString = '';
        String fieldType = '';
        String filterValue = '';
        String filterLogic = ' '+(mapFilterFieldToFilterValue.containsKey('FilterLogic') ? mapFilterFieldToFilterValue.remove('FilterLogic') : 'AND');
        String limitLogic = mapFilterFieldToFilterValue.containsKey('LIMIT') ? 'LIMIT ' + mapFilterFieldToFilterValue.remove('LIMIT') : '';
        Integer iterator = 0;
        Map<String,Schema.SObjectField> mapFields = describeInfo.fields.getMap();
        for(String fieldApiName : mapFilterFieldToFilterValue.keyset()){
            iterator++;
            filterValue = '';
            fieldType = String.valueOf(mapFields.get(fieldApiName).getDescribe().getType()).toLowerCase();
            if( fieldType == 'string' ) {
                filterValue = ' LIKE \'%' + mapFilterFieldToFilterValue.get(fieldApiName) + '%\'';
            } else if( fieldType == 'id' || fieldType == 'reference' || fieldType == 'phone' || fieldType == 'email' || fieldType == 'picklist' ) {
                String tempValue = mapFilterFieldToFilterValue.get(fieldApiName);
                if(tempValue != null && tempValue.contains('!=')) {
                    filterValue = ' != \''+tempValue.remove('!=')+'\'';
                }
                else {
                    filterValue = ' = \''+mapFilterFieldToFilterValue.get(fieldApiName)+'\'';
                }
            } else {
                filterValue = ' = ' + mapFilterFieldToFilterValue.get(fieldApiName);
            }
            filterString+=' '+fieldApiName+filterValue;
            if( iterator < mapFilterFieldToFilterValue.size() ) {
                filterString += filterLogic;
            }
        }
        filterString += ' ' + limitLogic;
        return filterString;
    }

    private class ObjectSelectTableControllerException extends Exception{}

}