@isTest
public with sharing class RestartJourneyQueueableTest {
    static final String BATCH_FROM_CONTACT_TRIGGER = 'FROM_CONTACT_TRIGGER';
    static final String BATCH_FROM_LEAD_TRIGGER = 'FROM_LEAD_TRIGGER';

    @testSetup
    static void setup(){
        List<sObject> recordsToInsert = new List<sObject>();

        Test.startTest();
        recordsToInsert.addAll((List<Lead>)TestingUtility.getRecords(new map<String, Object>{'doInsert' => 'false', 'objName' => 'Lead', 'numberOfRecords' => '11'}));
        recordsToInsert.addAll((List<Lead>)TestingUtility.getRecords(new map<String,object>{'doInsert' => 'false','objName' => 'Lead', 'numberOfRecords'=> '1', 'mapFieldValues' => new map<String,List<Object>>{'Company'=> new List<Object>{'Accenture'},'LastName'=> new List<Object>{'warner'},'Email'=> new List<Object>{'davidwarner@example.com'}, 'LeadSource'=> new List<Object>{'WeWork.cn'},'Generate_Journey__c'=>new List<Object>{false}, 'Marketing_Consent__c'=>new List<Object>{True}}}));
        if(!recordsToInsert.isEmpty()){
            insert recordsToInsert;
        }
        Test.stopTest();
    }

    @IsTest
    public static void executeFromContactTest(){
        Map<Id,Lead> leads = new Map<Id, Lead>([SELECT Id, Email, Campaign_Id__c FROM Lead LIMIT 5]);

        Test.startTest();
        RestartJourneyQueueable queueableInstance = new RestartJourneyQueueable(leads.keySet(), BATCH_FROM_CONTACT_TRIGGER);
        queueableInstance.call('contacts', new Map<String, Object>{'leadIds' => leads.keySet(), 'source' => BATCH_FROM_CONTACT_TRIGGER});
        queueableInstance.execute(null);
        Test.stopTest();

        for (Journey__c item : [SELECT NMD_Next_Contact_Date__c FROM Journey__c WHERE Primary_Lead__c IN :leads.keySet()]) {
            System.assertEquals(Date.today(), item.NMD_Next_Contact_Date__c, 'Records should have Today date');
        }
    }

    @IsTest
    public static void executeFromLeadTest(){
        Map<Id,Lead> leads = new Map<Id, Lead>([SELECT Id, Email, Campaign_Id__c FROM Lead LIMIT 5]);

        Test.startTest();
        RestartJourneyQueueable queueableInstance = new RestartJourneyQueueable(leads.keySet());
        queueableInstance.call('leads', new Map<String, Object>{'leadIds' => leads.keySet()});
        queueableInstance.execute(null);
        Test.stopTest();

        for (Journey__c item : [SELECT NMD_Next_Contact_Date__c FROM Journey__c WHERE Primary_Lead__c IN :leads.keySet()]) {
            System.assertEquals(Date.today(), item.NMD_Next_Contact_Date__c, 'Records should have Today date');
        }
    }
}