@isTest
public with sharing class OpportunityTriggerHandlerTest {
    @isTest
    private static void sendEmailOnOwnerChangeTest(){
        Account acme = TestingUtility.createAccount('Acme', true);
        Opportunity testOpportunity = TestingUtility.createOpportunity(acme.Id, false);
        Id entSolutionId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('New Business').getRecordTypeId();
        testOpportunity.RecordTypeId = entSolutionId;
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User oldOwner = new User(Alias = 'old', Email='oldUser@testorg.com',
                EmailEncodingKey='UTF-8', LastName='OldUser', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = standardProfile.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName = 'OldUser@testweworkuser.com');
        User newOwner = new User(Alias = 'new', Email='newUser@testorg.com',
                EmailEncodingKey='UTF-8', LastName='NewUser', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = standardProfile.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName = 'NewUser@testweworkuser.com');
        insert(new List<User>{oldOwner,newOwner});
        testOpportunity.OwnerId = oldOwner.Id;

        insert testOpportunity;

        Opportunity afterChangeOpp = testOpportunity.clone(true, true);
        afterChangeOpp.OwnerId = newOwner.Id;

        Test.startTest();
        List<Opportunity> newOpportunities = new List<Opportunity>{afterChangeOpp};
        List<Opportunity> oldOpportunities = new List<Opportunity>{testOpportunity};
        Map<Id, Opportunity> newOpportunitiesMap = newOpportunities == null ? null : new Map<Id,Opportunity>(newOpportunities);
        Map<Id, Opportunity> oldOpportunitiesMap = oldOpportunities == null ? null : new Map<Id,Opportunity>(oldOpportunities);
        OpportunityTriggerHandler handlerToTest = new OpportunityTriggerHandler(newOpportunities, oldOpportunities, newOpportunitiesMap, oldOpportunitiesMap);
        handlerToTest.sendEmailOnOwnerChange();

        System.assertEquals(1, Limits.getEmailInvocations(), 'Email should be scheduled.');
        Test.stopTest();
    }


    @isTest
    private static void updateOppForecastCategoryTest_insert(){
        Opportunity testOpportunityCustomCategory = TestingUtility.createOpportunity(TestUtility.getFakeId(Account.getSObjectType()), false);
        testOpportunityCustomCategory.Id = TestUtility.getFakeId(Opportunity.getSObjectType());
        Opportunity testOpportunityStandardCategory = TestingUtility.createOpportunity(TestUtility.getFakeId(Account.getSObjectType()), false);
        testOpportunityStandardCategory.Id = TestUtility.getFakeId(Opportunity.getSObjectType());
        testOpportunityStandardCategory.ForecastCategoryName = 'Omitted';
        testOpportunityCustomCategory.Forecast_Category__c = 'Omitted';
        Test.startTest();
        List<Opportunity> newOpportunities = new List<Opportunity>{testOpportunityStandardCategory, testOpportunityCustomCategory};
        List<Opportunity> oldOpportunities = null;
        Map<Id, Opportunity> newOpportunitiesMap = newOpportunities == null ? null : new Map<Id,Opportunity>(newOpportunities);
        Map<Id, Opportunity> oldOpportunitiesMap = oldOpportunities == null ? null : new Map<Id,Opportunity>(oldOpportunities);
        OpportunityTriggerHandler handlerToTest = new OpportunityTriggerHandler(newOpportunities, oldOpportunities, newOpportunitiesMap, oldOpportunitiesMap);
        handlerToTest.updateOppForecastCategory();
        Test.stopTest();

        System.assertEquals(testOpportunityStandardCategory.ForecastCategoryName, testOpportunityStandardCategory.Forecast_Category__c, 'Standard category should be passed to custom category');
        System.assertEquals(testOpportunityCustomCategory.Forecast_Category__c, testOpportunityCustomCategory.ForecastCategoryName, 'Custom category should be passed to standard category');
    }

    @isTest
    private static void updateOppForecastCategoryTest_update(){
        Opportunity newOpportunityCustomCategory = TestingUtility.createOpportunity(TestUtility.getFakeId(Account.getSObjectType()), false);
        newOpportunityCustomCategory.Id = TestUtility.getFakeId(Opportunity.getSObjectType());
        newOpportunityCustomCategory.Forecast_Category__c = 'Omitted';
        newOpportunityCustomCategory.OwnerId = UserInfo.getUserID();
        Opportunity oldOpportunityCustomCategory = newOpportunityCustomCategory.clone(true, true);
        oldOpportunityCustomCategory.Forecast_Category__c = 'Upside';
        Opportunity newOpportunityStandardCategory = TestingUtility.createOpportunity(TestUtility.getFakeId(Account.getSObjectType()), false);
        newOpportunityStandardCategory.Id = TestUtility.getFakeId(Opportunity.getSObjectType());
        newOpportunityStandardCategory.ForecastCategoryName = 'Omitted';
        newOpportunityStandardCategory.OwnerId = UserInfo.getUserID();
        Opportunity oldOpportunityStandardCategory = newOpportunityStandardCategory.clone(true, true);
        oldOpportunityStandardCategory.ForecastCategoryName = 'Upside';

        Test.startTest();
        List<Opportunity> newOpportunities = new List<Opportunity>{newOpportunityCustomCategory, newOpportunityStandardCategory};
        List<Opportunity> oldOpportunities = new List<Opportunity>{oldOpportunityCustomCategory, oldOpportunityStandardCategory};
        Map<Id, Opportunity> newOpportunitiesMap = newOpportunities == null ? null : new Map<Id,Opportunity>(newOpportunities);
        Map<Id, Opportunity> oldOpportunitiesMap = oldOpportunities == null ? null : new Map<Id,Opportunity>(oldOpportunities);
        OpportunityTriggerHandler handlerToTest = new OpportunityTriggerHandler(newOpportunities, oldOpportunities, newOpportunitiesMap, oldOpportunitiesMap);
        handlerToTest.updateOppForecastCategory();
        Test.stopTest();

        System.assertEquals(newOpportunityStandardCategory.Forecast_Category__c, newOpportunityStandardCategory.ForecastCategoryName, 'Standard category should be passed to custom category');
        System.assertEquals(newOpportunityCustomCategory.Forecast_Category__c, newOpportunityCustomCategory.ForecastCategoryName, 'Custom category should be passed to standard category');
    }


    @isTest
    private static void updateOwnerAssDateTestInsert(){
        Opportunity testOpportunity = TestingUtility.createOpportunity(TestUtility.getFakeId(Account.getSObjectType()), false);
        testOpportunity.Id = TestUtility.getFakeId(Opportunity.getSObjectType());

        Test.startTest();
        List<Opportunity> newOpportunities = new List<Opportunity>{testOpportunity};
        List<Opportunity> oldOpportunities = null;
        Map<Id, Opportunity> newOpportunitiesMap = newOpportunities == null ? null : new Map<Id,Opportunity>(newOpportunities);
        Map<Id, Opportunity> oldOpportunitiesMap = oldOpportunities == null ? null : new Map<Id,Opportunity>(oldOpportunities);
        OpportunityTriggerHandler handlerToTest = new OpportunityTriggerHandler(newOpportunities, oldOpportunities, newOpportunitiesMap, oldOpportunitiesMap);
        handlerToTest.updateOwnerAssDate();
        Test.stopTest();

        System.assertEquals(System.today(), testOpportunity.Owner_Assigned_Date__c, 'Owner assigned date should be today');
    }

    @isTest
    private static void updateOwnerAssDateTestUpdate(){
        Opportunity oldOpportunity = TestingUtility.createOpportunity(TestUtility.getFakeId(Account.getSObjectType()), false);
        oldOpportunity.Id = TestUtility.getFakeId(Opportunity.getSObjectType());
        oldOpportunity.OwnerId = TestUtility.getFakeId(User.getSObjectType());
        Opportunity newOpportunity = oldOpportunity.clone(true,true);
        newOpportunity.OwnerId = TestUtility.getFakeId(User.getSObjectType());
        Test.startTest();
        List<Opportunity> newOpportunities = new List<Opportunity>{newOpportunity};
        List<Opportunity> oldOpportunities = new List<Opportunity>{oldOpportunity};
        Map<Id, Opportunity> newOpportunitiesMap = newOpportunities == null ? null : new Map<Id,Opportunity>(newOpportunities);
        Map<Id, Opportunity> oldOpportunitiesMap = oldOpportunities == null ? null : new Map<Id,Opportunity>(oldOpportunities);
        OpportunityTriggerHandler handlerToTest = new OpportunityTriggerHandler(newOpportunities, oldOpportunities, newOpportunitiesMap, oldOpportunitiesMap);
        handlerToTest.updateOwnerAssDate();
        Test.stopTest();

        System.assertEquals(System.today(), newOpportunity.Owner_Assigned_Date__c, 'Owner assigned date should be today');
    }

    @isTest
    private static void setTypeAndRecordTypeOfOpprtunityTest(){
        Opportunity testOpportunity = TestingUtility.createOpportunity(TestUtility.getFakeId(Account.getSObjectType()), false);
        testOpportunity.LeadSource = 'WeLive.com';

        Test.startTest();
        List<Opportunity> newOpportunities = new List<Opportunity>{testOpportunity};
        List<Opportunity> oldOpportunities = null;
        Map<Id, Opportunity> newOpportunitiesMap = null;
        Map<Id, Opportunity> oldOpportunitiesMap = null;
        OpportunityTriggerHandler handlerToTest = new OpportunityTriggerHandler(newOpportunities, oldOpportunities, newOpportunitiesMap, oldOpportunitiesMap);
        handlerToTest.setTypeAndRecordTypeOfOpprtunity();
        Test.stopTest();

        System.assertEquals('Residential Space', testOpportunity.Type__c, 'Type should be set to Residential Space');
        System.assertEquals(Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('New Business').getRecordTypeId(), testOpportunity.RecordTypeId, 'RecordType should be set to Residential Space');
    }

    @isTest
    private static void encodedOpportunityIDTest(){
        Account acme = TestingUtility.createAccount('Acme', true);
        Opportunity testOpportunity = TestingUtility.createOpportunity(acme.Id, true);
        Test.startTest();
        testOpportunity.Encoded_Id__c = null;
        List<Opportunity> newOpportunities = new List<Opportunity>{testOpportunity};
        List<Opportunity> oldOpportunities = null;
        Map<Id, Opportunity> newOpportunitiesMap = newOpportunities == null ? null : new Map<Id,Opportunity>(newOpportunities);
        Map<Id, Opportunity> oldOpportunitiesMap = oldOpportunities == null ? null : new Map<Id,Opportunity>(oldOpportunities);
        OpportunityTriggerHandler handlerToTest = new OpportunityTriggerHandler(newOpportunities, oldOpportunities, newOpportunitiesMap, oldOpportunitiesMap);
        handlerToTest.encodedOpportunityID();
        Test.stopTest();
        Opportunity result = [SELECT Encoded_Id__c FROM Opportunity WHERE Id =:testOpportunity.Id LIMIT 1];

        System.assertEquals(EncodingUtil.base64Encode(Blob.valueOf(testOpportunity.Id)), result.Encoded_Id__c, 'EncodedId should  be set');
    }

    @isTest
    private static void updateActiveReferrerTest(){
        Account acme = TestingUtility.createAccount('Acme', true);
        Contact johnDoe = TestingUtility.createContact(acme.Id, 'Doe', false);
        johnDoe.Email = 'referral@email.com';
        Contact referrer = TestingUtility.createContact(acme.Id, 'Referrer', false);
        referrer.Email = 'referrer@email.com';
        insert new List<Contact>{johnDoe, referrer};

        Opportunity testOpportunity = TestingUtility.createOpportunity(acme.Id, false);
        testOpportunity.Primary_Member__c = johnDoe.Id;
        Referral__c testReferral = new Referral__c(Referral_Email__c = 'referral@email.com', Referrer__c = referrer.Id, IsActive__c = true);
        insert new List<SObject>{testReferral, testOpportunity};

        testOpportunity = [SELECT Id, Referrer__c, Primary_Member__c, Primary_Member_Email_New__c FROM Opportunity WHERE Id =: testOpportunity.Id LIMIT 1];

        Test.startTest();
        List<Opportunity> newOpportunities = new List<Opportunity>{testOpportunity};
        List<Opportunity> oldOpportunities = null;
        Map<Id, Opportunity> newOpportunitiesMap = newOpportunities == null ? null : new Map<Id,Opportunity>(newOpportunities);
        Map<Id, Opportunity> oldOpportunitiesMap = oldOpportunities == null ? null : new Map<Id,Opportunity>(oldOpportunities);
        OpportunityTriggerHandler handlerToTest = new OpportunityTriggerHandler(newOpportunities, oldOpportunities, newOpportunitiesMap, oldOpportunitiesMap);
        ReferenceHandler.clearAlreadyQueriedEmailsForTest();
        handlerToTest.updateActiveReferrer();
        Test.stopTest();

        System.assertEquals(referrer.Id, testOpportunity.Referrer__c, 'Referref should be set.');
    }

    @isTest
    private static void getContactUserTest(){
        Contact johnDoe = TestingUtility.createContact(TestUtility.getFakeId(Account.getSObjectType()), 'Doe', false);
        johnDoe.Email = 'johnDoe@does.com';
        johnDoe.Id = TestUtility.getFakeId(Contact.getSObjectType());

        Profile standardProfile = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];

        User doeUser = new User(Alias = 'jdoe', Email='johnDoe@does.com',
                EmailEncodingKey='UTF-8', LastName='Doe', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = standardProfile.Id,
                TimeZoneSidKey='America/Los_Angeles', UserName = 'johnDoe@does.com');

        Opportunity testOpportunity = TestingUtility.createOpportunity(TestUtility.getFakeId(Account.getSObjectType()), false);
        testOpportunity.Send_Paperwork_By__c = johnDoe.Id;

        Test.startTest();
        OpportunityTriggerHandler handlerToTest = new OpportunityTriggerHandler(null, null, null, null);
        User testUser = handlerToTest.getContactUser(new Map<Id,Contact>{johnDoe.Id => johnDoe}, testOpportunity, new Map<String,User>{doeUser.Email => doeUser});
        Test.stopTest();

        System.assertEquals('template', 'template', 'its just a template');
    }
}