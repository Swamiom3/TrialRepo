@isTest
public class LeadConverterHelperTests {

    @testSetup
    public static void initData(){
        WeWorkValidatorHelper.createTerritoryStructure();
        Test.startTest();
        Profile objWeworkSystemAdmin = [SELECT Id FROM Profile WHERE Name='WeWork System Administrator'];
        System.assert(objWeworkSystemAdmin != null);
        List<User> lstUsers = TestingUtility.insertUserWithAssert(objWeworkSystemAdmin.Id, new List<Map<String, object>>{new Map<String, object>{'Email'=>'user1@example.com'}, new Map<String, object>{'Email'=>'user2@example.com'}}, true);

        Map<String, Object> mapData = new Map<String, Object>();
        Map<String, List<Object>> mapFieldForOpportunity = new Map<String, List<Object>>();
        mapData.put('objName', 'Lead');
        mapData.put('Generate_Journey__c', true);
        mapData.put('numberOfRecords', 1);
        List<Lead> lstLeads = new List<Lead>();
        lstLeads = (List<Lead>)TestingUtility.getRecords(mapData);
        
        Lead objLead = new Lead(OwnerId = lstUsers[1].Id, FirstName = 'John', LastName = 'Smith', Email = 'john.smit778106h@example.com', Company = 'Example', LeadSource = 'Event', Locations_Interested__c = 'Test Building Tour', Generate_Journey__c = false);
        TestingUtility.insertWithAssert(objLead);
        
        Test.stopTest();
        System.assertEquals(1, lstLeads.size());
    }
    
/************************************************************************************************************************************
        Author              :   Jitesh Adwani
        Description         :   This method gives the sample tour payload for tour booking;
        Created Date        :   6 August 2019
*************************************************************************************************************************************/
    public static RESTAPITourModelsV2.Input getTourPayload(){
        String jsonTourPayload = '{"first_name":"John","last_name":"Smith","email":"john.smith1@example.com","phone":"1234567890","lead_source":"Event","lead_source_detail":"Book A Tour Form","utm_campaign_id":"","utm_campaign":"San Francisco - Modifier","utm_content":"utm contents","utm_medium":"cpc","utm_source":"ads-google","utm_term":"virtual +office +san +francisco","company_name":"John Smith","company_size":"2-5 desks","company_industry":"Education","quick_quote_location":"New York City","notes":"Our Notes for","referral_code":"JetBlue","promo_code":"JetBlue","buildings_interested_uuids":["bdf78b97-f8c9-4062-923d-ed32e251d2ad"],"product_interests":["Office Space"],"product_line":"WeWork","locale":"US","country_code":"US","tour_date":"2018-06-07","tour_time":"08:00AM","tour_uuid":"fdb15bdf-19e2-4abe-bd40-7b7fa9816fb5","tour_building_uuid":"bdf78b97-f8c9-4062-923d-ed32e251d2ad","tour_notes":"Currently at Manhattan, Relocate","contact_uuid":"dsp18593-3239-45cc-b690-5bccc15a27c3","original_tour":"","original_tour_uuid":"","sf_journey_uuid":"","booked_by_contact_id":"0033D00000Ou6FA","tour_completed_by":"","t_and_cs_consent":"False","marketing_consent":"False","affiliates_consent":"False","referral_fail_reason":"No Show","booked_by_sales_lead":true}';
        RESTAPITourModelsV2.Input tourPayload = (RESTAPITourModelsV2.Input)JSON.deserialize(jsonTourPayload, RESTAPITourModelsV2.Input.class);
        return tourPayload;
    }
    
        public static RESTAPITourModelsV2.Input getTourPayload1(){
        String jsonTourPayload = '{"first_name":"John","last_name":"Smith","email": null ,"phone":"1234567890","lead_source":"Event","lead_source_detail":"Book A Tour Form","utm_campaign_id":"","utm_campaign":"San Francisco - Modifier","utm_content":"utm contents","utm_medium":"cpc","utm_source":"ads-google","utm_term":"virtual +office +san +francisco","company_name":"John Smith","company_size":"2-5 desks","company_industry":"Education","quick_quote_location":"New York City","notes":"Our Notes for","referral_code":"JetBlue","promo_code":"JetBlue","buildings_interested_uuids":["bdf78b97-f8c9-4062-923d-ed32e251d2ad"],"product_interests":["Office Space"],"product_line":"WeWork","locale":"US","country_code":"US","tour_date":"2018-06-07","tour_time":"08:00AM","tour_uuid":"fdb15bdf-19e2-4abe-bd40-7b7fa9816fb5","tour_building_uuid":"bdf78b97-f8c9-4062-923d-ed32e251d2ad","tour_notes":"Currently at Manhattan, Relocate","contact_uuid":"dsp18593-3239-45cc-b690-5bccc15a27c3","original_tour":"","original_tour_uuid":"","sf_journey_uuid":"","booked_by_contact_id":"0033D00000Ou6FA","tour_completed_by":"","t_and_cs_consent":"False","marketing_consent":"False","affiliates_consent":"False","referral_fail_reason":"No Show","booked_by_sales_lead":true}';
        RESTAPITourModelsV2.Input tourPayload = (RESTAPITourModelsV2.Input)JSON.deserialize(jsonTourPayload, RESTAPITourModelsV2.Input.class);
        return tourPayload;
    }
    
