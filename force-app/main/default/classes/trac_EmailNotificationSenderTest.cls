/**
* Test Class for trac_EmailNotificationSender.
* @author Shubham Jain, Traction on Demand
* @date 10/23/2019
*/

@IsTest
public with sharing class trac_EmailNotificationSenderTest {
    
    static final TLTestFactory factory = new TLTestFactory();
    @testSetup static void unitTestSetup(){
        Account acc = new Account (LastName= 'Test', RecordTypeId = TLOrgConstants.PERSON_ACCOUNT_RECORD_TYPE_ID, PersonEmail = 'test@tractionondemand.com');
        insert acc;
        Contact con = [SELECT Id, LastName FROM Contact WHERE LastName = 'Test' LIMIT 1];
        Case cs = (Case) factory.createSObject(new Case(Subject = 'Test', contactId = con.Id), true);
    }
    @isTest public static void unitTest(){
        trac_EmailNotificationSender.Inputs inp = new trac_EmailNotificationSender.Inputs();
        List<trac_EmailNotificationSender.Inputs> lstInputs = new List<trac_EmailNotificationSender.Inputs>();
    
        Case cs = [SELECT Id, contactId FROM Case WHERE Subject = 'Test' LIMIT 1];
        EmailTemplate et = [SELECT Id FROM EmailTemplate LIMIT 1];
        
        inp.supportRequestId = cs.Id;
        inp.targetObjectId = cs.contactId;
        inp.templateId = et.Id;
        inp.toAddress = 'test@tractionondemand.com';
        lstInputs.add(inp);
        
        Test.startTest();
        trac_EmailNotificationSender.sendEmailNotification(lstInputs);
        System.assertEquals(1, Limits.getEmailInvocations(), 'Success');
        Test.stopTest();
    }
    
    @isTest public static void exceptionTest(){
        trac_EmailNotificationSender.Inputs inp = new trac_EmailNotificationSender.Inputs();
        List<trac_EmailNotificationSender.Inputs> lstInputs = new List<trac_EmailNotificationSender.Inputs>();
        
        Case cs = [SELECT Id, contactId FROM Case WHERE Subject = 'Test' LIMIT 1];
        
        inp.supportRequestId = cs.Id;
        inp.targetObjectId = cs.contactId;
        inp.toAddress = 'test@tractionondemand.com';
        lstInputs.add(inp);
        
        Test.startTest();
        trac_EmailNotificationSender.sendEmailNotification(lstInputs);
        
        Test.stopTest();
//        System.assertEquals(0, Limits.getEmailInvocations(), 'Success');
    }
}