/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for EmailService class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR            DETAIL
    1          5 Jul, 2021    Pawel Biszczak    Initial Deployment
**************************************************************************************************************************************/
@IsTest
public with sharing class EmailServiceTest {

    private static final String FIRST_TEMPLATE_DEVELOPER_NAME = 'Test_Template_1';
    private static final String SECOND_TEMPLATE_DEVELOPER_NAME = 'Test_Template_2';
    @testSetup 
    public static void setup() {
        Profile integrationProfile = [SELECT Id FROM Profile WHERE Name='WeWork Integration User'];		
        User integrationUser = new User(Alias = 'testU', Email='test2137@test.com', 
                                  EmailEncodingKey='UTF-8', LastName='UserIntegrationTest', LanguageLocaleKey='en_US', 
                                  LocaleSidKey='en_US', ProfileId = integrationProfile.Id, IsActive = true,
                                  TimeZoneSidKey='America/Los_Angeles', UserName='test2137@test.com.servicetest');

        Profile standardProfile = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User standardUser = new User(Alias = 'testU', Email='test213712@test.com', 
                                  EmailEncodingKey='UTF-8', LastName='UserStandardTest', LanguageLocaleKey='en_US', 
                                  LocaleSidKey='en_US', ProfileId = standardProfile.Id, IsActive = true,
                                  TimeZoneSidKey='America/Los_Angeles', UserName='test213712@test.com.servicetest');
        insert standardUser;
        insert integrationUser;
    }

    @isTest
    public static void shouldFetchEmailTemplates() {
        List<EmailTemplate> emailTemplates = getFakeEmailTemplates();
        emailTemplates[0].DeveloperName = FIRST_TEMPLATE_DEVELOPER_NAME;
        emailTemplates[1].DeveloperName = SECOND_TEMPLATE_DEVELOPER_NAME;
        emailTemplates[0].IsActive = false;
        emailTemplates[1].IsActive = true;
        Map<String, EmailTemplate> retrievedTemplates;
        Map<String, EmailTemplate> templatesRetrievedForSecondTime;

        Test.startTest();
        EmailService.emailTemplateSelector =
                (EmailTemplateSelector) MockService.createMock(
                        EmailTemplateSelector.class,
                        new Map<String, Object>{
                                'getEmailTemplatesByDeveloperNames' => emailTemplates
                        });
        retrievedTemplates = EmailService.getEmailTemplatesByDeveloperName(new Set<String>{
                FIRST_TEMPLATE_DEVELOPER_NAME, SECOND_TEMPLATE_DEVELOPER_NAME
        });
        templatesRetrievedForSecondTime = EmailService.getEmailTemplatesByDeveloperName(new Set<String>{
                FIRST_TEMPLATE_DEVELOPER_NAME, SECOND_TEMPLATE_DEVELOPER_NAME
        });
        Test.stopTest();

        System.assertEquals(retrievedTemplates.size(), 2, 'Should retrieve 2 records from database');
        System.assertEquals(templatesRetrievedForSecondTime.size(), 2, 'Should retrieve 2 records on already queried templates check');
        System.assertEquals(EmailService.alreadyQueriedTemplates.size(), 2, 'Already queried templates should contain 2 names after dml');
        System.assertEquals(retrievedTemplates.get(FIRST_TEMPLATE_DEVELOPER_NAME).DeveloperName, FIRST_TEMPLATE_DEVELOPER_NAME, 'Value should be equal to first template name');
        System.assertEquals(retrievedTemplates.get(SECOND_TEMPLATE_DEVELOPER_NAME).DeveloperName, SECOND_TEMPLATE_DEVELOPER_NAME, 'Value should be equal to second template name');
        System.assertEquals(retrievedTemplates.get(SECOND_TEMPLATE_DEVELOPER_NAME).IsActive, true, 'Second retrieved template should be active');
    }


    @isTest
    public static void shouldFetchSingleTemplate() {
        List<EmailTemplate> emailTemplates = getFakeEmailTemplates();
        emailTemplates[0].DeveloperName = FIRST_TEMPLATE_DEVELOPER_NAME;
        emailTemplates[1].DeveloperName = SECOND_TEMPLATE_DEVELOPER_NAME;
        emailTemplates[0].IsActive = false;
        emailTemplates[1].IsActive = true;
        EmailTemplate retrievedTemplate;

        Test.startTest();
        EmailService.emailTemplateSelector =
                (EmailTemplateSelector) MockService.createMock(
                        EmailTemplateSelector.class,
                        new Map<String, Object>{
                                'getEmailTemplatesByDeveloperNames' => emailTemplates
                        });
        retrievedTemplate = EmailService.getEmailTemplateByDeveloperName(FIRST_TEMPLATE_DEVELOPER_NAME);
        Test.stopTest();

        System.assertNotEquals(retrievedTemplate, null, 'Should retrieve template record');
        System.assertEquals(EmailService.alreadyQueriedTemplates.size(), 1, 'Should contain 1 template name');
        System.assertEquals(retrievedTemplate.DeveloperName, FIRST_TEMPLATE_DEVELOPER_NAME, 'Value should be equal to first template name');
    }

    @isTest
    public static void shouldReplaceEmailBody() {
        String emailBody = getFakeEmailBody();
        Messaging.SingleEmailMessage singleEmail = new Messaging.SingleEmailMessage();
        singleEmail.htmlBody = emailBody;
        Account testAccount = new Account();
        testAccount.Name = 'Test Account Name';
        Opportunity testOpportunity = new Opportunity();
        testOpportunity.Name = 'Test Opportunity';
        testOpportunity.Account = testAccount;
        testOpportunity.AccountId = testAccount.Id;

        Test.startTest();
        Map<String, String> replacementValues = new Map<String, String>();
        replacementValues.put('{Opportunity.Account.Name}', testOpportunity.Account.Name);
        replacementValues.put('{Opportunity.Name}', testOpportunity.Name);
        replacementValues.put('{Opportunity.OwnerId}', testOpportunity.OwnerId);

        singleEmail.htmlBody = new EmailService().replaceText(singleEmail.htmlBody, replacementValues);
        Test.stopTest();

        System.assert(String.isNotBlank(singleEmail.htmlBody), 'Html body should contain values after replacement');
        System.assert(singleEmail.htmlBody.contains(testOpportunity.Account.Name), 'Should contain Opportunity Account\'s Name');
        System.assert(!singleEmail.htmlBody.contains('{Opportunity.OwnerId}'), 'Should replace OwnerId to empty string and not thrown an error');
    }

    @isTest
    public static void shouldGetOrganizationWideDefaultAddressId() {
        Id orgWideAddressId;

        Test.startTest();
        orgWideAddressId = EmailService.getOrganizationWideDefaultAddressId();
        Test.stopTest();

        System.assertNotEquals(orgWideAddressId, null, 'Id for org wide address should not be null');
    }

    @isTest
    public static void shouldGetBaseUrl() {
        String baseurl;

        Test.startTest();
        baseUrl = EmailService.getBaseUrl();
        Test.stopTest();

        System.assertNotEquals(baseurl, null, 'baseUrl should not be null');
    }

    private static List<EmailTemplate> getFakeEmailTemplates() {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'EmailTemplate');
        recordsData.put('numberOfRecords', 2);
        return MockTestingUtility.getRecords(recordsData, true);
    }

    private static String getFakeEmailBody() {
       return '<p>You are receiving this test email because...</p>\n' +
               '<p><b>Email Details:</b><br/>\n' +
               'Test Account Name To Replace: {Opportunity.Account.Name}<br/>\n' +
               'Test Opportunity Name To Replace: {Opportunity.Name}<br/>\n' +
               'Test Opportunity OwnerID To Replace: {Opportunity.OwnerId}<br/>\n' +
               '</p>';
    }
    @IsTest
    static void validProfiles(){
        User integrationUser = [SELECT id,profileId from User WHERE LastName = 'UserIntegrationTest' LIMIT 1];
        User standardUser = [SELECT id,profileId from User WHERE LastName = 'UserStandardTest' LIMIT 1];
        Test.startTest();
        System.assertEquals(EmailService.isValidUserToSendEmailOnOwnerChange(integrationUser),false,'Return should be false');
        System.assertEquals(EmailService.isValidUserToSendEmailOnOwnerChange(standardUser),true,'Return should be true');
        System.assertEquals(EmailService.isValidUserToSendEmailOnOwnerChange(integrationUser.ProfileId),false,'Return should be false');
        System.assertEquals(EmailService.isValidUserToSendEmailOnOwnerChange(standardUser.ProfileId),true,'Return should be true');
        Test.stopTest();
    }

}