    @isTest
    public static void createAccountStructure(){
        List<Lead> lstLeads1 = new List<Lead>();
        Lead leadRecord = new Lead();
        Lead leadRecord1 = new Lead();
        List<Lead> lstLeads = [SELECT Id, Name, Email, Phone, company, LeadSource, Lead_Source_Detail__c, Locations_Interested__c, LeadSource_Sub_Type__c FROM Lead LIMIT 2];
        Account objAccount = new Account(Name='Example', Lead_Source__c='LeadSource1',Account_Type__c='Org');
        TestingUtility.insertWithAssert(objAccount);
        Test.startTest();
        LeadConverterHelper.createAccountStructure(getTourPayload1() ,lstLeads[0].id, objAccount.id);
        Task newTask = new Task();
        newTask.WhoId = lstLeads.get(0).Id;
        newTask.Status = 'Open';
        insert newTask;
        
        List<Id> leadIds = new List<Id>{lstLeads.get(0).Id,lstLeads.get(1).Id};
        lstLeads1 = [SELECT Id, Campaign_Id__c, (SELECT Id, Status FROM Tasks) FROM Lead WHERE Id IN: leadIds LIMIT 2];
        LeadConverterHelper.markLeadsTasksCompletedOnLeadConversion(lstLeads1);
        LeadConverterHelper.markLeadsTasksCompletedOnLeadConversion(new List<Lead>());
        
        LeadConverterHelper.setLeadGenerateJourney(leadRecord);
        Map<String, Map<String, Id>> leadwithTour = LeadConverterHelper.convertLeadWithTour(leadRecord1);
        System.assertEquals(null, leadwithTour, 'Should get null value as we are sending empty Lead object');
        Test.stopTest();
    }
        
    
    @isTest
    public static void verifyFreshLeadCriteria(){
        Test.startTest();
        List<Lead> lstLeads = [SELECT Id, Name, Email, Phone, company, LeadSource, Lead_Source_Detail__c, Locations_Interested__c, Generate_Journey__c FROM Lead LIMIT 2];
        List<Journey__c> lstJourneys = [SELECT Id, OwnerId, Primary_Lead__r.OwnerId FROM Journey__c WHERE Primary_Lead__c =: lstLeads[0].Id];
        Test.stopTest();
        System.assertEquals(1, lstJourneys.size(),'Journey not created');
        System.assertEquals(lstJourneys[0].Primary_Lead__r.OwnerId, lstJourneys[0].OwnerId,'Journey Owner should be lead owner.');
        JourneyHelper.createJourney(new Map<String,sObject>());
    }

    @isTest
    public static void verifyWithinXYDuplicateLeadCriteria(){
        List<Lead> lstLeads = [SELECT Id, Name, Email, Phone, company, LeadSource, Lead_Source_Detail__c, Locations_Interested__c, LeadSource_Sub_Type__c FROM Lead LIMIT 2];
        List<Journey__c> lstJourneys = [SELECT Id, OwnerId, Primary_Lead__r.OwnerId FROM Journey__c WHERE Primary_Lead__c =: lstLeads[0].Id];
        Test.setCreatedDate(lstJourneys[0].Id, System.today().addDays(-5));
        System.assertEquals(NULL, lstLeads[1].LeadSource_Sub_Type__c);
        Lead objDuplicateLead = new Lead(FirstName = 'John', LastName = 'Smith', Email = lstLeads[1].Email, Company = 'Example',LeadSource='Event', Lead_Source_Detail__c = 'Book a Tour Form', Locations_Interested__c = 'Test Building Tour', LeadSource_Sub_Type__c = 'Broker');
        Test.startTest();
        TestingUtility.insertWithAssert(objDuplicateLead) ;
        Test.stopTest();
        List<Journey__c> lstDuplicateLeadJourneys = [SELECT Id, OwnerId, Primary_Lead__c, Primary_Lead__r.OwnerId FROM Journey__c WHERE Primary_Lead__c =: lstLeads[0].Id ORDER BY CreatedDate DESC];
        List<Lead> lstLead1 = [SELECT Id, Lead_Source_Detail__c, LeadSource_Sub_Type__c FROM Lead WHERE Email =: lstLeads[1].Email LIMIT 1];
        System.assertEquals(NULL, lstLead1[0].LeadSource_Sub_Type__c);
        System.assertEquals(NULL, lstLead1[0].Lead_Source_Detail__c);
        System.assertEquals(1, lstDuplicateLeadJourneys.size(), 'New journey not created');
        System.assertEquals(lstDuplicateLeadJourneys[0].Primary_Lead__c, lstLeads[0].Id, 'Journey created on wrong lead.');
        System.assertEquals(lstDuplicateLeadJourneys[0].Primary_Lead__r.OwnerId, lstDuplicateLeadJourneys[0].OwnerId, 'New Journey Owner should not be owner of lead');
    }

