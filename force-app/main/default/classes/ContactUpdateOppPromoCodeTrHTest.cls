@isTest
public with sharing class ContactUpdateOppPromoCodeTrHTest {
    
    @isTest
    static void testGetRelatedAccIds_test_positive() {
        List<Contact> contacts = getFakeContacts(2);
        List<Contact> oldContacts = contacts.deepClone(true);
        oldContacts[0].Promo_Code__c = 'Fake_Promo0';
        oldContacts[1].Promo_Code__c = 'Fake_Promo1';
        
        ContactUpdateOppPromoCodeTrH updatePromoTrH = new ContactUpdateOppPromoCodeTrH(contacts, new Map<Id, Contact>(contacts), new Map<Id, Contact>(oldContacts));
        updatePromoTrH.setTriggerContext('after update', true);

        Test.startTest();
        Map<Id, Id> relatedAccIds = updatePromoTrH.getRelatedAccIds();
        Test.stopTest();

        System.assertNotEquals(null, relatedAccIds, 'Result Ids list must not be null');
        System.assertEquals(2, relatedAccIds.size(), 'The number of Contact Ids should be 2');
    }

    @isTest
    static void testGetRelatedAccIds_test_negative() {
        List<Contact> contacts = getFakeContacts(2);
        contacts[0].Promo_Code__c = null;
        contacts[1].Promo_Code__c = null;

        ContactUpdateOppPromoCodeTrH updatePromoTrH = new ContactUpdateOppPromoCodeTrH(contacts, new Map<Id, Contact>(contacts), null);
        updatePromoTrH.setTriggerContext('after insert', true);

        Test.startTest();
        Map<Id, Id> relatedAccIds = updatePromoTrH.getRelatedAccIds();
        Test.stopTest();

        System.assert(relatedAccIds.isEmpty(), 'Result Ids list must be empty');
    }

    @isTest
    static void testGetOppsToUpdate_test_positive(){
        List<Contact> contacts = getFakeContacts(2);
        List<Opportunity> opps = getFakeOpps(4);
        opps[0].AccountId = contacts[0].AccountId;
        opps[1].AccountId = contacts[0].AccountId;
        opps[2].AccountId = contacts[1].AccountId;
        opps[3].AccountId = contacts[1].AccountId;

        ContactUpdateOppPromoCodeTrH updatePromoTrH = new ContactUpdateOppPromoCodeTrH(contacts, new Map<Id, Contact>(contacts), null);
        updatePromoTrH.setTriggerContext('after insert', true);
        updatePromoTrH.oppSelector = (OpportunitySelector)  MockService.createMock(
                                                            OpportunitySelector.class,
                                                            new Map<String, Object>{
                                                            'getSelfServeOppsByAccountIds' => opps});

        Test.startTest();
        List<Opportunity> oppsToUpdate = updatePromoTrH.getOppsToUpdate();
        Test.stopTest();
        System.assertEquals(4, oppsToUpdate.size(), 'The number of Opportunities to Update should be 4');
    }

    @isTest
    static void testGetOppsToUpdate_test_negative(){
        List<Contact> contacts = getFakeContacts(2);
        ContactUpdateOppPromoCodeTrH updatePromoTrH = new ContactUpdateOppPromoCodeTrH(contacts, new Map<Id, Contact>(contacts), null);
        updatePromoTrH.setTriggerContext('after insert', true);
        updatePromoTrH.oppSelector = (OpportunitySelector)  MockService.createMock(
                                                            OpportunitySelector.class,
                                                            new Map<String, Object>{
                                                            'getSelfServeOppsByAccountIds' => new List<Opportunity>()});

        Test.startTest();
        List<Opportunity> oppsToUpdate = updatePromoTrH.getOppsToUpdate();
        updatePromoTrH.afterUpdate();
        Test.stopTest();
        System.assert(oppsToUpdate.isEmpty(), 'Result Opportunities list must be empty');
    }

    static List<Contact> getFakeContacts(Integer numberOfRecords) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            Contact testCont = TestingUtility.createContact(new Map<String,Object>{ 'Id' => TestUtility.getFakeId(Contact.SObjectType),
                                                                                    'LastName' => 'TestPromoContact' + i,
                                                                                    'AccountId' => TestUtility.getFakeId(Account.SobjectType),
                                                                                    'Status__c' => 'Active',
                                                                                    'Promo_Code__c' => 'TestPromoCode' + i}, false);
            contacts.add(testCont);
        }
        return contacts;
    }

    static List<Opportunity> getFakeOpps(Integer numberOfRecords) {
        List<Opportunity> newOpps = new List<Opportunity>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            newOpps.add(new Opportunity(Id = TestUtility.getFakeId(Opportunity.SObjectType),
                                        AccountId = TestUtility.getFakeId(Account.SobjectType),
                                        StageName = 'New',
                                        Name = 'Test Opp ' + i,
                                        CloseDate = System.today().addDays(5),
                                        Referrer__c = TestUtility.getFakeId(Contact.SObjectType),
                                        Building__c = TestUtility.getFakeId(Building__c.SObjectType),
                                        Lead_Source_Detail__c = 'Self Serve'));
        }
        return newOpps;
    }
}