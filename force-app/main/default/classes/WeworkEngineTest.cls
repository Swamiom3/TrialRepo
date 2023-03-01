//comment for cherrypic
/*
* @ Created By : Anant Kumar
* @ Created Date : 15 Mar 2016
*/
@isTest
private class WeworkEngineTest { 
    
    @TestSetup
    static void initData() {
        Building__c b1 = new Building__c(Name = 'B1');
        insert b1;
        OperatingHours objOpHour = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday',
                                                      Building_Id__c  = b1.Id);
        insert objOpHour;
        
        Profile p1 = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u1 = new User(Alias = 'testU', Email='testUser@example.com', 
                           EmailEncodingKey='UTF-8', LastName='User', LanguageLocaleKey='en_US', 
                           LocaleSidKey='en_US', ProfileId = p1.Id, IsActive = true,
                           TimeZoneSidKey='America/Los_Angeles', UserName='testUserName1@example.com');
        insert u1; 
    }
    
    static void testWeworkEngine(){
        Account accRec = TestingUtility.createAccount('strAccountName', true);
        String strQuery = 'SELECT Id FROM Account WhERE Id= \'' + accRec.Id + '\'';
        WeworkEngine engineObj = new WeworkEngine();
        System.assertEquals(accRec.Id, WeWorkEngine.Query(strQuery)[0].Id);
        System.assertEquals(UserInfo.getUserId(), WeWorkEngine.GetLoggedInUserInfo().Id);
        System.assertEquals(true, WeWorkEngine.fetchObjectFields('Account', 'AccountSource').size() > 0);
        String strSearchQuery = 'FIND \'*Account*\' IN Name FIELDS RETURNING Account( Id, Name )';
        WeWorkEngine.searchQuery(strSearchQuery); 
    }
    static void verifySaveRecords(){
        List<Account> lstAccount = new List<Account>();
        lstAccount.add(new Account(Name = 'Test'));
        List<SaveResult> saveResult = WeworkEngine.SaveRecords(lstAccount);
        System.assert(saveResult[0].IsSuccess); 
        
        List<SObject> lstSObject = new List<SObject>();
        lstSObject.add(new Account());
        List<SaveResult> nullSaveResult = WeworkEngine.SaveRecords(lstSObject);
        System.assertEquals(true,saveResult[0].IsSuccess);
    }
    static void verifyDeleteRecords(){
        List<Account> lstAccount = new List<Account>();
        lstAccount.add(new Account(Name = 'TestJohnSmith'));
        List<SaveResult> saveResult = WeworkEngine.SaveRecords(lstAccount);
        System.assert(saveResult[0].IsSuccess);
        saveResult = WeworkEngine.SaveRecords(lstAccount);
        System.assert(saveResult[0].IsSuccess);
        List<Database.DeleteResult>  deleteResult = WeworkEngine.DeleteRecords(new List<Id>{saveResult[0].Id});
        System.assert(deleteResult[0].isSuccess());
        List<Database.DeleteResult>  deleteResultNull = WeworkEngine.DeleteRecords(new List<Id>());
    }
	@isTest
    static void verifyGetAllFields(){
        WeworkEngine.GetAllFields('Lead');        
    }
    
    @isTest
    static void verifyGetUserName(){
        String strUserName = WeworkEngine.getUserName();
        System.assertEquals(strUserName, UserInfo.getName());
    }
    
    static void verifyGetBuildingList(){
        List<Building__c> lstBuilding = new List<Building__c>();
        lstBuilding.add(new Building__c(City__c = 'Amsterdam', Country__c = 'Netherlands',Name = 'AMS-Metropool', CurrencyIsoCode = 'USD',Time_Zone__c = 'Europe/Amsterdam'));
        lstBuilding.add(new Building__c(City__c = 'Brooklyn',Country__c = 'USA',State__c='CA',Name = 'BKN-Brooklyn Heights',CurrencyIsoCode = 'USD',Time_Zone__c = 'America/New_York'));
        lstBuilding.add(new Building__c(City__c = 'Berlin Mitte',Country__c = 'Germany',Name = 'BL-Sony Center',CurrencyIsoCode = 'USD',Time_Zone__c = 'America/New_York'));
        lstBuilding.add(new Building__c(City__c = 'Amsterdam',Country__c = 'USA',State__c='CA',Name = 'AMS-Labs',CurrencyIsoCode = 'USD',Time_Zone__c = 'America/New_York'));
        lstBuilding.add(new Building__c(City__c = 'Chicago',Country__c = 'USA',State__c='CA',Name = 'CHI-River North',CurrencyIsoCode = 'USD',Time_Zone__c = 'America/Chicago'));
        List<SaveResult> saveResult = WeworkEngine.SaveRecords(lstBuilding);
        
        /*Tour_Schedule__c tour_Schedule = new Tour_Schedule__c(
            Building__c = saveResult[0].Id,
            Simultaneous_Tours__c = '2',
            Tour_Spacing__c = 'Hour',
            Product_Line__c = 'WeWork',
            Maximum_Tour_Days__c = 1
        );
        insert tour_Schedule;*/
        //WeworkEngine.getBuildingList('WeWork');              
    }
    
    static void verifyAddBusinessDays(){
        Date resultDate = WeworkEngine.addBusinessDays(2016, 02, 25, 3);
    }
      
    static void verifyFetchObjectFields(){
        Account accRec = TestingUtility.createAccount('strAccountName1', true);
        accRec.Name = 'Test1';
        update accRec;
        
        Contact newContact1 = new Contact();
        newContact1.AccountId = accRec.Id;
        newContact1.firstname = 'TestFirstName';
        newContact1.lastname = 'TestLastName';
        newContact1.Email = 'Test11@example.com';
        newContact1.Status__c = 'active';
        newContact1.Convert_Lead__c = true;
        insert newContact1;
        
        Contact newContact2 = new Contact();
        newContact2.AccountId = accRec.Id;
        newContact2.firstname = 'TestFirstName';
        newContact2.lastname = 'TestLastName';
        newContact2.Email = 'Test12@example.com';
        newContact2.Status__c = 'active';
        newContact2.Convert_Lead__c = true;
        insert newContact2;
        
        WeworkEngine.fetchObjectFields('Contact','Email');
    }
    
    static void verifyConstructSobject(){
        
        String jsonStr = '{"LastName":"Doe", "End_Date__c" :"'+ System.today() +'", "ID_Last_Sync__c":"'+ System.now() +'", "Interested_in_Number_of_Desks__c":"'+ 2 +'"}';
        //String jsonstring = Json.serialize(jsonStr); 
        WeworkEngine.ConstructSobject('Contact',jsonStr);
        /*Added By Milanjeet*/
        String jsonStr2 = '{"Name":"TestOpportunity","Probability":"'+10+'","Monthly_Phone_Fee__c":"'+52+'"}';
        WeworkEngine.ConstructSobject('Opportunity',jsonStr2);
    } 
    
    static void testDeleteRecord(){        
        String jsonStr = '{"LastName":"Doe","End_Date__c" :"'+ System.today() +'", "ID_Last_Sync__c":"'+ System.now() +'", "Interested_in_Number_of_Desks__c":"'+ 2 +'"}';
        WeworkEngine.DeleteRecord('Name',jsonStr);
    }
    
    static testMethod void testGetTypedSetings(){
        MySettings settingsMy = new MySettings();
        settingsMy.count = 10;
        settingsMy.timestamp = Date.today();
        settingsMy.name = 'Test';
    }
    
    public class MySettings {
        Integer count;
        Date timestamp;
        String name;
    }
    
    static testMethod void testExtendReference(){
        Test.startTest();
        Account accRec = TestingUtility.createAccount('strAccountName2', true);
        Contact referrer1 = new Contact();
        referrer1.FirstName = 'First Name Referrer1';
        referrer1.LastName = 'referrer1';
        referrer1.Email = 'referrer1@example.com';
        TestingUtility.insertWithAssert(referrer1);
        
        Contact referrer2 = new Contact();
        referrer2.FirstName = 'First Name Referrer2';
        referrer2.LastName = 'referrer1';
        referrer2.Email = 'referrer2@example.com';
        TestingUtility.insertWithAssert(referrer2);
        
        Referral__c referral1 = new Referral__c();
        referral1.Referral_Email__c = 'referral1@example.com';
        referral1.IsActive__c = true;
        referral1.Referrer__c = referrer1.Id;
        referral1.Expires_On__c = Date.today().addDays(10);
        TestingUtility.insertWithAssert(referral1);
        
        Referral__c referral2 = new Referral__c();
        referral2.Referral_Email__c = 'referral2@example.com';
        referral2.IsActive__c = false;
        referral2.Referrer__c = referrer1.Id;
        referral2.Expires_On__c = Date.today().addDays(10);
        TestingUtility.insertWithAssert(referral2);
        
        WeworkEngine.extendReference(referral1.Id,Date.today(), Date.today());
        Referral__c assertReferral = [Select Id,Name,Referral_Email__c,Expires_On__c,Referrer__r.Name,Referrer_Email__c,Referred_Date__c From Referral__c where Id =:referral1.Id ];
        Test.stopTest();
        System.assertEquals(assertReferral.Expires_On__c , Date.today().addDays(60));
        System.assertEquals(assertReferral.Referred_Date__c , Date.today());
    }
        
    static testMethod void verifyChangeStageRelatedLeadOrContactOnJourney(){
        Test.startTest();
        WeworkEngine.JourneyStageUpdateResult resultContact = new WeworkEngine.JourneyStageUpdateResult();
        WeworkEngine.JourneyStageUpdateResult resultLead = new WeworkEngine.JourneyStageUpdateResult();
        //Test Account created for testContact.
        Account testAccount = new Account();
        testAccount.Name = 'Test Account2';
        
        insert testAccount;
        //Test Contact created for testJourney.
        Contact testContact = new Contact();
        testContact.AccountId = testAccount.Id;
        testContact.firstname = 'TestFirstName';
        testContact.lastname = 'TestLastName';
        testContact.Email = 'Test111@example.com';
        testContact.Status__c = 'active';
        insert testContact;        
        
        //Test Journey for JourneyDetailController.        
        Journey__c testJourney = new Journey__c();
        testJourney.Name = 'testJourneyName';
        testJourney.CurrencyIsoCode = 'USD';
        testJourney.Primary_Contact__c = testContact.Id;
        testJourney.Status__c ='Known';
        testJourney.NMD_Next_Contact_Date__c = Date.today();
        TestingUtility.insertWithAssert(testJourney);
        
        resultContact = WeworkEngine.changeStageRelatedLeadOrContactOnJourney(testJourney.Id);        
               
        //Test Account created for testContact.
        Lead leadNew = new Lead(LastName = 'Test Lead Last Name', Company = 'Test Company', Email = 'test@example.com', Phone = '1212121125', Generate_Journey__c = false);
        insert leadNew;
        //Test Journey for JourneyDetailController.        
        Journey__c testJourneyLead = new Journey__c();
        testJourneyLead.Name = 'testJourneyLead';
        testJourneyLead.CurrencyIsoCode = 'USD';
        testJourneyLead.Primary_Lead__c = leadNew.Id;
        testJourneyLead.Status__c ='Known';
        testJourneyLead.NMD_Next_Contact_Date__c = Date.today();
        testJourneyLead.Outreach_Stage__c = 'Call 1';
        TestingUtility.insertWithAssert(testJourneyLead);
        
        resultLead = WeworkEngine.changeStageRelatedLeadOrContactOnJourney(testJourneyLead.Id);        
        Test.stopTest();
        
        System.assertNotEquals(testContact.Id, null);
        System.assertEquals(resultContact.errorType ,'success');
        System.assertEquals(resultLead.errorType ,'success');
    }
    
    static testMethod void combineSmallTests(){
        //verifyGetAllFields();
        verifyGetUserName();
        // verifyGetSettings();
        verifyAddBusinessDays();       
        verifyConstructSobject();
        testDeleteRecord();
        testWeworkEngine();        
        verifySaveRecords();
        verifyDeleteRecords();
        verifyGetBuildingList();       
        Test.startTest();
        verifyFetchObjectFields();
        Test.stopTest();
    }
    
    /*
    *	Created By   	: Dipak Pawar
    *	Created Date 	: 23-09-2016
    * 	Issue No.		: ST-701
    */
    static testMethod void verifyExceptionFormatter(){
        try {
            insert new Lead();            
        }catch(Exception ex) {
            ApexDebugLog.logException(ex, 'new Lead()', 'WeworkEngineTest', 'verifyExceptionFormatter');
        }   
    }
    
    static testMethod void testCallDateDiff() {
        DateTime dt1 = DateTime.newInstance(2016, 12, 13, 0, 0, 0);
        DateTime dt2 = DateTime.newInstance(2016, 12, 14, 0, 0, 0);
        Long diff = WeworkEngine.callDateDiff(dt1, dt2, 0, 0, 0);
        //System.assertEquals(24,diff);
    }
    
    static void testGetContactInfo() {
        Account testAccount = new Account();
        testAccount.Name = 'Test Account9';
        insert testAccount;
        //Test Contact created for testJourney.
        Contact testContact = new Contact();
        testContact.AccountId = testAccount.Id;
        testContact.firstname = 'TestFirstName';
        testContact.lastname = 'TestLastName';
        testContact.Email = 'Test111@example.com';
        testContact.Status__c = 'active';
        insert testContact;
        System.assertNotEquals(testContact.Id, null);
        
        List<Contact> lstContacts = WeworkEngine.GetContactInfo(testContact.Email);
        System.assertNotEquals(lstContacts, null);
        System.assertEquals(1, lstContacts.size());
        System.assertEquals(testContact.Email.toLowerCase(), lstContacts[0].Email.toLowerCase());
    }	
    
       
    static void testJourney2Journey(){
        Settings.FieldMappings mapping = WeworkEngine.Journey2Journey();
        System.assertNotEquals(null, mapping);
    }
    
    static testMethod void testSaveWebsiteLead(){
        Lead l = new Lead(FirstName = 'Test Setup',
                          LastName = 'Lead',
                          Company = 'TestCompany',
                          Status = 'Known',
                          Email = 'testsetup@example.com');
        insert l;
        test.startTest();
        /*Journey__c testJourney = new Journey__c();
        testJourney.Name = 'testSetupJourney';
        testJourney.CurrencyIsoCode = 'USD';
        testJourney.Primary_Lead__c = l.Id;
        testJourney.NMD_Next_Contact_Date__c = Date.today();
        testJourney.Deferred_Reason__c = 'Unresponsive';
        TestingUtility.insertWithAssert(testJourney);   */    
        WeWorkEngine.SaveWebsiteLead(new List<Lead>{l});
        WeWorkEngine.reassignGuestUser(new List<Lead>{l});
        WeWorkEngine.reassignGuestUserLead(new List<Lead>{l});
        test.stopTest();       
        List<String> picklistValues = WeWorkEngine.getPicklistValues('Lead', 'Status');         
    }
    
    
    static testMethod void combineSmallTests2(){
       // Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorForLightning());
        testCallDateDiff();
        testGetContactInfo();       
        testJourney2Journey();
        WeworkEngine.Contact2Activity();
        WeworkEngine.Lead2Journey();
        WeworkEngine.Contact2Journey();
        WeworkEngine.getJourneyFields();
        WeworkEngine.Contact2Opportunity();
        WeworkEngine.Lead2Activity();
        WeworkEngine.getLowerCompanySize('3');
        WeworkEngine.getMapObjectRecordTypeId('Account');
        WeworkEngine.getObjectRecordTypeId('Account','Business Account');
        WeWorkEngine.getAllUpdatableSobjectField('Journey__c');
        WeWorkEngine.getResourceURL('vendor_css');       
        WeWorkEngine.getPicklistValues('Lead','LeadSource');
    }
   
    /*
	* Created By   	: Amol Darekar
	* Created Date 	: 06-06-2017
	* Comment		: This test method is use to test the getMasterAccountUUID() function.
	* Issue No.		: ST-1156
	*/
   static testMethod void getMasterAccountUUIDTest(){
   	  //Insert Account record for testing 
   	  list<Account> lstTestAccounts = new list<Account>();
   	  Account accRec = TestingUtility.createAccount('strAccountName4', false);
	  accRec.RecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();
	  lstTestAccounts.add(accRec);       
	    
	  Account accRec2 = new Account();
	  accRec2.Name = 'strAccountName5';
	  accRec2.RecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId();
	  lstTestAccounts.add(accRec2);
	    
	  Account accRec3 = new Account();
	  accRec3.Name = 'strAccountName6';
	  lstTestAccounts.add(accRec3);
	  insert lstTestAccounts;
	  
	  lstTestAccounts = [SELECT Id, UUID__c FROM Account];
	  
	  //Call to database merge function.
	  Database.merge(lstTestAccounts[0],(String)lstTestAccounts[1].Id);
	  
	  //Call to getMasterAccountUUID() methodto get master account UUID
	  String masterAccountUUID = WeworkEngine.getMasterAccountUUID(lstTestAccounts[1].UUID__c);
	  
	  //Check whether function retun the Master account UUID or not
	  system.assertEquals(lstTestAccounts[0].UUID__c,masterAccountUUID);
   }    
}