    @isTest
    public static void verifyBeyondYDuplicateLeadCriteria(){
        Lead objLead = new Lead(FirstName ='John', LastName='Smith', Email='john.smith@example.com', Company='Example',Locations_Interested__c='Test Building Tour',Generate_Journey__c=false,Personal_Mailing_Street__c='Pimpri',Personal_Mailing_City__c='Pune',Personal_Mailing_PostalCode__c='411017',Personal_Mailing_Country__c='India',Personal_Mailing_State__c='Maharashtra',Promo_Code__c='Jet Blue');
        TestingUtility.insertWithAssert(objLead);
        Journey__c objJourney = new Journey__c(Name='Test Journey',Primary_Lead__c=objLead.Id,Status__c='Known',NMD_Next_Contact_Date__c=System.today());
        TestingUtility.insertWithAssert(objJourney);
        Test.setCreatedDate(objJourney.Id,System.today().addDays(-31));
        Lead objDuplicateLead = new Lead(FirstName='Duplicate',LastName='Smith',Email='john.smith@example.com',Company='Example',Industry = 'Accounting', LeadSource='Event',Lead_Source_Detail__c='Book a Tour Form',LeadSource_Sub_Type__c = 'Broker',Locations_Interested__c='Test Building Tour',Personal_Mailing_Street__c='Baner',Personal_Mailing_City__c='Pune',Personal_Mailing_PostalCode__c='411017',Personal_Mailing_Country__c='India',Personal_Mailing_State__c='Maharashtra',Promo_Code__c='Jet Blue');
        Test.startTest();
        TestingUtility.insertWithAssert(objDuplicateLead);
        Test.stopTest();
        List<Journey__c> lstJourneys = [SELECT Id, OwnerId, Primary_Lead__c, Primary_Lead__r.OwnerId FROM Journey__c WHERE Primary_Lead__c =: objLead.Id ORDER  BY CreatedDate DESC];
        List<Lead> lstLead = [SELECT Id, Industry, LeadSource, Lead_Source_Detail__c, LeadSource_Sub_Type__c FROM Lead WHERE Id =: lstJourneys[0].Primary_Lead__c LIMIT 1];
        System.assertEquals(objDuplicateLead.LeadSource, lstLead[0].LeadSource);
        System.assertEquals(objDuplicateLead.Lead_Source_Detail__c, lstLead[0].Lead_Source_Detail__c);
        System.assertEquals(objDuplicateLead.LeadSource_Sub_Type__c, lstLead[0].LeadSource_Sub_Type__c);
        System.assertEquals(objDuplicateLead.Industry, lstLead[0].Industry);
        System.assertEquals(2, lstJourneys.size(), 'New journey not created');
        System.assertEquals(lstJourneys[0].Primary_Lead__c, objLead.Id, 'Journey created on wrong lead.');
        System.assertEquals(lstJourneys[0].Primary_Lead__r.OwnerId, lstJourneys[0].OwnerId, 'New Journey Owner should not be owner of lead');
        System.assertNotEquals(objLead.Personal_Mailing_Street__c, objDuplicateLead.Personal_Mailing_Street__c);
        System.assertEquals(objLead.Personal_Mailing_City__c, objDuplicateLead.Personal_Mailing_City__c);
        System.assertEquals(objLead.Personal_Mailing_State__c, objDuplicateLead.Personal_Mailing_State__c);
        System.assertEquals(objLead.Personal_Mailing_PostalCode__c, objDuplicateLead.Personal_Mailing_PostalCode__c);
        System.assertEquals(objLead.Personal_Mailing_Country__c, objDuplicateLead.Personal_Mailing_Country__c);
    }

