/************************************************************************************************************************************
    Author      :   Rohit Nimase  
    Description :   This class contain all test methods related to Inbound Call Controller.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     ISSUE NUMBER    DATE                AUTHOR                  DETAIL
    1           ST-2864         8 January 2019      Rohit Nimase            Initial Developement
**************************************************************************************************************************************/
@isTest
public class InboundCallControllerTest {
    /************************************************************************************************************************************
        Author      :   Rohit Nimase  
        Description :   This method is used to create initial data required for methods.
        ----------------------------------------------------------------------------------------------------------------------------------
        VERSION     ISSUE NUMBER    DATE                AUTHOR                  DETAIL
        1           ST-2864         9 January 2019      Rohit Nimase            Initial Developement
    **************************************************************************************************************************************/ 
    @TestSetup
    static void initData(){
        OperatingHours objOpHour = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday');
        insert objOpHour;
        Map<String, Object> mapData = new Map<String, Object>();
        
        mapData.put('objName', 'Lead');
        mapData.put('numberOfRecords', 2);
        mapData.put('doInsert', true);
        List<Lead> lstLeads = TestingUtility.getRecords(mapData);
        
        mapData.put('objName', 'Contact');
        mapData.put('numberOfRecords', 2);
        mapData.put('doInsert', true);
        List<Contact>  lstContacts = TestingUtility.getRecords(mapData);
        
        Building__c objBuilding = new Building__c(Name = 'testBuilding', CurrencyIsoCode = 'USD', UUID__c = 'buildingUUID', City__c = 'test');
        insert objBuilding;
        
        Region__c objRegion = new Region__c(Name = 'Test Region', Region__c = 'Test Region');
        TestingUtility.insertWithAssert(objRegion, 'Region not inserted');
        
        Territory__c objTerritory = new Territory__c(Name = 'Test Territory', Territory__c =' Test Territory', RegionID__c = objRegion.Id);
        TestingUtility.insertWithAssert(objTerritory, 'Territory not inserted');
        
        Market__c objMarket = new Market__c(Name = 'Test Portfolio', Portfolio__c = 'Test Portfolio', TerritoryId__c = objTerritory.Id);
        TestingUtility.insertWithAssert(objMarket, 'Portfolio not inserted');
    }
    
    /************************************************************************************************************************************
       Author      :   Rohit Nimase  
       Description :   This method is used to verify searchDataByKeyword() method of InboundCallController class.
       ----------------------------------------------------------------------------------------------------------------------------------
       VERSION     ISSUE NUMBER DATE                AUTHOR                  DETAIL
       1           ST-2864  8 January 2019      Rohit Nimase            Initial Developement
   **************************************************************************************************************************************/
  
   public static testMethod void verifySearchDataByKeyword(){
        List<Id> lstLeadIds = new List<Id>();
        for(Lead objLead : [SELECT Id FROM Lead]){
            lstLeadIds.add(objLead.Id);
        }
        System.assertEquals(2, lstLeadIds.size());        
        Test.setFixedSearchResults(lstLeadIds);        
      
        DatabaseResult searchResult  = InboundCallController.searchDataByKeyword('John', null);
        System.assertNotEquals(null, searchResult.data);
        
        searchResult = InboundCallController.searchDataByKeyword('John1', '9556856235');
        System.assertNotEquals(null, searchResult.data);        
    } 
    /************************************************************************************************************************************
        Author      :   Rohit Nimase  
        Description :   This method is used to verify getRecordById() method of InboundCallController class.
        ----------------------------------------------------------------------------------------------------------------------------------
        VERSION     ISSUE NUMBER    DATE                AUTHOR                  DETAIL
        1           ST-2864         9 January 2019      Rohit Nimase            Initial Developement
    **************************************************************************************************************************************/    
   
