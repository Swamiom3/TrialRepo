@isTest
public class RESTInboundLeadAPITest {
    Boolean checkMarket = false;
    private static TaskSelector taskSelector = new TaskSelector();

    @testSetup 
    static void setup() {
        WeWorkValidatorHelper.createTerritoryStructure();
        Account referrerAccount = TestingUtility.createAccount('Test Account Name', true);
        
        Contact referrerContact = TestingUtility.createContact(referrerAccount.Id, 'Test Contact Name', false);
        referrerContact.Email = 'testreferrer@example.com';
        referrerContact.Type__c = 'Broker';
        TestingUtility.insertWithAssert(referrerContact);
        
        Market__c market1 = new Market__c(Name = 'Amsterdam',Email__c = 'amsterdammarket1@example.com',UUID__c = 'test-market-uuid1');
        TestingUtility.insertWithAssert(market1);
        market1 = new Market__c(Name = 'Atlanta',Email__c = 'atlantamarket2@example.com',UUID__c = 'test-market-uuid2');
        TestingUtility.insertWithAssert(market1);
        
        Building__c Building1 = new Building__C();
        Building1.Name =  'Building15318_1';
        Building1.UUID__c = '15318_1';
        Building1.Email__c = 'Building1@example.com'; 
        Building1.Market__c = market1.Id;
        insert Building1;
        
        Profile p1 = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u1 = new User(Alias = 'testU', Email='testUserName1@example.com', 
                           EmailEncodingKey='UTF-8', LastName='User', LanguageLocaleKey='en_US', 
                           LocaleSidKey='en_US', ProfileId = p1.Id, IsActive = true,
                           TimeZoneSidKey='America/Los_Angeles', UserName='testUserName1@example.com',CommunityNickname = TestingUtility.createUserCommunityName());
        insert u1;
        //SalesConsoleSettings.createSplashEventJourney();
    }
    @isTest 
    static void testInboundLead1() {
        List<Contact> lstReferrerContact = [SELECT Id,Name,Email FROM Contact WHERE Email ='testreferrer@example.com' LIMIT 1];
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        WWTypes.InboundLead inboundLead = new RESTInboundLeadAPITest().getInboundLeadPayload();
        inboundLead.market = null;
        inboundLead.market_uuids = new List<String>{getMarketWithAssert('amsterdammarket1@example.com').UUID__c};
        if(lstReferrerContact != null && !lstReferrerContact.isEmpty())
            inboundLead.referrer_sfid = lstReferrerContact.get(0).Id;
        req.requestURI = '/services/apexrest/InboundLeadAPI';  
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        RESTInboundLeadAPI.Response response = RESTInboundLeadAPI.doPost(inboundLead);
        system.assertEquals(true, response.success);
        Test.stopTest();
    }
    @isTest 
    static void testInboundLead2() {
        Profile weworkSystemAdmin = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        Map<String,Object> userRecordMap = new Map<String,Object>();
        userRecordMap.put('LastName','Last Name 1');
        userRecordMap.put('Username','testweworkuser1@example.com');
        userRecordMap.put('Email','testweworkuser1@example.com');
        User testUser = TestingUtility.insertUserWithAssert(weworkSystemAdmin.Id, userRecordMap, true); 
        
        Campaign objCampaign = new Campaign(Name='Test Campaign', Lead_Owner__c=testUser.Id, Region__c = 'China');
        Market__c objMarket1 = getMarketWithAssert('amsterdammarket1@example.com');
        Market__c objMarket2 = getMarketWithAssert('atlantamarket2@example.com');
        
        insert objCampaign;
        WWTypes.InboundLead inboundLead = new RESTInboundLeadAPITest().getInboundLeadPayload();
        inboundLead.market_uuids = new List<String>{objMarket1.UUID__c, objMarket2.UUID__c};
        inboundLead.campaign_sfid = objCampaign.Id;
        
        Test.startTest();
        RESTInboundLeadAPI.Response response = RESTInboundLeadAPI.doPost(inboundLead);
        Test.stopTest();
        system.assertEquals(true, response.success);    
        
        Lead[] arrOfLead = [SELECT Id, FirstName, Phone, Interested_in_Number_of_Desks__c FROM Lead WHERE email = :inboundLead.email LIMIT 1];
        System.assertEquals(1,arrOfLead.size(),'A lead should be created');
        System.assertEquals(21,arrOfLead[0].Interested_in_Number_of_Desks__c);
        System.assertEquals('John', arrOfLead[0].FirstName, 'First name should match the payload\'s value');
        
        Task[] Ts = taskSelector.getTasksWithRelatedObjectsFieldsByWhoIdsLimited(new List<Id>{ arrOfLead[0].Id }, 1);
        system.assertEquals(0,Ts.size(),'A task associated to the lead should not be created'); 

        arrOfLead = [ SELECT Id FROM Lead WHERE Id IN (SELECT LeadId FROM CampaignMember WHERE CampaignId =: objCampaign.Id AND LeadId != null) ];
        system.assertEquals(1,arrOfLead.size(),'A Lead associated to the Campaign should be created');
    }
    