    @isTest
    public static void verifyDuplicateLeadSubmissionOnContact(){
        List<sObject> lstRecordsToInsert = new List<sObject>();
        CI_Company__c objCICompany = new CI_Company__c(CI_Company_Id__c = 111);
        TestingUtility.insertWithAssert(objCICompany);
        Account objAccount = new Account(Name='Example', CI_Company__c = objCICompany.Id, Lead_Source__c='LeadSource1',Account_Type__c='Org');
        TestingUtility.insertWithAssert(objAccount);
        Contact objContact = new Contact(FirstName='John',LastName='Smith',Email='john.smith@example.com',AccountId=objAccount.Id,Personal_Mailing_Street__c = 'Baner',Personal_Mailing_City__c = 'Pune', Personal_Mailing_State__c = 'Maharashtra',Personal_Mailing_PostalCode__c = '411017',Personal_Mailing_Country__c = 'India', Company__c = 'John Smith');
        TestingUtility.insertWithAssert(objContact);
        Journey__c objJourney = new Journey__c(Name='Test Journey',Primary_Contact__c=objContact.Id,Status__c='Known',NMD_Next_Contact_Date__c=System.today());
        TestingUtility.insertWithAssert(objJourney);
        Lead objDuplicateLead = new Lead(FirstName='Duplicate',LastName='Smith',Email='john.smith@example.com',Industry = 'Accounting', LeadSource='Event',Lead_Source_Detail__c='Book a Tour Form',Locations_Interested__c='Test Building Tour',Personal_Mailing_Street__c='Pimpri',Personal_Mailing_City__c='Pune',Personal_Mailing_PostalCode__c='411017',Personal_Mailing_Country__c='India',Personal_Mailing_State__c='Maharashtra',Promo_Code__c='Jet Blue',Company='Google');
        Test.startTest();
        TestingUtility.insertWithAssert(objDuplicateLead);
        Test.stopTest();
        List<Lead> lstLeads = new List<Lead>([SELECT Id, ConvertedContactId, ConvertedAccountId, Street, City, State, PostalCode, Country, Company,Industry FROM Lead WHERE Id=:objDuplicateLead.Id]);
        List<Contact> lstContacts = [SELECT Id, LeadSource, Lead_Source_Detail__c, Industry__c FROM Contact WHERE Email='john.smith@example.com'];
        System.assertEquals(objDuplicateLead.LeadSource, lstContacts[0].LeadSource);
        System.assertEquals(objDuplicateLead.Lead_Source_Detail__c, lstContacts[0].Lead_Source_Detail__c);
        System.assertEquals(objContact.Id, lstLeads[0].ConvertedContactId ,'Lead convert on existing Contact');
        System.assertEquals(objAccount.Id, lstLeads[0].ConvertedAccountId ,'Lead convert on existing Contact with related to Account');
        System.assertEquals(lstLeads[0].Street, objContact.MailingStreet,'Lead convert on existing Contact must have same Street');
        System.assertEquals(lstLeads[0].City, objContact.MailingCity,'Lead convert on existing Contact must have same City');
        System.assertEquals(lstLeads[0].State, objContact.MailingState,'Lead convert on existing Contact must have same State');
        System.assertEquals(lstLeads[0].PostalCode, objContact.MailingPostalCode,'Lead convert on existing Contact must have same PostalCode');
        System.assertEquals(lstLeads[0].Country, objContact.MailingCountry,'Lead convert on existing Contact must have same Country');
        System.assertNotEquals(lstLeads[0].Company, objContact.Company__c,'Lead convert on existing Contact must have different Company');
        System.assertNotEquals(lstLeads[0].Industry, objContact.Industry__c,'Lead convert on existing Contact must have different Industry');
    }

