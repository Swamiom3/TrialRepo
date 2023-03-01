/***********************************************************************************************************************
Author   :   Neelima
Description :   This is test class for ConvertBrokerLeadController.

History     :
----------------------------------------------------------------------------------------------------------------
VERSION         DATE            AUTHOR              DETAIL
1               01/04/2022      Neelima             Increased the code coverage
*************************************************************************************************************************/
@isTest
public class ConvertBrokerLeadControllerTest {
    @isTest
    public static void testConvert(){
        test.startTest();
        
        //Insert Account
        Account accountObj = new Account(Name='Test Account');
        insert accountObj;
        
        //Insert Company
        CI_Company__c testcompany = new CI_Company__c();
        testcompany.size__c = 7;
        insert testcompany;
        
        //Insert Lead
        lead testlead = new lead();
        testlead.Email = 'sd@gmail.com';
        testlead.phone = '8765432567';
        testlead.lastname = 'sneha';
        testlead.CI_Company__c = testcompany.Id;        
        insert testlead;
        
        //Insert Task
        Task taskObj = new Task();
        taskObj.WhoId = testlead.Id;
        taskObj.Status = 'Not Started';
        insert taskObj;
        
        //Insert Contact
        Contact testContact = new Contact();
        testcontact.FirstName = 'First Name Test';
        testcontact.LastName = 'mina';
        insert testContact;
        
        //Insert journey records
        journey__c testjourneyOne =new journey__c();
        testjourneyOne.Primary_Lead__c = testlead.Id;
        testjourneyOne.NMD_Next_Contact_Date__c = system.today();
        insert testjourneyOne;
        
        journey__c testjourneyTwo =new journey__c();
        testjourneyTwo.Primary_Lead__c = testlead.Id;   
        testjourneyTwo.NMD_Next_Contact_Date__c = system.today();
        insert testjourneyTwo;
        
        journey__c testjourney =new journey__c();
        Map<String, Object> filters = new Map<String, Object>();
        filters.put('journeyId',testjourneyOne.id);
        Map<String, Object> filter = new Map<String, Object>();
        filter.put('journeyId',testjourneyTwo.Id);
        
        ConvertBrokerLeadController.getQueryResultForLabel('journeyDetails', filters);
        ConvertBrokerLeadController.getQueryResultForLabel('journeyDetails', filter);    
        ConvertBrokerLeadController.verifyBrokerLead(testlead.Id,false,testlead,testcontact.Id,false); 
        ConvertBrokerLeadController.verifyBrokerLead(testlead.Id,true,testlead,'',false);
        ConvertBrokerLeadController.getJourneyToUpdate(testlead.Id);
        ConvertBrokerLeadController.getJourneyToUpdate('');
        ConvertBrokerLeadController.getJourneyClosedStages();
        ConvertBrokerLeadController.isParterAffilate(testlead);
        ConvertBrokerLeadController.saveJourney(testjourneyOne);
        ConvertBrokerLeadController.saveJourney(testjourney);
        ConvertBrokerLeadController.verifyBrokerLeadForWebService(testlead.Id,false,testlead,testcontact.Id,false);
        ConvertBrokerLeadController.verifyAndConvertBrokerLead(testlead.Id,true,testlead,'',false);
        test.stopTest();
        System.assertEquals(1,filters.size(),'No journey records exist');
        System.assertEquals(1,filter.size(),'No journey records exist');
    }    
}