    @isTest 
    static void testInboundLead3() {
        Profile weworkSystemAdmin = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        Map<String,Object> userRecordMap = new Map<String,Object>();
        userRecordMap.put('LastName','Last Name 1');
        userRecordMap.put('Username','testweworkuser1@example.com');
        userRecordMap.put('Email','testweworkuser1@example.com');
        User testUser = TestingUtility.insertUserWithAssert(weworkSystemAdmin.Id, userRecordMap, true); 
        
        Campaign objCampaign = new Campaign(Name='Test Campaign', Lead_Owner__c=testUser.Id, Region__c = 'China');
        insert objCampaign;
        
        Contact objReferContact = [SELECT Id FROM Contact WHERE Email ='testreferrer@example.com' LIMIT 1];
        System.assertNotEquals(objReferContact, null);
        Lead leadRec1 = new Lead(Email = 'test.lead1@test123.com',LastName = 'Test Lead',Company = 'test123',Status = 'Known',LeadSource = 'wework.com');
        Database.SaveResult result = TestingUtility.insertWithAssert(leadRec1);
        
        CampaignMember objCampaignMember = new CampaignMember(CampaignId=objCampaign.Id ,LeadId=result.Id, Status='Sent');
        insert objCampaignMember;
        
        WWTypes.InboundLead inboundLead = new RESTInboundLeadAPITest().getInboundLeadPayload();
        inboundLead.email = 'test.lead1@test123.com';
        inboundLead.campaign_sfid = objCampaign.Id;
        inboundLead.referrer_sfid = objReferContact.Id; 
        
        Test.startTest();
        RESTInboundLeadAPI.Response response = RESTInboundLeadAPI.doPost(inboundLead);
        Test.stopTest();
        
        system.assertEquals(false, response.success);
    }
     
    @isTest 
    static void testInboundLead4() {
        Campaign objCampaign = new Campaign(Name='Test Campaign', Region__c = 'China');
        insert objCampaign;
        
        Account objReferalAccount = [SELECT Id FROM Account WHERE Name = 'Test Account Name' LIMIT 1];
        System.assertNotEquals(objReferalAccount, null);
        
        Contact objReferalContact = [SELECT Id FROM Contact WHERE Email='testreferrer@example.com' LIMIT 1];
        System.assertNotEquals(objReferalContact, null);
        
        Contact existingContact = TestingUtility.createContact(objReferalAccount.Id, 'existing Contact', false);
        existingContact.Email = 'test.lead@test123.com';
        TestingUtility.insertWithAssert(existingContact);
        Opportunity objOppRec = TestingUtility.createOpportunity(objReferalAccount.Id, false);
        objOppRec.Primary_Member__c = existingContact.Id;
        TestingUtility.insertWithAssert(objOppRec);
        
        Map<String,Object> tourDataMap = new Map<String,Object>();
        tourDataMap.put('Scheduled_By__c', existingContact.Id);
        tourDataMap.put('Status__c', 'Scheduled');
        tourDataMap.put('Tour_Date__c', system.today().addDays(-1));
        tourDataMap.put('Start_Time__c', '9:00AM');
        //Tour_Outcome__c contactRecord = (Tour_Outcome__c)TestingUtility.createTestRecords(Tour_Outcome__c.SObjectType, tourDataMap, true);
        
        WWTypes.InboundLead inboundLead = new RESTInboundLeadAPITest().getInboundLeadPayload();
        inboundLead.email = 'test.lead@test123.com';
        inboundLead.campaign_sfid = objCampaign.Id;
        inboundLead.referrer_sfid = objReferalContact.Id;  
        inboundLead.company_size = '100+';
        
        Test.startTest();
        RESTInboundLeadAPI.Response response = RESTInboundLeadAPI.doPost(inboundLead);
        Test.stopTest();
        
        system.assertEquals(true, response.success,response+'');
        
        Lead[] arrOfLead = [SELECT id, Phone, Interested_in_Number_of_Desks__c FROM Lead WHERE email = :inboundLead.email LIMIT 1];
        system.assertEquals(1,arrOfLead.size(),'A lead should be created');
        System.assertEquals(100, arrOfLead[0].Interested_in_Number_of_Desks__c);
        system.assertEquals(1, [SELECT Id, Expires_On__c, Referrer__c FROM Referral__c].size());
    }
    