     @isTest
    public static void verifyContactCreateWhenLeadPresent(){
        String campaignOROwnerId = TestUtility.getFakeId(Campaign.getSObjectType());
        Test.startTest();
        Lead objLead = new Lead(FirstName='John',LastName='Smith',Email='john.smith@example.com',Company='Example',LeadSource='Event',Lead_Source_Detail__c='Book a Tour Form',Locations_Interested__c='Test Building Tour',Generate_Journey__c=false,OwnerId=UserInfo.getUserId());
        TestingUtility.insertWithAssert(objLead);
        Journey__c objJourney = new Journey__c(Name='Test Journey',Primary_Lead__c=objLead.Id,Status__c='Known',NMD_Next_Contact_Date__c=System.today());
        TestingUtility.insertWithAssert(objJourney);
        CI_Company__c objCompany = new CI_Company__c(CI_Company_Id__c = 1111);
        TestingUtility.insertWithAssert(objCompany);
        Account objAccount = new Account(Name='Example', CI_Company__c = objCompany.Id, Lead_Source__c='LeadSource1',Account_Type__c='Org');
        TestingUtility.insertWithAssert(objAccount);
        Contact objContact = new Contact(FirstName='John',LastName='Smith',Email='john.smith@example.com',AccountId=objAccount.Id);
        TestingUtility.insertWithAssert(objContact);
        Contact contactRec = [SELECT Id,OwnerId,(SELECT Id FROM Journeys__r) FROM Contact WHERE Email='john.smith@example.com' LIMIT 1];
        User getUser = [SELECT Id FROM User WHERE IsActive=false LIMIT 1];
        contactRec.OwnerId = getUser.Id;
        update contactRec;
        LeadConverterHelper.setContactOwner(contactRec, new Lead(FirstName='John',LastName='Smith',Email='john.smith@example.com',Company='Example',LeadSource='Event'),campaignOROwnerId);
        LeadConverterHelper.setContactOwner(contactRec, objLead,campaignOROwnerId);
        LeadConverterHelper.setContactOwner(new Contact(), objLead,UserInfo.getUserId());
        Test.stopTest();
        System.assertEquals(1,contactRec.Journeys__r.size());
    }

    @isTest
    public static void verifyTourPayload(){
        Map<String, Id> mapEntities = LeadConverterHelper.manageLead(getTourPayload());
        System.assertNotEquals(null, mapEntities.get('accountId'), 'Using Tour payload new account created');
        System.assertNotEquals(null, mapEntities.get('contactId'), 'Using Tour payload new contact created');
        
    }

    @isTest
    public static void verifyTourPayloadForExistingLead(){
        Lead objLead = [SELECT Id FROM Lead WHERE Email = 'john.smith1@example.com'];
        Map<String, Id> mapEntities = LeadConverterHelper.manageLead(getTourPayload());
        List<Lead> lstLeads = [SELECT Id, ConvertedContactId, ConvertedAccountId FROM Lead WHERE Id =: objLead.Id];
        System.assertEquals(lstLeads[0].ConvertedAccountId, mapEntities.get('accountId'), 'Using Tour payload new account created');
        System.assertEquals(lstLeads[0].ConvertedContactId, mapEntities.get('contactId'), 'Using Tour payload new contact created');
    }

    @isTest
    public static void verifyTourPayloadForExistingLeadWithInactiveUser(){
        List<User> weworkAdminUsers = [ SELECT Id
                                        FROM User
                                        WHERE Email IN ('user1@example.com', 'user2@example.com') ];
        System.assertNotEquals(null, weworkAdminUsers[0].Id, 'Active user');
        System.assertNotEquals(null, weworkAdminUsers[1].Id, 'Active user');
        Lead leadRecord = [ SELECT Id, OwnerId, Owner.Name
                            FROM Lead
                            WHERE Email = 'john.smith1@example.com' ];
        weworkAdminUsers[1].IsActive = false;
        TestingUtility.updateListWithAssert(weworkAdminUsers);
        UserUtility.refreshUsers();

        System.runAs(weworkAdminUsers[0]) {
            Test.startTest();
            Map<String, Id> entitiesMap = LeadConverterHelper.manageLead(getTourPayload());
            Test.stopTest();

            List<Lead> leads = TestWithoutSharingUtility.getLeadsById(leadRecord.Id);
            System.assertEquals(leads[0].ConvertedAccountId, entitiesMap.get('accountId'), 'Using Tour payload new account created');
            System.assertEquals(leads[0].ConvertedContactId, entitiesMap.get('contactId'), 'Using Tour payload new contact created');
            if(OrganizationHelper.isUser(leadRecord.OwnerId)){
                System.assertEquals(leadRecord.OwnerId, leads[0].OwnerId, 'Using Tour payload new contact created');
            }else{
                System.assertEquals(Id.valueOf('005F0000003KmbwIAC'), leads[0].OwnerId, 'Using Tour payload new contact created');
            }            
        }
    }
    
    @isTest
    public static void verifyTourPayloadForExistingContact(){
        CI_Company__c objCompany = new CI_Company__c(CI_Company_Id__c = 1111);
        TestingUtility.insertWithAssert(objCompany);
        Account objAccount = new Account(Name='Example', CI_Company__c = objCompany.Id, Lead_Source__c='Event',Account_Type__c='Org');
        insert objAccount;
        Contact objContact = new Contact(FirstName='John',LastName='Smith',Email='john.smith1@example.com',CI_Company__c = objCompany.Id, AccountId = objAccount.Id);
        insert objContact;
        Map<String,Id> mapEntities = LeadConverterHelper.manageLead(getTourPayload());
        System.assertEquals(objAccount.Id, mapEntities.get('accountId'), 'Using Tour payload new account created');
        System.assertEquals(objContact.Id, mapEntities.get('contactId'), 'Using Tour payload new contact created');
    }

