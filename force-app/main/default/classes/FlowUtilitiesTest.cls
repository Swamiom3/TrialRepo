/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class has testmethods to cover FlowUtilities class
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           04/04/2022          Salesforce              Initial creation
**************************************************************************************************************************************/
@isTest
public with sharing class FlowUtilitiesTest {
    @testSetup
    static void setup() {
        EmailTemplate emailTemplate = new EmailTemplate (DeveloperName = 'Test_Template',isActive=True,FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'Test Template');        
        insert emailTemplate;        
    }            

    @isTest
    static void sendEmailNotification(){        
        Test.startTest();

        Profile profile = [Select Id from Profile WHERE Name = 'System Administrator'];

        User user = new User();
        user.FirstName = 'Test User';
        user.LastName = 'Number One';
        user.Email = 'testcontact@wework.com';
        user.Username = 'testcontact@wework.com';
        user.Alias = 'tester';        
        user.ProfileId = profile.Id;
        user.TimeZoneSidKey    = 'America/Denver';
        user.LocaleSidKey      = 'en_US';
        user.EmailEncodingKey  = 'UTF-8';
        user.LanguageLocaleKey = 'en_US';

        insert user;

        List<EmailInputsWrapper> emailInputsWrapper =  new List<EmailInputsWrapper>();
        EmailInputsWrapper emailInputWrapper =  new EmailInputsWrapper();
        Id templateId = [Select Id from EmailTemplate where DeveloperName = 'Test_Template' LIMIT 1].Id;
        Id fromAddressId = [Select Id from OrgWideEmailAddress where DisplayName = 'Do Not Reply'].Id;
                
        emailInputWrapper.fromAddress = fromAddressId;
        emailInputWrapper.targetObjectId = user.Id;
        emailInputWrapper.templateId = templateId;
        emailInputWrapper.toAddress = user.Email;

        emailInputsWrapper.add(emailInputWrapper);

        List<FlowUtilities.EmailInputsRequest> emailRequests = new List<FlowUtilities.EmailInputsRequest>();
        FlowUtilities.EmailInputsRequest emailRequest = new FlowUtilities.EmailInputsRequest();
        emailRequest.emailInputs = emailInputsWrapper;
        emailRequests.add(emailRequest);
        FlowUtilities.sendEmailNotification(emailRequests);
        
        Test.stopTest();
                
        System.assert(FlowUtilities.emailResults[0].isSuccess(), 'Email Message sent successfully');        
    }
}