/**
 * @File Name          : TestingUtility.cls
 * @Description        :
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              :
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 3/19/2020, 8:52:44 AM
 * @Modification Log   :
 * Ver       Date            Author      		    Modification
 * 1.0    9/5/2019   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
@isTest
public class TestingUtility {

    private final static Map<String, Schema.RecordTypeInfo> SCHEMA_OPP_REC_TYPE_BY_NAME = Schema.sObjectType.Opportunity.getRecordTypeInfosByName();
    private final static Id OPPORTUNITY_NEW_BUSINESS_RECORD_TYPE_ID = SCHEMA_OPP_REC_TYPE_BY_NAME.get('New Business').getRecordTypeId();
    public static List<String> monthsList = new List<String>{'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'};
    public static final String CURRENT_YEAR = String.valueOf( Date.today().year() );
    public static final String PHONE_NUMBER = '12312323';
    public static final String LAST_NAME = 'Test Last Name';
    public static final String FIRST_NAME = 'Test First Name';
    public static final String COMPANY_NAME = 'Test Company Name';
    public static Boolean isAccounstInserted = false;
    public static Boolean isBillingAccountInserted = false;
    public static Boolean isContactsInserted = false;
    public static Boolean isOpportunityInserted = false;
    public static Boolean isTaskInserted = false;
    public static Boolean isMarketInserted = false;
    public static Boolean isBuildingInserted = false;
    public static Boolean isJourneyInserted = false;
    public static Boolean isLeadInserted = false;
    public static Boolean isCampaignInserted = false;
    public static Boolean isTourScheduleInserted = false;
    public static Boolean isTourOpenHours = false;
    public static Boolean isCasesInserted = false;
    public static Boolean isUnomyCompanyInserted = false;
    public static Boolean isReservableInserted = false;
    public static Boolean isReservationsInserted = false;
    public static Integer accountsCount = 0;

    // <summary>
    // Created By: Anant Kumar.
    // Created On: 23-02-2016.
    // Purpose: To Create multiple Test Records for Test methods.
    // Parameters:
    // 1. intRecordCount: Number of Records to be Created.
    // 2. sObjectTypeRequested: sObject Type for which record to be Created.
    // 3. recordValuesMap: If record has specific value for Fields.
    // 4. DoInsert: Perform insert or return Only records.
    // Return type: List of Requested sObject Type Records.

    public static List<sObject> createTestRecords(Integer intRecordCount,Schema.sObjectType sObjectTypeRequested, List<Map<String,Object>> recordValuesList,Boolean DoInsert){
        List<sObject> sObjectList = new List<sObject>();
        Map<String,Schema.DescribeFieldResult> requiredFieldsMap = getNullabelRequiredFields(sObjectTypeRequested);
        sObject record = null;
        for(integer index = 0; index < intRecordCount; index++){
            record = sObjectTypeRequested.newSobject();
            Map<String, Object> recordValuesMap;
            if(recordValuesList != null && intRecordCount <= recordValuesList.size()){
                recordValuesMap = recordValuesList[index];
            }
            else if(recordValuesList != null && recordValuesList.size() > 0){
                recordValuesMap = recordValuesList[0];
            }
            if(recordValuesMap != null && !recordValuesMap.isEmpty()){
                for(String strUserField : recordValuesMap.keySet()){

                    record.put(strUserField.trim(),recordValuesMap.get(strUserField));
                }
            }
            for(String strField : requiredFieldsMap.keySet()){
                if(recordValuesMap == null || recordValuesMap.isEmpty() || !recordValuesMap.containsKey(strField)) {
                    record.put(strField,getTestValue(requiredFieldsMap.get(strField)));
                }
            }
            sObjectList.add(record);
        }
        if(DoInsert){
            InsertListWithAssert(sObjectList);
        }
        return sObjectList;
    }

    // Created By: Anant Kumar
    // Created On: 23-02-2016
    // Purpose: To Create a Test Records for Test methods.
    // Parameters:
    // 1. sObjectTypeRequested: sObject Type for which record to be Created.
    // 2. recordValuesMap: If record has specific value for Fields.
    // 3. DoInsert: Perform insert or return Only records.
    // Return type: single sObject type record.
    public static sObject createTestRecords(Schema.sObjectType sObjectTypeRequested, Map<String,Object> recordValuesMap,Boolean DoInsert){
        List<Map<String,Object>> newListOfMap = new List<Map<String,Object>>();
        newListOfMap.add(recordValuesMap);
        return createTestRecords(1, sObjectTypeRequested, newListOfMap, DoInsert)[0];
    }

    //Return Type: Mulitple sObject type record
    public static List<sObject> createTestRecords(Schema.sObjectType sObjectTypeRequested, List<Map<String,Object>> recordValuesList,Boolean DoInsert){
        return createTestRecords(recordValuesList.size(), sObjectTypeRequested, recordValuesList, DoInsert);
    }

    // <summary>
    // Created By: Anant Kumar
    // Created On: 23-02-2016.
    // Purpose: To Get the Required Fields from sObject.
    // Parameters:
    // 1. sObjectTypeRequested: sObject Type to get Required Fields.
    // Return type: List Field Describe Object of required Fields.
    static Map<String,Schema.DescribeFieldResult> getNullabelRequiredFields(Schema.sObjectType sObjectTypeRequested){
        Map<String,Schema.DescribeFieldResult> describeFieldMap = new Map<String,Schema.DescribeFieldResult>();
        Schema.DescribeSObjectResult dResult = sObjectTypeRequested.getDescribe();
        Map<String,Schema.SObjectField> fieldsMap = dResult.fields.getMap();
        for(Schema.SObjectField field : fieldsMap.values()){
            Schema.DescribeFieldResult fieldMetadata = field.getDescribe();
            if(fieldMetadata.IsCreateable() && !fieldMetadata.IsNillable() && !fieldMetadata.IsDefaultedOnCreate() ){
                describeFieldMap.put(fieldMetadata.getName(),fieldMetadata);
            }
        }
        return describeFieldMap;
    }

    // <summary>
    // Created By: Anant Kumar.
    // Created On: 23-02-2016.
    // Purpose: To Get the Test Values for sObject's Required Fields.
    // Parameters:
    // 1. fieldDescribe: Result of Field Describe.
    // Return type: Object of Test Value.
    static Object getTestValue(Schema.DescribeFieldResult fieldDescribe){
        Object TestValue = null;
        if(fieldDescribe != null){
            Schema.DisplayType displayType = fieldDescribe.getType();
            if(displayType.equals(Schema.DisplayType.Email)){
                TestValue = createStringValue() +'@Email.com';
            } else if(displayType.equals(Schema.DisplayType.DATETIME)){
                TestValue = DateTime.now();
            }else if(displayType.equals(Schema.DisplayType.STRING) || displayType.equals(Schema.DisplayType.TEXTAREA)){
                TestValue = createRandomString();
            }else if(displayType.equals(Schema.DisplayType.URL)){
                TestValue = 'https://'+ createStringValue() +'.com';
            }else if(displayType.equals(Schema.DisplayType.TIME)){
                TestValue = Time.newInstance(12, 00, 00, 00);
            }else if(displayType.equals(Schema.DisplayType.BASE64)){
                TestValue = Blob.valueOf(createStringValue());
            }else if(displayType.equals(Schema.DisplayType.Currency)){
                TestValue = math.rint( math.random() * 100000 );
            }else if(displayType.equals(Schema.DisplayType.Date)){
                TestValue = Date.today();
            }else if(displayType.equals(Schema.DisplayType.Double)){
                TestValue = math.rint( math.random() * 100000 );
            }else if(displayType.equals(Schema.DisplayType.Percent)){
                TestValue = math.rint( math.random() * 100000 );
            }else if(displayType.equals(Schema.DisplayType.Phone)){
                TestValue = 987654321;
            }else if(displayType.equals(Schema.DisplayType.Reference)){
                List<sObject> sObjectList = createTestRecords(1,fieldDescribe.getReferenceTo()[0], null,true);
                TestValue = sObjectList[0].Id;
            }
        }
        return TestValue;
    }

    public static Map<Schema.SObjectType, Map<String,Id>> recordTypeInfoMapBySobjectType = new Map<Schema.SObjectType, Map<String,Id>>();
    //Method to get the record type of sObjects By Name.
    public static Map<String,Id> getRecordTypeMapByName ( Schema.SObjectType sObjectType){
        if(recordTypeInfoMapBySobjectType.containsKey(sObjectType)){
            return recordTypeInfoMapBySobjectType.get(sObjectType);
        }
        Map<String,Id> recordTypeByNameMap = new Map<String,Id>();
        for( RecordType recordType :  [SELECT Id, Name FROM RecordType WHERE sObjectType =: String.valueOf(sObjectType)]){
            recordTypeByNameMap.put( recordType.Name, recordType.Id);
        }
        recordTypeInfoMapBySobjectType.put(sObjectType, recordTypeByNameMap);
        return recordTypeByNameMap;
    }

    //Method to get the Admin User
    public static User getAdminUser(){
        return [SELECT Id, Name, Email FROM User WHERE Profile.Name ='System Administrator' AND IsActive = true LIMIT 1];
    }

    //Method to get the guest User
    public static User getGuestUser(){
        User guestUser = [SELECT Id, alias, Email, LastName, ProfileId, UserName, CommunitynickName FROM User WHERE userType='Guest'  LIMIT 1];
        system.assert(guestUser != null,'No Guest User Found');
        return guestUser;
    }

    //Method to get the current User
    public static User getCurrentUser(){
        User currentUser = [SELECT Id, Alias, Email, Lastname, FirstName,Profileid, UserName, CommunitynickName,CompanyName FROM user WHERE Id = :UserInfo.getUserId()];
        return currentUser;
    }

    //Method to get the admin profile id
    public static Id getAdminProfileId(){
        Id profileId = [SELECT Id FROM Profile WHERE Name =:'System Administrator' LIMIT 1].Id;
        return profileId;
    }
    //Purpose: To get the Random Name for Test Record.
    public static String createStringValue(){
        return'TestValue' + math.rint( math.random() * 100000 );
    }

    //Purpose: To get the Random Name for Test Record.
    public static String createRandomString(){
        return'Te' + math.rint( (math.random() * 1000));
    }

    // <summary>
    // Created By: Anant Kumar.
    // Created On: 23-02-2016.
    // Purpose: To Get the Test Values for sObject's Required Fields.
    // Parameters:
    // 1. objName: API Name of object.
    // 2. fieldsToCheck : Fields name to be check for Access.
    // 3. crudType: crudType i.e Delete, Update, Insert
    // Return type: Is Fields has specified Access.
    public Boolean checkObjectCrud( Schema.SObjectType objectType, Set<String> fieldsToCheck, String crudType ){
        // Get the global describe
        Schema.DescribeSObjectResult objectResult = objectType.getDescribe();
        Map<String,Schema.SObjectField> fieldsMap = objectResult.fields.getMap();
        if(fieldsToCheck != null && !fieldsToCheck.isEmpty()){
            for(String field : fieldsToCheck){
                if(fieldsMap.containsKey(field)){
                    Schema.DescribeFieldResult fieldDescribe = fieldsMap.get( field ).getDescribe();
                    if('create'.equalsIgnoreCase( crudType ) && !fieldDescribe.isCreateable()){
                        return false;
                    }else if( 'update'.equalsIgnoreCase( crudType ) && !fieldDescribe.isUpdateable()){
                        return false;
                    }else if( 'delete'.equalsIgnoreCase( crudType ) && !fieldDescribe.isRestrictedDelete()){
                        return false;
                    }
                }else{
                    return false;
                }
            }
        }
        return true;
    }


    /* Database Operations */
    // Insert Single Record and Assert.
    public static Database.SaveResult insertWithAssert( sObject dataObject){
        Database.SaveResult saveResult = Database.insert( dataObject);
        System.assert(saveResult.isSuccess());
        return saveResult;
    }

    public static Database.SaveResult insertWithAssert( sObject dataObject,string msg){
        Database.SaveResult saveResult = Database.insert( dataObject);
        System.assert(saveResult.isSuccess(), msg);
        return saveResult;
    }

    // Update Single Record and Assert.
    public static Database.SaveResult updateWithAssert( sObject dataObject){
        Database.SaveResult saveResult = Database.update( dataObject);
        System.assert( saveResult.isSuccess());
        return saveResult;
    }

    public static Database.SaveResult updateWithAssert( sObject dataObject,string msg){
        Database.SaveResult saveResult = Database.update( dataObject);
        System.assert(saveResult.isSuccess(), msg);
        return saveResult;
    }

    // Upsert Single Record and Assert.
    public static Database.Upsertresult upsertWithAssert( sObject dataObject){
        Database.Upsertresult upsertResult = Database.upsert( dataObject);
        System.assert( upsertResult.isSuccess());
        return upsertResult;
    }

    // Delete single Record and Assert.
    public static Database.DeleteResult deleteWithAssert( sObject dataObject){
        Database.DeleteResult deleteResult = Database.delete( dataObject);
        System.assert( deleteResult.isSuccess());
        return deleteResult;
    }

    // Insert List of records and Assert.
    public static Database.SaveResult[] insertListWithAssert( List<sObject> sObjectsList){
        Database.SaveResult[] arrSaveResult = Database.insert( sObjectsList);
        for(Database.SaveResult saveResult : arrSaveResult){
            System.assert( saveResult.isSuccess());
        }
        return arrSaveResult;
    }

    // Update List of Records with Assert.
    public static Database.SaveResult[] updateListWithAssert( List<sObject> sObjectsList){
        Database.SaveResult[] arrUpdateResult = Database.update( sObjectsList);
        for(Database.SaveResult saveResult : arrUpdateResult){
            System.assert( saveResult.isSuccess());
        }
        return arrUpdateResult;
    }

    // Upsert List of records with Assert.
    public static Database.Upsertresult[] upsertListWithAssert( List<sObject> sObjectsList){
        Database.Upsertresult[] arrSaveResult = Database.upsert( sObjectsList);
        for(Database.Upsertresult saveResult : arrSaveResult){
            System.assert( saveResult.isSuccess());
        }
        return arrSaveResult;
    }

    //Delete List of records with Assert.
    public static Database.DeleteResult[] deleteListWithAssert( List<sObject> sObjectsList){
        Database.DeleteResult[] arrDeleteResult = Database.delete( sObjectsList);
        for(Database.DeleteResult deleteResult : arrDeleteResult){
            System.assert( deleteResult.isSuccess());
        }
        return arrDeleteResult;
    }

    //Current Pagereference
    public static pagereference currentPageReference( String pageName, Map<String,String> queryStringMap){
        PageReference pageRef =  new ApexPages.PageReference(pageName);
        for(String key : queryStringMap.keySet()){
            pageRef.getParameters().put(key,queryStringMap.get(key));
        }
        Test.setCurrentPageReference(pageRef);
        system.assert(pageRef != null);
        return pageRef;
    }

    // <summary>
    // Created By: Anant Kumar.
    // Created On: 23/02/2016.
    // Purpose: User create/insert method.
    // Parameters:
    // 1. Id: profileId.
    // 2. Map Of User Fields
    // 3. crudType: crudType i.e Insert
    // Return type: Single User.
    public static User insertUserWithAssert(Id profileId,Map<String,Object> recordValuesMap){
        return insertUserWithAssert(profileId, recordValuesMap, true);
    }

    public static User insertUserWithAssert(Id profileId, Map<String,Object> recordValuesMap, Boolean b_doInsert){
        Map<String,Object> userRecordMap = new Map<String,Object>();
        userRecordMap.put('alias','te');
        userRecordMap.put('Username',createStringValue()+'standarduser@test.com');
        userRecordMap.put('ProfileId',profileId);
        userRecordMap.put('EmailEncodingKey','ISO-8859-1');
        userRecordMap.put('LanguageLocaleKey','en_US');
        userRecordMap.put('LocaleSidKey','en_US');
        userRecordMap.put('TimeZoneSidKey','America/Los_Angeles');
        //Added by Milanjeet Singh to overcome from duplicate Community nickname
        userRecordMap.put('CommunityNickname', createStringValue()+DateTime.now().getTime());
        if(recordValuesMap != null){
            for(String key : recordValuesMap.keySet()){
                userRecordMap.put(key,recordValuesMap.get(key));
            }
        }
        User objUser = new User();
        objUser = (User)TestingUtility.createTestRecords(User.SObjectType, userRecordMap, b_doInsert);
        return objUser;
    }

    public static List<User> insertUserWithAssert(Id profileId, List<Map<String,Object>> lstRecordValuesMap, Boolean b_doInsert){
        List<Map<String,Object>> lstUserRecordValuesMap = new List<Map<String,Object>>();
        for(Map<String,Object> recordValuesMap : lstRecordValuesMap){
            Map<String,Object> userRecordMap = new Map<String,Object>();
            userRecordMap.put('alias','te');
            userRecordMap.put('Username',createStringValue()+'standarduser@test.com');
            userRecordMap.put('ProfileId',profileId);
            userRecordMap.put('EmailEncodingKey','ISO-8859-1');
            userRecordMap.put('LanguageLocaleKey','en_US');
            userRecordMap.put('LocaleSidKey','en_US');
            userRecordMap.put('TimeZoneSidKey','America/Los_Angeles');
            //Added by Milanjeet Singh to overcome from duplicate Community nickname
            userRecordMap.put('CommunityNickname', createStringValue()+DateTime.now().getTime());
            if(recordValuesMap != null){
                for(String key : recordValuesMap.keySet()){
                    userRecordMap.put(key,recordValuesMap.get(key));
                }
            }
            lstUserRecordValuesMap.add(userRecordMap);
        }
        return (List<User>)createTestRecords(lstUserRecordValuesMap.size(), User.SObjectType, lstUserRecordValuesMap, b_doInsert);
    }

    // Purpose: get sObject Picklist Values.
    // Parameters:
    // 1. String ObjectApiName: object Name.
    // 2. String strFieldName: picklist field api name
    // 3. crudType: crudType i.e Insert
    // Return type: List Of Picklist Values
    public static List<String> getPicklistValues(String strObjectApiName,String strFieldName){
        List<String> pickValsList=new List<String>();
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(strObjectApiName);
        Sobject sObjName = targetType.newSObject();
        Schema.sObjectType sObjType = sObjName.getSObjectType();
        Schema.DescribeSObjectResult sObjDescribe = sObjType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = sObjDescribe.fields.getMap();
        List<Schema.PicklistEntry> picklistEntryList = fieldMap.get(strFieldName).getDescribe().getPickListValues();
        for (Schema.PicklistEntry pcEntry : picklistEntryList) {
            pickValsList.add(pcEntry.getValue());
        }
        return pickValsList;
    }

    //create single Referral__c record with assertion
    public static Referral__c createReferral(Map<String,Object> recordValuesMap, Boolean doInsert){
        return (Referral__c) createTestRecords(Referral__c.sObjectType, recordValuesMap, doInsert);
    }

    //create single Lead record with assertion
    public static Lead createLead(Map<String,Object> recordValuesMap, Boolean doInsert){
        //create Lead data
        if (recordValuesMap.get('Email') == null) {
            recordValuesMap.put('Email', 'Test' + createUserCommunityName() + '@Example.com');
        }
        if (recordValuesMap.get('FirstName') == null) {
            recordValuesMap.put('FirstName', FIRST_NAME);
        }
        if (recordValuesMap.get('LastName') == null) {
            recordValuesMap.put('LastName', LAST_NAME);
        }
        if (recordValuesMap.get('Phone') == null) {
            recordValuesMap.put('Phone', PHONE_NUMBER);
        }
        if (recordValuesMap.get('Company') == null) {
            recordValuesMap.put('Company', COMPANY_NAME);
        }
        return (Lead) createTestRecords(Lead.sObjectType, recordValuesMap, doInsert);
    }

    //create single account record with assertion
    public static Account createAccount(String strAccountName, Boolean doInsert ){
        Map<String,Object> recordValuesMap = new Map<String,Object>();
        List<Map<String,Object>> newListOfMap = new List<Map<String,Object>>();
        recordValuesMap.put('Name',strAccountName);
        newListOfMap.add(recordValuesMap);
        return (Account)createTestRecords(1, Account.sObjectType, newListOfMap, doInsert)[0];

    }

    //create account records with assertion
    public static List<Account> createAccounts(Integer countToCreate, String name, Boolean doInsert){
        //create different account records with assertion
        List<Map<String,Object>> accountRecordListOfMap = new List<Map<String,Object>>();
        for( Integer i = 0; i < countToCreate; i++ ){
            Map<String,Object> accountRecordMap = new Map<String,Object>();
            accountRecordMap.put('Name',name+i);
            accountRecordListOfMap.add(accountRecordMap);
        }
        return createTestRecords(Account.sObjectType, accountRecordListOfMap, doInsert);
    }


    //create single contact records with assertion
    public static Contact createContact( Id acctId, String lastName, Boolean doInsert ){
        //Create Contact Data
        Map<String,Object> recordValuesMap = new Map<String,Object>();
        List<Map<String,Object>> newListOfMap = new List<Map<String,Object>>();
        recordValuesMap.put('FirstName','First Name Test');
        recordValuesMap.put('LastName',lastName);
        recordValuesMap.put('AccountId',acctId);
        recordValuesMap.put('Email','Test@Example.com');
        newListOfMap.add(recordValuesMap);
        return (Contact)createTestRecords(1, Contact.sObjectType, newListOfMap, doInsert)[0];
    }

    //create single contact records with assertion
    public static Contact createContact(Map<String,Object> recordValuesMap, Boolean doInsert ){
        //Create Contact Data
        if(recordValuesMap.get('FirstName') == null){
            recordValuesMap.put('FirstName','First Name 1');
        }
        if(recordValuesMap.get('LastName') == null){
            recordValuesMap.put('LastName','Last Name 1');
        }
        if(recordValuesMap.get('Email') == null){
            recordValuesMap.put('Email','Test'+createUserCommunityName()+'@Example.com');
        }
        return (Contact)createTestRecords(Contact.sObjectType, recordValuesMap, doInsert);
    }

    //create single Opportunity records with assertion
    public static Opportunity createOpportunity(Id accountId, Boolean doInsert){
        List<String> stageValsList = TestingUtility.getPicklistValues('Opportunity','StageName');
        Map<String,Object> recordValuesMap = new Map<String,Object>();
        recordValuesMap.put('StageName',stageValsList[0]);
        recordValuesMap.put('Name','Test Opportunity');
        recordValuesMap.put('CloseDate',System.today().addDays(30));
        recordValuesMap.put('AccountId',accountId);
        recordValuesMap.put('Term_Sheet_Status__c', 'Signed');
        recordValuesMap.put('Term_Sheet_Link__c', 'temp text');
        return (Opportunity)createTestRecords(Opportunity.sObjectType, recordValuesMap, doInsert);
    }
    public static User_Attribute__c createUserAttribute(Id userId, Boolean doInsert){
        Map<String,Object> recordValuesMap = new Map<String,Object>();
        recordValuesMap.put('User__c', userId);
        return (User_Attribute__c)createTestRecords(User_Attribute__c.sObjectType, recordValuesMap, doInsert);
    }
    public static Opportunity createOpportunity(Map<String,Object> recordValuesMap, Boolean doInsert){
        if(String.isBlank((String)recordValuesMap.get('StageName'))){
            List<String> stageValsList = TestingUtility.getPicklistValues('Opportunity','StageName');
            recordValuesMap.put('StageName',stageValsList[0]);
        }
        if(recordValuesMap.get('CloseDate')==null){
            recordValuesMap.put('CloseDate',System.today().addDays(30));
        }
        recordValuesMap.put('Name','Test Opportunity');
        return (Opportunity)createTestRecords(Opportunity.sObjectType, recordValuesMap, doInsert);
    }

    public static Account createAccount(Map<String,Object> recordValuesMap, Boolean doInsert){
        if(String.isBlank((String)recordValuesMap.get('Name'))){
            recordValuesMap.put('Name','Test Opportunity');
        }
        return (Account)createTestRecords(Account.sObjectType, recordValuesMap, doInsert);
    }

    //Create single opportunity with Billing Account
    public static Opportunity createOpportunityWithBillingAcc(Id billingAccId, Boolean doInsert){
        List<String> stageValsList = TestingUtility.getPicklistValues('Opportunity','StageName');
        Map<String,Object> recordValuesMap = new Map<String,Object>();
        recordValuesMap.put('StageName',stageValsList[0]);
        recordValuesMap.put('Name','Test Opportunity');
        recordValuesMap.put('CloseDate',System.today().addDays(30));
        recordValuesMap.put('Billing_Account__c',billingAccId);
        return (Opportunity)createTestRecords(Opportunity.sObjectType, recordValuesMap, doInsert);
    }

    public static User getPortalUser(Id portalProfileId, String portalType, User userWithRole, Boolean doInsert) {
        Id portalProfId;
        Account accObj;
        Contact conObj;
        //Make sure the running user has a role otherwise an exception will be thrown.
        if(userWithRole == null) {
            if(UserInfo.getUserRoleId() == null) {
                UserRole userRoleObj = new UserRole(name = 'TEST ROLE');
                Database.insert(userRoleObj);
                Map<String,Object> userRecordMap = new Map<String,Object>();
                userRecordMap.put('UserRoleId',userRoleObj.id);
                userWithRole = TestingUtility.insertUserWithAssert(UserInfo.getProfileId(),userRecordMap);
            }else {
                userWithRole = new User(Id = UserInfo.getUserId(), UserRoleId = UserInfo.getUserRoleId());
            }
        }
        System.runAs(userWithRole) {
            accObj = TestingUtility.createAccount('Test Account', true);
            conObj = TestingUtility.createContact(accObj.Id,'Test Contact',true);
        }
        // Get any profile Id for the given type.
        if(portalProfileId != null){
            portalProfId = portalProfileId;
        }else{
            portalProfId = [SELECT Id FROM Profile WHERE Usertype = :portalType LIMIT 1].Id;
        }
        Map<String,Object> userRecordMap = new Map<String,Object>();
        userRecordMap.put('ContactId',conObj.Id);
        userRecordMap.put('Email','asuniqueasme@sunGard.com');
        User portalUser = TestingUtility.insertUserWithAssert(portalProfId,userRecordMap, doInsert);
        return portalUser;
    }

    //Added by    @ Milanjeet Singh
    //Date        @ 19/June/2017
    //Purpose     @ To rsolve duplicate Community Nickname for User
    //Description @ It returns randon string with current timeStamp as user Community Nickname
    public static string createUserCommunityName(){
        string nickName = (createRandomString()+Datetime.now().getTime()+userInfo.getOrganizationId()) + '' +math.random();
        return nickName.right(30);
    }

    public static Building__c createBuilding(Map<String,Object> recordValuesMap, Boolean doInsert){
        if(String.isBlank((String)recordValuesMap.get('Name'))){
            recordValuesMap.put('Name','Test Building');
        }
        return (Building__c)createTestRecords(Building__c.sObjectType, recordValuesMap, doInsert);
    }

    /*This method can be used to create bulk building records*/
    public static List<Building__c> createBuildings(Map<String,Object> recordValuesMap,Integer count){
        List<Building__c> lstBuilding= new List<Building__c>();
        for(Integer index = 1 ; index <= count ;index ++){
            if(String.isBlank((String)recordValuesMap.get('Name'))){
                recordValuesMap.put('Name','Test Building '+index);
            }
            lstBuilding.add((Building__c)createTestRecords(Building__c.sObjectType, recordValuesMap,false));
        }
        return lstBuilding;
    }

    public static List<Building__c> createBuildings(List<Map<String,String>> lstMapTestBuildings, Boolean doInsert) {
        return (List<Building__c>)createTestRecords(lstMapTestBuildings.size(), Building__c.sObjectType, lstMapTestBuildings, doInsert);
    }

    public static Inventory__c createReservable(Map<String,Object> recordValuesMap, Boolean doInsert){
        return (Inventory__c)createTestRecords(Inventory__c.sObjectType, recordValuesMap, doInsert);
    }

    public static OpportunityLineItem createOpportunityLineItem(Map<String,Object> recordValuesMap, Boolean doInsert){
        return (OpportunityLineItem)createTestRecords(OpportunityLineItem.sObjectType, recordValuesMap, doInsert);
    }

    public static Product2 createProduct2(Map<String,Object> recordValuesMap, Boolean doInsert){
        return (Product2)createTestRecords(Product2.sObjectType, recordValuesMap, doInsert);
    }

    public static List<Account> getSalesAccountsWithHierarchy(Integer numberOfOrgAccounts,Boolean createHierarchy){
        List<Account> lstAcc = new List<Account>();
        for(integer index = 0; index <= numberOfOrgAccounts; index++){
            lstAcc.add( new Account(Name='test Sales'+index,Nickname__c = 'Sales'+index+TestingUtility.createUserCommunityName()));
        }
        insert lstAcc;
        if(createHierarchy){
            lstAcc = createHierarchy(numberOfOrgAccounts, lstAcc);
        }
        return lstAcc;
    }

    public static Id orgAccountIdOnInsert;
    public static List<Account> createHierarchy(Integer numberOfOrgAccounts, List<Account> lstSalesAccounts){
        for(Integer index = 0; index < lstSalesAccounts.size(); index++){
            if(index != 0){
                lstSalesAccounts[index].parentId = lstSalesAccounts[index-1].Id;
                lstSalesAccounts[index].Account_Type__c = 'Sales';
            }else{
                lstSalesAccounts[index].Account_Type__c = 'Org';
                orgAccountIdOnInsert = lstSalesAccounts[0].Id;
            }
        }
        update lstSalesAccounts;
        return lstSalesAccounts;
    }

    public static set<String> getEditableFields(Set<String> setFields , String sObjectName){
        Set<String> setFieldstoReturn = new Set<String>();
        Schema.DescribeSObjectResult sObjResult = Schema.getGlobalDescribe().get(sObjectName).getDescribe();
        for(String fieldName:sObjResult.fields.getMap().keyset()){
            Schema.DescribeFieldResult fieldResult = sObjResult.fields.getMap().get(fieldName).getDescribe();
            if(fieldResult.isCreateable() && !fieldResult.isAutoNumber() && !fieldResult.isCalculated()){
                if(setFields!= null && setFields.contains(fieldName.toLowerCase())){
                    setFieldstoReturn.add(fieldResult.getName());
                }else if(setFields == null){
                    setFieldstoReturn.add(fieldResult.getName());
                }
            }
        }
        return setFieldstoReturn;
    }

    public static Map<String, Object> getUserMapValues(string nameDifferentiator){
        Map<String, Object> mapUserValues = new Map<String, Object>();
        mapUserValues.put('Alias', String.valueOf(createRandomString()).substring(0,5));
        mapUserValues.put('Email', 'testUser_' + nameDifferentiator + '@example.com');
        mapUserValues.put('LastName', 'User' + nameDifferentiator);
        mapUserValues.put('UserName', 'testUser_' + nameDifferentiator + '@example.com');
        mapUserValues.put('CommunityNickName', 'Test'  + nameDifferentiator + system.now());
        return mapUserValues;
    }

    public static List<Account> getAccountsByType(Map<String,Object> recordValuesMap, String accountType, Integer count){
        List<Account> lstAccount= new List<Account>();
        if(recordValuesMap !=null && !recordValuesMap.isEmpty()){
            for(Integer index = 1 ; index <= count; index ++){
                if(String.isBlank((String)recordValuesMap.get('Name'))){
                    recordValuesMap.put('Name','Test Account' + index);
                }else{
                    recordValuesMap.put('Name',String.valueOf(recordValuesMap.get('Name')) + index);
                }
                if(String.isBlank((String)recordValuesMap.get('Account_Type__c')) && accountType != null){
                    recordValuesMap.put('Account_Type__c', accountType);
                }
                lstAccount.add((Account)createTestRecords(Account.sObjectType, recordValuesMap, false));
            }
        }
        return lstAccount;
    }

    public static set<Id> insertRecordsWithAssert(sObject[] recordsToInsert, Boolean allOrNone){
        set<Id> recordIds = new set<Id>();
        for(Database.SaveResult result : Database.insert( recordsToInsert,allOrNone)){
            if(result.isSuccess()){
                recordIds.add(result.getId());
            }
        }
        return recordIds;
    }

    /************************************************************************************************************************************
         Author              :   Sunil Bhosale
         Description         :
         Created By          :   19 Oct 2018
     **************************************************************************************************************************************/
    private static List<Account> getAccounts(Integer numberOfAccount, Boolean shallCreateBillingAccount){
        List<Account>  lstAccount = new List<Account>();
        List<CI_Company__c> lstUnomyCompany = new List<CI_Company__c>([SELECT Id FROM CI_Company__c LIMIT : numberOfAccount]);
        String billingAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();
        for(Integer count=(accountsCount + 1);count <= (numberOfAccount + accountsCount); count++){
            Account accountRecord = new Account(Name = 'john'+count, Lead_Source__c = 'Wework.com', CI_Updated_DateTime__c = System.today());
            if (shallCreateBillingAccount) {
                accountRecord.UUID__c = 'billUUID' + count;
                accountRecord.RecordTypeId = billingAccountRecordTypeId;
            }
            lstAccount.add(accountRecord);
		}
        insertRecordsWithAssert(lstAccount, false);
        if(lstAccount.size() > 0 && lstAccount[0].Id != null){
            isAccounstInserted = true;
            accountsCount += lstAccount.size();
            return  lstAccount;
        }
        return null;
    }

    private static List<Contact> getContacts(Integer numberOfContacts, List<String> lstEmails, Map<String, Object> mapData, Boolean doInsert){
        if(!isAccounstInserted){
            getAccounts(numberOfContacts, false);
        }
        List<Contact> lstContacts = new List<Contact>();
        Map<String,  List<Object>> mapFieldValues;
        if(lstEmails != null && lstEmails.size() > 0){
            Integer count = 0;
            for(Account account : [SELECT Id, Name FROM Account LIMIT : numberOfContacts]){
                lstContacts.add(new Contact(FirstName=account.Name,LastName='Smith',Email=lstEmails[count],AccountId=account.Id));
                count++;
            }
        }else if(mapData != null && mapData.get('mapFieldValues') != null){
            mapFieldValues = (Map<String, List<Object>>) mapData.get('mapFieldValues');
            lstContacts.addAll((List<Contact>)createRecordsWithFields(Contact.sObjectType, mapFieldValues, null, numberOfContacts, null));
        }else{
            for(Account account : [SELECT Id, Name, CI_Company__c FROM Account LIMIT : numberOfContacts]){
                lstContacts.add(new Contact(FirstName = account.Name, LastName='Smith', Email=account.Name+'.Contact@example.com', AccountId=account.Id, CI_Company__c = account.CI_Company__c
                ));

            }
        }
        if(doInsert) insertRecordsWithAssert(lstContacts, false);
        if(lstContacts.size() > 0 && lstContacts[0].Id != null){
            isContactsInserted = true;
            return lstContacts;
        }else if(!lstContacts.isEmpty()){
            return lstContacts;
        }else{
            return null;
        }
    }

    private static List<Opportunity> getOpportunities(Integer numberOfOpportunities, Boolean doInsert){
        Map<String, Id> oppRecordType = TestingUtility.getRecordTypeMapByName(Opportunity.sObjectType);
        List<Opportunity> lstOpportunities = new List<Opportunity>();
        if(!isContactsInserted){
            getContacts(numberOfOpportunities, null, null, true);
        }
        Integer count = 1;
        for(Contact contact : [SELECT Id, Name, AccountId, Account_Name__c FROM Contact LIMIT : numberOfOpportunities]){
            lstOpportunities.add(new Opportunity(
                    Name ='Opp-'+contact.Name+contact.Account_Name__c,
                    CloseDate = System.today().addDays(30),
                    AccountId =  contact.AccountId,
                    Primary_Member__c = contact.Id,
                    contract_UUId__c = 'test121'+count,
                    StageName = 'Selling',
                    RecordTypeId = oppRecordType.get('New Business')
            ));
            count++;
        }
        if(doInsert){
            insertRecordsWithAssert(lstOpportunities, false);
        }

        if(lstOpportunities.size() > 0){
            isOpportunityInserted = true;
        }
        return lstOpportunities;
    }

    private static List<Opportunity> getOpportunities(Map<String, List<Object>> mapFieldValues, Integer numberOfOpportunities, Boolean doInsert){
        Map<String, Id> oppRecordType = TestingUtility.getRecordTypeMapByName(Opportunity.sObjectType);
        List<Opportunity> lstOpportunities = new List<Opportunity>();
        Map<String, Object> mapOpportunityDefaults = new Map<String, Object>{
                'StageName' => 'Selling',
                'CloseDate' => System.today().addDays(30),
                'Term_Sheet_Status__c' => 'Signed',
                'Term_Sheet_Link__c' => 'not empty'
        };
        if(!isContactsInserted && mapFieldValues != null){
            getContacts(numberOfOpportunities,null, null, true);
        }
        Map<String,Schema.DescribeFieldResult> requiredFieldsMap = getNullabelRequiredFields(Opportunity.sObjectType);
        if(mapFieldValues != null && mapFieldValues.Size() > 0){
            lstOpportunities.addAll((List<Opportunity>)createRecordsWithFields(Opportunity.sObjectType, mapFieldValues, mapOpportunityDefaults, numberOfOpportunities, null));
        }else{
            for(Contact contact : [SELECT Id, Name, AccountId, Account_Name__c FROM Contact LIMIT : numberOfOpportunities]){
                Opportunity objOpp = new Opportunity();
                for(String fieldApiName : mapOpportunityDefaults.keyset()){
                    objOpp.put(fieldApiName, mapOpportunityDefaults.get(fieldApiName));
                }
                objOpp.Name = 'Opp-'+contact.Name+contact.Account_Name__c;
                objOpp.AccountId =  contact.AccountId;
                objOpp.Primary_Member__c = contact.Id;
                lstOpportunities.add(objOpp);
            }
        }
        if(doInsert){
            insertRecordsWithAssert(lstOpportunities, false);
            isOpportunityInserted = true;
        }
        return lstOpportunities;
    }

    public static List<sObject> createRecordsWithFields(Schema.sObjectType sObjectTypeRequested, Map<String, List<Object>> mapFieldValues, Map<String, Object> mapDefaults, Integer totalRecords, List<Map<String, Object>> lstCustomMap){
        Map<String,Schema.DescribeFieldResult> requiredFieldsMap;
        if(sObjectTypeRequested != null){
            requiredFieldsMap = getNullabelRequiredFields(sObjectTypeRequested);
        }
        Boolean createMap = (mapDefaults != null && mapDefaults.get('createMap') != null) ? Boolean.valueOf(mapDefaults.get('createMap')) : false;
        List<sObject> lstRecords = new List<sObject>();
        sObject obj;
        Map<String, Object> mapCustomFieldAndValues;
        if(mapFieldValues != null && mapFieldValues.Size() > 0){
            for(Integer index = 0; index < totalRecords; index++){
                if(createMap){
                    mapCustomFieldAndValues = new Map<String, Object>();
                }else{
                    obj =  getDefultValuesInSobject(sObjectTypeRequested, requiredFieldsMap, mapDefaults);
                }
                for(String fieldApiName : mapFieldValues.Keyset()){
                    if(mapCustomFieldAndValues != null){
                        mapCustomFieldAndValues.put(fieldApiName, mapFieldValues.get(fieldApiName)[index]);
                    }else if(obj != null ){
                        obj.put(fieldApiName, mapFieldValues.get(fieldApiName)[index]);
                    }
                }
                if(lstCustomMap != null){
                    lstCustomMap.add(mapCustomFieldAndValues);
                }
                lstRecords.add(obj);
            }
        }
        return lstRecords;
    }

    private static sObject getDefultValuesInSobject(Schema.sObjectType sObjectTypeRequested, Map<String,Schema.DescribeFieldResult> requiredFieldsMap, Map<String, Object> defaults){
        sObject record = sObjectTypeRequested.newSobject();
        if(defaults != null){
            for(String strField : requiredFieldsMap.keySet()){
                if( !defaults.KeySet().contains(strField)){
                    record.put(strField,getTestValue(requiredFieldsMap.get(strField)));
                }
            }
            for(String fieldApiName : defaults.keySet()){
                record.put(fieldApiName,defaults.get(fieldApiName));
            }
        }
        return record;
    }

    
    private static List<ServiceAppointment> getTours(Integer numberOfTours, Boolean doInsert){
        List<sobject> lstTours = new List<sobject>();
        Integer Count = 0;
        List<sObject> lstsObject;
        List<sobject> lstOpportunities;
        if(!isOpportunityInserted){
          lstOpportunities =  getOpportunities(numberOfTours, doInsert);
        }
        if(!isJourneyInserted){
            getJourneys(numberOfTours, true);
        }
        if(!isBuildingInserted){
           getBuildings(numberOfTours);
        }
        List<Journey__c> lstJourney= [select id from Journey__c LIMIT : numberOfTours];
        List<Building__C> lstBuilding = [select id, Email__c, Name, uuid__c, Time_Zone__c from Building__C where Name LIKE 'testBuilding%'];
        Boolean useCount = lstBuilding.size() == lstOpportunities.size();
        for(Opportunity opportunity : (List<Opportunity>)lstOpportunities){
            lstTours.add(new ServiceAppointment(
                Opportunity_Id__c = opportunity.Id,
                ParentRecordId = opportunity.Id,
                Status = 'Scheduled',
                Building_Id__c = useCount ? lstBuilding[Count].Id : lstBuilding[0].Id,
                ContactId =  opportunity.Primary_Member__c,
                Scheduled_Start_Time__c = '8:00pm',
                Tour_Confirmation_Email_Sent__c = true,
                SchedStartTime = System.DateTime.now().addDays(3),
                Journey_Id__c = lstJourney[Count].Id,
                UUID__c = 'uuid'+Count
            ));
            Count++;
        }
        BuildingUtility.idToBuilding = null;
        if(doInsert){
            insertRecordsWithAssert(lstTours, false);
        }else{
            lstsObject = new List<sObject>();
            lstsObject.addAll(lstTours);
            lstsObject.addAll(lstOpportunities);
        }
        if(!doInsert){
            return lstsObject;
        }else if(!lstTours.isEmpty()){
            return lstTours;
        }else{
            return null;
        }
    }
   

    private static List<Task> getTasks(Integer  numberOfTask){
        List<Task> lstTask = new List<Task>();
        if(!isContactsInserted)
            getContacts(numberOfTask,null, null, true);
        for(Contact contact : [SELECT Id, Name, AccountId, Account_Name__c FROM Contact LIMIT : numberOfTask]){
            lstTask.add(new Task(
                    WhoId = contact.Id,
                    Subject = 'Follow up',
                    Status = 'In Progress'
            ));
        }
        insertRecordsWithAssert(lstTask, false);
        if(lstTask.size() > 0 && lstTask[0].Id != null){
            return lstTask;
        }
        return null;
    }


    private static List<Journey__c> getJourneys(Integer  numberOfJourneys, Boolean doInsert){
        List<Journey__c> lstJourney= new List<Journey__c>();
        if(!isContactsInserted){
            getContacts(numberOfJourneys, null, null, true);
        }
        for(Contact contact : [SELECT Id, Name FROM Contact LIMIT : numberOfJourneys]){
            lstJourney.add(new Journey__c(
                    Name = 'testJourney'+contact.Name,
                    Primary_Contact__c = contact.Id,
                    NMD_Next_Contact_Date__c = System.today()
            ));
        }
        if(!doInsert){
            return lstJourney;
        }
        insertRecordsWithAssert(lstJourney, false);
        if(lstJourney.size() > 0 && lstJourney[0].Id != null){
            return lstJourney;
        }else{
            return null;
        }
    }

    private static List<Market__c> getMarkets(Integer numberOfMarkets){
        Map<Region__c, Territory__c> mapRegionToTerr = getRegionAndTerritory(1);
        List<Market__c>  lstMarkets = new List<Market__c>();
        for(Integer count=1; count <= numberOfMarkets; count++){
            lstMarkets.add(
                    new Market__c(
                            Name = 'testMarket'+(Math.random()*count),
                            CurrencyIsoCode = 'USD',
                            UUID__c = 'MarketUUID'+count,
                            TerritoryID__c = mapRegionToTerr.values()[0].Id
                    )
            );
        }
        insertRecordsWithAssert(lstMarkets, false);
        if(lstMarkets.size() > 0 && lstMarkets[0].Id != null){
            isMarketInserted= true;
            return lstMarkets;
        }else{
            return null;
        }
    }

    private static List<Building__c> getBuildings(Integer numberOfBuildings){
        List<Building__c>  lstBuildings = new List<Building__c>();
        List<Market__c>  lstMarkets;
        if(!isMarketInserted){
            lstMarkets = getMarkets(numberOfBuildings);
        }
        for(Integer count=1; count <= numberOfBuildings; count++){
            lstBuildings.add(new Building__c(Name = 'testBuilding'+count, Is_Tourable__c = true, Country__c = 'USA', Time_Zone__c ='America/Denver', Portfolio_Name__c = 'test portfolio', Market__c = lstMarkets[count-1].Id, CurrencyIsoCode = 'USD', UUID__c = 'buildingUUID'+count, City__c = 'test',Email__c='testBuilding'+count+'@wework.com',Location_No_City__c='testCity'+count));
        }
        insertRecordsWithAssert(lstBuildings, false);
        if(lstBuildings.size() >0 && lstBuildings[0].Id != null){
            isBuildingInserted= true;
            return  lstBuildings;
        }else{
            return null;
        }
    }

    private static List<Inventory__c> getInventories(Integer numberOfReservables){
        List<Building__c> lstBuildings;
        if(!isBuildingInserted){
            lstBuildings = getBuildings(numberOfReservables);
        }
        List<Inventory__c> lstInventories = new List<Inventory__c>();
        for(Building__c building : lstBuildings){
            lstInventories.add(new Inventory__c(Name = 'testInventoryof'+building.Name, Building__c = building.Id,
                    CurrencyIsoCode = 'USD', UUID__c = 'InventoryUUIDOf'+building.UUID__c));
        }
        insertRecordsWithAssert(lstInventories, false);
        return lstInventories;
    }

    private static List<Referral__c> getReferrals(Integer numberOfReferrals, Map<String, Object> mapData, Boolean doInsert){
        List<Referral__c> lstReferrals = new List<Referral__c>();
        if(mapData.get('referralEmails') == null){
            if(!isContactsInserted){
                getContacts(numberOfReferrals,null, null, true);
            }
            List <String> lstEmails = new List<String>();
            for(Integer index = 1 ;index <= numberOfReferrals; index++ ){
                lstEmails.add('zilla@comcast.net'+index);
            }
            List<Contact> lstReferrer = getContacts(numberOfReferrals, lstEmails, null, true);
            Integer count = 0;
            for(Contact contact : [SELECT Id, Name, Email FROM Contact LIMIT : numberOfReferrals]){
                lstReferrals.add(new Referral__c(
                        Name = 'testReferralOf'+contact.Name,
                        IsActive__c = true,
                        Referral_Email__c = contact.Email,
                        Referrer__c = lstReferrer[count].Id
                ));
                count++;
            }
            insertRecordsWithAssert(lstReferrals, false);
            if(lstReferrals.size() > 0 && lstReferrals[0].Id != null){
                return lstReferrals;
            }
        }else{
            integer count = 0;
            List<String> lstReferralEmail = new List<String>();
            lstReferralEmail.addAll((List<String>)mapData.get('referralEmails'));
            List <String> lstEmails = new List<String>();
            for(Integer index = 1 ;index <= numberOfReferrals; index++ ){
                lstEmails.add('referralContact'+index+'@comcast.net');
            }
            for(Contact Referralcontact : getContacts(numberOfReferrals, lstEmails, null, true)){
                lstReferrals.add(new Referral__c(
                        Name = 'testReferralOf'+contact.Name,
                        IsActive__c = true,
                        Referral_Email__c = lstReferralEmail[count],
                        Referrer__c = Referralcontact.Id
                ));
                count++;
            }
            if(doInsert){
                insertRecordsWithAssert(lstReferrals, false);
            }
            return lstReferrals;
        }
        return null;
    }


    public static List<Product2> createAllWeWorkProducts(Boolean doInsert){
        String JSONForAllWeWorkProducts = '{"Name":["Dedicated Desk","Deal","Dedicated Desk","Enterprise Solutions Desk","Hot Desk","WeMembership","Shared Office Desk","Global Access Membership","Desk","Not Considered"],' + 
                                          '"ProductCode":["PRDE-000200","PRDL-000001","PRES-000300","PRHD-000400","PRWM-000500","PRSO-000700","PRGA-000800","PROF-000900","Not Considered"],'+ 
                                          '"Default_Product_Category__c":["Standard Office","Standard Office","Custom Office","Hot Desk","WeMembership","Standard Office","Access","Standard Office","Standard Office"],' +
                                          '"Family":["WeWork","WeWork","Enterprise Solutions","WeWork","WeWork","WeWork","Access","WeWork","WeWork"],' +
                                          '"Product_UUID__c":["Product_UUID_1","Product_UUID_2","Product_UUID_3","Product_UUID_4","Product_UUID_5","Product_UUID_6","Product_UUID_7","Product_UUID_8","Product_UUID_9"]}';
        Map<String, List<String>> mapFieldValues = (Map<String, List<String>>) JSON.deserialize(JSONForAllWeWorkProducts, Map<String, List<String>>.class);
        List<Product2> lstProductItems = createProducts(mapFieldValues, doInsert);
        if(doInsert){
            List<Product2> lstProducts = new List<Product2>();
            for(Product2 objProduct: lstProductItems){
                objProduct.IsActive = true;
                lstProducts.add(objProduct);
            }
            if(lstProducts.size() > 0){
                update lstProducts;
            }
        }
        return lstProductItems;
    }

    private static List<Product2> createProducts(Map<String, List<Object>> mapFieldValues, Boolean doInsert){
        List<Product2> lstProduct2 = (List<Product2>)createRecordsWithFields(Product2.sobjectType, mapFieldValues, null, 9, null);
        if(doInsert){
            insertListWithAssert(lstProduct2);
            createPriceBookEntriesForProduct(lstProduct2);
        }
        return lstProduct2;
    }

    private static void createPriceBookEntriesForProduct(List<Product2> lstProduct2){
        Id pricebookId = Test.getStandardPricebookId();
        List<PricebookEntry> lstPricebookEntry = new List<PricebookEntry>();
        for(CurrencyType objCurrencyType : [SELECT ISOCode, ConversionRate FROM CurrencyType WHERE IsActive = TRUE]){
            for(Product2 objProduct2 : lstProduct2){
                PricebookEntry priceBook = new PricebookEntry();
                priceBook.Pricebook2Id = pricebookId;
                priceBook.Product2Id  = objProduct2.Id;
                priceBook.CurrencyIsoCode = objCurrencyType.ISOCode;
                priceBook.UnitPrice = 9999;
                priceBook.IsActive = true;
                lstPricebookEntry.add(priceBook);
            }
        }
        insertListWithAssert(lstPricebookEntry);
    }

    private static List<Lead> getLeads(Integer numberOfLead, Map<String, Object> mapData, Boolean doInsert){
        List<Lead>  lstLead = new List<Lead>();
        Map<String,  List<Object>> mapFieldValues;
        if(mapData.get('mapFieldValues') != null){
            mapFieldValues = (Map<String,  List<Object>>) mapData.get('mapFieldValues');
            lstLead.addAll((List<Lead>)createRecordsWithFields(Lead.sObjectType, mapFieldValues, null, numberOfLead, null));
        }else{
            for(Integer count=1; count <= numberOfLead; count++){
                Lead objLead = new Lead(FirstName = 'FirstName' + count, LastName = 'LastName' + count, Company = 'Company');
                objLead.Email = mapData.containsKey('Email') ? String.valueOf(mapData.get('Email')) : 'john.smith' + count + '@example.com';
                objLead.LeadSource = mapData.containsKey('LeadSource') ? String.valueOf(mapData.get('LeadSource')) : 'WeWork.com';

                objLead.Lead_Source_Detail__c = mapData.containsKey('Lead_Source_Detail__c') ? String.valueOf(mapData.get('Lead_Source_Detail__c')) : 'Book a Tour Form';
                objLead.Generate_Journey__c = mapData.containsKey('Generate_Journey__c') ? Boolean.valueOf(mapData.get('Generate_Journey__c')) : true;

                lstLead.add(objLead);
            }
        }
        doInsert = mapData.get('doInsert') != null ? Boolean.valueOf(mapData.get('doInsert')) : doInsert;
        // doInsert = Boolean.valueOf(mapData.get('doInsert'));
        if(doInsert){
            insertRecordsWithAssert(lstLead, false);
            isLeadInserted = true;
        }
        return  lstLead;
    }
    //User insertion
    private static List<User> getUsers(Integer numberOfUsers,Map<String,Object> mapData){
        List<User> lstUsers = new List<User>();
        Map<string , Object> mapofUsers = new Map <String, object>();
        List<Profile> lstProfiles = new List<Profile>();
        Profile profileRecord;
        if(mapData.containsKey('userProfiles') && mapData.get('userProfiles') != null){
            List<String> lstProfileNames = (List<String>)mapData.get('userProfiles');
            lstProfiles = [SELECT Id FROM Profile WHERE Name IN: lstProfileNames];
        }
        else{
            profileRecord = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        }

        String emailDomain = mapData.containsKey('emailDomain') ? String.valueOf(mapData.get('emailDomain')) : 'test.com';
        Map<String,  List<Object>> mapFieldValues;
        if(mapData.get('mapFieldValues') != null){
            mapFieldValues = (Map<String,  List<Object>>) mapData.get('mapFieldValues');
        }
        for(Integer count = 1; count <= numberOfUsers; count++){
            if((mapFieldValues != null) && mapFieldValues.containsKey('Sales_Role__c') && mapFieldValues.get('Sales_Role__c') != null){
                mapOfUsers.put('Sales_Role__c', mapFieldValues.get('Sales_Role__c').get(0));
            }
            mapofUsers.put('LastName', 'testUser ' + count + '@' + emailDomain);
            mapofUsers.put('Email', 'testUserEmail' + count + '@' + emailDomain);
            User objUser;
            if(mapData.containsKey('userProfiles') && mapData.get('userProfiles') != null && lstProfiles.size() > 0){
                for(Integer index = 0; index < lstProfiles.size();index++){
                    objUser = insertUserWithAssert(lstProfiles[index].Id,mapofUsers,true);
                }
            }else{
                objuser = insertUserWithAssert(profileRecord.Id,mapofUsers,true);
            }

            lstUsers.add(objuser);
        }
        return lstUsers;
    }



    //This method will insert number Of Campaigns provided as a parameter "numberOfCampaign" and first of them is Parent Campaign
    private static List<Campaign> getCampaigns(Integer numberOfCampaign){
        List<Campaign> lstCampaigns = new List<Campaign>();
        Campaign objCampaign = new Campaign(Name = 'Parent Campaign', Region__c = 'India;Mumbai');
        insertWithAssert(objCampaign);
        for(Integer count = 1; count < numberOfCampaign; count++){
            lstCampaigns.add(new Campaign(Name = 'Test Campaign '+count, Region__c = 'Maharashtra', Type = 'Telemarketing', ParentId = objCampaign.Id));
        }
        insertRecordsWithAssert(lstCampaigns, false);
        if(lstCampaigns.size() > 0 && lstCampaigns[0].Id != null){
            isCampaignInserted = true;
            return lstCampaigns;
        }else
                return null;
    }

    /*private static List<CampaignMember> getCampaignMembers(Integer numberOfCampaignMember){
        Integer count = 0;
        List<CampaignMember> lstCampaignMember = new List<CampaignMember>();
        if(!isContactsInserted)
            getContacts(numberOfCampaignMember, null, null, true);
        if(!isCampaignInserted)
            getCampaigns(numberOfCampaignMember);
        List<Campaign> lstCamapaign = [SELECT Id FROM Campaign];
        for(Contact objContact : [SELECT Id, Name FROM Contact LIMIT : numberOfCampaignMember]){
            lstCampaignMember.add(new CampaignMember(
                CampaignId = lstCamapaign[count].Id,
                ContactId = objContact.Id
            ));
            count++;
        }
        insertRecordsWithAssert(lstCampaignMember, false);
        if(lstCampaignMember.size() > 0 && lstCampaignMember[0].Id != null){
           return lstCampaignMember;
        }else{
            return null;
        }
    }

    private static List<Tour_Schedule__c> getTourSchedule(Integer numberTourSchedule){
        List<Tour_Schedule__c> lstTourSchedule = new List<Tour_Schedule__c>();
        if(!isBuildingInserted){
            getBuildings(numberTourSchedule);
        }
        for(Building__c objBuilding : [SELECT Id FROM Building__c LIMIT : numberTourSchedule]){
            lstTourSchedule.add(new Tour_Schedule__c(Building__c = objBuilding.Id, Simultaneous_Tours__c = '2', Tour_Spacing__c = 'Hour', Maximum_Tour_Days__c = 1));
        }
        insertRecordsWithAssert(lstTourSchedule, false);
        if(lstTourSchedule.size() > 0 && lstTourSchedule[0].Id != null){
            isTourScheduleInserted = true;
            return lstTourSchedule;
        }else
            return null;
    }
    */

    /************************************************************************************************************************************
    Author 				: Rupesh Patil
    Description 		: This method is used to get Case records.
    Created Date		: 28 Nov 2018
   **************************************************************************************************************************************/

    private static List<Case> getCases(Integer numberOfCases){
        List<Case> lstCases = new List<Case>();
        if(!isOpportunityInserted)
            getOpportunities(numberOfCases, true);
        for(Opportunity objOpp : [SELECT Id, Name, Primary_Member__c, AccountId FROM Opportunity LIMIT : numberOfCases]){
            lstCases.add(new Case(AccountId = objOpp.AccountId, Opportunity__c = objOpp.Id, Status = 'New'));
        }
        insertRecordsWithAssert(lstCases, false);
        if(lstCases.size() > 0 && lstCases[0].Id != null){
            isCasesInserted = true;
            return  lstCases;
        }else
                return null;
    }

    /************************************************************************************************************************************
    Author 				: Rupesh Patil
    Description 		: This method is used to get  records.
    Created Date		: 28 Nov 2018
   **************************************************************************************************************************************/
    private static List<OpportunityTeamMember> getOpportunityTeamMembers(Integer numberOfTeamMembers, Boolean doInsert){
        List<OpportunityTeamMember> lstOppTeamMems = new List<OpportunityTeamMember>();
        List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name = 'Wework System Administrator' AND IsActive = true LIMIT : numberOfTeamMembers];
        if(!isOpportunityInserted){
            getOpportunities(numberOfTeamMembers, true);
        }
        for(Opportunity objOpp : [SELECT Id FROM Opportunity LIMIT : numberOfTeamMembers]){
            for(Integer count=0 ;count < numberOfTeamMembers; count++){
                lstOppTeamMems.add(new OpportunityTeamMember(OpportunityId = objOpp.Id, UserId = lstUsers[count].Id));
            }
        }
        if(doInsert){
            insertRecordsWithAssert(lstOppTeamMems, false);
        }
        if(!lstOppTeamMems.isEmpty() && lstOppTeamMems[0].Id != null){
            return lstOppTeamMems;
        }else if(!lstOppTeamMems.isEmpty()){
            return lstOppTeamMems;
        }
        return null;
    }


    public static List<CI_Company__c> getUnomyCompany(Integer numberOfUnomyCompany, Boolean doInsert, Map<String, Object> mapData){
        List<CI_Company__c> lstUnomyCompany = new List<CI_Company__c>();
        Map<String,  List<Object>> mapFieldValues;
        if(mapData != null && mapData.get('mapFieldValues') != null){
            mapFieldValues = (Map<String,  List<Object>>) mapData.get('mapFieldValues');
            lstUnomyCompany.addAll((List<CI_Company__c>)createRecordsWithFields(CI_Company__c.sObjectType, mapFieldValues, null, numberOfUnomyCompany, null));

        }else{
            for(Integer count = 1; count <= numberOfUnomyCompany; count++){
                lstUnomyCompany.add(new CI_Company__c(Location_Address__c = 'Banner'+count, Location_City__c = 'Pune', Company_Name__c = 'unomy Enzigma', Location_Country__c = 'India', Location_State__c = 'Maharashtra', Phone__c = '12456789', Size__c = 110, CI_Company_Id__c = 123456789+count, CurrencyIsoCode = 'USD'));
            }
        }
        if(doInsert){
            insertRecordsWithAssert(lstUnomyCompany, false);
            isUnomyCompanyInserted = true;
            return lstUnomyCompany;
        }
        return lstUnomyCompany;
    }

    public static List<sObject> getRecords(Map<String,Object> mapData){
        String objName = String.valueOf(mapData.get('objName')).toLowerCase();
        Integer numberOfRecords = Integer.valueOf(mapData.get('numberOfRecords'));
        List<String> lstEmails = (List<String>)(mapData.get('lstEmails'));
        Boolean doInsert;
        if(mapData.get('doInsert') != null){
            doInsert = Boolean.valueOf(mapData.get('doInsert'));
        }
        Map<String,  List<Object>> mapFieldValues;
        if(mapData.get('mapFieldValues') != null){
            mapFieldValues = (Map<String,  List<Object>>) mapData.get('mapFieldValues');
        }
        switch on objName {
            when 'lead' {
                return getLeads(numberOfRecords, mapData, true);
            }
            when 'user'  {
                return getUsers(numberOfRecords, mapData);
            }
            when 'account' {
                return getAccounts(numberOfRecords, false);
            }
            when 'contact' {
                return getContacts(numberOfRecords,lstEmails, mapData, doInsert);
            }
            when 'opportunity' {
                return getOpportunities(mapFieldValues, numberOfRecords, doInsert);
            }
            
            when 'tour' {
                return getTours(numberOfRecords, doInsert != null ? doInsert : true);
            }
            when 'inventory'{
                return getInventories(numberOfRecords);
            }
            when 'referral'{
                return getReferrals(numberOfRecords, mapData, doInsert);
            }
            when 'billing_account__c'{
                return getAccounts(numberOfRecords, true);
            }

            when 'product2'{
                return createAllWeWorkProducts(doInsert);
            }

            when 'journey'{
                return getJourneys(numberOfRecords, doInsert != null ? doInsert : true);
            }
            when 'campaign'{
                return getCampaigns(numberOfRecords);
            }
            when 'building__c' {
                return getBuildings(numberOfRecords);
            }

            when 'case' {
                return getCases(numberOfRecords);
            }

            when 'oppoteam' {
                return getOpportunityTeamMembers(numberOfRecords, doInsert != null ? doInsert : true);
            }

            when 'unomy'{
                return getUnomyCompany(numberOfRecords, doInsert, mapData);
            }

        }
        return null;
    }

    public static void getTerritorystructure(){
        Test.loadData(Region__c.sObjectType, 'Region');
        Test.loadData(Territory__c.sObjectType, 'Territory');
        Test.loadData(Market__c.sObjectType, 'Portfolio');
        Test.loadData(Building__c.sObjectType, 'Buildings');
        Test.loadData(Geography__c.sObjectType, 'Geography');
    }
    /************************************************************************************************************************************
        Author 		: Nicholas Zozaya
        Description : This method creates a parent Account, some number of Contacts and some number of Opportunities related to those Contacts.
        Params      :
                      accountFields - only fieldApiName=>Value entries
                      contactParams - fieldApiName=>Value && 'numRecords'=>value entries
                      opportunityParams - fieldApiName=>Value && 'contactRel'=>{ContactLookupFieldApiName} entries
        History:
    ----------------------------------------------------------------------------------------------------------------------------------
        VERSION			DATE				AUTHOR					DETAIL							      ISSUE
        1			13 June, 2019		Nicholas Zozaya			Initial Developement			         ST-4108
    **************************************************************************************************************************************/
    public static void insertAcctContOppFamily(Map<String, Object> accountFields, Map<String, Object> contactParams, Map<String, Object> opportunityParams){
        Map<String, Object> accountValuesMap = new Map<String, Object>{'Name' => 'strAccountName1','Account_Type__c' => 'Org','RecordTypeId' =>  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Enterprise Solutions').getRecordTypeId()};
        if(!accountFields.isEmpty()) accountValuesMap.putAll(accountFields);
        List<Account> lstAccounts = TestingUtility.getAccountsByType(accountValuesMap, 'Org', 1);
        try{
            TestingUtility.insertListWithAssert(lstAccounts);
        }catch(Exception e){
            throw new TestUtilException('error inserting Account in TestingUtility.insertAcctContOppFamily, here\'s the error message: '+e.getMessage());
        }

        Integer numContacts = (contactParams.get('numRecords') != null ? (Integer) contactParams.remove('numRecords') : 5);
        List<Contact> lstContacts = new List<Contact>();
        Map<String, Object> contactValuesMap = new Map<String, Object>{'FirstName'=>'strContact', 'AccountId'=>lstAccounts[0].Id};
        if(!contactParams.isEmpty()) contactValuesMap.putAll(contactParams);
        for(Integer index = 0; index < numContacts; index++){
            contactValuesMap.put('Email', 'Test'+(index+Math.random())+'@gmail.com');
            lstContacts.add((Contact) TestingUtility.createContact(contactValuesMap, false));
        }
        try{
            TestingUtility.insertListWithAssert(lstContacts);
        }catch(Exception e){
            throw new TestUtilException('error inserting Contact in TestingUtility.insertAcctContOppFamily, here\'s the error message: '+e.getMessage());
        }

        List<Opportunity> lstOpportunities = new List<Opportunity>();
        Map<String, Object> opportunityValuesMap = new Map<String, Object>{'AccountId' => lstAccounts[0].Id};
        if(opportunityValuesMap.get('Amount') == null) opportunityValuesMap.put('Amount', 150);
        String oppContactRelApiName = (String) opportunityParams.remove('contactRel');
        if(!opportunityParams.isEmpty()) opportunityValuesMap.putAll(opportunityParams);
        for(Integer i = 0; i < numContacts; i++){
            Decimal randContactSizeDecimal = (Math.random()*lstContacts.size());
            Integer randContactIndex = Integer.valueOf(randContactSizeDecimal.setScale(0, RoundingMode.DOWN));
            opportunityValuesMap.put( (oppContactRelApiName == null ? 'Referrer__c' : oppContactRelApiName ) , lstContacts[randContactIndex].Id);
            lstOpportunities.add((Opportunity)TestingUtility.createOpportunity(opportunityValuesMap, false));
        }
        try{
            TestingUtility.insertListWithAssert(lstOpportunities);
        }catch(Exception e){
            throw new TestUtilException('error inserting Opportunity in TestingUtility.insertAcctContOppFamily, here\'s the error message: '+e.getMessage());
        }
    }
    public static void checkLimits(){
        system.assert(Limits.getQueries() < (Limits.getLimitQueries() - 1), 'Total current queries==>'+ Limits.getQueries());
    }

    public static boolean isInsert(Map<String, Opportunity> mapOldOpportunities){
        if(mapOldOpportunities == null){
            return true;
        }else{
            return false;
        }
    }

    public static boolean isTriggerHandlerActive(String triggerConfigLabel){
        return [SELECT Active__c FROM Trigger_Configuration__mdt WHERE MasterLabel=: triggerConfigLabel].Active__c;
    }

    public static void createAccountTeamTestData(){
        Map<String, Object> mapSingleAccount = new Map<String, Object>{'Account_Type__c' => 'Org', 'RecordTypeId' =>  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Enterprise Solutions').getRecordTypeId()};
        mapSingleAccount.put('Name', 'ACCOUNT_TEST');
        List<Account> lstAccounts = new List<Account>();
        lstAccounts.add(TestingUtility.getAccountsByType(mapSingleAccount, 'Org', 1)[0]);
        insert lstAccounts;
        List<String> lstValidTeamRoles = (List<String>) JSON.deserialize(Settings.getMetadataSetting('Valid_AccountTeamMember_Roles').Data__c, List<String>.class);
        List<String> lstSalesFunctions = TestingUtility.getPicklistValues('User', 'Sales_Role__c');
        Map<String, Object> mapUserValues = TestingUtility.getUserMapValues('_Test1');
        mapUserValues.put('numberOfRecords',lstValidTeamRoles.size());
        mapUserValues.put('objName', 'User');
        mapUserValues.put('Sales_Role__c', lstSalesFunctions[0]);
        List<User> lstUsers = TestingUtility.getRecords(mapUserValues);
        Map<Region__c, Territory__c> mapRegionAndTerritory = getRegionAndTerritory(1);
        List<AccountTeamMember> lstTeamMembers = new List<AccountTeamMember>();
        for(Integer i = 0; i<lstUsers.size(); i++){
            lstTeamMembers.add(getAccountTeamMember(lstAccounts[lstAccounts.size()-1].Id, lstUsers[i], lstValidTeamRoles[i], new List<Region__c>(mapRegionAndTerritory.keyset())[0].Id, mapRegionAndTerritory.values()[0].Id));
        }
        insert lstTeamMembers;
    }

    public static Map<Region__c, Territory__c> getRegionAndTerritory(Integer count){
        List<Region__c> lstRegions = new List<Region__c>();
        Map<Region__c, Territory__c> mapRegionAndTerritory = new Map<Region__c, Territory__c>();
        for(Integer i = 0; i<count; i++){
            Region__c region = new Region__c(
                    Regional_Sales_Manager__c = UserInfo.getUserId(),
                    Name = 'Test Region',
                    Region__c = 'Test Region'+String.valueOf(Math.random())
            );
            lstRegions.add(region);
        }
        insert lstRegions;
        for(Region__c region : lstRegions){
            Territory__c territory = new Territory__c(
                    Territory_Sales_Manager__c = UserInfo.getUserId(),
                    Name = 'Test Territory',
                    RegionID__c = region.Id
            );
            mapRegionAndTerritory.put(region, territory);
        }
        insert mapRegionAndTerritory.values();
        return mapRegionAndTerritory;
    }

    public static AccountTeamMember getAccountTeamMember(Id accountId, User u, String role, Id regionId, Id territoryId){
        String salesFuncPrefix = (String.isNotBlank(u.Sales_Role__c) && u.Sales_Role__c.contains('-')) ? u.Sales_Role__c.substringBefore('-') : null; // get prefix for validation sequence
        return new AccountTeamMember(
                AccountId = accountId,
                Start_Date__c = Date.today(),
                TeamMemberRole = role,
                UserId = u.Id,
                Region__c = regionId,
                Territory__c = territoryId,
                User_Sales_Function__c = u.Sales_Role__c,
                Validation_Sequence__c = accountId+salesFuncPrefix+role+regionId+territoryId
        );
    }

    public static List<User> getCompleteUsers(AccountTeamMember member, Integer numberOfRecords){
        Map<String, Object> mapUserValues = TestingUtility.getUserMapValues('_Test1');
        mapUserValues.put('numberOfRecords',numberOfRecords);
        mapUserValues.put('objName', 'User');
        mapUserValues.put('Sales_Role__c', member.User_Sales_Function__c);
        return (List<User>) TestingUtility.getRecords(mapUserValues);
    }

    public static List<AccountTeamMember> createNewAccountTeamData(Boolean roleCheck){
        List<String> validatedRoles = (List<String>) JSON.deserialize([SELECT Data__c FROM MetadataSetting__mdt WHERE DeveloperName='Non_Duplicated_Account_Team_Roles'].Data__c, List<String>.class);
        List<AccountTeamMember> lstMembers;
        if(roleCheck){
            lstMembers = [SELECT Id, AccountId, TeamMemberRole, Region__c, Territory__c, User_Sales_Function__c, UserId, User.Sales_Role__c FROM AccountTeamMember WHERE TeamMemberRole NOT IN: validatedRoles AND User.Sales_Role__c != null LIMIT 2];
        }else{
            lstMembers = [SELECT Id, TeamMemberRole, User_Sales_Function__c, AccountId, Region__c, Territory__c, UserId FROM AccountTeamMember LIMIT 2];
        }
        List<User> lstUsers = TestingUtility.getCompleteUsers(lstMembers[0], 2);
        Account objAccount = getSingleAccount();
        Map<Region__c, Territory__c> mapRegionAndTerritory = TestingUtility.getRegionAndTerritory(2);
        List<AccountTeamMember> lstNewMembers = new List<AccountTeamMember>();
        List<String> lstRoles = TestingUtility.getPicklistValues('AccountTeamMember', 'TeamMemberRole');
        lstNewMembers.add(TestingUtility.getAccountTeamMember(objAccount.Id, lstUsers[0], 'Client Partner', new List<Region__c>(mapRegionAndTerritory.keyset())[0].Id, mapRegionAndTerritory.values()[0].Id));
        lstNewMembers.add(TestingUtility.getAccountTeamMember(objAccount.Id, lstUsers[1], 'MLB Hold', new List<Region__c>(mapRegionAndTerritory.keyset())[1].Id, mapRegionAndTerritory.values()[1].Id));
        insert lstNewMembers;
        return lstNewMembers;
    }

    public static Account getSingleAccount(){
        Map<String, Object> mapSingleAccount = new Map<String, Object>{'Name'=>'Verify Dupe Role Test','Account_Type__c' => 'Org', 'RecordTypeId' =>  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Enterprise Solutions').getRecordTypeId()};
        Account objAccount = TestingUtility.getAccountsByType(mapSingleAccount, 'Org', 1)[0];
        insert objAccount;
        return objAccount;
    }

    /************************************************************************************************************************************
        Modified By    : Rupesh Patil
        Modified Date  : 4 March 2019
    Description     : This method Creates opportunity data for testing
    **************************************************************************************************************************************/
    public static void opportunityDataForTesting(List<Account> lstAccounts, List<Building__c> lstBuildings, List<User> lstUsers){
        List<Opportunity> lstOpportunities = new List<Opportunity>();
        Map<String,Object> mapOpportunityRecord = new Map<String,Object>();
        //Opportunity 1
        mapOpportunityRecord.put('StageName', 'Selling');
        mapOpportunityRecord.put('Type__c','WeWork');
        mapOpportunityRecord.put('CloseDate', system.today().addDays(5));
        mapOpportunityRecord.put('AccountId', lstAccounts[1].Id);
        mapOpportunityRecord.put('Tour_Notes__c', 'Opportunity Tour Notes');
        mapOpportunityRecord.put('Tour_Outcome_Notes__c', 'Tour Outcome Notes');
        mapOpportunityRecord.put('Description', 'Opprtunity Description');
        mapOpportunityRecord.put('Locations_Interested__c', lstBuildings[0]+';'+lstBuildings[1]);
        mapOpportunityRecord.put('Contract_UUID__c', 'opp01-contract1-0001');
        lstOpportunities.add(TestingUtility.createOpportunity(mapOpportunityRecord, false));

        //Opportunity 2 with Closed Lost
        mapOpportunityRecord.put('StageName', 'Closed Lost');
        mapOpportunityRecord.put('Contract_UUID__c', 'opp03-contract3-0003');
        lstOpportunities.add(TestingUtility.createOpportunity(mapOpportunityRecord, false));

        //Opportunity 3
        mapOpportunityRecord.put('StageName', 'Negotiating');
        mapOpportunityRecord.put('Contract_UUID__c', 'opp04-contract4-0004');
        mapOpportunityRecord.put('AccountId', lstAccounts[2].Id);
        mapOpportunityRecord.put('OwnerId', lstUsers[0].Id);
        mapOpportunityRecord.put('Building__c', lstBuildings[0].Id);

        lstOpportunities.add(TestingUtility.createOpportunity(mapOpportunityRecord, false));

        //Opportunity 4
        mapOpportunityRecord.put('StageName', 'Negotiating');
        mapOpportunityRecord.put('Contract_UUID__c', 'opp05-contract5-0005');
        mapOpportunityRecord.put('AccountId', lstAccounts[3].Id);
        mapOpportunityRecord.put('Type__c','PxWe');
        lstOpportunities.add(TestingUtility.createOpportunity(mapOpportunityRecord, false));

        //Opportunity 5 with Closed Lost
        mapOpportunityRecord.put('StageName', 'Closed Lost');
        mapOpportunityRecord.put('Contract_UUID__c', 'opp06-contract6-0006');
        lstOpportunities.add(TestingUtility.createOpportunity(mapOpportunityRecord, false));

        //Opportunity 6 with Qualifying
        mapOpportunityRecord.put('StageName', 'Qualifying');
        mapOpportunityRecord.put('Contract_UUID__c', 'opp07-contract7-0007');
        mapOpportunityRecord.put('Type__c','WeWork');
        mapOpportunityRecord.put('CloseDate', system.today().addDays(5));
        mapOpportunityRecord.put('RecordTypeId', OPPORTUNITY_NEW_BUSINESS_RECORD_TYPE_ID);
        mapOpportunityRecord.put('AccountId', lstAccounts[1].Id);
        mapOpportunityRecord.put('Tour_Notes__c', 'Opportunity Tour Notes');
        mapOpportunityRecord.put('Tour_Outcome_Notes__c', 'Tour Outcome Notes');
        mapOpportunityRecord.put('Description', 'Opprtunity Description');
        mapOpportunityRecord.put('Locations_Interested__c', lstBuildings[0]+';'+lstBuildings[1]);
        lstOpportunities.add(TestingUtility.createOpportunity(mapOpportunityRecord, false));
        //Inserting Opportunities
        TestingUtility.insertListWithAssert(lstOpportunities);
    }

    public static void createOppHandlerTestData(){

        Map<String, Object> mapData = new Map<String, Object>();
        Map<String, List<Object>> mapField = new Map<String, List<Object>>();
        Account accRec = TestingUtility.createAccount('strAccountName', true);

        List<Contact> lstContacts = new List<Contact>();
        lstContacts.add(TestingUtility.createContact(new Map<String, Object>{
            'FirstName' => 'testFirstName1',
            'LastName' => 'testContact1',
            'Email' => 'test0.contact0@example.com',
            'AccountId' => accRec.Id
        }, false));
        lstContacts.add(TestingUtility.createContact(new Map<String, Object>{
            'FirstName' => 'testFirstName2',
            'LastName' => 'testContact2', 
            'Email' => 'test1.contact1@example.com', 
            'AccountId' => accRec.Id
        }, false));
        lstContacts.add(TestingUtility.createContact(new Map<String, Object>{
            'FirstName' => 'testFirstName3', 
            'LastName' => 'testContact3', 
            'Email' => 'test2.contact2@example.com', 
            'AccountId' => accRec.Id
        }, false));
        TestingUtility.insertListWithAssert(lstContacts);

        List<Building__c> lstBuilding = new List<Building__c>();
        lstBuilding.add(TestingUtility.createBuilding(new Map<String, Object>{'Name' => 'Test1', 'uuid__c' => 'abc123'}, false));
        lstBuilding.add(TestingUtility.createBuilding(new Map<String, Object>{'Name' => 'Test2', 'uuid__c' => 'abc1234'}, false));
        TestingUtility.insertListWithAssert(lstBuilding);

        List<Opportunity> lstOpportunity = new List<Opportunity>();
        Map<String, Id> oppRecordType = TestingUtility.getRecordTypeMapByName(Opportunity.sObjectType);
        lstOpportunity.add(TestingUtility.createOpportunity(new Map<String, Object>{'Primary_Member__c' => lstContacts[0].Id, 'StageName' => 'Selling', 'CloseDate' => System.today().addDays(5), 'CurrencyIsoCode' => 'USD', 'RecordTypeId' => oppRecordType.get('New Business'), 'Description' => 'Opprtunity 1 Tour_Notes__c', 'Amount' => 10, 'Locations_Interested__c' => 'Test2;', 'Contract_UUID__c' => 'testPrimaryOpp1'}, false));
        lstOpportunity.add(TestingUtility.createOpportunity(new Map<String, Object>{'Primary_Member__c' => lstContacts[0].Id, 'StageName' => 'Selling', 'CloseDate' => System.today().addDays(5), 'CurrencyIsoCode' => 'USD', 'RecordTypeId' => oppRecordType.get('New Business'), 'Description' => 'Opprtunity 2 Tour_Notes__c', 'Amount' => 10, 'Locations_Interested__c' => 'Test1;Test2;', 'Contract_UUID__c' => 'testoppRec1'}, false));
        lstOpportunity.add(TestingUtility.createOpportunity(new Map<String, Object>{'Primary_Member__c' => lstContacts[0].Id, 'StageName' => 'Selling', 'CloseDate' => System.today().addDays(5), 'CurrencyIsoCode' => 'USD', 'RecordTypeId' => oppRecordType.get('New Business'), 'Description' => 'Opprtunity 3 Tour_Notes__c', 'Amount' => 10, 'Contract_UUID__c' => 'testoppRec2'}, false));
        lstOpportunity.add(TestingUtility.createOpportunity(new Map<String, Object>{'Primary_Member__c' => lstContacts[0].Id, 'StageName' => 'Selling', 'CloseDate' => system.today().addDays(5), 'CurrencyIsoCode' => 'AED', 'RecordTypeId' => oppRecordType.get('New Business'), 'Description' => 'Opprtunity 4 Tour_Notes__c', 'Amount' => 10, 'Contract_UUID__c' => 'testoppRec3'}, false));
        lstOpportunity.add(TestingUtility.createOpportunity(new Map<String, Object>{'Primary_Member__c' => lstContacts[1].Id, 'StageName' => 'Selling', 'CloseDate' => system.today().addDays(5), 'CurrencyIsoCode' => 'AED', 'RecordTypeId' => oppRecordType.get('New Business'), 'Description' => 'Opprtunity 5 Tour_Notes__c', 'Amount' => 10, 'Locations_Interested__c' => 'Test1;Test2;', 'Contract_UUID__c' => 'testoppRec4'}, false));
        TestingUtility.insertListWithAssert(lstOpportunity);

        mapData.put('objName', 'inventory');
        mapData.put('numberOfRecords', 3);
        List<Inventory__c > lstInventories = TestingUtility.getRecords(mapData);
        mapField.clear();
        mapField.put('Inventory__c', new List<Object>{lstInventories[0].Id, lstInventories[1].Id, lstInventories[2].Id});
        mapField.put('Opportunity__c', new List<Object>{lstOpportunity[3].Id, lstOpportunity[3].Id, lstOpportunity[3].Id});
        mapField.put('Monthly_Price__c', new List<Object>{0, 250, 100});
        mapField.put('Monthly_Payment_Method__c', new List<Object>{'Credit Card','Wire', 'ACH'});
        mapField.put('CurrencyIsoCode', new List<Object>{'AED', 'AED', 'USD'});

        List<Product2> lstProducts = TestingUtility.createAllWeWorkProducts(true);
        List<PricebookEntry> lstPricebookEntry = [SELECT Id, UnitPrice, CurrencyIsoCode FROM PricebookEntry WHERE CurrencyIsoCode = 'USD' LIMIT 2];

        List<OpportunityLineItem> lstOpportunityLineItem = new List<OpportunityLineItem>();
        lstOpportunityLineItem.add(TestingUtility.createOpportunityLineItem(new Map<String, Object>{'OpportunityId' => lstOpportunity[2].Id, 'Quantity' => 5, 'PricebookEntryId' => lstPricebookEntry[0].Id, 'TotalPrice' => 5 * lstPricebookEntry[0].UnitPrice}, false));
        lstOpportunityLineItem.add(TestingUtility.createOpportunityLineItem(new Map<String, Object>{'OpportunityId' => lstOpportunity[1].Id, 'Quantity' => 5, 'PricebookEntryId' => lstPricebookEntry[1].Id, 'TotalPrice' => 100}, false));
        TestingUtility.insertListWithAssert(lstOpportunityLineItem);

        List<OpportunityContactRole> lstOpportunityContactRoles = new List<OpportunityContactRole>();
        lstOpportunityContactRoles.add(new OpportunityContactRole(ContactId = lstContacts[0].Id, OpportunityId = lstOpportunity[0].Id, IsPrimary = TRUE, Role = 'Decision Maker'));
        lstOpportunityContactRoles.add(new OpportunityContactRole(ContactId = lstContacts[1].Id, OpportunityId = lstOpportunity[1].Id, IsPrimary = FALSE, Role = 'Economic Decision Maker'));
        lstOpportunityContactRoles.add(new OpportunityContactRole(ContactId = lstContacts[1].Id, OpportunityId = lstOpportunity[1].Id, IsPrimary = FALSE, Role = 'Economic Decision Maker'));
        TestingUtility.insertListWithAssert(lstOpportunityContactRoles);

        List<User> lstTestUser = [SELECT Id FROM User WHERE IsActive = TRUE AND Profile.Name = 'System Administrator' LIMIT 1];
        List<OpportunityTeamMember> lstNewTestOppteam = new List<OpportunityTeamMember>();
        lstNewTestOppteam.add(new OpportunityTeamMember(OpportunityId = lstOpportunity[1].Id, UserId = UserInfo.getUserId(), TeamMemberRole = 'Account Manager'));
        lstNewTestOppteam.add(new OpportunityTeamMember(OpportunityId = lstOpportunity[2].Id, UserId = lstTestUser[0].Id, TeamMemberRole = 'Lead Qualifire'));
        TestingUtility.insertListWithAssert(lstNewTestOppteam);

        ContentVersion objContentVersion = new ContentVersion(Origin = 'H', PathOnClient='myFile.txt', Title ='myFile', VersionData = Blob.valueOf('I am a file posting to Chatter'));
        TestingUtility.insertWithAssert(objContentVersion);
        FeedItem contentFI = new FeedItem(Type = 'ContentPost', ParentId = lstOpportunity[1].Id, RelatedRecordId = objContentVersion.Id, Title = 'Content Post', Body = 'Body of content post');
        TestingUtility.insertWithAssert(contentFI);
    }

    /*****************************************************************************************************************************
        Author         		: Krishana Tupe
        Description     	: This method will cretae a Map with key as provide keyvalue param and value as sobject record from the list e.g. Map<keyValue, sObject>.
        Created Date    	: 15 June 2020
    ******************************************************************************************************************************/
    public static void createMapOfValues(List<sObject> lstRecords, Map<String, sObject> mapRecords, String keyValue) {
        for(sObject objRecord : lstRecords) {
            mapRecords.put(String.valueOf(objRecord.get(keyValue)), objRecord);
        }
    }

    public class TestUtilException extends Exception {}
}