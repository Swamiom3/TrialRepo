/************************************************************************************************************************************
    Author      :   Rohit Nimase  
    Description :   This class contain all test methods related to FollowUp Call Controller.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION         DATE                AUTHOR                  DETAIL
    1               10 January 2019     Rohit Nimase            Initial Developement
**************************************************************************************************************************************/
@isTest
public class FollowUpControllerTest {
    /************************************************************************************************************************************
        Author      :   Rohit Nimase  
        Description :   This method is used to create initial data required for methods.
        ----------------------------------------------------------------------------------------------------------------------------------
        VERSION     DATE                AUTHOR                  DETAIL
        1           10 January 2019     Rohit Nimase            Initial Developement
    **************************************************************************************************************************************/
    @TestSetup
    static void initData(){
        Test.startTest();
        Map<String, Object> mapData = new Map<String, Object>();
        
        mapData.put('objName', 'Lead');
        mapData.put('numberOfRecords', 2);
        mapData.put('doInsert', true);
        List<Lead> lstLeads = TestingUtility.getRecords(mapData);
        
        mapData.put('objName', 'Contact');
        mapData.put('numberOfRecords', 2);
        mapData.put('doInsert', true);
        List<Contact>  lstContacts = TestingUtility.getRecords(mapData);
        Test.stopTest();
    }
    
    /************************************************************************************************************************************
        Author      :   Rohit Nimase  
        Description :   This method is used to verify getFollowUpData() method of FollowUpController class.
        ----------------------------------------------------------------------------------------------------------------------------------
        VERSION     DATE                AUTHOR                  DETAIL
        1           10 January 2019     Rohit Nimase            Initial Developement
    **************************************************************************************************************************************/    
    public static testMethod void verifyGetFollowUpData(){
        List<Journey__c> lstJourneys = [SELECT Id, Name FROM Journey__c LIMIT 2];       
        
        List<id> lstJourneyIds = new List<id>();
        lstJourneyIds.add(lstJourneys[0].Id);
        
        DatabaseResult followUpResult1 =  FollowUpController.getFollowUpData(lstJourneyIds);
        Map<String, Object> mapFollowupData = (Map<String, Object>)followUpResult1.data;        
        
        System.assertNotEquals(null, mapFollowupData.get('currentDate'));
        System.assertNotEquals(null, mapFollowupData.get('followupCallSetting'));
        System.assertEquals(lstJourneyIds[0], ((list<Journey__c>)mapFollowupData.get('journeyRecord'))[0].Id);
        
        DatabaseResult followUpResult2 =  FollowUpController.getFollowUpData(null);
        Map<String, Object> mapFollowupData1 = (Map<String, Object>)followUpResult2.data;
        System.assertNotEquals(null, mapFollowupData1);
    }
    
    /************************************************************************************************************************************
        Author      :   Rohit Nimase  
        Description :   This method is used to verify saveJourneyFollowUp() method of FollowUpController class.
        ----------------------------------------------------------------------------------------------------------------------------------
        VERSION     DATE                AUTHOR                  DETAIL
        1           10 January 2019     Rohit Nimase            Initial Developement
    **************************************************************************************************************************************/     
    public static testMethod void verifySaveJourneyFollowUp(){
        Test.startTest();
        List<Lead> lstLead = [SELECT Id, Name FROM Lead LIMIT 2];
        List<Contact> lstContact = [SELECT Id, Name FROM Contact LIMIT 2];
        
        Journey__c objJourney1 = new Journey__c(Primary_Lead__c = lstLead[0].Id, Name = 'objJourney1');
        Journey__c objJourney2 = new Journey__c(Primary_Contact__c = lstContact[0].Id, Name = 'objJourney2');

        DatabaseResult journeyResult1 = InboundCallController.createOrUpdateJourney(objJourney1, lstLead[0].Id, null);
        System.assertNotEquals(null, journeyResult1.data);
        
        DatabaseResult journeyResult2 = InboundCallController.createOrUpdateJourney(objJourney2, lstContact[0].Id, null);
        System.assertNotEquals(null, journeyResult2.data);
        
        List<Journey__c> lstJourneys = [SELECT Id, Name, Primary_Contact__c, Primary_Lead__c FROM Journey__c];
        Date dtToday = Date.Today();
        Date nextFollowUpDate = dtToday.addDays(3);
        List<Id> lstJourneyIds = new List<Id>();
        
        lstJourneyIds.add(lstJourneys[0].Id);
        lstJourneyIds.add(lstJourneys[1].Id);
        
        
        Journey__c updateJourney = [SELECT Id FROM Journey__c WHERE Id =: lstJourneys[1].Id];
        updateJourney.Primary_Contact__c = lstContact[0].Id;
        updateJourney.Primary_Lead__c = null;
        update updateJourney;
        DatabaseResult followUpResultWithLeads = FollowUpController.saveJourneyFollowUp(lstJourneyIds, String.valueOf(nextFollowUpDate) , null);
        DatabaseResult followUpResultWithContacts = FollowUpController.saveJourneyFollowUp(new List<Id>{lstJourneys[1].Id, objJourney1.Id}, String.valueOf(nextFollowUpDate) , null);
        boolean l = (Boolean)FollowUpController.bulkJourneyUpdates(lstJourneyIds, '2017-11-24', 'description').data;
        //11-11-21 : Test Class fixes
        Integer outputt = FollowUpController.getFollowupCallPeriod();
        Datetime startDateTime = datetime.newInstance(2014, 9, 15, 12, 30, 0);
        Datetime endDateTime = datetime.newInstance(2014, 9, 15, 13, 30, 0);
        FollowUpController.getDateDifference(endDateTime,startDateTime);
       
        Test.stopTest();
        
        ApexPages.StandardSetController setController = new ApexPages.StandardSetController(Database.getQueryLocator([SELECT Id, Name, Primary_Contact__c, Primary_Lead__c FROM Journey__c]));
         System.assertEquals(new FollowUpController(setController).journeyIds.get(0), ApexPages.currentPage().getParameters().get('id'), 'Should get Apex  current Page Id List of JournyIds List');
        
        setController= new ApexPages.StandardSetController(Database.getQueryLocator([SELECT Id, Name, Primary_Contact__c, Primary_Lead__c FROM Journey__c WHERE Name='objJourney1']));
        setController.setSelected(new List<SObject>{objJourney1});
        System.assertEquals(new FollowUpController(setController).journeyIds.get(0), setController.getSelected().get(0).Id, 'Selected Journey Id\'s should be same');
        
        System.assertEquals(true, followUpResultWithLeads.success, 'Should get the leads');
        System.assertEquals(true, followUpResultWithContacts.data, 'Should get success the Process');
        
    }
}