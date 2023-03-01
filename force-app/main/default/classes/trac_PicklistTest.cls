@isTest
public class trac_PicklistTest {
    @isTest
    public static void tracpicklistTest(){
        trac_Picklist tracpic = new trac_Picklist();
        List<String> stringList = new List<String>();
        Test.startTest();
        stringList = trac_Picklist.getPicklistValueBasedUponRecordType('Case','Id','Support_Request');
        String val= trac_Picklist.decimalToBinary(10);
        String val1 =  trac_Picklist.base64ToBits('Test');
        Map<String,List<String>> returnmap = new Map<String,List<String>>();
        returnmap = trac_Picklist.getDependentMap('Case','Category__c','Case_Type__c');
        trac_Picklist.PicklistEntryWrapper entrywrapper = new trac_Picklist.PicklistEntryWrapper();
        entrywrapper.active= 'test';
        entrywrapper.defaultValue= 'test 1';
        entrywrapper.label= 'test 2';
        entrywrapper.value = 'test 3';
        Test.stopTest();
    }

}