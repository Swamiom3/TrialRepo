@isTest
private class TStringUtilsTest {
    @isTest
    static void testGetDependentOptions() {
        Test.startTest();
        Map<String, List<String>> leadSourceDependentOptions = TStringUtils.getDependentOptions('Lead', 'LeadSource', 'LeadSource_Sub_Type__c');
        Test.stopTest();
        System.assertNotEquals(null, leadSourceDependentOptions, 'Dependent options must be returned for Lead Source and Lead Source Subtype');
        System.assert(leadSourceDependentOptions.containsKey('WeWork.com'), 'WeWork.com must be one of lead source values returned');
        System.assert(!leadSourceDependentOptions.get('WeWork.com').isEmpty(), 'WeWork.com must have available dependent options');
    }

    @isTest
    static void testGetDependentOptionsInvalidParameters() {
        System.assertEquals(new Map<String, List<String>>(), TStringUtils.getDependentOptions('', 'LeadSource', 'LeadSource_Sub_Type__c'), 'No results should be returned for empty object parameter');
        System.assertEquals(new Map<String, List<String>>(), TStringUtils.getDependentOptions('Opportunity', '', ''), 'No results should be returned for empty field parameters');
    }
}