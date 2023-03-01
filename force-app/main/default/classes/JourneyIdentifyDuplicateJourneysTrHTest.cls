/**********************************************************************************************************
    Author        :  Ashish Sharma
    Description   :  Test class for JourneyIdentifyDuplicateJourneysTrH.
    Issue No.     :  ST-8162
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE          AUTHOR           DETAIL
      1         23-Apr-2021    Ashish Sharma      ST-8162
**********************************************************************************************************/
@isTest
private class JourneyIdentifyDuplicateJourneysTrHTest {
    
    @isTest
    private static void markDuplicateJourneysTest() {
        Lead testLead = UtilLead.getNewLeads(1, false)[0];
        testLead.Email = 'test1@gmail.com';
        testLead.Generate_Journey__c = true;
        TestingUtility.insertWithAssert(testLead);        
        Journey__c masterJourney = [SELECT Id FROM Journey__c WHERE Primary_Lead__c = :testLead.Id];
        
        //created on same day, should be marked duplicate
        List<Journey__c> journeysToInsert = new List<Journey__c>();
        journeysToInsert.add(new Journey__c(Name = 'journey2', Primary_Lead__c = testLead.Id, Primary_Email__c = testLead.Email, Status__c = 'Known', NMD_Next_Contact_Date__c = Date.today()));
        journeysToInsert.add(new Journey__c(Name = 'journey3', Primary_Lead__c = testLead.Id, Primary_Email__c = testLead.Email, Status__c = 'Known', NMD_Next_Contact_Date__c = Date.today()));
        journeysToInsert.add(new Journey__c(Name = 'journey4', Primary_Lead__c = testLead.Id, Primary_Email__c = testLead.Email, Status__c = 'Known', NMD_Next_Contact_Date__c = Date.today()));
        TestingUtility.insertListWithAssert(journeysToInsert);
        
        List<Journey__c> duplicateJourneys = [SELECT Id, Name FROM Journey__c WHERE Master_Journey__c = :masterJourney.Id AND Duplicate_Journey__c = TRUE];
        System.assertEquals(3, duplicateJourneys.size(), 'Three duplicate journeys should be present');
        
        MetadataDrivenTriggerHandler.clearLoopCount('JourneyIdentifyDuplicateJourneysTrH');
        Test.setCreatedDate(masterJourney.Id, Datetime.now().addDays(-1));
        journeysToInsert.clear();
        Test.startTest();
        journeysToInsert.add(new Journey__c(Name = 'journey5', Primary_Lead__c = testLead.Id, Primary_Email__c = testLead.Email, Status__c = 'Known', NMD_Next_Contact_Date__c = Date.today()));
        journeysToInsert.add(new Journey__c(Name = 'journey6', Primary_Lead__c = testLead.Id, Primary_Email__c = testLead.Email, Status__c = 'Known', NMD_Next_Contact_Date__c = Date.today()));
        TestingUtility.insertListWithAssert(journeysToInsert);
        Test.stopTest();
        
        //should not be duplicate journeys
        for(Journey__c journeyToAssert : [SELECT Name, Duplicate_Journey__c, Master_Journey__c 
                                          FROM Journey__c WHERE Id IN :journeysToInsert]) {
            System.assertEquals(false, journeyToAssert.Duplicate_Journey__c, 'Journey should not be considered duplicate');
            System.assertEquals(null, journeyToAssert.Master_Journey__c, 'Journey should not be considered duplicate');
        }
    }
    
    @isTest
    private static void duplicateJourneysInsertedAtSameTimeTest() {
        Lead testLead = UtilLead.getNewLeads(1, false)[0];
        testLead.Generate_Journey__c = false;
        testLead.Email = 'test1@gmail.com';
        TestingUtility.insertWithAssert(testLead);
        List<Journey__c> journeysToInsert = new List<Journey__c>();
        journeysToInsert.add(new Journey__c(Name = 'journey1', Primary_Lead__c = testLead.Id, Primary_Email__c = testLead.Email, Status__c = 'Known', NMD_Next_Contact_Date__c = Date.today()));
        journeysToInsert.add(new Journey__c(Name = 'journey2', Primary_Lead__c = testLead.Id, Primary_Email__c = testLead.Email, Status__c = 'Known', NMD_Next_Contact_Date__c = Date.today()));
        journeysToInsert.add(new Journey__c(Name = 'journey3', Primary_Lead__c = testLead.Id, Primary_Email__c = testLead.Email, Status__c = 'Known', NMD_Next_Contact_Date__c = Date.today()));
        TestingUtility.insertListWithAssert(journeysToInsert);
        for(Journey__c journeyToAssert : [SELECT Name, Duplicate_Journey__c, Master_Journey__c 
                                          FROM Journey__c WHERE Id IN :journeysToInsert]) {
            if(journeysToInsert[0].Id == journeyToAssert.Id) {
                System.assertEquals(false, journeyToAssert.Duplicate_Journey__c, 'Journey should not be considered duplicate');
                System.assertEquals(null, journeyToAssert.Master_Journey__c, 'Journey should not be considered duplicate');
            } else {
                System.assertEquals(true, journeyToAssert.Duplicate_Journey__c, 'Journey should be duplicate');
                System.assertEquals(journeysToInsert[0].Id, journeyToAssert.Master_Journey__c, 'Journey should be duplicate');
            }
        }
    }
}