    @isTest 
    static void testGetCompanySize() {
        String strCompanySize = '121+';
        System.assertEquals(121,new RESTInboundLeadAPIHelper().getCompanySize(strCompanySize));
        strCompanySize = '12-';
        System.assertEquals(12,new RESTInboundLeadAPIHelper().getCompanySize(strCompanySize));
        strCompanySize = '120- desks';
        System.assertEquals(120,new RESTInboundLeadAPIHelper().getCompanySize(strCompanySize));
        strCompanySize = '10- desk';
        System.assertEquals(10,new RESTInboundLeadAPIHelper().getCompanySize(strCompanySize));
    }

    @isTest 
    static void handleInboundEmailRequestTest() {
        WWTypes.InboundLead inboundLead = new RESTInboundLeadAPITest().getInboundLeadPayload();
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.toAddresses =  new List <String>{};
        RESTInboundLeadAPIController RESTinboundLead = new RESTInboundLeadAPIController(email, null);
        Set<Id> emailIds = RESTinboundLead.handleInboundEmailRequest();
        System.assert(emailIds == null, 'Set should not be empty');
    }

    @isTest
    static void testInboundEmailRequestEmailInFirstName() {
        WWTypes.InboundLead inboundLead = new RESTInboundLeadAPITest().getInboundLeadPayload();
        inboundLead.first_name = 'test@test.com';
        Test.startTest();
        RESTInboundLeadAPI.Response response = RESTInboundLeadAPI.doPost(inboundLead);
        Test.stopTest();
        System.assertEquals(true, response.success, 'Request should be successful');
        System.assertEquals('test', [SELECT FirstName FROM Lead WHERE Id = :response.lead_sfid].FirstName, 'Email in first name field should be truncated');
    }

    public static Market__c getMarketWithAssert(String strEmail){
        Market__c objMarket = [SELECT Id,UUID__c FROM Market__C WHERE Email__c = :strEmail];
        System.assertNotEquals(objMarket,null);
        return objMarket;
    }

    public WWTypes.InboundLead getInboundLeadPayload(){

        WWTypes.InboundLead inboundLead = new WWTypes.InboundLead();
        inboundLead.company_name = 'A company';
        inboundLead.last_name = 'Doe';
        inboundLead.first_name = 'John';
        inboundLead.email = 'john.smith@example.com';
        inboundLead.locale ='en-US';
        inboundLead.generate_journeys = false;
        inboundLead.phone = '0321456987';
        inboundLead.lead_source = 'WeWork.com';
        inboundLead.lead_source_detail = 'Book a Tour Form';
        inboundLead.lead_type = 'Office Space';
        inboundLead.Product_Interests = new List<String>{'Office Space','Residential Space'};
        inboundLead.company_size = '21-50';
        inboundLead.marketing_consent = 'true';
        inboundLead.loyalty_program = 'AAdvantage Member';
        inboundLead.loyalty_number = '1234567';
        if (checkMarket == false) {
            inboundLead.market = 'Atlanta';
        } else {
            inboundLead.market = null;
        }
        checkMarket = true;
        return inboundLead;
    }
}