    public static testMethod void verifyGetRecordById(){
        List<Lead> lstLeads = [SELECT Id, Name, Email FROM Lead LIMIT 2];
        List<Contact> lstContacts = [SELECT Id, Name, Email FROM Contact LIMIT 2];
        
        DatabaseResult record1 = InboundCallController.getRecordById(lstLeads[0].Id);
        Lead objLead = (Lead)record1.data;
        System.assertEquals(lstLeads[0].Email, objLead.Email);
        
        DatabaseResult record2 = InboundCallController.getRecordById(lstContacts[0].Id);
        Contact objContact =(Contact)record2.data;
        System.assertEquals(lstContacts[0].Email, objContact.Email);
    }
    /************************************************************************************************************************************
        Author      :   Rohit Nimase  
        Description :   This method is used to verify getObjectFields() method of InboundCallController class.
        ----------------------------------------------------------------------------------------------------------------------------------
        VERSION     ISSUE NUMBER    DATE                AUTHOR                  DETAIL
        1           ST-2864         8 January 2019      Rohit Nimase            Initial Developement
    **************************************************************************************************************************************/
   
    public static testMethod void verifyGetObjectFields(){
        List<String> leadFields = InboundCallController.getObjectFields('Lead');
        System.assertNotEquals(0, leadFields.size());
        
        List<String> contactFields = InboundCallController.getObjectFields('Contact');
        System.assertNotEquals(0, contactFields.size());
        
        List<String> journeyFields = InboundCallController.getObjectFields('Journey');
        System.assertNotEquals(0, journeyFields.size());
        
        List<String> emptyFields = InboundCallController.getObjectFields(null);
        System.assertEquals(0, emptyFields.size());
    }
    /************************************************************************************************************************************
        Author      :   Rohit Nimase  
        Description :   This method is used to verify createOrUpdateJourney() and getJourneys() method of InboundCallController class.
        ----------------------------------------------------------------------------------------------------------------------------------
        VERSION     ISSUE NUMBER    DATE                AUTHOR                  DETAIL
        1           ST-2864         9 January 2019      Rohit Nimase            Initial Developement
    **************************************************************************************************************************************/
  
    public static testMethod void verifyCreateOrUpdateJourney(){
        List<Lead> lstLeads = [SELECT Id, Name FROM Lead LIMIT 2];
        LIst<Contact> lstContacts = [SELECT Id, Name FROM Contact LIMIT 2];
        
        Journey__c objJourney1 = new Journey__c();
        DatabaseResult journeyResult1 = InboundCallController.createOrUpdateJourney(objJourney1, lstLeads[0].Id, null);
        System.assertNotEquals(null, journeyResult1);
        
        Map<String, Object> mapjourneyResult1 = (Map<String, Object>)JSON.deserializeUntyped(String.valueOf(journeyResult1.data));
        System.assertNotEquals(null, mapjourneyResult1.get('id'));
        
        Journey__c objJourney2 = new Journey__c();
        DatabaseResult journeyResult2 = InboundCallController.createOrUpdateJourney(objJourney2, lstContacts[0].Id, null);        
        Map<String, Object> mapjourneyResult2 = (Map<String, Object>)JSON.deserializeUntyped(String.valueOf(journeyResult2.data));
        System.assertNotEquals(null, mapjourneyResult2.get('id'));
        
        DatabaseResult journeyResult3 = InboundCallController.createOrUpdateJourney(objJourney2, null, null);
        System.assertEquals(null, journeyResult3.data);
        
        List<sObject> lstSObjects = InboundCallController.getParentRecordOwner(null);
        String building = InboundCallController.getJourneyBuildingCity(null);
        System.assertEquals(null, lstSObjects);
        System.assertEquals('', building);
        
        DatabaseResult lstJourneys1 = InboundCallController.getJourneys(lstLeads[0].Id);
        Map<String, List<Journey__c>> journeysResult1 = (Map<String, List<Journey__c>>)lstJourneys1.data;
        System.assertNotEquals(null, journeysResult1.get('openJourneys'));
        
        DatabaseResult lstJourneys2 = InboundCallController.getJourneys(lstContacts[0].Id);
        Map<String, List<Journey__c>> journeysResult2 = (Map<String, List<Journey__c>>)lstJourneys2.data;
        System.assertNotEquals(null, journeysResult2.get('openJourneys'));
        
    }
    /************************************************************************************************************************************
        Author      :   Jitesh Adwani 
        Description :   This method is used to verify saveLead method, lead is created or not.
        ----------------------------------------------------------------------------------------------------------------------------------
        VERSION     ISSUE NUMBER    DATE                AUTHOR                  DETAIL
        1           ST-2864         30 January 2019     Jitesh              Initial Developement
    **************************************************************************************************************************************/ 
    
