/************************************************************************************************************************************
    Author        : Sunil Bhosale
    Description   : update Longstanding Journeys
    Issue No      : ST-1547

    History       :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE          AUTHOR           DETAIL
    1        	             Sunil Bhosale    Initial Developement
    2          14/11/2018    Jitesh Adwani	  Use the testing utility methods and change the according to the issue.
**************************************************************************************************************************************/
@isTest
public class BatchToForceFullyUpdateJourneysTest {
    private static TaskSelector taskSelector = new TaskSelector();

    /************************************************************************************************************************************
        Author         : Jitesh Adwani
        Description    : This method is used in BatchToForceFullyUpdateJournys to update the Journey.
        Created Date   : 14 Nov 2018 
        Issue No       : ST-3033
    **************************************************************************************************************************************/
    @isTest
    static void testBatchToForceFullyUpdateJourneys(){
        List<Journey__c> journeys = TestingUtility.getRecords(new Map<String, Object>{'objName'=>'journey', 'numberOfRecords'=>3, 'doInsert' => false});
        for(Journey__c journeyRecord : journeys){
            journeyRecord.Lead_Source__c = 'WeWork.com';
            journeyRecord.Lead_Source_Detail__c = 'Website';
            journeyRecord.NMD_Next_Contact_Date__c = Date.newInstance(2017, 10, 30);
        }
        TestingUtility.insertListWithAssert(journeys);

        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Task');
        recordsData.put('numberOfRecords', 2);
        
        List<Task> tasks = MockTestingUtility.getRecords(recordsData);
        tasks[0].WhatId = journeys[0].Id;
        tasks[0].Type = 'Other';
        tasks[0].Status = 'Not Started';
        tasks[1].WhatId = journeys[1].Id;
        tasks[1].Type = 'Other';
        tasks[1].Status = 'active';
        tasks[1].ActivityDate = Date.today().addDays(-10);
        TestingUtility.insertListWithAssert(tasks);
        
        List<Task> tasksAfterInsert =  taskSelector.getTasks();
        List<SObject> recordsToUpdate = new List<SObject>();
        
        //execute batch
        List<Journey__c> journeysToUpdate = new List<Journey__c>();
        List<Task> tasksToUpdate = new List<Task>();
        
        Datetime dateToFilter;
        MetadataSetting__mdt metadataRecord = Settings.getMetadataSettingByDevName('BatchToForceFullyUpdateJourneys');
        if(metadataRecord != null && String.isNotBlank(metadataRecord.Data__c)){
            MetadataSetting batchSettings = (MetadataSetting) System.JSON.deserialize(metadataRecord.Data__c, MetadataSetting.class);
            if(batchSettings.endDate != null){
                dateToFilter = batchSettings.endDate;
            }else{
                dateToFilter = Date.today().addDays(-(batchSettings.numberOfDays));
            }
        }
        Test.setCreatedDate(journeys[0].Id, dateToFilter.addDays(-30));
        journeysToUpdate.add(journeys[0]);
        Test.setCreatedDate(tasksAfterInsert[0].Id, dateToFilter.addDays(-30));
        tasksToUpdate.add(tasksAfterInsert[0]);
        
        Test.setCreatedDate(journeys[1].Id, dateToFilter.addDays(-32));
        journeysToUpdate.add(journeys[1]);
        Test.setCreatedDate(tasksAfterInsert[1].Id, dateToFilter.addDays(-15));
        tasksToUpdate.add(tasksAfterInsert[1]);
        
        Test.setCreatedDate(tasksAfterInsert[2].Id, dateToFilter.addDays(-5));
        tasksToUpdate.add(tasksAfterInsert[2]);
        
       	Test.setCreatedDate(journeys[2].Id, dateToFilter.addDays(-2));
        journeysToUpdate.add(journeys[2]);
        recordsToUpdate.addAll(journeysToUpdate);
        recordsToUpdate.addAll(tasksToUpdate);
        TestingUtility.updateListWithAssert(recordsToUpdate);
        
        Test.startTest();
        System.assertEquals(0, Limits.getEmailInvocations());
        Database.executeBatch(new BatchToForceFullyUpdateJourneys());
        Test.stopTest();
        
        for(Journey__c journeyRecord : [SELECT Id, Status__c, IsAuto_Complete_Expiration__c, Auto_Complete_Expiration__c, Lead_Source__c, Lead_Source_Detail__c FROM Journey__c]){
            System.assert(String.isNotBlank(journeyRecord.Status__c));
            System.assert(journeyRecord.Status__c.equalsIgnoreCase('Deferred'));
            System.assert(journeyRecord.Lead_Source__c.equalsIgnoreCase('WeWork.com'));
            System.assert(journeyRecord.Lead_Source_Detail__c.equalsIgnoreCase('Website'));
        }        

        System.assertEquals(1, BatchToForceFullyUpdateJourneys.emailLimits);
    }
    class MetadataSetting {
        Datetime endDate;
        Integer numberOfDays;
    }
}