/*********************************************************************************************************
	Author        :  Shobhit Gahlot
	Description   :  Test class for JourneyPrivateEventNotificationsTrH
	Issue No.     :  ST-8957
	History       :
-----------------------------------------------------------------------------------------------------------
	VERSION        DATE            AUTHOR             DETAIL
	1          09-Sept-2021      Shobhit Gahlot    Initial development 
**********************************************************************************************************/
@isTest
public class JourneyPrivateEventNotificationsTrHTest {
    private final static String ALLOW_LEAD_SOURCE_CHANGE_PERM_SET_NAME = 'AllowLeadSourceChange';
    @isTest
    public static void privateEventNotifyAfterInsertTest(){
        User assignedUser = [SELECT Id, Name, Email FROM User LIMIT 1];
        List<Lead> testLeads = getInsertedLeads(1, assignedUser);
        List<Journey__c> testJournies = getInsertedJournies(1, testLeads, assignedUser);
        Test.startTest();
        insert testJournies;
        Test.stopTest();
        System.assert(Limits.getEmailInvocations() == 0, 'Email sent');
    }
    @isTest
    public static void privateEventNotifyAfterUpdateTest(){
        User userLeadSourceChange = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId()];
        insert new PermissionSetAssignment(
            AssigneeId = UserInfo.getUserId(),
            PermissionSetId = [SELECT Id FROM PermissionSet WHERE Name =: ALLOW_LEAD_SOURCE_CHANGE_PERM_SET_NAME].Id
        );
        System.runAs(userLeadSourceChange){
            User assignedUser = [SELECT Id, Name, Email FROM User LIMIT 1];
            List<Lead> testLeads = getInsertedLeads(1, assignedUser);
            List<Journey__c> testJournies = getInsertedJournies(1, testLeads, assignedUser);
            insert testJournies;
            testJournies[0].LeadSource_Sub_Type__c = 'Chat';
            testJournies[0].Market__c = 'Alexandria';
            Test.startTest();
            update testJournies;
            Test.stopTest();
        }
        System.assert(Limits.getEmailInvocations() > 0, 'Email not sent');
    }

    @isTest
    public static void privateEventNotifyAfterInsertPortofolioInterestedInTest(){
        User assignedUser = [SELECT Id, Name, Email FROM User LIMIT 1];
        List<Lead> testLeads = getInsertedLeads(1, assignedUser);
        List<Journey__c> testJournies = getInsertedJournies(1, testLeads, assignedUser);
        testJournies[0].Portfolio_Interested_In__c = getInsertedPortfolio().Id;
        insert testJournies;

        Test.startTest();
        update testJournies;
        Test.stopTest();
        System.assert(Limits.getEmailInvocations() > 0, 'Email not sent');
    }

    private static List<Lead> getInsertedLeads (Integer size, User assignedUser){
        List<Lead> testLeads = new List<Lead>();
        for(Integer i = 0 ; i < size ; i++){
                testLeads.add(new Lead(
                                       OwnerId = assignedUser.Id,
                                       LastName = 'Test ' + i,
                                       Email = 'Test'+ i + '@test.com',
                                       Status = 'Known',
                                       Company = 'Test Pvt Ltd',
                                       Phone = '(777) 648-222' + i,
                                       LeadSource = 'Other',
                                       Generate_Journey__c = true
                                      ));
        }
        TestingUtility.insertListWithAssert(testLeads);
        return testLeads;
    }
    private static List<Journey__c> getInsertedJournies(Integer size, List<Lead> testLeads, User assignedUser){
        List<Journey__c> testJourney = new List<Journey__c>();
        for(Integer i = 0; i < size ; i++){
            testJourney.add(new Journey__c(
                                           Name = 'Test Journey' + i, 
                                           OwnerId = assignedUser.Id,
                                           Primary_Lead__c = testLeads[i].Id,
                                           Primary_Lead__r = testLeads[i],
                                           NMD_Next_Contact_Date__c = Date.today(),
                                           Lead_Source__c = 'WeWork.com',
                                           LeadSource_Sub_Type__c = 'Consultation - Event Space'
                                          ));
        }
        return testJourney;
    }

    private static Market__c getInsertedPortfolio(){
       Territory__c territory = new Territory__c(Name = 'Test Territory');
       insert territory;
       Market__c portfolio = new Market__c(Name = 'Test Portfolio', TerritoryID__c = territory.Id);
       insert portfolio;

       return portfolio;
    }
}