    public static testMethod void verifySaveLead(){
        List<Building__c> lstBuildings = [SELECT Id, Name FROM Building__c LIMIT 1];        
        
        Lead objLead = new Lead(Company = 'WeWork', Email = 'wework010101@example.com', Phone = '123456789', Building_Interested_In__c = lstBuildings[0].Id, LeadSource = 'WeWork.com', Lead_Source_Detail__c = 'Inbound Call Page', Generate_Journey__c = True);
        
        DatabaseResult resultLead = InboundCallController.saveLead(objLead);
        System.assertEquals(null, resultLead.data);
        
        objLead.LastName = 'WeWork LastName';
        resultLead = InboundCallController.saveLead(objLead);
        System.assertEquals(true, resultLead.success);
    }
    /************************************************************************************************************************************
        Author      :   Dipak Pawar
        Description :   This method is used to verify saveContact method, Contact and Acccount is updated or not.
        ----------------------------------------------------------------------------------------------------------------------------------
        VERSION     ISSUE NUMBER    DATE                AUTHOR                  DETAIL
        1           ST-2864         30 January 2019     Jitesh              Initial Developement
    **************************************************************************************************************************************/ 
    
    public static testMethod void verifySaveContact(){
        DatabaseResult saveContactResult = InboundCallController.saveContact(null);
        System.assertEquals(null, saveContactResult.data);
        
        List<Building__c> lstBuildings = [SELECT Id, Name FROM Building__c LIMIT 1];        
        System.assertEquals(1, lstBuildings.size());
        
        List<Account> lstAccounts = new List<Account>([SELECT Id, Interested_in_Number_of_Desks__c, BillingCity FROM Account]);
        System.assertEquals(2, lstAccounts.size());
        
        List<Contact> lstContacts = new List<Contact>([SELECT Id, AccountId, Location__c FROM Contact]);
        System.assertEquals(2, lstContacts.size());
        
        List<Market__c> lstMarkets = new List<Market__c>([SELECT Id FROM Market__c]);
        System.assertEquals(1, lstMarkets.size());
        
        Contact objContact = lstContacts[0];
        objContact.Location_Interested__c = 'Test Building 1';
       
        objContact.MailingStreet = '490';
        objContact.MailingCity = 'Shore Court';
        objContact.MailingState = 'Rochester';
        objContact.MailingCountry = 'New York';
        objContact.MailingPostalCode = '14609';
       
        
        saveContactResult = InboundCallController.saveContact(objContact);
        System.assertEquals(true, saveContactResult.success);
        
        lstAccounts = new List<Account>([SELECT Id, Interested_in_Number_of_Desks__c, BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode FROM Account]);
        System.assertEquals(2, lstAccounts.size());
        System.assertEquals('490', lstAccounts[0].BillingStreet);
        System.assertEquals('Shore Court', lstAccounts[0].BillingCity);
        System.assertEquals('Rochester', lstAccounts[0].BillingState);
        System.assertEquals('New York', lstAccounts[0].BillingCountry);
        System.assertEquals('14609', lstAccounts[0].BillingPostalCode);
        
        lstContacts = new List<Contact>([SELECT Id, MailingStreet, MailingCity, MailingState, MailingCountry, MailingPostalCode, Location_Interested__c FROM Contact]);
        System.assertEquals(2, lstContacts.size());
        System.assertEquals('490', lstContacts[0].MailingStreet);
        System.assertEquals('Shore Court', lstContacts[0].MailingCity);
        System.assertEquals('Rochester', lstContacts[0].MailingState);
        System.assertEquals('New York', lstContacts[0].MailingCountry);
        System.assertEquals('14609', lstContacts[0].MailingPostalCode);
        System.assert(lstContacts[0].Location_Interested__c.containsIgnoreCase('Test Building 1'));
    }
    /************************************************************************************************************************************
        Author      :   Dipak Pawar
        Description :   This method is used to verify saveContact method, Contact and Acccount is updated or not.
        ----------------------------------------------------------------------------------------------------------------------------------
        VERSION     ISSUE NUMBER    DATE                AUTHOR                  DETAIL
        1           ST-2864         30 January 2019     Jitesh              Initial Developement
    **************************************************************************************************************************************/ 

