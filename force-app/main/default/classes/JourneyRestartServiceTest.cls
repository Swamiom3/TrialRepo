@isTest
public with sharing class JourneyRestartServiceTest {
    
    @testSetup
    static void setup(){
        List<sObject> recordsToInsert = new List<sObject>();

        Test.startTest();
        recordsToInsert.addAll((List<Lead>)TestingUtility.getRecords(new map<String, Object>{'doInsert' => 'false', 'objName' => 'Lead', 'numberOfRecords' => '11'}));
        recordsToInsert.addAll((List<Contact>)TestingUtility.getRecords(new map<String, Object>{'doInsert' => 'false', 'objName' => 'Contact', 'numberOfRecords' => '11'}));
        if(!recordsToInsert.isEmpty()){
            insert recordsToInsert;
        }
        Test.stopTest();
    }

    @IsTest
    public static void restartJourneyForLeadTest(){
        Map<Id,Lead> leads = new Map<Id, Lead>([SELECT Id, Email, Campaign_Id__c FROM Lead LIMIT 5]);

        Test.startTest();
        JourneyRestartService journeyService = new JourneyRestartService();
        journeyService.restartJourneyForLead(leads.keySet());
        Test.stopTest();

        for (Journey__c item : [SELECT NMD_Next_Contact_Date__c FROM Journey__c WHERE Primary_Lead__c IN :leads.keySet()]) {
            System.assertEquals(Date.today(), item.NMD_Next_Contact_Date__c, 'Records should have Today date');
        }
    }

    @IsTest
    public static void restartJourneyForContactTest(){
        Map<Id,Contact> contacts = new Map<Id, Contact>([SELECT Id, Email FROM Contact LIMIT 5]);

        Test.startTest();
        JourneyRestartService journeyService = new JourneyRestartService();
        journeyService.restartJourneyForContact(contacts.keySet());
        Test.stopTest();

        for (Journey__c item : [SELECT NMD_Next_Contact_Date__c FROM Journey__c WHERE Primary_Contact__c IN :contacts.keySet()]) {
            System.assertEquals(Date.today(), item.NMD_Next_Contact_Date__c, 'Records should have Today date');
        }
    }
}