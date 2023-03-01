/*********************************************************************************************************
    Author        :  Krishna Somwanshi
    Description   :  Test class for BuildingAssignCommunityLeadTrH
    Issue No.     :  ST-8736
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1          24-Aug-2021      Krishna Somwanshi     Refactor
**********************************************************************************************************/
@isTest
public class BuildingAssignCommunityLeadTrHTest {

    @isTest
    private static void assignCommunityLeadInsertTest() {
        User assignedUser = [SELECT Id, Name, Full_Name__c, Email FROM User LIMIT 1];
        List<Building__c> testBuildings = getInsertedBuildings();
        List<Building__c> mockedBuildings = new List<Building__c>{
            new Building__c(Id = testBuildings[0].Id, Community_Sales_Lead__r = assignedUser, Community_Lead__r = assignedUser),
            new Building__c(Id = testBuildings[1].Id, Community_Sales_Lead__r = assignedUser),
            new Building__c(Id = testBuildings[2].Id, Community_Lead__r = assignedUser),
            new Building__c(Id = testBuildings[3].Id)
        };
       
        Test.startTest();
        BuildingAssignCommunityLeadTrH assignCommunityLead = new BuildingAssignCommunityLeadTrH();
        assignCommunityLead.newBuildings = mockedBuildings;
        assignCommunityLead.beforeInsert();
        Test.stopTest();
        System.assertEquals(mockedBuildings[0].Community_Lead__c, mockedBuildings[0].Community_Sales_Lead__c, 'Community Lead and Community Sales Lead are not same');//Positive case
        System.assertEquals(mockedBuildings[1].Community_Lead__c, mockedBuildings[1].Community_Sales_Lead__c, 'Community Lead and Community Sales Lead are not same');//Positive case
        System.assertEquals(mockedBuildings[2].Community_Lead__c, mockedBuildings[2].Community_Sales_Lead__c, 'Community Lead and Community Sales Lead are same');//Negative case
        System.assertEquals(mockedBuildings[3].Community_Lead__c, mockedBuildings[3].Community_Sales_Lead__c, 'Community Lead and Community Sales Lead are same');//Negative case
    }
    
    @isTest
    private static void assignCommunityLeadUpdateTest() {
        User assignedUser = [SELECT Id, Name, Full_Name__c, Email FROM User LIMIT 1];
        List<Building__c> testBuildings = getInsertedBuildings();
        List<Building__c> mockedBuildings = new List<Building__c>{
            new Building__c(Id = testBuildings[0].Id, Community_Sales_Lead__r = assignedUser, Community_Lead__r = assignedUser),
            new Building__c(Id = testBuildings[1].Id, Community_Sales_Lead__r = assignedUser),
            new Building__c(Id = testBuildings[2].Id, Community_Lead__r = assignedUser),
            new Building__c(Id = testBuildings[3].Id)
        };
       
        Test.startTest();
        BuildingAssignCommunityLeadTrH assignCommunityLead = new BuildingAssignCommunityLeadTrH();
        assignCommunityLead.newBuildings = mockedBuildings;
        assignCommunityLead.beforeUpdate();
        Test.stopTest();
        System.assertEquals(mockedBuildings[0].Community_Sales_Lead__c, mockedBuildings[0].Community_Lead__c, 'Community Lead and Community Sales Lead are not same');//Positive case
        System.assertEquals(mockedBuildings[1].Community_Sales_Lead__c, mockedBuildings[1].Community_Lead__c, 'Community Lead and Community Sales Lead are not same');//Positive case
        System.assertEquals(mockedBuildings[2].Community_Sales_Lead__c, mockedBuildings[2].Community_Lead__c, 'Community Lead and Community Sales Lead are same');//Negative case
        System.assertEquals(mockedBuildings[3].Community_Sales_Lead__c, mockedBuildings[3].Community_Lead__c, 'Community Lead and Community Sales Lead are same');//Negative case
    }
    
    private static List<Building__c> getInsertedBuildings() {
        List<Building__c> testBuildings = new List<Building__c>();
        for(Integer i = 0; i < 4; i++) {
            testBuildings.add(new Building__c(
                Id = TestUtility.getFakeId(Building__c.getSObjectType()),
                Name = 'Test Building ' + i
            ));
        }
        return testBuildings;
    }
}