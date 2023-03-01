/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for EmailTemplateSelector class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR            DETAIL
    1          6 Jul, 2021    Pawel Biszczak    Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class EmailTemplateSelectorTest {
    private static EmailTemplateSelector emailTemplateSelector = new EmailTemplateSelector();

    @isTest
    static void shouldGetRecordsDeveloperName() {
        List<EmailTemplate> templates;
        List<EmailTemplate> existingTemplates;

        Test.startTest();
        existingTemplates = [SELECT Id, DeveloperName
                             FROM EmailTemplate
                             LIMIT 1];
        templates = emailTemplateSelector.getEmailTemplatesByDeveloperNames(new List<String>{
                existingTemplates[0].DeveloperName
        });
        Test.stopTest();

        System.assert(!templates.isEmpty(), 'Template list should have some values');
        System.assertEquals(existingTemplates[0].Id, templates[0].Id, 'Template Id should have same value');
    }

    @isTest
    static void shouldRetrieveNoRecords() {
        List<EmailTemplate> templatesForFakeName;
        List<EmailTemplate> templatesForEmptyList;

        Test.startTest();
        templatesForFakeName = emailTemplateSelector.getEmailTemplatesByDeveloperNames(new List<String>{
                'Fake_DeveloperName_Name_For_EmailTemplateSelectorTest'
        });
        templatesForEmptyList = emailTemplateSelector.getEmailTemplatesByDeveloperNames(new List<String>());
        Test.stopTest();

        System.assert(templatesForFakeName.isEmpty(), 'List should be empty on fake email template name');
        System.assert(templatesForEmptyList.isEmpty(), 'List should be empty on empty email names list');
    }
}