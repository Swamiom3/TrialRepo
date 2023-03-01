/*****************************************************************************************************************************
Author      :  Shubham Nandwana
Description :  This class contains the Test Class of OpportunityUpdateContactFieldsTrH
History     :  
----------------------------------------------------------------------------------------------------------------------------------
VERSION                 DATE                    AUTHOR                          ISSUE
1                   	26 July 2021            Shubham Nandwana                TWSPG-2285
******************************************************************************************************************************/
@isTest
private class OpportunityUpdateReferralFieldsTrHTest {
    @testSetup
    static void makeData(){
        Account account1 = TestingUtility.createAccount('test1', true);
        Account account2 = TestingUtility.createAccount('test2', true);
        Contact con1 = TestingUtility.createContact(account1.Id, 'testAcc1', true);
        
        //map to create another contact with new email
        Map<String,Object> recordValuesMap = new Map<String,Object>();
        recordValuesMap.put('FirstName','First Name testAcc2');
        recordValuesMap.put('LastName','testAcc2');
        recordValuesMap.put('AccountId',account2.Id);
        recordValuesMap.put('Email','Test2@Example.com');
        recordValuesMap.put('Type__c','Broker');
        Contact con2 = TestingUtility.createContact(recordValuesMap, true);
        Opportunity opp = TestingUtility.createOpportunity(account1.Id, false);
        opp.Referrer__c = con1.Id;
        insert opp;
    }
    
    @isTest
    public static void testOpportunityUpdateContactFieldsOnInsertTest(){
        Test.startTest();
        List<Opportunity> opps = [SELECT Referrer__c, Referrer_Account__c, Referrer_Contact_Type__c
                                  FROM Opportunity];
        List<Contact> contacts = [SELECT Id,AccountId, Type__c FROM Contact];
        System.assert(opps != null, 'Opporutnity record should be returned');
        System.assertEquals(opps.get(0).referrer__c,contacts.get(0).Id, 'Contact Id should be matched with referrer');
        System.assertEquals(opps.get(0).Referrer_Account__c,contacts.get(0).AccountId,
                            'Account Id should be matched in opportunity and contact');
        System.assertEquals(opps.get(0).Referrer_Contact_Type__c,contacts.get(0).Type__c,
                            'Contact type should be matched in opportunity and contact');
        Test.stopTest();
    }
    
    @isTest
    public static void testOpportunityUpdateContactFieldsOnUpdateTest(){
        Test.startTest();
        List<Opportunity> opps = [SELECT Referrer__c, Referrer_Account__c , Referrer_Contact_Type__c 
                                  FROM Opportunity];
        List<Contact> contacts = [SELECT Id,AccountId, Type__c FROM Contact];
        opps.get(0).referrer__c = contacts.get(1).Id;
        update opps;
        opps = [SELECT Referrer__c,Referrer_Account__c,Referrer_Contact_Type__c  FROM Opportunity];
        System.assert(opps != null, 'Opporutnity record should be returned');
        System.assertEquals(opps.get(0).Referrer__c,contacts.get(1).Id, 'Contact Id should be matched with referrer');
        System.assertEquals(opps.get(0).Referrer_Account__c,contacts.get(1).AccountId,
                            'Account Id should be matched in opportunity and contact');
        System.assertEquals(opps.get(0).Referrer_Contact_Type__c,contacts.get(1).Type__c,
                            'Contact type should be matched in opportunity and contact');
        Test.stopTest();
    }
}