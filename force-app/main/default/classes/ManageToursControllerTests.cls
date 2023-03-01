/************************************************************************************************************************************
    Author      :   Prashant Mane
    Description :   This class contain all test methods related to ManageToursController class.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           10 Jan 2019         Prashant Mane           Initial Developement
**************************************************************************************************************************************/
@isTest
private class ManageToursControllerTests {
    @TestSetup
    static void testDataSetup(){

        List<Opportunity> lstOpportunities = new List<Opportunity>();
        Map<String,Object> mapOpportunityRecord = new Map<String,Object>();
        Map<String,Object> mapRecordValues = new Map<String,Object>();
        Test.startTest();
        Account testAccount = TestingUtility.createAccount(new Map<String,Object>{'Name'=>'Test Account1','UUID__c'=>'0000-0001'}, false);
        TestingUtility.insertWithAssert(testAccount);

        Account testAccount1 = TestingUtility.createAccount(new Map<String,Object>{'Name'=>'Test Account2','UUID__c'=>'0000-0002'}, false);
        TestingUtility.insertWithAssert(testAccount1);
        Test.stopTest();

        mapRecordValues.clear();
        mapRecordValues.put('FirstName','First Name Test');
        mapRecordValues.put('LastName','Primary Contact');
        mapRecordValues.put('Email','TestContact@example.com');
        mapRecordValues.put('AccountId',testAccount.Id);
        TestingUtility.createContact(mapRecordValues, true);

        //Opportunity 1 for selling stage
        mapOpportunityRecord.put('StageName', 'Selling');
        mapOpportunityRecord.put('CloseDate', system.today().addDays(5));
        mapOpportunityRecord.put('AccountId', testAccount.Id);
        mapOpportunityRecord.put('Contract_UUID__c', 'Opp-0001');
        lstOpportunities.add(TestingUtility.createOpportunity(mapOpportunityRecord, false));

        //Opportunity 2 for Closed Won stage
        mapOpportunityRecord.put('StageName', 'Closed Won');
        mapOpportunityRecord.put('CloseDate', system.today().addDays(10));
        mapOpportunityRecord.put('AccountId', testAccount.Id);
        mapOpportunityRecord.put('Contract_UUID__c', 'Opp-0002');
        lstOpportunities.add(TestingUtility.createOpportunity(mapOpportunityRecord, false));

        //Opportunity 3 for Closing stage and contract stage is Contract Sent
        mapOpportunityRecord.put('StageName', 'Closing');
        mapOpportunityRecord.put('Contract_Stage__c', 'Contract Sent');
        mapOpportunityRecord.put('CloseDate', system.today().addDays(15));
        mapOpportunityRecord.put('AccountId', testAccount.Id);
        mapOpportunityRecord.put('Contract_UUID__c', 'Opp-0003');
        lstOpportunities.add(TestingUtility.createOpportunity(mapOpportunityRecord, false));

        //Inserting Opportunities
        TestingUtility.insertListWithAssert(lstOpportunities);

    }

	/************************************************************************************************************************************
    	Author 				:	Samadhan Kadam
    	Description 		: 	This method tests verifyIsValidOppForManageTour.
    	Created Date		: 	18 July 2018
    **************************************************************************************************************************************/
    @isTest
    public static void verifyIsValidOppForManageTour(){
        Set<String> setContractUUIDs = new Set<String>{'Opp-0001','Opp-0002','Opp-0003'};
        Test.startTest();
        List<Opportunity> lstOpportunities = [SELECT Id FROM Opportunity WHERE Contract_UUID__c In: setContractUUIDs];
        String resultForSellingOpp = ManageToursController.isValidOpportunityForManageTour(lstOpportunities[0].id);
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(resultForSellingOpp);
        System.assertEquals(true, response.get('isValid'));

        String resultForClosedOpp = ManageToursController.isValidOpportunityForManageTour(lstOpportunities[1].id);
        response = (Map<String, Object>)JSON.deserializeUntyped(resultForClosedOpp);
        System.assertEquals(false, response.get('isValid'));
        System.assertEquals(response.get('errorMsg'), 'Cannot Book Tours for Opportunity with stage Closed Won, Closed Lost or Merged');

        String resultForClosingopp = ManageToursController.isValidOpportunityForManageTour(lstOpportunities[2].id);
        response = (Map<String, Object>)JSON.deserializeUntyped(resultForClosingopp);
        System.assertEquals(false, response.get('isValid'));
        System.assertEquals(response.get('errorMsg'), 'Cannot Book Tours on Closing Opportunity with Contract Stage as Sent or Signed');
        ManageToursController.isValidOpportunityForManageTourLightning(lstOpportunities[1].id);
        ManageToursController.isValidOpportunityForManageTourLightning(null);
        Test.stopTest();

    }

	/************************************************************************************************************************************
		Author 				:	Samadhan Kadam
		Description 		: 	This method tests verify IsValidAccountForManageTour.
		Created Date		: 	18 July 2018
	**************************************************************************************************************************************/
    @isTest
    public static void verifyIsValidAccountForManageTour(){
        Set<String> setAccounUUIDs = new Set<String>{'0000-0001','0000-0002'};
        Test.startTest();
        List<Account> lstAccounts = [SELECT Id,Name FROM Account WHERE UUID__c In: setAccounUUIDs];
        string resultForAccountWithCon = ManageToursController.isValidAccountForManageTour(lstAccounts[0].id);
        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(resultForAccountWithCon);
        System.assertEquals(true, response.get('isValid'));

        string resultForAccountWithoutCon = ManageToursController.isValidAccountForManageTour(lstAccounts[1].id);
        response = (Map<String, Object>)JSON.deserializeUntyped(resultForAccountWithoutCon);
        System.assertEquals(false, response.get('isValid'));
        System.assertEquals(response.get('errorMsg'), 'You cannot book a tour due to Contact not found under '+lstAccounts[1].Name+'');

        ManageToursController.isValidAccountForManageTourLightning(lstAccounts[0].id);
		ManageToursController.isValidAccountForManageTourLightning(null);
        Test.stopTest();
    }

    /************************************************************************************************************************************
		Author 				:	Rohit Nimase
		Description 		: 	This method is used to verify getDataForManageTours method.
		Created Date		: 	3 July 2019
	**************************************************************************************************************************************/
    @isTest
    public static void verifyGetDataForManageTours(){
        Test.startTest();
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData.put('objName', 'Journey');
        recordsData.put('numberOfRecords', 1);
        recordsData.put('doInsert', true);
        List<Journey__c> journeys = TestingUtility.getRecords(recordsData);

        Map<String, String> mapData = new Map<String, String>();
		mapData.put('Id', journeys[0].Id);
        mapData.put('entityType', 'journey');
        DatabaseResult resultJourneyData = ManageToursController.getDataForManageTours(mapData);
        Map<String, Object> journeyManageTourWrapper = (Map<String, Object>)JSON.deserializeUntyped(String.valueOf(resultJourneyData.data));
        System.assert(journeyManageTourWrapper != NULL);
        System.assert(journeyManageTourWrapper.get('entityData') != NULL);

        mapData.clear();
        List<Contact> contacts = [SELECT Id, AccountId FROM Contact LIMIT 1];
        mapData.put('Id', contacts[0].Id);
        mapData.put('entityType', 'contact');
        DatabaseResult resultOppData = ManageToursController.getDataForManageTours(mapData);
        Map<String, Object> oppManageTourWrapper = (Map<String, Object>)JSON.deserializeUntyped(String.valueOf(resultOppData.data));
        System.assert(oppManageTourWrapper.get('entityData') != NULL);

		Test.stopTest();
    }

}