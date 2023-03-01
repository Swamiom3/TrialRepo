/**
 * Tests for TLSobj
 *
 * @author Grant Adamson, Traction on Demand
 * @date 2017-08-01
 * @modified Jeremy Horan, Traction on Demand - 2018-11-07
 * @group TLSObj
 */
@IsTest
private class TLSObjTest {
    private static final Map<SObjectField, SObjectField> TEST_FIELD_MAP = new Map<SObjectField, SObjectField>{
            Account.Name => Opportunity.Name
    };

    @IsTest
    private static void testCopyUsingMapping() {
        final Account a = new Account(Name = 'Test');
        final Opportunity o = new Opportunity();


        Test.startTest();

        TLSObj.copyUsingMapping(a, o, TEST_FIELD_MAP);

        Test.stopTest();


        System.assertEquals(a.Name, o.Name,
                'The appropriate field value was copied as per the field mapping');
    }

    @IsTest
    private static void testGetRecordTypeForName() {
        final RecordType[] testRTs = [SELECT Name, SobjectType FROM RecordType LIMIT 1];

        // If the org has no RTs, skip this test
        if(testRTs.isEmpty()) {
            return;
        }

        final RecordType testRT = testRTs[0];
        final SObjectType sobjType = ((SObject)Type.forName(testRT.SobjectType).newInstance()).getSObjectType();


        Test.startTest();

        final Id result = TLSObj.getRecordTypeIdForName(sobjType, testRT.Name);

        Test.stopTest();


        System.assertEquals(testRT.Id, result, 'An Id should be returned');
    }

    @IsTest
    private static void testGetRecordTypeForNameInvalid() {
        final String badRTName = 'A BAD RECORD TYPE THAT DOES NOT EXIST';

        Test.startTest();

        String exceptionMsg;
        try {
            TLSObj.getRecordTypeIdForName(Account.SObjectType, badRTName);
        } catch(Exception e) {
            exceptionMsg = e.getMessage();
        }

        System.assertEquals('Invalid record type name "' + badRTName + '" for SObject type "Account"', exceptionMsg,
                'The correct error message should be generated');
    }

    @IsTest
    private static void testGetRecordTypeForDeveloperName() {
        final RecordType[] testRTs = [SELECT DeveloperName, SobjectType FROM RecordType LIMIT 1];

        // If the org has no RTs, skip this test
        if(testRTs.isEmpty()) {
            return;
        }

        final RecordType testRT = testRTs[0];
        final SObjectType sobjType = ((SObject)Type.forName(testRT.SobjectType).newInstance()).getSObjectType();


        Test.startTest();

        final Id result = TLSObj.getRecordTypeIdForDeveloperName(sobjType, testRT.DeveloperName);

        Test.stopTest();


        System.assertEquals(testRT.Id, result, 'An Id should be returned');
    }

    @IsTest
    private static void testGetRecordTypeForDeveloperNameInvalid() {
        final String badRTDeveloperName = 'A BAD RECORD TYPE THAT DOES NOT EXIST';

        Test.startTest();

        String exceptionMsg;
        try {
            TLSObj.getRecordTypeIdForDeveloperName(Account.SObjectType, badRTDeveloperName);
        } catch(Exception e) {
            exceptionMsg = e.getMessage();
        }

        System.assertEquals('Invalid record type name "' + badRTDeveloperName + '" for SObject type "Account"',
                exceptionMsg, 'The correct error message should be generated');
    }

    @IsTest
    private static void testGetFieldValue() {
        final Account parentAccount = new Account(Name = 'test');
        final Account account = new Account(Name = 'test', Parent = parentAccount);

        Test.startTest();

        final String result = (String)TLSObj.getFieldValue(account, 'Name');
        final String parentResult = (String)TLSObj.getFieldValue(account, 'Parent.Name');
        final String nullResult = (String)TLSObj.getFieldValue(null, 'Name');

        Test.stopTest();

        System.assertEquals(account.Name, result, 'The result should be the value of the name field');
        System.assertEquals(parentAccount.Name, parentResult, 'The result should be the value of the parent name field');
        System.assertEquals(null, nullResult, 'The result should be null');
    }

    @IsTest
    static void testCopyFieldValues() {
        String contactJson ='{' +
                '"AccountId":"001f4000002W5brAAC",' +
                '"Id":"003f4000001rSZ6AAM",' +
                '"Account":{' +
                '"Id":"001f4000002W5brAAC",' +
                '"Name":"Spruce Household"' +
                '}' +
                '}';
        Contact source = (Contact) JSON.deserialize(contactJson, Contact.class);
        Contact destination = new Contact(FirstName='test');
        Map<String, SObjectField> sourceToDest = new Map<String, SObjectField> {
                'Account.Name' => Contact.FirstName
        };
        TLSObj.copyFieldValues(source, destination, sourceToDest);
        System.assertEquals('Spruce Household', destination.FirstName);
    }

    @IsTest
    static void isEqualUsingMappingTrue() {
        final Account a = new Account(Name = 'Test');
        final Opportunity o = new Opportunity(Name = 'Test');

        Boolean result;

        Test.startTest();

        result = TLSObj.isEqualUsingMapping(a, o, TEST_FIELD_MAP);

        Test.stopTest();

        System.assertEquals(true, result, 'The method should return true when the fields match');
    }

    @IsTest
    static void isEqualUsingMappingFalse() {
        final Account a = new Account(Name = 'Test');
        final Opportunity o = new Opportunity(Name = 'Different');

        Boolean result;

        Test.startTest();

        result = TLSObj.isEqualUsingMapping(a, o, TEST_FIELD_MAP);

        Test.stopTest();

        System.assertEquals(false, result, 'The method should return false when the fields match');
    }

    @IsTest
    static void getSObjectTypeForName() {
        final String sobjectTypeString = 'AccounT'; // case should not matter

        SObjectType result = TLSObj.getSObjectTypeForName(sobjectTypeString);

        System.assertEquals(Account.SObjectType, result, 'The correct SObjectType should be returned');
    }

    @IsTest
    static void getSObjectTypeForNameInvalidType() {
        final String invalidSObjectTypeString = 'BAD';

        SObjectType result = TLSObj.getSObjectTypeForName(invalidSObjectTypeString);

        System.assertEquals(null, result, 'The method should return null if no corresponding SObjectType can be found');
    }

    @IsTest
    static void getRecordTypeId() {
        final Id aCaseRecordTypeId = Case.SObjectType.getDescribe().getRecordTypeInfos()[0].getRecordTypeId();
        final Case c = new Case(RecordTypeId = aCaseRecordTypeId);
        final ApexClass cls = new ApexClass();

        System.assertEquals(aCaseRecordTypeId, TLSObj.getRecordTypeId(c),
                'It should return the record type Id for records that have one');
        System.assertEquals(null, TLSObj.getRecordTypeId(cls),
                'It should return null for SObject types that do not have record types');
    }

    @IsTest
    static void getSObjectFieldForName() {
        final String sobjectFieldString = 'NAMe'; // case should not matter

        SObjectField result = TLSObj.getSObjectFieldForName(Account.SObjectType, sobjectFieldString);

        System.assertEquals(Account.Name, result, 'The correct SObjectField value should be returned');
    }

    @IsTest
    static void getSObjectFieldForNameInvalid() {
        final String sobjectFieldString = 'ThisIsABadFieldName'; // case should not matter

        SObjectField result = TLSObj.getSObjectFieldForName(Account.SObjectType, sobjectFieldString);

        System.assertEquals(null, result, 'The method should return null if no corresponding SObjectField can be found');
    }
}