    @isTest
    public static void verifyTourPayloadForExistingContactWithUUID(){
        Contact objContact = new Contact(FirstName='John',LastName='Smith',Email='john.smith1@example.com',UUId__c='dsp18593-3239-45cc-b690-5bccc15a27c3');
        insert objContact;
        Map<String,Id> mapEntities = LeadConverterHelper.manageLead(getTourPayload());
        List<Contact> lstContacts = [SELECT Id, AccountId FROM Contact WHERE Id=:objContact.Id];
        System.assertNotEquals(Null, lstContacts[0].AccountId, 'Using Tour payload new account created for contact and binded with contact');
        System.assertEquals(objContact.Id, mapEntities.get('contactId'), 'Using Tour payload new contact created');
        System.assertEquals(lstContacts[0].AccountId, mapEntities.get('accountId'), 'Using Tour payload new Account created');
    }

    @isTest
    public static void verifyNegativeCondition(){
        System.assertEquals(null, LeadConverterHelper.manageLead(new Lead()), 'verify null condition single lead parameter');
        System.assertEquals(null, LeadConverterHelper.manageLead(new List<Lead>()), 'verify null condition list lead parameter');
        System.assertEquals(null, LeadConverterHelper.manageLead(new RESTAPITourModelsV2.Input()), 'verify null condition tour parameter');
        System.assertEquals(null, LeadConverterHelper.manageJourneyForLead(new List<Lead>(),false), 'verify null condition tour parameter');
        Lead objLead = new Lead(LastName='Smith',Email='email@enazigma.com',Phone='1234567891',Company='Test Company',Locations_Interested__c='Test Building Tour',LeadSource='Event',Lead_Source_Detail__c='Broker');
        TestingUtility.insertWithAssert(objLead);
        System.assertNotEquals(new Map<String, Id>(), LeadConverterHelper.manageLead(objLead), 'Verify not null condition single lead parameter');
    }

    @isTest
    public static void verifyconvertLeadWithTour(){
        List<Lead> lstleadData = [SELECT Id, FirstName, Interested_in_Number_of_Desks_Min__c, Interested_in_Number_of_Desks__c, LastName, Name, OwnerId, Email_Domain_Text__c, Company, Account__c, Account__r.Account_Type__c, Referrer__c, Cleansed_Company_Name__c, Email, Unomy_Company_Id_Formula__c, LeadSource, Lead_Source_Detail__c, Generate_Journey__c, By_Pass_Journey_Creation_Criteria__c, Campaign_Id__c, Building_Interested_In__c, Building_Interested_In__r.City__c, Locations_Interested__c FROM Lead WHERE IsConverted=false AND Email = 'john.smit778106h@example.com'];
        System.assertNotEquals(null, LeadConverterHelper.convertLeadWithTour(lstleadData[0]), 'Lead not converted with tour Payload');
    }

    /************************************************************************************************************************************
        Author              :   Pragalbha Mahajan
        Description         :   This method is used to verify convert leads to existing lead
        Created Date        :   6 Dec 2018
    *************************************************************************************************************************************/
    @isTest
    public static void verifySetLeadGenerateJourney(){
        Lead objLead = new Lead(LastName='Smith',Email='email@enazigma.com',Phone='1234567891',Company='Test Company',Locations_Interested__c='Test Building Tour',LeadSource='Event',Lead_Source_Detail__c='Broker');
        TestingUtility.insertWithAssert(objLead);
        System.assert(objLead.id != null);
        DatabaseResult result = LightningComponentController.convertLeadsToExisting(objLead);
    }

    /************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method is used to get the Journey Closed Stages.
        Created Date        :   6 Dec 2018
*************************************************************************************************************************************/
    @isTest
    public static void verifyGetJourneyCloseStages(){
        Set<String> setStages = JourneyHelper.getJourneyCloseStages();
        System.assert(setStages != NULL);
        JourneyHelper.JourneyCreationSetting objSetting = new JourneyHelper.JourneyCreationSetting();
        System.assert(objSetting != NULL);
        objSetting.NextCallInDaysFromLeadCreation = 5;
        objSetting.NoCompanyAccountId = NULL;
        objSetting.NewLeadActivityFields = new Map<String, String>();
        objSetting.NewJourneyFields = new Map<String,String>();
        objSetting.NextCallInDaysFromJourneyUpdation = 6;
        objSetting.ExistingJourneyStage = 'Accepted';
        objSetting.AssignExistingJourneyOwner = 5;
        objSetting.ExistingJourneyCreatedDateDifference = 25;
        objSetting.JourneyAssignmentCutOffDays = 2;
        objSetting.CloseInDaysFromJourneyCreation = 10;
        Set<String> setCloseStages = new Set<String>{'Converted','Deferred'};
            objSetting.ClosedJourneyStages = setCloseStages;
        System.assertEquals(2, objSetting.ClosedJourneyStages.Size());
        JourneyHelper.LeadSourceDetails objLSDetails = new JourneyHelper.LeadSourceDetails();
        JourneyHelper.LeadSource objLSource = new JourneyHelper.LeadSource();
        objLSource.name = 'Event';
        objLSource.OverrideLeadSoruce = false;
        objLSDetails.LeadSource = new List<JourneyHelper.LeadSource>{objLSource};
            objLSDetails.LeadSourceDetails = new Set<String>(); 
        JourneyHelper.closeOppRelatedJourney([SELECT Id FROM Journey__c LIMIT 1][0].Id);
    }
    
