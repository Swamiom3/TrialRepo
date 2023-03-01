/************************************************************************************************************************************
    Author      : Shobhit Gahlot
    Description : This class will have all the testing logic for CommunityViewSalesInquiryServer
--------------------------------------------------------------------------------------------------------------------------------------
    VERSION                 DATE                    AUTHOR                          DETAIL
    1                       10 June, 2020           Shobhit Gahlot                  Initial Development
*************************************************************************************************************************************/
@isTest
public class CommunityViewSalesInquiryServerTest {
    private static TaskSelector taskSelector = new TaskSelector();

    @testSetup
    static void testSetupData(){
        List<Account> lstAccount = UtilAccount.GetNewAccounts(1, true);
        List<Contact> lstContact = UtilContact.GetNewContacts(1, lstAccount[0], true);
        Campaign campaignToInsert = new Campaign(Name = 'Test Campaign 3', State__c = 'DC', City__c = 'Washington DC',
                                        Type = 'Splash Event', Email_Address__c='campaign2@example.com');
        TestingUtility.insertWithAssert(campaignToInsert);
    }

    @isTest
    static void getBillingAccountRecordType() {
        String billingAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();
        Test.startTest();
        String billingAccountRecordType = (String)CommunityViewSalesInquiryServer.getBillingAccountRecordType().data;
        Test.stopTest();
        System.assertEquals(billingAccountRecordTypeId, billingAccountRecordType);
    }

    @isTest
    static void saveTaskAndOpportunity(){
        List<Account> lstAccount = [SELECT Id, Name FROM Account];
        List<Contact> lstContact = [SELECT Id FROM Contact];
        List<Campaign> campaigns = [SELECT Id FROM Campaign];
        List<Opportunity> lstOpportunity = UtilOpportunity.GetNewOpportunity(1, lstAccount[0], false);
        Task objTask = new Task();
        objTask.WhoId = lstContact[0].Id;
        objTask.Type = 'Sales Inquiry';
        objTask.Status = 'Not Started';
        CampaignMember campaignMember = new CampaignMember();
        campaignMember.CampaignId = campaigns[0].Id;
        campaignMember.ContactId = lstContact[0].Id;
        System.assert(taskSelector.getTasks().size() == 0);
        System.assert([SELECT Id FROM Opportunity].size() == 0);
        Test.startTest();
        CommunityViewSalesInquiryServer.saveTaskAndOpportunity(objTask, lstOpportunity[0], campaignMember);
        Test.stopTest();
        List<Opportunity> lstOpportunityForAssert = [SELECT Id, OwnerId FROM Opportunity];
        List<Task> lstTasks = taskSelector.getTasksWithRelatedObjectsFieldsByWhatIds(new List<Id>{ lstOpportunity[0].Id });
        List<CampaignMember> campaignMembers = [SELECT Id, ContactId FROM CampaignMember];
        List<Contact> contacts = [SELECT Id FROM Contact];
        System.assert(lstTasks.size() == 1);
        System.assert(lstOpportunityForAssert.size() == 1);
        System.assert(campaignMembers.size() == 1);
        Id apiUserId = UserUtility.getApiUserId();
        System.assertEquals(lstOpportunityForAssert[0].OwnerId, apiUserId);
        System.assertEquals(lstTasks[0].OwnerId, apiUserId);
        System.assertEquals(campaignMembers[0].ContactId, contacts[0].Id);
    }
}