/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name:            UtilAccount.cls

Description:    Account Object Utility for testing and general functions .        
Date            Author          Summary of Changes 
25-SEP-2018     Rashad Saeed  Initial Implementation 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
@isTest()
public Class UtilAccount {
    // this method return Accounts with for all active recordtypes with auto fields mapping 'for Required  fields only '.
    Private Static String methodNameRunning ='';
    Private Static Map <String,Id>ActiveRecordTypes = UtilRecordType.GetSobjectActiveRecordTypes('Account');
    Private Static List <Id> recordTypeIds = ActiveRecordTypes.Values();
    Private Static Map<String,Object> stMapFields = new Map<String,Object> ();
    
    public static List<Account> GetNewAccounts(Integer numberOfRecords, Boolean doInsert) {
        Boolean setSize = methodNameRunning == 'GetAccountsWithAllRecordTypes' ? true : false;
        if (numberOfRecords < recordTypeIds.size() && setSize) {
            numberOfRecords = recordTypeIds.size(); 
        }
        List<Map<String, Object>> listOfMapFields = new List<Map<String, Object>>();
        for (Integer i = 1, j = numberOfRecords; i <= j; i++) {
            Map<String, Object> accountFieldsMap = new Map<String, Object>(stMapFields);
            if (methodNameRunning == 'GetAccountsWithAllRecordTypes') {
                accountFieldsMap.put('RecordTypeId',recordTypeIds[math.mod(i,recordTypeIds.size())]);
            }
            accountFieldsMap.put('Name', 'Test-' + i);
            listOfMapFields.add(accountFieldsMap);
        }
        return UtilGeneral.createTestRecords(Account.SObjectType, listOfMapFields, doInsert);
    }

    public static List <Account> GetAccountsWithAllRecordTypes (Boolean doInsert)
    {
        methodNameRunning ='GetAccountsWithAllRecordTypes';   
        return GetNewAccounts(1, doInsert);
    }

    // this method return Accounts for all active recordtypes with field mapping if there is Required fields missing this method will fill it automatically .
    public static List<Account> GetNewAccountsWithFieldMapping(Integer numberOfRecords, Map<String, Object> mapFields, Boolean doInsert) {
        stMapFields = mapFields.clone();
        methodNameRunning = 'GetNewAccountsWithFieldMapping';
        return GetNewAccounts(numberOfRecords, doInsert);
    }
    
    // this method will return accounts with specific record type ex .  GetNewAccountsByRecordType (10,'Consumer',Map<String,Object>,false)
    Public static list <Account> GetNewAccountsByRecordType (Integer NumberOfRecords,String RecordTypeName,Map<String,Object> MapFields,Boolean DoInsert)
    {
        stMapFields = MapFields.clone();
        RecordTypeName = RecordTypeName.toLowerCase();
        methodNameRunning ='GetNewAccountsByRecordType';
        if (ActiveRecordTypes.containsKey(RecordTypeName))
            stMapFields.put('RecordTypeId',ActiveRecordTypes.get(RecordTypeName));
        else
            return null;
        return GetNewAccounts(NumberOfRecords,DoInsert);
    } 
    
    // TO DO 
    // Create new method that create accounts with related contacts . 
    // Create new method that create accounts with related Opportunities . 
}