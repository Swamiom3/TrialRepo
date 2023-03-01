/**
 * @description Unit tests for the trac_ContentDocumentLink class
 * @see trac_ContentDocumentLink
 * @author Daniel Labonte, Traction on Demand
 * @date 2020-03-03
 */

@IsTest
private class trac_ContentDocumentLinkTest {
    static final TLTestFactory FACTORY = new TLTestFactory();

    @IsTest
    static void testInsertLink() {
        Automation_Settings__c settings = Automation_Settings__c.getInstance() != null ? Automation_Settings__c.getInstance() : new Automation_Settings__c();
        settings.Process_Builders_Disabled__c = true;
        upsert settings;
        
        SObjectDomain.getTriggerEvent(trac_Case.class).disableAll();
        Case parentCase = (Case) FACTORY.createSObject(new Case(Subject = 'Test Case'),true);

        ContentVersion content = new ContentVersion();
        content.Title='My_File';
        content.PathOnClient='/' + content.Title + '.jpg';
        content.VersionData=Blob.valueOf('PIXELS EVERYWHERE');
        content.Origin = 'H';
        insert content;

        content = [SELECT ContentDocumentId FROM ContentVersion];

        SObjectDomain.getTriggerEvent(trac_ContentDocumentLink.class).disableAll();
        ContentDocumentLink link = new ContentDocumentLink();
        link.LinkedEntityId = parentCase.Id;
        link.ContentDocumentId = content.ContentDocumentId;
        insert link;


        SObjectDomain.getTriggerEvent(trac_ContentDocumentLink.class).enableAll();
        Test.startTest();
        trac_ContentDocumentLink linkTrigger = new trac_ContentDocumentLink(new List<ContentDocumentLink>{link});
        SObjectDomain.triggerHandler(
                linkTrigger,
                false,
                true,
                true,
                false,
                false,
                false,
                new Map<Id,SObject>{link.Id => link});
        System.assert(linkTrigger.linkEvents.size() > 0, 'No events were published');
        Test.stopTest();
    }
}