/**
* @description Test class for the Case trigger
* @name trac_CaseTest
* @author Shubham Jain, Traction on Demand
* @date 2019-08-28
*/

@isTest
public class trac_CaseTest {
    
    static TLTestFactory factory = new TLTestFactory();
    
    @isTest
    public static void caseTracMethod(){
        BusinessHours hours = [SELECT ID FROM BusinessHours WHERE Name='India (Asia/Kolkata)'];
        Case createCase = new Case();
        createCase.SuppliedEmail = 'test@test.test';
        createCase.Status = 'Waiting_on_Support_Request_Submitter';  
        createCase.BusinessHoursId = hours.Id;
        createCase.RecordTypeId=Schema.SObjectType.Case.getRecordTypeInfosByName().get('Enterprise Finance & Strategy').getRecordTypeId();        
        insert createCase;
        
        List<Case> case1 = (List<Case>) factory.createSObjects(new Case(SuppliedEmail = 'test@test.test',Status='Resolved',RecordTypeId=(Schema.SObjectType.Case.getRecordTypeInfosByName().get('Enterprise Finance & Strategy').getRecordTypeId())), 2, false);
        Id profId = [Select Id, Name FROM Profile WHERE Name = 'WeWork Interr Vendor'].Id;
        User testUser = new User(Alias = 'contrl', Email='interrcontroll@wecompany.com.test', 
                                    EmailEncodingKey='UTF-8', LastName='Control', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = profId, 
                                    TimeZoneSidKey='America/Los_Angeles', UserName='interrcontroll@wecompany.com.test_only');
        Test.startTest();
        System.runAs(testUser){           
            insert case1[0];
        }        
        Test.stopTest();        
        System.assertEquals(NULL, createCase.Waiting_on_Support_Request_24_hours__c, 'This date field should be null when the record type is not Support Request');
        System.assertEquals(False, createCase.Is_24_Hours_After_Email_Sent__c, 'This field should be false');
    }
}