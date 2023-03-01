/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for PersonEndpointHelper class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR            DETAIL
    1          8 Aug, 2021    Pawel Biszczak    Initial Deployment
**************************************************************************************************************************************/
@IsTest
public with sharing class PersonEndpointHelperTest {

    @IsTest
    public static void shouldManagePerson(){
        Map<String, String> personParameters;
        RESTAPIPersonModelsV2.Input personInput = getFakePersonInput();
        List<Contact> contacts = getFakeContacts(false);
        Contact firstContact = contacts[0];
        firstContact.Email = personInput.email;
        firstContact.FirstName = 'Test First Name';
        firstContact.LastName = 'Test';
        TestingUtility.insertWithAssert(firstContact);

        Test.startTest();
        PersonEndpointHelper.contactSelector = (ContactSelector) MockService.createMock(
                        ContactSelector.class,
                        new Map<String, Object> { 'getContactsWithPersonFieldsByEmails' => new List<Contact>{ firstContact },
                                                  'getContactsWithPersonFieldsByIds' => new List<Contact>{ firstContact }});
        personParameters = PersonEndpointHelper.managePerson(personInput);
        Test.stopTest();

        System.assertEquals(personParameters.get('contact_sfid'), firstContact.Id, 'Parameter from payload body should be equal to contact Id');
    }

    @IsTest
    public static void shouldManagePersonOnNullResult(){
        Map<String, String> personParameters;
        RESTAPIPersonModelsV2.Input personInput = getFakePersonInput();
        List<Contact> contacts = getFakeContacts(true);
        Contact firstContact = contacts[0];
        firstContact.Email = personInput.email;
        firstContact.LastName = 'Test';

        Test.startTest();
        PersonEndpointHelper.contactSelector = (ContactSelector) MockService.createMock(
                ContactSelector.class,
                new Map<String, Object> { 'getContactsWithPersonFieldsByEmails' => new List<Contact>(),
                'getContactsWithPersonFieldsByIds' => new List<Contact>{ firstContact }});
        personParameters = PersonEndpointHelper.managePerson(personInput);
        Test.stopTest();

        System.assertEquals(personParameters.get('contact_sfid'), firstContact.Id, 'Parameter from payload body should be equal to contact Id');
    }

    @IsTest
    public static void shouldManagePersonWithBillingAccount(){
        RESTAPIPersonModelsV2.Input personInput = getFakePersonInput();
        List<Contact> contacts = getFakeContacts(false);
        Account parentBillingAcc = new Account();
        parentBillingAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();
        parentBillingAcc.Name = 'ParentAccTest';
        Account businessAcc = new Account();
        businessAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId();
        businessAcc.Name = 'ChildAccTest';

        insert new List<Account>{businessAcc, parentBillingAcc};
        
        Contact firstContact = contacts[0];
        firstContact.Email = personInput.email;
        firstContact.FirstName = 'First Name Test';
        firstContact.LastName = 'Test';
        firstContact.AccountID = businessAcc.Id;
        TestingUtility.insertWithAssert(firstContact);

        AccountContactRelation acr = new AccountContactRelation();
        acr.AccountId = parentBillingAcc.Id;
        acr.ContactId = firstContact.Id;
        acr.Roles = 'Primary Member';
        insert acr;

        Test.startTest();
        Map<String, String> personParameters = PersonEndpointHelper.managePerson(personInput);
        Test.stopTest();

        System.assertEquals(personParameters.get('contact_sfid'), firstContact.Id, 'Parameter from payload body should be equal to contact Id');
        System.assertEquals(personParameters.get('billing_account_sfid'), parentBillingAcc.Id, 'billing account parameter should be set');

        System.assertEquals(businessAcc.Id, [SELECT Ultimate_Parent_Org__c FROM Account WHERE Id = :parentBillingAcc.Id].Ultimate_Parent_Org__c ,'Ultimate_Parent_Org__c should be set');
    } 

    @IsTest
    public static void shouldFillContact(){
        Contact contactToFill = new Contact();

        Test.startTest();
        PersonEndpointHelper.fillContactByPerson(getFakePersonInput(), contactToFill);
        Test.stopTest();

        System.assert(contactToFill.Marketing_Consent__c, 'Marketing Consent should be true');
        System.assert(String.isNotBlank(contactToFill.Email), 'Email should not be empty');
    }

    @IsTest
    public static void shouldReturnContactFilledByPerson(){
        Contact contactToFill;

        Test.startTest();
        contactToFill = PersonEndpointHelper.getContactByPerson(getFakePersonInput());
        Test.stopTest();

        System.assert(contactToFill.Marketing_Consent__c, 'Marketing Consent should be true');
        System.assert(String.isNotBlank(contactToFill.Email), 'Email should not be empty');
    }

    /*

    Commented as not valid for orgC however might need to be adjusted in the future for existing mtd or account record type

    static List<Billing_Account__c> getFakeBillingAccounts(Boolean isFakeId) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Billing_Account__c');
        recordsData.put('numberOfRecords', 1);
        return MockTestingUtility.getRecords(recordsData, isFakeId);
    }
    */


    static List<Contact> getFakeContacts(Boolean isFakeId) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Contact');
        recordsData.put('numberOfRecords', 2);
        return MockTestingUtility.getRecords(recordsData, isFakeId);
    }

    private static RESTAPIPersonModelsV2.Input getFakePersonInput() {
        RESTAPIPersonModelsV2.Input fakePerson = new RESTAPIPersonModelsV2.Input();
        fakePerson.email='test@example.com';
        fakePerson.first_name='Joe';
        fakePerson.last_name='Doe';
        fakePerson.lead_source='WeWork.com';
        fakePerson.lead_source_detail='Book a Tour Form';
        fakePerson.phone='1234567891';
        fakePerson.type='Broker';
        fakePerson.utm_campaign_id ='12345';
        fakePerson.utm_campaign ='12345';
        fakePerson.utm_content ='12345';
        fakePerson.utm_medium ='12345';
        fakePerson.utm_source ='12345';
        fakePerson.utm_term ='12345';
        fakePerson.locale ='12345';
        fakePerson.country_code ='US';
        fakePerson.market ='US-NY';
        fakePerson.marketing_consent = 'true';
        fakePerson.email_opt_out = 'true';
        return fakePerson;
    }
}