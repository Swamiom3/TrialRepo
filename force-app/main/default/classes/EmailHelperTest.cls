/************************************************************************************************************************************
    Author      :   Maciej Miłosz
    Description :   Test class for Email Helper
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           28 Jan 2021         Maciej Miłosz           Trigger refactoring
**************************************************************************************************************************************/
@isTest
public class EmailHelperTest {
    @isTest
    public static void setEmailDomainForLeads_beforeInsertTest() {
        List<Lead> newLeads = createLeads(10);
        LeadSetEmailDomainTrH handler = new LeadSetEmailDomainTrH(newLeads, null);
        Test.startTest();
        handler.beforeInsert();
        Test.stopTest();
        for(Lead newLead : newLeads){
            System.assertEquals('example.com', newLead.Email_Domain_Text__c, 'Email Domain should be set on before insert operation.');
        }
    }
    
    @isTest
    public static void setEmailDomainForLeads_beforeUpdateTest() {
        List<Lead> newLeads = createLeads(10);
        LeadSetEmailDomainTrH handler = new LeadSetEmailDomainTrH(newLeads, null);
        handler.beforeInsert();
        Map<Id, Lead> oldLeadsMap = new Map<Id, Lead>(newLeads.deepClone(true, false, false));
        newLeads[0].Email = 'test1@notExample.com';
        handler = new LeadSetEmailDomainTrH(newLeads, oldLeadsMap);
        Test.startTest();
        handler.beforeUpdate();
        Test.stopTest();
        System.assertEquals('notexample.com', newLeads[0].Email_Domain_Text__c, 'Email Domain should be changed upon before update operation.');
    }

    @isTest
    public static void setEmailDomainForLeads_DMLTest(){
        Lead leadRecord = TestingUtility.createLead(new Map<String, Object> {
            'Email' => 'testdml@truedmltest.com',
            'LastName' => 'testdml',
            'Phone' => '123456789011'
        }, false);
        insert leadRecord;
        Lead assertRecord = [SELECT Id, Email_Domain_Text__c FROM Lead WHERE Id = :leadRecord.Id];
        System.assertEquals('truedmltest.com', assertRecord.Email_Domain_Text__c, 'Email Domain should be set after insertion of a lead record.');
        Test.startTest();
        leadRecord.Email = 'notimportant@updatedDomain.com';
        MetadataDrivenTriggerHandler.clearLoopCount();
        update leadRecord;
        Test.stopTest();
        Lead updateAssertRecord = [SELECT Id, Email_Domain_Text__c FROM Lead WHERE Id = :leadRecord.Id];
        System.assertEquals('updateddomain.com', updateAssertRecord.Email_Domain_Text__c, 'Email Domain should be set after update of a lead record.');
    }

    private static List<Lead> createLeads(Integer leadsToCreate){
        List<Lead> retList = new List<Lead>();
        for (Integer i = 0; i < leadsToCreate; i++) {
            retList.add(TestingUtility.createLead(new Map<String, Object> {
                'Id' => TestUtility.getFakeId(Lead.SObjectType),
                'Email' => 'test' + String.valueOf(i) + '@example.com',
                'LastName' => 'test' + String.valueOf(i),
                'Phone' => '1234567' + i
            }, false));
        }
        return retList;
    }
}