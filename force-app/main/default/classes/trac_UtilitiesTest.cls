/**
 * @description unit tests for the trac_Utilities class
 * @name trac_UtilitiesTest
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-09-25
 */
@IsTest
public with sharing class trac_UtilitiesTest {
    static final TLTestFactory factory = new TLTestFactory();

    static final String CREDIT_CARD_VISA         = '4111-1111-1111-1111';
    static final String CREDIT_CARD_CARTEBLANCHE = '3000 0000 0000 04';
    static final String CREDIT_CARD_ENROUTE      = '201400000000009';

    @IsTest
    static void testQuickExit() {
        System.assert(trac_Utilities.QuickExit() == null);
    }

    @IsTest
    static void testMaskCreditCardNumbersCase() {
        Case cs = (Case) factory.createSObject(new Case(),false);

        for(Schema.FieldSetMember field : Schema.SObjectType.Case.fieldSets.Credit_Card_Mask_Fields.getFields()) {
            cs.put(field.getFieldPath(),'Test' + CREDIT_CARD_VISA + ' test');
        }

        Test.startTest();
        insert cs;
        Test.stopTest();

        Case caseInDatabase = [SELECT Subject, Description FROM Case WHERE Id = :cs.Id];
        for(Schema.FieldSetMember field : Schema.SObjectType.Case.fieldSets.Credit_Card_Mask_Fields.getFields()) {
            System.assert(!String.valueOf(cs.get(field.getFieldPath())).contains('\\d'), 'The case '+ String.valueOf(cs.get(field.getFieldPath())) +' contains digits, meaning the credit card number was not masked');
        }

        System.assert(!caseInDatabase.Description.contains('\\d'), 'The case subject contains digits, meaning the credit card number was not masked');
    }

    @IsTest
    static void testMaskCreditCardNumbersEmailMessage() {
        EmailMessage message = (EmailMessage) factory.createSObject(new EmailMessage(),false);
        message.Subject = 'Test ' + CREDIT_CARD_VISA + ' test';
        message.TextBody = 'Test description no digits and no space' + CREDIT_CARD_CARTEBLANCHE + 'test description no digits and no space' + CREDIT_CARD_ENROUTE;

        Test.startTest();
        insert message;
        Test.stopTest();

        EmailMessage messageInDatabase = [SELECT Subject, TextBody FROM EmailMessage WHERE Id = :message.Id];
        System.assert(!messageInDatabase.Subject.contains('\\d'), 'The case subject contains digits, meaning the credit card number was not masked');
        System.assert(!messageInDatabase.TextBody.contains('\\d'), 'The case subject contains digits, meaning the credit card number was not masked');
    }
    @isTest
    private static void testUtilitiesMethod2(){
        trac_Utilities traUtil = new trac_Utilities();
        String toAddress ='test.test@gmail.com';
        String subject ='Test';
        String message ='Test';
        String templateId ;
        String parentId ;
        List<User> users = TLTestUtils.createUsers(null, 1, true);
        User u =users[0];
        system.runas(u){
            EmailTemplate e = new EmailTemplate (developerName = 'test',isActive=True,FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'test'); // plus any other fields that you want to set
            insert e;
            templateId=e.id;
        }
        Case c= new Case();
        insert c;
        Account acc = new Account();
        acc.Name ='Test';
        insert acc;
        String Caseid = acc.id;
        List<SObject> sobjects= new List<SObject>();
        Account a = new Account();
        sobjects.add(a);
        Set<String> fieldsToCheck= new  Set<String>();
        fieldsToCheck.add('name');
        trac_Utilities.maskCreditCardNumbers(sobjects, fieldsToCheck);
        List<Case> caselist = new List<Case>();
        caselist.add(c);
        trac_Utilities.sendMail(toAddress,subject,message,c);
        trac_Utilities.sendMail(toAddress,subject,message,caselist);
        trac_Utilities.sendMail(toAddress,message,c);
        trac_Utilities.sendMailNotification('test@123.com',userinfo.getUserId(),templateId);
    }  
}