    public static testMethod void verifySaveContactForLocation(){
        DatabaseResult saveContactResult = InboundCallController.saveContact(null);
        System.assertEquals(null, saveContactResult.data);
        
        List<Building__c> lstBuildings = [SELECT Id, Name FROM Building__c LIMIT 1];        
        System.assertEquals(1, lstBuildings.size());
        
        List<Account> lstAccounts = new List<Account>([SELECT Id, Interested_in_Number_of_Desks__c, BillingCity FROM Account]);
        System.assertEquals(2, lstAccounts.size());
        
        List<Contact> lstContacts = new List<Contact>([SELECT Id, AccountId FROM Contact]);
        System.assertEquals(2, lstContacts.size());
        
        List<Market__c> lstMarkets = new List<Market__c>([SELECT Id FROM Market__c]);
        System.assertEquals(1, lstMarkets.size());
        
        Contact objContact = lstContacts[0];        
        objContact.Location__c = lstBuildings[0].Id;
        objContact.Location_Interested__c = 'Test Building 1';
        objContact.MailingStreet = '490';
        objContact.MailingCity = 'Shore Court';
        objContact.MailingState = 'Rochester';
        objContact.MailingCountry = 'New York';
        objContact.MailingPostalCode = '14609';
        
        saveContactResult = InboundCallController.saveContact(objContact);
        System.assertEquals(true, saveContactResult.success);
        
        lstAccounts = new List<Account>([SELECT Id,Interested_in_Number_of_Desks__c, BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode FROM Account]);
        System.assertEquals(2, lstAccounts.size());
        System.assertEquals('490', lstAccounts[0].BillingStreet);
        System.assertEquals('Shore Court', lstAccounts[0].BillingCity);
        System.assertEquals('Rochester', lstAccounts[0].BillingState);
        System.assertEquals('New York', lstAccounts[0].BillingCountry);
        System.assertEquals('14609', lstAccounts[0].BillingPostalCode);
        
        lstContacts = new List<Contact>([SELECT Id, MailingStreet, MailingCity, MailingState, MailingCountry, MailingPostalCode, Location_Interested__c FROM Contact]);
        System.assertEquals(2, lstContacts.size());
        System.assertEquals('490', lstContacts[0].MailingStreet);
        System.assertEquals('Shore Court', lstContacts[0].MailingCity);
        System.assertEquals('Rochester', lstContacts[0].MailingState);
        System.assertEquals('New York', lstContacts[0].MailingCountry);
        System.assertEquals('14609', lstContacts[0].MailingPostalCode);
        System.assert(lstContacts[0].Location_Interested__c.containsIgnoreCase('Test Building 1'));
    }
    
    /************************************************************************************************************************************
        Author      :   Rohit Nimase  
        Description :   This method is used to verify isContactPresentWithEmail Methods.
        ----------------------------------------------------------------------------------------------------------------------------------
        VERSION     ISSUE NUMBER    DATE                AUTHOR                  DETAIL
        1           ST-5985         3 March 2020      	Rohit Nimase            Initial Developement
    **************************************************************************************************************************************/
    public static testMethod void verifyisContactPresentWithEmail(){
        List<Contact> lstContacts = [SELECT Id, Email FROM Contact LIMIT 1];
        System.assertEquals(true, InboundCallController.isContactPresentWithEmail(lstContacts[0].Email));
    }
}