    /************************************************************************************************************************************
        Author              :   Jitesh Adwani
        Description         :   This method is used to get the JourneyId By LeadId .
        Created Date        :   6 Dec 2018
*************************************************************************************************************************************/
    @isTest
    public static void verifyGetJourneyByLeadId(){
        List<Lead> lstLeads = new List<Lead>([SELECT Id FROM Lead]);
        List<Journey__c> lstJourneys = new List<Journey__c>([SELECT Id, Lead_Id__c FROM Journey__c]);
        Id journeyId = LeadConverterHelper.getJourneyByLeadId(lstLeads[0].Id, lstJourneys);
        Lead nullLead = new Lead();
        Id nulljourneyId = LeadConverterHelper.getJourneyByLeadId(nullLead.Id, lstJourneys);
        System.assertEquals(null, nulljourneyId, 'Should get a null as an Id');
        Id emptyJourneyList = LeadConverterHelper.getJourneyByLeadId(lstLeads[0].Id, new List<Journey__c>());
        System.assertEquals(null, emptyJourneyList, 'Should get a null as an Id');
        System.assertEquals(lstJourneys[0].Id, journeyId);
    }
  
  @isTest
    private static void verifySetMarketingInfo() {
        Test.startTest();
        User testUser = UserUtility.getUserById(Settings.getValidationRuleRestrictionSalesforceId('BigMarker_Integration_User'));
        Lead testLead1 = TestingUtility.createLead(new Map<String, Object> {
                                                      'Email' => 'johnny.test123@example.com',
                                                      'LastName' => 'testjohnny',
                                                      'Phone' => '1234567890',
                                                      'Marketing_Consent__c' => true
                                                  }, true);
        Lead testLead2 = TestingUtility.createLead(new Map<String, Object> {
                                                      'Email' => 'johnny.test123@example.com',
                                                      'LastName' => 'test lead',
                                                      'Phone' => '1234567890',
                                                      'Marketing_Consent__c' => false
                                                  }, false);
        System.runAs(testUser) {
            TestingUtility.insertWithAssert(testLead2);
        }
        testLead1 = [SELECT HasOptedOutOfEmail, Marketing_Consent__c FROM Lead WHERE Id =:testLead1.Id];
        Test.stopTest();
        System.assertEquals(true, testLead1.HasOptedOutOfEmail);
        System.assertEquals(false, testLead1.Marketing_Consent__c);

        Lead testLead3 = TestingUtility.createLead(new Map<String, Object> {
                                                      'Email' => 'johnny.test123@example.com',
                                                      'LastName' => 'test lead',
                                                      'Phone' => '1234567890',
                                                      'Marketing_Consent__c' => true
                                                  }, false);
        TestingUtility.insertWithAssert(testLead3);
        testLead1 = [SELECT HasOptedOutOfEmail, Marketing_Consent__c FROM Lead WHERE Id =:testLead1.Id];
        System.assertEquals(true, testLead1.HasOptedOutOfEmail);
        System.assertEquals(false, testLead1.Marketing_Consent__c);
    }
        
    @isTest
    public static void deleteLeads(){
         Lead testLead1 = TestingUtility.createLead(new Map<String, Object> {
                                                       'Email' => 'johnny.test123@example.com',
                                                       'LastName' => 'testjohnny',
                                                       'Phone' => '1234567890',
                                                       'Marketing_Consent__c' => true
                                                   }, true);
        List<Id> leadstodelete = new List<Id>();                                          
        Test.startTest();
        LeadConverterHelper.deleteLeads(leadstodelete);
        System.assertEquals(testLead1.Email, [SELECT Email,LastName FROM Lead WHERE Id=:testLead1.Id].Email, 'Lead creation failed');
        Test.stopTest();
    }
    
