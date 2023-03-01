/*************************************************************************************************************************************
    Author      :   Anant Kumar
    Description :   This class provides sufficient test coverage for ReferenceHandler class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             DETAIL
    1          20 Jun, 2016    Anant Kumar        Initial Deployment
    2          13 Jan, 2022    Pawel Biszczak     Refactor
**************************************************************************************************************************************/
@isTest
private class ReferenceHandlerTest {

    @isTest
    static void shouldGetActiveReference() {
        TestingUtility.createAccount('strAccountName', true);
        Contact referrer1 = new Contact();
        referrer1.FirstName = 'First Name Test1';
        referrer1.LastName = 'referrer1';
        referrer1.Email = 'referrer1@example.com';
        TestingUtility.insertWithAssert(referrer1);

        Contact referrer2 = new Contact();
        referrer2.FirstName = 'First Name Test2';
        referrer2.LastName = 'referrer2';
        referrer2.Email = 'referrer2@example.com';
        TestingUtility.insertWithAssert(referrer2);

        Referral__c reference1 = new Referral__c();
        reference1.Referral_Email__c = 'reference1@example.com';
        reference1.IsActive__c = true;
        reference1.Referrer__c = referrer1.Id;
        reference1.Expires_On__c = Date.today().addDays(10);
        TestingUtility.insertWithAssert(reference1);

        Referral__c reference2 = new Referral__c();
        reference2.Referral_Email__c = 'reference2@example.com';
        reference2.IsActive__c = false;
        reference2.Referrer__c = referrer1.Id;
        reference2.Expires_On__c = Date.today().addDays(10);
        TestingUtility.insertWithAssert(reference2);

        Set<String> emails = new Set<String>();
        emails.add(reference1.Referral_Email__c);
        emails.add(reference2.Referral_Email__c);
        Map<String, Id> mapReferrer;

        Test.startTest();
        ReferenceHandler.ExtendReference(emails);
        ReferenceHandler.ExtendReference(reference1.Id, Date.today(), Date.today());
        mapReferrer = ReferenceHandler.getActiveReference(emails);
        Test.stopTest();

        System.assertEquals(referrer1.Id, mapReferrer.get(reference1.Referral_Email__c));
        System.assertEquals(referrer1.Id, ReferenceHandler.getActiveReference(reference1.Referral_Email__c));
        System.assertEquals(null, ReferenceHandler.getActiveReference(reference2.Referral_Email__c));
    }

    @isTest
    static void shouldGetNoActiveReferences() {
        Set<String> emails = new Set<String>();
        emails.add('fakeReference@example.com');
        Map<String, Id> mapReferrer;

        Test.startTest();
        ReferenceHandler.ExtendReference(emails);
        mapReferrer = ReferenceHandler.getActiveReference(emails);
        Test.stopTest();

        System.assertEquals(null, ReferenceHandler.getActiveReference('fakeReference@example.com'));
    }
}