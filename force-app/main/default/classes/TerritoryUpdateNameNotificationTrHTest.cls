/*********************************************************************************************************
	Author        :  Shobhit Gahlot
	Description   :  Test class for TerritoryUpdateNameNotificationTrH
	Issue No.     :  ST-8870
	History       :
-----------------------------------------------------------------------------------------------------------
	VERSION        DATE            AUTHOR             DETAIL
	1          17-Aug-2021      Shobhit Gahlot    Initial development 
**********************************************************************************************************/

@isTest
public class TerritoryUpdateNameNotificationTrHTest {
    @testSetup
    private static void initData() {     
        Test.startTest();        
        List<Territory__c> testTerritories = getInsertedTerritories(new List<String>{'North Test', 'South Test'});
        TestingUtility.insertListWithAssert(testTerritories);
        Group testGroup = [SELECT (SELECT UserOrGroupId FROM GroupMembers) FROM Group WHERE Name =: Label.Queue_Name];
        if (testGroup == null) {
            testGroup = new Group(Name = Label.Queue_Name, Type = 'Queue');
            TestingUtility.insertWithAssert(testGroup);
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SobjectType = 'Territory__c');
            TestingUtility.insertWithAssert(testQueue);
        }
		User standardUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            LastName = 'LastName123',
            Username = 'test@test.com' + System.currentTimeMillis(),
            CompanyName = 'Test_Comp',
            Email = 'test@test.com',
            IsActive = TRUE,
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        insert standardUser;
        Test.stopTest();    
    }
    
    @isTest
    public static void territoryUpdateNameNotificationTest(){

        Group testGroup = [SELECT (SELECT UserOrGroupId FROM GroupMembers) FROM Group WHERE Name =: Label.Queue_Name];
        System.assert(testGroup != null);
        //to avoid mixed DML
		User standardUser = [SELECT id from User where lastname = 'LastName123' limit 1];
        System.runAs(new User(Id = UserInfo.getUserId())) {
            if (testGroup.GroupMembers.isEmpty()) {
                GroupMember member = new GroupMember();
                member.UserOrGroupId = standardUser.Id;
                member.GroupId = testGroup.Id;
                TestingUtility.insertWithAssert(member);
            }  
        }

        List<Territory__c> territoryToUpdate = new List<Territory__c>();
        List<Territory__c> insertedTerritories = [SELECT Id, Name FROM Territory__c];
        for(Territory__c territory : insertedTerritories){
            if(territory.Name == 'North Test'){
                territory.Name = 'West Territory';
            }
            territoryToUpdate.add(territory);
        }
        Test.startTest();
        update territoryToUpdate;
        Test.stopTest();  

        System.assertEquals(1, TerritoryUpdateNameNotificationTrH.totalEmails, 'Email gets send when territory name updated');
    }
    
    private static List<Territory__c> getInsertedTerritories(List<String> territoriesName) {
        List<Territory__c> testTerritories = new List<Territory__c>();
        for(String territoryName : territoriesName) {
            testTerritories.add(new Territory__c( 
                Name = territoryName,
                Territory__c = 'Test'
            ));
        }
        return testTerritories;
    }
}