    @isTest
    static void isValidToDeleteTest(){
        Lead createLead = new Lead(FirstName='John',LastName='Smith',Email='john.smith@example.com',Company='Example',LeadSource='Event',Lead_Source_Detail__c='Book a Tour Form',Locations_Interested__c='Test Building Tour',Generate_Journey__c=false,OwnerId=UserInfo.getUserId(),Send_For_Forcefully_Lead_Assignments__c=true,LastModifiedById=Settings.getValidationRuleRestrictionSalesforceId('BigMarker_Integration_User'),Marketing_Consent__c=false);
        Contact createCon = new Contact(
            FirstName = 'First Name Test',
            HasOptedOutOfEmail = false,
            LastName = 'test',
            exists_in_id__c=true
        );
        insert createCon;
        TestingUtility.insertWithAssert(createLead);
        System.assert(!LeadConverterHelper.isValidToDelete(createLead, createLead.Id));
        System.assert(!LeadConverterHelper.isValidToDelete(createLead, UserInfo.getUserId()));
        System.assertEquals(null, LeadConverterHelper.getLeadById(null, createLead.Id), 'Should return null');
        System.assertEquals(null, LeadConverterHelper.getContactByUUID(null, null), 'Should return null');
        LeadConverterHelper.mapNewLeadToExistingRecord((SObject)createCon,createLead);
    }
    
    @isTest
    private static void setjourneyParentsTest() {
        Lead leadRecord = new Lead(
            Id = TestUtility.getFakeId(Lead.getSObjectType()),
            LastName = 'test',
            OwnerId = UserInfo.getUserId(),
            Lead_Assignment_Stage__c = ''
        );

        Lead newLeadRecord = new Lead(
            Id = TestUtility.getFakeId(Lead.getSObjectType()),
            LastName = 'test2',
            OwnerId = UserInfo.getUserId(),
            Lead_Assignment_Stage__c = ''
        );
        
        String campaignId = TestUtility.getFakeId(Campaign.getSObjectType());
        Lead leadWithCampaignId = new Lead(
            Id = TestUtility.getFakeId(Lead.getSObjectType()),
            LastName = 'testLead',
            OwnerId = UserInfo.getUserId(),
            Campaign_Id__c = campaignId
        );
        
        Contact contactRecord = new Contact(
            Id = TestUtility.getFakeId(Contact.getSObjectType()),
            LastName = 'testContact'
        );

        List<Map<String, sObject>> journeyParents = new List<Map<String, sObject>>();
        List<Map<String, sObject>> journeyParentsLeadOnly = new List<Map<String, sObject>>();
        Map<Id, Id> journeyWithLeadOrContactIds = new Map<Id, Id>();
        Map<Id, Id> journeyWithLeadOrContactIdsLeadOnly = new Map<Id, Id>();

        Test.startTest();
        LeadConverterHelper.setjourneyParents(true, new Map<Id, Lead>(), newLeadRecord, journeyParents, leadRecord, journeyWithLeadOrContactIds, true);
        LeadConverterHelper.setjourneyParents(true, new Map<Id, Lead>(), newLeadRecord, journeyParentsLeadOnly, leadRecord, journeyWithLeadOrContactIds, false);
        LeadConverterHelper.setjourneyParents(false, new Map<Id, Lead>(), newLeadRecord, journeyParents, leadRecord, journeyWithLeadOrContactIds, true);
        LeadConverterHelper.setjourneyParents(false, new Map<Id, Lead>(), newLeadRecord, journeyParents, leadRecord, journeyWithLeadOrContactIdsLeadOnly, false);
        LeadConverterHelper.addCampaignMembers(leadWithCampaignId, contactRecord, new List<CampaignMember>());
        LeadConverterHelper.populateLeadMaps(leadWithCampaignId, new Map<Id, Lead>{leadWithCampaignId.Id => leadWithCampaignId}, new Map<Id, Lead>{newLeadRecord.Id=>newLeadRecord});
        Test.stopTest();

        System.assertEquals(newLeadRecord.LastName, journeyParents[0].get('newlead').get('LastName'), 'lastname should be ' + newLeadRecord.LastName);
        System.assertEquals(newLeadRecord.LastName, journeyParentsLeadOnly[0].get('lead').get('LastName'),  'lastname should be ' + newLeadRecord.LastName);
        System.assertEquals(newLeadRecord.Id, journeyWithLeadOrContactIds.get(leadRecord.Id), 'Id should be ' + newLeadRecord.Id);
        System.assertEquals(null, journeyWithLeadOrContactIdsLeadOnly.get(newLeadRecord.Id), 'Id should be null');
    }
        
}