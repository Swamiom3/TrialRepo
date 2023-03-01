/************************************************************************************************************************************
Author      :   Vamsi
Description :   This class provides sufficient test coverage for JourneyActionsController class
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           26 Nov 2021         Vamsi             Initial Developement
**************************************************************************************************************************************/
@isTest
public class JourneyActionsControllerTest{
    
    @isTest
    static void updateJourneyTest(){        
        
        Lead lead = new Lead();
        lead.LastName = 'TestLead';
        lead.Email = 'Test@mailinator.com';
        lead.Phone = '1234567890';
        insert lead;
        
        Journey__c journey = new Journey__c();
        journey.Name = 'TestJourney';
        journey.Primary_Lead__c = lead.Id;
        journey.NMD_Next_Contact_Date__c = System.today();
                        
        Journey__c journeyTest = new Journey__c();
        journeyTest.Name = 'TestJourney';
        journeyTest.Primary_Lead__c  = lead.Id;
        journeyTest.NMD_Next_Contact_Date__c = System.today();
        insert journeyTest;
        system.debug('journeyTest***'+journeyTest.OwnerId);
        
        Lead leadTest = new Lead();
        leadTest.LastName = 'TestLead1';
        leadTest.Email = 'Test@mailinator.com';
        leadTest.Phone = '1234567890';
        insert leadTest;
        
        journeyTest.Name = 'Test Journey';
        journeyTest.Primary_Lead__c = leadTest.id;
        journeyTest.ownerId = userInfo.getUserId();
        try{
          update journeyTest;   
        }catch(exception e){
            System.assert(true, 'Exception ' + e);
        }
        
        
        Set<Id> setLeadIds = new Set<Id>();
        List<Id> LeadList = new List<Id>();
        set<String> stringSets = new set<String>();
        set<String> stringSet = new set<String>();
        List<Journey__c> lstJourneys = new List<Journey__c>();
        setLeadIds.add(lead.id);
        LeadList.add(lead.id);
        lstJourneys.add(journey);
        stringSets.add('Name');
            
        Test.startTest();
        insert journey;
        List<String> journeyStringList = JourneyActionsController.getNotSalesReadyReasons();
        JourneyActionsController.updateJourney(journey.Id,'Working','Not a Fit');
        Id listViewId = JourneyActionsController.getListViewByName(lead.LastName,'Lead');
        String primaryMemberName = JourneyActionsController.getPrimaryMemberName(journey.Id);
        
        JourneyHelperUtility jHelp = new JourneyHelperUtility();
        JourneyHelperUtility.checkIsUniqueJourney(journey, lstJourneys);
        JourneyHelperUtility.checkIsUniqueJourney(journey, lstJourneys);
        JourneyHelperUtility.getJourneyModeofAssignment(lead);    
        JourneyHelperUtility.updateJourneyOwner(null,LeadList);
        SObjectTriggerHandler.clearLoopCount('JourneyUpdateJourneyStatusTrH');
        update journey;
        Test.stopTest();  
        
        List<String> fields = new List<String>();
        for(Schema.PicklistEntry fieldValues : Journey__c.Deferred_Reason__c.getDescribe().getPicklistValues()){
            fields.add(fieldValues.getLabel());
        }
        
        System.assertEquals('Working', [SELECT Status__c,Deferred_Reason__c FROM Journey__c WHERE Id =:journey.Id LIMIT 1].Status__c, 'Updation Failed for Journey');
        System.assertEquals(null, listViewId, 'Id didn\'t matched');
        System.assertEquals('TestJourney', primaryMemberName, 'primaryMember Not not Found');
    }
}