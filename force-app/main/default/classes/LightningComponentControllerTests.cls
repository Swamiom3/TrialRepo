/************************************************************************************************************************************
    Author      : Ajaysinh Chauhan
    Description : This class Contains Unit Tests methods of LightningComponentController
    History     :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              DETAIL
    1           -                   Ajaysinh Chauhan    Initial Developement
    2           28 November 2018    Rupesh Patil        Optimized and Changed to increase code coverage
    3           06 Feburary 2020    Vaishnavi Khandar   Optimized and Changed according to new Structure
    4           8 Dec, 2021         Pawel Biszczak      Add  test coverage for Billing Accounts' migration
**************************************************************************************************************************************/
@isTest
public class LightningComponentControllerTests {

    @TestSetup
    public static void testSetup(){
        TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Lead', 'numberOfRecords' => 1});
        List<Contact> contacts =
                    (List<Contact>) TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Contact',
                                                                                      'doInsert' => true,
                                                                                      'numberOfRecords' => 5});

        Test.startTest();
        TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Building__c',
                                                          'numberOfRecords' => 1});

        List<Account> lstAccounts = new List<Account>();
        lstAccounts.add(new Account(Name = 'TestAcc1',
                                    UUID__c = 'enterprize-0001-0001',
                                    Phone = '12345'));
        lstAccounts.add(new Account(Name = 'TestAcc2',
                                    UUID__c = 'enterprize-0002-0002',
                                    Phone = '12345'));
        TestingUtility.insertListWithAssert(lstAccounts);//getReferrenceDataTest

        List<Geography__c> lstGeography = new  List<Geography__c>();
        lstGeography.add(new Geography__c(Name = 'Baner ,Maharashtra',City__c = 'Pune',
                                          Country__c = 'India',
                                          District__c='Pune',
                                          Formatted_Address__c = 'Baner, Pune, Maharashtra, India',
                                          Geocode__Latitude__s = 18.5596581,
                                          Geocode__Longitude__s = 73.7799374,
                                          JSON__c = getFirstGeographyJSON(),
                                          Location_Type__c = 'APPROXIMATE',
                                          Place_ID__c = 'ChIJy9Nd8M--wjsRfat_-5cSkaE',
                                          State__c = 'Maharashtra' ));
        lstGeography.add(new Geography__c(Name='1460 Broadway, WeWork',
                                          City__c = 'New York',
                                          Country__c = 'United States',
                                          District__c = 'New York',
                                          Formatted_Address__c = '1460 Broadway, New York, United States',
                                          Geocode__Latitude__s = 45.5771387,
                                          Geocode__Longitude__s = 55.2079648,
                                          JSON__c = getSecondGeographyJSON(),
                                          Location_Type__c = 'APPROXIMATE',
                                          Place_ID__c = 'ChIJy9Nd8M--wjsRfat_-5cSkaG',
                                          State__c = 'New York',
                                          CurrencyIsoCode = 'USD'));
        TestingUtility.upsertListWithAssert(lstGeography);//verifySaveGoogleLocations

        TestingUtility.upsertWithAssert(new Lead(LastName = 'lastName',
                                                 Email = 'email@enazigma.com',
                                                 Phone = '1234567891',
                                                 Company = 'Test Company',
                                                 Locations_Interested__c = 'Test Building Tour',
                                                 LeadSource= 'Event',
                                                 Lead_Source_Detail__c = 'Broker' ));//verify convert lead to Existing
        //This Test start and Stop block consumes 90 SOQL
        Test.stopTest();
    }

    @isTest
    public static void LightningComponentControllerMethod(){
        Test.startTest();
        User objUser = [SELECT Id, Name FROM User WHERE Id=:UserInfo.getUserId()];
        Contact objContact = new Contact(FirstName = 'John',
                                         LastName = 'Rambo',
                                         Email = 'john@example.com');
        List<Contact> lstContactsInserted = [SELECT Id, Name, Email, AccountId FROM Contact WHERE Email = 'john1.Contact@example.com'];
        List<Opportunity> lstOpportunitiesInserted = [SELECT Id FROM Opportunity WHERE Primary_Member__r.Email = 'john1.Contact@example.com'];
        List<Account> lstAccountsInserted = [SELECT Id, Name, RecordTypeId, RecordType.Name FROM Account LIMIT 1];
        List<lead> lstLeadsInserted = [SELECT Id, Name, Email FROM Lead Limit 1];
        List<Geography__c> lstGeographiesInserted = [SELECT Name, City__c, State__c,Country__c, Formatted_Address__c, Geocode__Latitude__s, Geocode__Longitude__s, JSON__c, Location_Type__c, Place_ID__c FROM Geography__c LIMIT 2];
        List<String> lstObjectNames = new List<String>{'Account', 'Contact', 'Opportunity'};
        List<String> lstFields = new List<String>{'Name', 'Email'};
        List<String> lstRelationFields = new  List<String>{'Name:Account.Name','AccountNumber:Account.AccountNumber'};
        List<String> lstQueries = new List<String>{'SELECT Id, Name FROM Contact', 'SELECT Id FROM Account'};
        List<Building__c> lstBuildingsInserted = [SELECT Id, Name FROM Building__c LIMIT 1];
        verifyGetLayout(lstAccountsInserted[0], lstBuildingsInserted[0]);
        verifyGetPickListBasedOnRecordType(lstObjectNames[0],lstFields[0]);
        verifyGetQueryData(lstQueries[0]);
        verifyGetListQueryData(lstQueries);
        verifyGetLayoutForNewRecord(lstObjectNames[0]);
        verifySaveRecord(objContact,lstContactsInserted[0]);
        verifySaveRecords(objContact,lstAccountsInserted[0]);
        verifyGetFieldsMetadata(lstFields);
        verifyGetFieldMetadata();
        verifyGetAllFields();
        verifyGetExternalSystemEndPoints();
        verifyGetTableData(lstQueries[0]);
        verifyGetSobjectNameById(lstAccountsInserted[0]);
        verifyGetUserInfo(objUser);
        verifyDescribeTable(lstFields);
        verifGetRelationFieldsMetadata(lstRelationFields);
        verifygetTodaysDate();
        verifyGetUserProfileInfo();
        verifyAddBusinessDays();
        verifySaveGoogleLocations(lstGeographiesInserted);
        verifyGetRecordTypeInfosTest(lstObjectNames);
        verifyGetSalesConsoleSettingTest();
        verifyGetObjectFields(lstObjectNames[0]);
        verifyGetsObjectPrefix(lstObjectNames[0]);
        verifyTimezoneOffset();
        verifyGetTimezoneOffset();
        verifyGetSessionId();
        verifyGetUITheme();
        verifygetRecordTypeInfo(lstObjectNames[0]);
        verifygetAPISessionId();
        verifygetRESTCalloutData();
        verifyGetTableBody(lstLeadsInserted);
        verifyGetListQueryDataBySOSL();
        Test.stopTest();
    }

    @isTest
    public static void LightningComponentControllerMethod1(){
        Test.startTest();
        List<string> lstUserIdsInserted = new List<string>{'005F0000003KmbwIAC',UserInfo.getUserId()};
        List<ApexLog> lstApexLogIdsInserted = [SELECT Id FROM ApexLog limit 3];
        List<Lead> lstLeadIdsInserted = [SELECT Id FROM Lead LIMIT 1];

        List<Journey__c> lstJourneyIdsInserted = [SELECT Id FROM Journey__c LIMIT 1];

        List<Account> lstAccountIdsInserted = [SELECT Id FROM Account LIMIT 2] ;
        List<Account> lstAccountsInserted = [SELECT Id, Name, UUID__c FROM Account WHERE Phone = '12345'];
        List<RecordType> lstRecordTypesInserted = [SELECT Id, Name FROM RecordType WHERE SobjectType = 'Account'];
        List<Contact> lstContactsInserted = [SELECT Id, Name, Email, AccountId FROM Contact WHERE Email = 'john1.Contact@example.com'];
        List<Contact> contacts = [ SELECT Id, AccountId
                                   FROM Contact
                                   LIMIT 3 ];
        List<Account> accounts = [ SELECT Id
                                   FROM Account ];
        verifyGetLayoutWithMapping();

        verifyValidateLeadforWebService(lstLeadIdsInserted, lstJourneyIdsInserted);

        verifyExecuteRestQuery();
        verifyGetUserLogs(lstUserIdsInserted);
        verifydeleteLogs(lstApexLogIdsInserted);
        getBillingAccountMemberCountTest(contacts, accounts);

        verifyDescribeById(lstAccountIdsInserted);
        verifyGetAllRecordTypesById(lstAccountIdsInserted, lstRecordTypesInserted);
        getReferrenceDataTest(lstAccountsInserted);
        verifySendEmail();
        Test.stopTest();
    }

    @isTest
    public static void LightningComponentControllerMethod2(){
        List<Building__c> lstBuildings = [SELECT Id, UUID__c, Building_Price_Book_Id__c FROM Building__c LIMIT 1];
        verifyRevStarApiPrice(lstBuildings[0]);
    }

    @isTest
    public static void LightningComponentControllerMethod3(){
        List<Building__c> buildings = [SELECT Id, UUID__c FROM Building__c LIMIT 1];
        verifyRevStarApi(buildings[0]);
    }

    /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies getQueryData()
    **************************************************************************************************************************************/
    private static void verifyGetQueryData(String Query) {
        List<Contact> lstContacts = (List<Contact>)LightningComponentController.getQueryData(Query).data;
        System.assert(lstContacts.size() != 0);
        lstContacts = (List<Contact>)LightningComponentController.getQueryData('SELECT').data;//To verify whether the unexpected token exception caught by the method or not if incomplete or wrong query is passed
        System.assert(lstContacts == NULL);
        lstContacts = (List<Contact>)LightningComponentController.getQueryData(NULL).data;//To verify whether the NULL pointer exception caught by the method or not if null is passed
        System.assert(lstContacts == NULL);
        try{
            DatabaseResult nullResult = LightningComponentController.getQueryData(NULL);//To verify whether the NULL pointer exception caught by this method or not if wrong data is passed
        } catch(Exception exc){
            System.assertNotEquals(NULL, exc);
        }
    }

     /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies getListQueryData()
    **************************************************************************************************************************************/
    private static void verifyGetListQueryData(List<String> lstQueries) {
        List<List<sObject>> lstContacts = (List<List<sObject>>)LightningComponentController.getListQueryData(lstQueries).data;
        System.assert(lstContacts[0].size() != 0 && lstContacts[1].size() != 0);
        DatabaseResult result = LightningComponentController.getListQueryData(new List<String>{' '});//To verify whether the NULL pointer exception caught by the method or not if null is passed
        System.assertEquals(false, result.success);
        System.assertNotEquals(result.message, NULL);
        try{
            DatabaseResult nullResult = LightningComponentController.getListQueryData(NULL);//To verify whether the NULL pointer exception caught by this method or not if wrong data is passed
        } catch(Exception exc){
            System.assertNotEquals(NULL, exc);
        }
    }

     /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies saveRecord()
    **************************************************************************************************************************************/
    private static  void verifySaveRecord(Contact objContact, Contact objInsertedContact) {
        Database.SaveResult response = (Database.SaveResult)JSON.deserializeStrict((String)LightningComponentController.saveRecord(objContact).data,Database.SaveResult.class);
        System.assert(response.success);
        DatabaseResult result = LightningComponentController.saveRecord(NULL);//To verify whether the NULL pointer exception caught by the method or not if NULL is passed
        System.assertEquals(false, result.success);
        System.assertNotEquals(result.message, NULL);
        Database.SaveResult responseOfSavedContact = (Database.SaveResult)JSON.deserializeStrict((String)LightningComponentController.saveRecord(objInsertedContact).data,Database.SaveResult.class);
        System.assert(responseOfSavedContact.success);
        try{
            DatabaseResult nullResult = LightningComponentController.saveRecord(NULL);//To verify whether the NULL pointer exception caught by this method or not if wrong data is passed
        } catch(Exception exc){
            System.assertNotEquals(NULL, exc);
        }
    }

     /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies saveRecords()
    **************************************************************************************************************************************/
    private static void verifySaveRecords(Contact objContact, Account objInsertedAccount) {
        objInsertedAccount.Name = 'UpdatedAcccount';
        Map<String,List<Database.SaveResult>> response = (Map<String, List<Database.SaveResult>>)JSON.deserializeStrict((String)LightningComponentController.saveRecords(new List<sObject>{objContact, objInsertedAccount}).data,Map<String, List<Database.SaveResult>>.class);
        for(Database.SaveResult sr:response.get('insertedRecords')){
            System.assert(sr.success);
        }
        for(Database.SaveResult sr:response.get('updatedRecords')){
            System.assert(sr.success);
        }
        DatabaseResult result = LightningComponentController.saveRecords(NULL);//To verify whether the NULL pointer exception caught by the method or not if wrong data is passed
        System.assertEquals(false, result.success);
        System.assertNotEquals(result.message, NULL);
        try{
            DatabaseResult nullResult = LightningComponentController.saveRecords(NULL);//To verify whether the NULL pointer exception caught by this method or not if wrong data is passed
        } catch(Exception exc){
            System.assertNotEquals(NULL, exc);
        }
    }

    /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies deleteRecord()
    **************************************************************************************************************************************/
    private static void verifyDeleteRecord(Contact objInsertedContact, Journey__c objInsertedJourney, Opportunity objInsertedOpportunity) {
        DatabaseResult resOppo = LightningComponentController.deleteRecord(objInsertedOpportunity.Id);
        System.assert(resOppo.success);
        DatabaseResult resJourney = LightningComponentController.deleteRecord(objInsertedJourney.Id);
        System.assert(resJourney.success);
        DatabaseResult resContact = LightningComponentController.deleteRecord(objInsertedContact.Id);
        System.assert(resContact.success);
        DatabaseResult result = LightningComponentController.deleteRecord('Exception'); //To verify whether the invalid Id exception caught by the method or not if wrong data is passed
        System.assertEquals(false, result.success);
        System.assertNotEquals(NULL,result.message);
        try{
            DatabaseResult nullResult = LightningComponentController.deleteRecord(NULL);//To verify whether the NULL pointer exception caught by this method or not if wrong data is passed
        } catch(Exception exc){
            System.assertNotEquals(NULL, exc);
        }
    }

     /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies deleteRecords()
    **************************************************************************************************************************************/
    private static void verifyDeleteRecords(Contact objInsertedContact, Journey__c objInsertedJourney, Opportunity objInsertedOpportunity) {
        List<String> recordsToDelete = new List<String>{objInsertedJourney.Id, objInsertedOpportunity.Id, objInsertedContact.AccountId, objInsertedContact.Id};
        DatabaseResult response = LightningComponentController.deleteRecords(recordsToDelete);
        String validationMessage='You can not delete Accounts having child Accounts, Contacts or Opportunities except while merging.';
        System.assertEquals(validationMessage.toLowerCase(), response.message.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,')[1].split(':')[0].trim().toLowerCase(), 'Account is deleted having related contacts ');
        DatabaseResult result = LightningComponentController.deleteRecords(NULL);//To verify whether the NULL pointer exception caught by the method or not if wrong data is passed
        System.assertEquals(false, result.success);
        try{
            DatabaseResult nullResult = LightningComponentController.deleteRecords(NULL);//To verify whether the NULL pointer exception caught by this method or not if wrong data is passed
        } catch(Exception exc){
            System.assertNotEquals(NULL, exc);
        }
    }

     /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies getFieldsMetadata()
    **************************************************************************************************************************************/
    private static void verifyGetFieldsMetadata(List<String> lstFields) {
            String metadata = (String)LightningComponentController.getFieldsMetadata('Contact', lstFields).data;
        System.assertNotEquals(NULL, metadata);
        DatabaseResult result = LightningComponentController.getFieldsMetadata('Exception', new List<String>{'exception'}); //To verify whether the null pointer exception caught by this method or not if wrong data is passed
        System.assertEquals(false, result.success);
        System.assertNotEquals(NULL, result.message);
    }

    /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies getFieldMetadata()
    **************************************************************************************************************************************/
    private static void verifyGetFieldMetadata() {
        String metadata = (String)LightningComponentController.getFieldMetadata('Contact', 'Name').data;
        System.assertNotEquals(NULL, metadata);
        DatabaseResult result = LightningComponentController.getFieldMetadata('Contact', 'Exception');//To verify whether the null pointer exception caught by this method or not if wrong data is passed
        System.assertEquals(false, result.success);
        System.assertNotEquals(NULL, result.message);
    }

     /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies getAllFields()
    **************************************************************************************************************************************/
    private static void verifyGetAllFields() {
        String allfields = (String)LightningComponentController.getAllFields('Contact').data;
        System.assertNotEquals(NULL, allfields);
        DatabaseResult result = LightningComponentController.getAllFields('Exception');//To verify whether the null pointer exception caught by this method or not if wrong data is passed
        System.assertEquals(false, result.success);
        System.assertNotEquals(NULL, result.message);
        try{
            DatabaseResult nullResult = LightningComponentController.getAllFields(NULL);//To verify whether the null pointer exception caught by this method or not if wrong data is passed
        }catch(Exception exc){
            System.assertNotEquals(NULL, exc);
        }
    }

    /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies getTableData()
    **************************************************************************************************************************************/
    private static void verifyGetTableData(String Query) {
        Map<string,Object> tabledata = (Map<string,Object>)LightningComponentController.getTableData(Query).data;
        DatabaseResult result = LightningComponentController.getTableData(' ');//To verify whether the null pointer exception caught by this method or not if null data is passed
        System.assertEquals(false, result.success);
        System.assertNotEquals(NULL, result.message);
        try{
            DatabaseResult nullResult = LightningComponentController.getTableData(NULL);//To verify whether the null pointer exception caught by this method or not if wrong data is passed
        }catch(Exception exc){
            System.assertNotEquals(NULL, exc);
        }
    }

    /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies getLayout()
    **************************************************************************************************************************************/
    private static void verifyGetLayout(Account objInsertedAccount, Building__c  objInsertedBuilding) {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorForLightning());
        Object obj = LightningComponentController.getLayout(objInsertedAccount.Id);
        DatabaseResult wrongResult =  LightningComponentController.getLayout(objInsertedBuilding.Id);
        System.assertNotEquals(NULL, JSON.serialize(obj));
        System.assert(wrongResult.success);
        DatabaseResult nullResult =  LightningComponentController.getLayout(NULL);//To verify whether the null pointer exception caught by this method or not if null data is passed
        System.assert(!nullResult.success);
    }

     /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies getLayoutWithMapping()
    **************************************************************************************************************************************/
    private static void verifyGetLayoutWithMapping(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorForLightning());
        DatabaseResult objAccount = LightningComponentController.getLayoutWithMapping('Account');
        DatabaseResult objSetting = LightningComponentController.getLayoutWithMapping('Sales_Console_Setting__mdt');
        System.assert(objAccount.success);
        System.assert(objSetting.success);
        try{
            DatabaseResult nullResult = LightningComponentController.getLayoutWithMapping(NULL);//To verify whether the null pointer exception caught by this method or not if wrong data is passed
        } catch(Exception exc){
            System.assertNotEquals(NULL, exc);
        }
    }

     /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies describeById()
    **************************************************************************************************************************************/
    private static void verifyDescribeById(List<Account> lstInsertedAccountIds){
        DatabaseResult result = LightningComponentController.describeById(new List<Id>{lstInsertedAccountIds[0].Id, lstInsertedAccountIds[1].Id});
        System.assert(result.success);
        DatabaseResult wrongResult = LightningComponentController.describeById(new List<Id>{'906F0000000DDd6IAG'});
        System.assertEquals(false, wrongResult.success);
        System.assertNotEquals(NULL, wrongResult.message);
        try{
            DatabaseResult nullResult = LightningComponentController.describeById(NULL);//To verify whether the null pointer exception caught by this method or not if wrong data is passed
        } catch(Exception exc){
            System.assertNotEquals(NULL, exc);
        }
    }

    /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies getSobjectNameById()
    **************************************************************************************************************************************/
    private static void verifyGetSobjectNameById(Account objInsertedAccount){
        String objName = (String)LightningComponentController.getSobjectNameById(objInsertedAccount.Id).data;
        system.assertEquals('Account', objName);
        DatabaseResult result = LightningComponentController.getSobjectNameById('906F0000000DDd6IAG');
        System.assertEquals(false, result.success);
        System.assertNotEquals(result.message, NULL);
        try{
            result = LightningComponentController.getSobjectNameById(NULL);//To verify whether the null pointer exception caught by this method or not if wrong data is passed
        } catch(Exception exc){
            System.assertNotEquals(NULL, exc);
        }
    }

     /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies getAllRecordTypesById()
    **************************************************************************************************************************************/
    private static void verifyGetAllRecordTypesById(List<Account> lstInsertedAccountIds, List<RecordType> lstRecordType1){
        List<RecordType> lstRecordType = (List<RecordType>)LightningComponentController.getAllRecordTypesById(lstInsertedAccountIds[0].Id).data;
        boolean isEquals = lstRecordType.equals(lstRecordType1);
        System.assertEquals(true, isEquals);
        DatabaseResult result = LightningComponentController.getAllRecordTypesById('906F0000000DDd6IAG');//To verify whether the invalid id exception caught by this method or not if wrong id is passed
        System.assertEquals(false, result.success);
        System.assertNotEquals(result.message, NULL);
        try{
            DatabaseResult nullResult = LightningComponentController.getAllRecordTypesById(NULL);//To verify whether the null pointer exception caught by this method or not if wrong data is passed
        } catch(Exception exc){
            System.assertNotEquals(NULL, exc);
        }
    }

    /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies getUserInfo()
    **************************************************************************************************************************************/
    private static void verifyGetUserInfo(User objUser){
        DatabaseResult result = LightningComponentController.getUserInfo();
        System.assert(result.success);
    }

     /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies describeTable()
    **************************************************************************************************************************************/
    private static void verifyDescribeTable(List<String> lstFields){
        DatabaseResult result = LightningComponentController.describeTable('Contact',lstFields);
        System.assert(result.success);
        DatabaseResult nullResult = LightningComponentController.describeTable(NULL,new List<String>{''});//To verify whether the null pointer exception caught by this method or not if wrong data is passed
        System.assert(!nullResult.success);
    }

     /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies getRelationFieldsMetadata()
    **************************************************************************************************************************************/
    private static void verifGetRelationFieldsMetadata (List<String> lstRelationFields){
        LightningComponentController.getRelationFieldsMetadata(lstRelationFields);
        DatabaseResult result = LightningComponentController.getRelationFieldsMetadata(new List<String>{'Exception'});//To verify with wrong data
        System.assertEquals(false,result.success);
        System.assertNotEquals(result.message,NULL);
        try{
            DatabaseResult nullResult = LightningComponentController.getRelationFieldsMetadata(NULL);//To verify whether the null pointer exception caught by this method or not if wrong data is passed
        } catch(Exception exc){
            System.assertNotEquals(NULL, exc);
        }
    }

     /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies getTodaysDate()
    **************************************************************************************************************************************/
    private static void verifygetTodaysDate(){
        Date objDate = (Date)LightningComponentController.getTodaysDate().data;
        System.assertEquals(System.today(), objDate);
    }
    /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies getUserProfileInfo()
    **************************************************************************************************************************************/
    private static void verifyGetUserProfileInfo(){
        String UserInfo = (String)LightningComponentController.getUserProfileInfo().data;
        System.assert(UserInfo != NULL);
    }

    /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies addBusinessDays()
    **************************************************************************************************************************************/
    private static void verifyAddBusinessDays(){
        Date businessDate = (Date)LightningComponentController.addBusinessDays(2017, 09, 15, 2).data;
        System.assertEquals(Date.newInstance(2017, 09, 19), businessDate);
        try{
            businessDate = (Date)LightningComponentController.addBusinessDays(NULL, NULL, NULL, NULL).data;
        } catch(Exception exc){
            System.assertNotEquals(NULL, exc);
        }
    }

    /************************************************************************************************************************************
        Author              : Priyanka Ambre
        Description         : This method  tests SaveGoogleLocations .
        Created Date        : 27 November 2017
        Issue No.           : ST-1640
    **************************************************************************************************************************************/
    private static  void verifySaveGoogleLocations(List<Geography__c> lstInsertedGeography){
        Id geoId = (Id)LightningComponentController.upsertGeolocation(lstInsertedGeography[0]).data;
        System.assertNotEquals(NULL, geoId);
        lstInsertedGeography[1].Place_ID__c = 'ChIJy9Nd8M--wjsRfat_-5cSkaE';
        Id newGeoId = (Id)LightningComponentController.upsertGeolocation(lstInsertedGeography[1]).data;
        System.assertNotEquals(NULL, newGeoId);
        System.assertEquals(geoId, newGeoId);
        try{
            newGeoId = (Id)LightningComponentController.upsertGeolocation(NULL).data;
        } catch(Exception exc){
            System.assertNotEquals(NULL, exc);
        }
    }

     /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies getRecordTypeInfos()
    **************************************************************************************************************************************/
    private static void verifyGetRecordTypeInfosTest(List<String> lstObjectNames){
        Map<String, Map<String, Id>> result = (Map<String, Map<String, Id>>)LightningComponentController.getRecordTypeInfos(lstObjectNames).data;
        System.assertNotEquals(NULL, result);
        Id billingAccountRecordTypeIdofAcc = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();
        System.assertEquals(billingAccountRecordTypeIdofAcc, result.get('Account').get('Billing Account'));
        Id contactRecordTypeOfContact = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Contact').getRecordTypeId();
        System.assertEquals(contactRecordTypeOfContact, result.get('Contact').get('Contact'));
        Id newBusinessRecordTypeOfOppo = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('New Business').getRecordTypeId();
        System.assertEquals(newBusinessRecordTypeOfOppo, result.get('Opportunity').get('New Business'));
        try{
            result = (Map<String, Map<String, Id>>)LightningComponentController.getRecordTypeInfos(NULL).data;//To verify null pointer exception
        } catch(Exception exc){
            System.assertNotEquals(NULL, exc);
        }
    }

     /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies getSalesConsoleSetting()
    **************************************************************************************************************************************/
    private static void verifyGetSalesConsoleSettingTest(){
        try{
            String result = (String)LightningComponentController.getSalesConsoleSetting(NULL).data;//To verify with null data
        } catch(Exception exc){
            System.assertNotEquals(NULL, exc);
        }
    }

     /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies getObjectFields()
    **************************************************************************************************************************************/
    private static void verifyGetObjectFields(String ObjectName){
        DatabaseResult objFieldsForAccount =  LightningComponentController.getObjectFields(ObjectName);
        System.assertNotEquals(NULL, objFieldsForAccount);
        DatabaseResult objFieldsForException =  LightningComponentController.getObjectFields(ObjectName+'s');
        System.assertNotEquals(NULL, objFieldsForException);
        try{
            objFieldsForException = LightningComponentController.getObjectFields(NULL);//To verify with null data
        } catch(Exception exc){
            System.assertNotEquals(NULL, exc);
        }
    }

    /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies getsObjectPrefix()
    **************************************************************************************************************************************/
    private static void verifyGetsObjectPrefix(String ObjectName){
        DatabaseResult sObjectPrefix =  LightningComponentController.getsObjectPrefix(ObjectName);
        System.assertNotEquals(NULL, sObjectPrefix);
        System.assertEquals('001', (String)sObjectPrefix.data);
        sObjectPrefix =  LightningComponentController.getsObjectPrefix('exception');
        System.assertEquals(false, sObjectPrefix.success);
        System.assertNotEquals(NULL, sObjectPrefix.message);
        try{
            sObjectPrefix = LightningComponentController.getsObjectPrefix(NULL);//to verify the exception with null data
            System.assertEquals(false, sObjectPrefix.success);
        } catch(Exception exc){
            System.assertNotEquals(NULL, exc);
        }
    }

     /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies getTimezoneOffset()
    **************************************************************************************************************************************/
    private static void verifyTimezoneOffset(){
        DatabaseResult timeZoneOffset =  LightningComponentController.getTimezoneOffset();
        System.assertNotEquals(NULL, timeZoneOffset);
    }

     /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies getTimezoneOffset()
    **************************************************************************************************************************************/
    private static void verifyGetTimezoneOffset() {
        TimeZone tz1 = UserInfo.getTimeZone();
        Integer offset = tz1.getOffset(DateTime.newInstance(2019,05,06));
        DatabaseResult result = LightningComponentController.getTimezoneOffset();
        System.assertEquals(offset, Integer.valueOf(result.data));
    }

     /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies getSessionId()
    **************************************************************************************************************************************/
    private static void verifyGetSessionId() {
        DatabaseResult result = LightningComponentController.getSessionId();
        System.assert(result.success);
        //System.assertEquals(UserInfo.getSessionId(), (String)result.data);
    }

     /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies getUITheme()
    **************************************************************************************************************************************/
    private static void  verifyGetUITheme() {
        DatabaseResult result = LightningComponentController.getUITheme();
        System.assertEquals(UserInfo.getUiTheme(), String.valueOf(result.data));
    }

    private static void getBillingAccountMemberCountTest(List<Contact> contacts, List<Account> billingAccounts){
        for(Contact contactRecord : contacts){
            contactRecord.AccountId = billingAccounts[0].Id;
        }
        TestingUtility.updateListWithAssert(contacts);
        Map<Id, Integer> billingAccountIdsToMemberCountMap = LightningComponentController.getBillingAccountMemberCount(billingAccounts);
        Account accountRecord = [ SELECT Id, (SELECT Id FROM Contacts)
                                  FROM Account
                                  WHERE Id =:billingAccounts[0].Id
                                  LIMIT 1 ];
        System.assertEquals(accountRecord.Contacts.size(),
                billingAccountIdsToMemberCountMap.get(accountRecord.Id),
                'Incorrect Billing Account Contacts__r count returned');
    }

    private static void  verifygetRecordTypeInfo(String ObjectName) {
        DatabaseResult result = LightningComponentController.getRecordTypeInfo(ObjectName);
        Map<Id,String> mapOfRecordTypes = (Map<Id,String>)result.data;
        Integer size = Schema.getGlobalDescribe().get(ObjectName).getDescribe().getRecordTypeInfosByName().values().size();
        System.assertEquals(size, mapOfRecordTypes.size());
        result = LightningComponentController.getRecordTypeInfo('exception');
        System.assertEquals(false,result.success);
        System.assertNotEquals(result.message,NULL);
        try{
            result  = LightningComponentController.getRecordTypeInfo(NULL);//to verify with null data
        } catch(Exception exc){
            System.assertNotEquals(NULL, exc);
        }
    }

     /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies executeRestQuery()
    **************************************************************************************************************************************/
    private static void  verifyExecuteRestQuery() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorForLightning());
        DatabaseResult result = LightningComponentController.executeRestQuery(false, 'GET','http://example.com/example/test', new Map<String,String>{'Authorization'=>'Standard'},'');
        DatabaseResult result1 = LightningComponentController.executeRestQuery(true, 'GET','http://example1.com/example/test', new Map<String,String>{'Authorization'=>'Standard'},'');
        DatabaseResult result2 = LightningComponentController.executeRestQuery(true, 'POST','http://example2.com/example/test', new Map<String,String>{'Authorization'=>'Standard','Content-type'=>'Data'},'');
        System.assertEquals(true, result.success);
        System.assertEquals(true, result1.success);
        System.assertEquals(true, result2.success);
        System.assertEquals('{"foo":"bar"}', String.valueOf(result.data));
        try{
            result  = LightningComponentController.executeRestQuery(NULL, 'GET','http://example.com/example/test', new Map<String,String>{'Authorization'=>'Standard'},'');//to verify the exception generated with NULL and wrong data
        } catch(Exception exc){
            System.assertNotEquals(NULL, exc);
        }
    }

    /************************************************************************************************************************************
    Author         : Samadhan Kadam
    Description     : This method is used in apex log component to fetch debug logs.
    Created Date    : 05 May 2018
    Modified By     : Rupesh Patil
    Modified Date   : 28 Nov 2018
    **************************************************************************************************************************************/
    private static void verifyGetUserLogs(List<string> lstInsertedUserId) {
        string startTime = '11:00';
        string startDate = '2017-05-21';
        string endTime = '11:00';
        string endDate = '2022-05-31';
        List<string> lstOperations = new List<string>();
        string size = '2';
        string searchTerm = 'foo';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorForLightning());
        DatabaseResult result = LightningComponentController.getUserLogs(lstInsertedUserId,startDate,endDate,size,searchTerm,lstOperations,startTime,endTime);
        System.assert(result.success);
        DatabaseResult result1 = LightningComponentController.getUserLogs(NULL,startDate,endDate,size,'test exception',lstOperations,startTime,endTime);
        System.assertNotEquals(true, result1.success);
    }

    /************************************************************************************************************************************
    Author         : Samadhan Kadam
    Description     : This method is used in apex log component to delete debug logs.
    Created Date    : 05 May 2018
    Modified By     : Rupesh Patil
    Modified Date   : 28 Nov 2018
    **************************************************************************************************************************************/
    private static void  verifydeleteLogs(List<ApexLog> lstInsertedApexLog) {
        List<String> lstApexLogId = new List<string>();
        for(ApexLog objApexLog : lstInsertedApexLog ){
            lstApexLogId.add(objApexLog .Id);
        }
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorForLightning());
        DatabaseResult result = LightningComponentController.deleteLogs(lstApexLogId);
        System.assert(result.success);
        try{
            DatabaseResult nullResult = LightningComponentController.deleteLogs(NULL);//To verify whether the NULL pointer exception caught by this method or not if wrong data is passed
        } catch(Exception exc){
            System.assertNotEquals(NULL, exc);
        }
    }

     /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies getDateAccordingToLoginUserTimeZone()
    **************************************************************************************************************************************/
    private static void verifygetAPISessionId(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorForLightning());
        DatabaseResult dbresult = LightningComponentController.getAPISessionId();
        System.assert(dbresult != NULL);
    }

     /************************************************************************************************************************************
        Modified By     : Rupesh Patil
        Modified Date   : 28 Nov 2018
        Description     : This method verifies getDateAccordingToLoginUserTimeZone()
    **************************************************************************************************************************************/
    private static void verifygetRESTCalloutData(){
        DatabaseResult objdbresult = LightningComponentController.getRESTCalloutData();
        System.assert(objdbresult.success);
    }

    /************************************************************************************************************************************
        Author : Ashish Mishra
        Description : This method cover the getTableBody() function.
        Created Date    : 19 June 2018
    **************************************************************************************************************************************/
    private static void verifyGetTableBody(List<lead> lstInsertedLeads){
        Map<String, List<sObject>> mapSobjectRecords = new Map<string, List<sObject>>();
        Set<String> setTblFields = new Set<String>{'Name', 'Email'};
        mapSobjectRecords.put('Existing Leads', lstInsertedLeads);
        String body = LightningComponentController.getTableBody(setTblFields, mapSobjectRecords);
        System.assert(body != NULL);
    }

    /************************************************************************************************************************************
        Author          : Jitesh Adwani
        Description     : This method verifies the getListQueryDataBySOSL()
        Created Date    : 27 July 2018
        Last Modified By: Rupesh Patil
        Last Modified Date : 28 Nov 2018
  **************************************************************************************************************************************/
    private static void verifyGetListQueryDataBySOSL(){
        List<String> lstQuery = new List<String>();
        String query = 'FIND {A} IN Name FIELDS RETURNING Account(Name) LIMIT 1';
        lstQuery.add(query);
        DatabaseResult result = LightningComponentController.getListQueryDataBySOSL(lstQuery);
        System.assertEquals(true, result.success);
        DatabaseResult result1 = LightningComponentController.getListQueryDataBySOSL(NULL);
        System.assert(!result1.success);
        try{
            DatabaseResult nullResult = LightningComponentController.getListQueryDataBySOSL(NULL);//To verify whether the NULL pointer exception caught by this method or not if wrong data is passed
        } catch(Exception exc){
            System.assertNotEquals(NULL, exc);
    }
    }

    /************************************************************************************************************************************
        Author          : Ashish Mishra
        Description     : This method verifies the verifySendPaperworkOpportunity()
        Created Date    : 23 Oct 2018
        Modified By     : Rupesh Patil
        Modified Date   : 29 Nov 2018
   **************************************************************************************************************************************/
    private static void verifyGetLayoutForNewRecord(String sobjectName){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorForLightning());
        DatabaseResult layout = LightningComponentController.getLayoutForNewRecord(sobjectName);
        System.assert(layout.success);
        layout = LightningComponentController.getLayoutForNewRecord(NULL);//To verify with NULL data
        System.assert(!layout.success);
        try{
            DatabaseResult nullResult = LightningComponentController.getLayoutForNewRecord(NULL);//To verify whether the NULL pointer exception caught by this method or not if wrong data is passed
        } catch(Exception exc){
            System.assertNotEquals(NULL, exc);
        }
    }

    /************************************************************************************************************************************
        Author          : Rupesh Patil
        Description     : This method verifies the validateLeadforWebService() and validateLead()
        Created Date    : 15 Nov 2018
    **************************************************************************************************************************************/
    private static void verifyValidateLeadforWebService(List<Lead> lstInsertedLeads, List<Journey__c> lstInsertedJourneys){
        LightningComponentController.WebServiceWrapper objWrapper = LightningComponentController.validateLeadforWebService(lstInsertedLeads[0].Id);
        System.assert(objWrapper.success);
        objWrapper = LightningComponentController.validateLeadforWebService(lstInsertedJourneys[0].Id);
        System.assert(objWrapper.success);
        objWrapper = LightningComponentController.validateLeadforWebService(NULL);//To verify exception with NULL id
        System.assert(!objWrapper.success);
    }

