/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for UtilRecordType class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR            DETAIL
    1          16 Dec, 2021    Pawel Biszczak    Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class UtilRecordTypeTest {

    @isTest
    static void shouldProcessWithRecordTypesRetrieve(){
        String objectToTestName = Schema.SObjectType.Account.getName();

        Test.startTest();
            System.assert(!UtilRecordType.getSobjectActiveRecordTypes(objectToTestName).isEmpty(),
                          'Should retrieve active RecordTypes');
            System.assert(!UtilRecordType.getSobjectActiveRecordTypesById(objectToTestName).isEmpty(),
                          'Should retrieve active RecordTypes by Ids');
            System.assert(!UtilRecordType.getSobjectActiveRecordTypesByLabelNotLower(objectToTestName).isEmpty(),
                          'Should retrieve RecordTypes by labels');
            System.assert(!UtilRecordType.getSobjectActiveRecordTypesByLabelNotLowerById(objectToTestName).isEmpty(),
                          'Should retrieve RecordTypes by labels and Ids');
            System.assert(!UtilRecordType.getSobjectAllExistingRecordTypesById(objectToTestName).isEmpty(),
                          'Should retrieve existing RecordTypes by Ids');
        Test.stopTest();
    }

    @isTest
    static void shouldProcessWithRecordTypesRetrieveOnFakeObject(){
        String fakeObjectName = 'Fake Object Name';

        Test.startTest();
            System.assertEquals(UtilRecordType.getSobjectActiveRecordTypes(fakeObjectName), null,
                                'Should not retrieve active RecordTypes for fake object name');
            System.assertEquals(UtilRecordType.getSobjectActiveRecordTypesById(fakeObjectName), null,
                                'Should not retrieve active RecordTypes by Ids for fake object name');
            System.assertEquals(UtilRecordType.getSobjectActiveRecordTypesByLabelNotLower(fakeObjectName), null,
                                'Should not retrieve RecordTypes by labels for fake object name');
            System.assertEquals(UtilRecordType.getSobjectActiveRecordTypesByLabelNotLowerById(fakeObjectName), null,
                                'Should not retrieve RecordTypes by labels and Ids for fake object name');
            System.assertEquals(UtilRecordType.getSobjectAllExistingRecordTypesById(fakeObjectName), null,
                                'Should not retrieve existing RecordTypes by Ids');
        Test.stopTest();
    }
}