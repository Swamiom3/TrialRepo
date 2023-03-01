/**
 * Created by pbisz on 11/5/2021.
 */
@isTest
public with sharing class LeadConversionAsyncQueueableTest {
    private static final String BATCH_FROM_CONTACT_TRIGGER = 'FROM_CONTACT_TRIGGER';

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
    public static void shouldProceedWithLeadConversionAsyncUsingExecutor(){
        AsyncsExecutor executorInstance;

        Test.startTest();
        executorInstance= new AsyncsExecutor(
                LeadConversionAsyncQueueable.class,
                'leads',
                new Map<String, Object>{
                        'leads'=> [SELECT Id, Email, Campaign_Id__c
                                   FROM Lead
                                   LIMIT 5],
                        'source'=> BATCH_FROM_CONTACT_TRIGGER});
        executorInstance.execute();

        Test.stopTest();

        System.assertNotEquals(executorInstance.queueableInstance, null, 'Should be executed in async scope');
    }

    @IsTest
    public static void shouldProceedWithLeadConversionAsyncUsingCallMethod(){
        Map<String, Object> args;

        Test.startTest();
        LeadConversionAsyncQueueable queueableInstance = new LeadConversionAsyncQueueable();
        args = new Map<String, Object>{
                'leads'=> [SELECT Id, Email, Campaign_Id__c
                           FROM Lead
                           LIMIT 5],
                'source'=> BATCH_FROM_CONTACT_TRIGGER};
        queueableInstance = queueableInstance.call('leads' , args);
        queueableInstance.execute(null);
        Test.stopTest();

        System.assert(!LeadConverterHelper.isCreateActivity, 'Should be set to false after execution');
    }
}