/************************************************************************************************************************************
        Author          : Rohit Nimase
    Description     : This method verifies the getExternalSystemEndPoints()
        Created Date    : 7 Feb 2019
        Issue No.       : STL-127
**********************************************************************************************************************************/
    private static void verifyGetExternalSystemEndPoints(){
        Set<String> setTourEndpoint = new set<String>();
        for(Integration_Data__mdt tourEndpoint : [SELECT Label FROM Integration_Data__mdt]){
            setTourEndpoint.add(tourEndpoint.Label);
        }
        Map<String, Integration_Data__mdt> allTourAPIs = LightningComponentController.getExternalSystemEndPoints(setTourEndpoint);
        System.assertNotEquals(NULL, allTourAPIs.get('tourbuildingavailabilitiesapi'));
    }

    /************************************************************************************************************************************
        Author        : Nikhil Mehta
        Description   : This method covers the getReferrenceData method in lightning component
        Created Date  : 24 Jan 2019
    **************************************************************************************************************************************/
    private static void getReferrenceDataTest(List<Account> lstAccountsToInsert){
        Map<String,Object> mapAccountFieldValues = new Map<String,Object>();
        DatabaseResult result = LightningComponentController.getReferenceData('TestAcc', new List<String>{'Account'}, 'Account_Type__c', NULL, '', '', 10);
        List<Account> lstAccounts = (List<Account>) result.data;
        System.assertEquals(lstAccountsToInsert.size(), lstAccounts.size());

        result = LightningComponentController.getReferenceData('TestAcc', new List<String>{'Account'}, 'Account_Type__c', new List<String>{'Name'}, 'UUID__c = \'enterprize-0001-0001\'', '', 10);
        lstAccounts = (List<Account>) result.data;
        System.assertEquals(lstAccountsToInsert[0].Id, lstAccounts[0].Id);

        result = LightningComponentController.getReferenceData('', new List<String>{'Account'}, 'Account_Type__c', NULL, '', lstAccountsToInsert[1].Id, NULL);
        lstAccounts = (List<Account>) result.data;
        System.assertEquals(lstAccountsToInsert[1].Id, lstAccounts[0].Id);
    }

/************************************************************************************************************************************
    Author        : Vaishnavi Khandar
    Description   : This method covers the getPickListBasedOnRecordType method in lightning component
    Created Date  : 06 Feb 2020
 **************************************************************************************************************************************/
    private static void  verifyGetPickListBasedOnRecordType(String ObjAccount, String fieldName){
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorForLightning());
        DatabaseResult result = LightningComponentController.getPickListBasedOnRecordType(ObjAccount, recordTypeId, fieldName);//To verify whether the NULL pointer exception caught by the method or not if wrong data is passed
        System.assertEquals(true, result.success);
    }

/************************************************************************************************************************************
        Author        : Vaishnavi Khandar
        Description   : This method covers the sendEmail method in lightning component
        Created Date  : 06 Feb 2020
**************************************************************************************************************************************/
    private static void verifySendEmail(){
        string header = 'Hello\n';
        string finalstr = header ;
        string recordString = '12345678, String ,krishana,test data,None\n';
        finalstr = finalstr +recordString;
        String result = (String)LightningComponentController.SendMail(finalstr).data;
        system.assertEquals('done', result);
        try{
            result = (String)LightningComponentController.SendMail(null).data;
        } catch(Exception exc){
            System.assertNotEquals(null, exc);
        }
    }

    /****************************************************************************************************************************
        Author              : Roshan Kankrayane
        Description         : This method covers the revStarPrice method in lightning component.
        Created Date        : 30,May 2020
    *****************************************************************************************************************************/
    private static void  verifyRevStarApiPrice(Building__c building) {
        Test.startTest();
        building.building_price_book_id__c = Test.getStandardPricebookId();
        update building;
        List<Account> accounts = [SELECT Id,Name FROM Account WHERE UUID__c = 'enterprize-0001-0001'];
        List<Opportunity> opportunities = UtilOpportunity.GetNewOpportunity(1, accounts.get(0), false);
        opportunities.get(0).Building__c = building?.Id;
        opportunities.get(0).Interested_in_Number_of_Desks__c = 2;
        opportunities.get(0).Type__c = 'All Access';
        opportunities.get(0).Pricebook2Id = Test.getStandardPricebookId();
        opportunities.get(0).LeadSource = null;
        insert opportunities;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        opportunities = [SELECT Id,Name,Sales_Price__c, CurrencyIsoCode, Type__c FROM Opportunity
                          WHERE AccountId =: accounts.get(0).Id];
        DatabaseResult result = LightningComponentController.getRevStarAPIPrice(building.Id, 10, opportunities.get(0));
        System.assertEquals('{"BuildingName":"testBuilding1","Currency":"USD","Success":true,"RevStar_Price":0}',
                            JSON.serialize(result.data), 'Response is returned incorrectly');
        Test.stopTest();
        //Assert we got a valid response from the mock and the functions returns success.
        system.assertEquals(result.success, true);
    }

    /****************************************************************************************************************************
        Author              : Salesforce
        Description         : This method covers the revStarPrice method in lightning component.
        Created Date        : 11 Jan 2022
    *****************************************************************************************************************************/
    private static void  verifyRevStarApi(Building__c building) {
        Test.startTest();
        building.building_price_book_id__c = Test.getStandardPricebookId();
        update building;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponeGeneratorForRevstarAPI());
        DatabaseResult result = LightningComponentController.getRevStarAPIPrice(building.Id, 10, null);
        System.assertEquals('{"BuildingName":"testBuilding1","Success":false}',
                            JSON.serialize(result.data), 'Response is returned incorrectly');
        Test.stopTest();
        System.assertEquals(result.success, true);
    }

    private static String getFirstGeographyJSON() {
        return  '{\n' +
                '   "address_components":[\n' +
                '      {\n' +
                '         "long_name":"Baner",\n' +
                '         "short_name":"Baner",\n' +
                '         "types":[\n' +
                '            "locality",\n' +
                '            "political"\n' +
                '         ]\n' +
                '      },\n' +
                '      {\n' +
                '         "long_name":"Pune",\n' +
                '         "short_name":"Pune",\n' +
                '         "types":[\n' +
                '            "administrative_area_level_2",\n' +
                '            "political"\n' +
                '         ]\n' +
                '      },\n' +
                '      {\n' +
                '         "long_name":"Maharashtra",\n' +
                '         "short_name":"MH",\n' +
                '         "types":[\n' +
                '            "administrative_area_level_1",\n' +
                '            "political"\n' +
                '         ]\n' +
                '      },\n' +
                '      {\n' +
                '         "long_name":"India",\n' +
                '         "short_name":"IN",\n' +
                '         "types":[\n' +
                '            "country",\n' +
                '            "political"\n' +
                '         ]\n' +
                '      },\n' +
                '      {\n' +
                '         "long_name":"422605",\n' +
                '         "short_name":"422605",\n' +
                '         "types":[\n' +
                '            "postal_code"\n' +
                '         ]\n' +
                '      }\n' +
                '   ],\n' +
                '   "formatted_address":"Sangamner, Maharashtra 422605, India",\n' +
                '   "geometry":{\n' +
                '      "bounds":{\n' +
                '         "northeast":{\n' +
                '            "lat":19.5954532,\n' +
                '            "lng":74.2273235\n' +
                '         },\n' +
                '         "southwest":{\n' +
                '            "lat":19.5567976,\n' +
                '            "lng":74.1888714\n' +
                '         }\n' +
                '      },\n' +
                '      "location":{\n' +
                '         "lat":19.5771387,\n' +
                '         "lng":74.2079648\n' +
                '      },\n' +
                '      "location_type":"APPROXIMATE",\n' +
                '      "viewport":{\n' +
                '         "northeast":{\n' +
                '            "lat":19.5954532,\n' +
                '            "lng":74.2273235\n' +
                '         },\n' +
                '         "southwest":{\n' +
                '            "lat":19.5567976,\n' +
                '            "lng":74.1888714\n' +
                '         }\n' +
                '      }\n' +
                '   },\n' +
                '   "partial_match":true,\n' +
                '   "place_id":"ChIJeavrqdAB3TsRiL6oagFS3UY",\n' +
                '   "types":[\n' +
                '      "locality",\n' +
                '      "political"\n' +
                '   ]\n' +
                '}';
    }

    private static String getSecondGeographyJSON() {
        return  '{\n' +
                '   "address_components":[\n' +
                '      {\n' +
                '         "long_name":"New York",\n' +
                '         "short_name":"NY",\n' +
                '         "types":[\n' +
                '            "locality",\n' +
                '            "political"\n' +
                '         ]\n' +
                '      },\n' +
                '      {\n' +
                '         "long_name":"New York",\n' +
                '         "short_name":"NY",\n' +
                '         "types":[\n' +
                '            "administrative_area_level_2",\n' +
                '            "political"\n' +
                '         ]\n' +
                '      },\n' +
                '      {\n' +
                '         "long_name":"New York",\n' +
                '         "short_name":"NY",\n' +
                '         "types":[\n' +
                '            "administrative_area_level_1",\n' +
                '            "political"\n' +
                '         ]\n' +
                '      },\n' +
                '      {\n' +
                '         "long_name":"United States",\n' +
                '         "short_name":"US",\n' +
                '         "types":[\n' +
                '            "country",\n' +
                '            "political"\n' +
                '         ]\n' +
                '      },\n' +
                '      {\n' +
                '         "long_name":"422605",\n' +
                '         "short_name":"422605",\n' +
                '         "types":[\n' +
                '            "postal_code"\n' +
                '         ]\n' +
                '      }\n' +
                '   ],\n' +
                '   "formatted_address":"Sangamner, Maharashtra 422605, India",\n' +
                '   "geometry":{\n' +
                '      "bounds":{\n' +
                '         "northeast":{\n' +
                '            "lat":19.5954532,\n' +
                '            "lng":74.2273235\n' +
                '         },\n' +
                '         "southwest":{\n' +
                '            "lat":19.5567976,\n' +
                '            "lng":74.1888714\n' +
                '         }\n' +
                '      },\n' +
                '      "location":{\n' +
                '         "lat":19.5771387,\n' +
                '         "lng":74.2079648\n' +
                '      },\n' +
                '      "location_type":"APPROXIMATE",\n' +
                '      "viewport":{\n' +
                '         "northeast":{\n' +
                '            "lat":19.5954532,\n' +
                '            "lng":74.2273235\n' +
                '         },\n' +
                '         "southwest":{\n' +
                '            "lat":19.5567976,\n' +
                '            "lng":74.1888714\n' +
                '         }\n' +
                '      }\n' +
                '   },\n' +
                '   "partial_match":true,\n' +
                '   "place_id":"ChIJeavrqdAB3TsRiL6oagFS3UY",\n' +
                '   "types":[\n' +
                '      "locality",\n' +
                '      "political"\n' +
                '   ]\n' +
                '}';
    }

    @isTest
    public static void getOzonetelKeyTest() {
        insert new Ozonetel__c(Api_Key__c = '12345AB');
        DatabaseResult ozonetelData = LightningComponentController.getOzonetelKey();
        System.assertEquals('12345AB', ozonetelData.data, 'Api key should be 12345AB');
    }
}