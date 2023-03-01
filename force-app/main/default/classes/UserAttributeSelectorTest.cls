/*************************************************************************************************************************************
    Author      :   Tomasz Sadowski
    Description :   This class provides sufficient test coverage for UserAttributeSelector class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR             DETAIL
    1          2 Dec, 2021    Tomasz Sadowski    Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class UserAttributeSelectorTest {
    private static UserAttributeSelector uaSelector = new UserAttributeSelector();

    @testSetup
    static void setup() {
        Schema.DescribeSobjectResult describeResult = Schema.describeSObjects(new List<String>{'User_Attribute__c'})[0];
        String buildingTeamRT = describeResult.getRecordTypeInfosByName().get('Building Team').getRecordTypeId();
        Building__c building = UtilBuilding.createBuildings(1, true)[0];
        User_Attribute__c ua = new User_Attribute__c(RecordTypeId = (Id) buildingTeamRT,
                                                    Building__c = building.Id,
                                                    User__c = UserInfo.getUserId(),
                                                    As_of_Date__c = Date.today(),
                                                    End_Date__c = Date.today().addDays(10),
                                                    Building_Team_Role__c = GlobalConstants.USER_ATTRIBUTE_REA);
        insert ua;
    }

    @isTest
    static void shouldGetUserAttributesByIds() {
        List<User_Attribute__c> uas;
        Set<Id> uaIds = new Map <Id, User_Attribute__c> ([SELECT Id
                                               FROM User_Attribute__c]).keySet();

        Test.startTest();
        uas = uaSelector.getUserAttributesById(new List<Id>(uaIds));
        Test.stopTest();

        System.assertEquals(1, uas.size(), 'Should get 1 user attribute');
    }

    @isTest
    static void shouldGetUserAttributesByBuildingIds() {
        List<User_Attribute__c> uas;
        Set<Id> buildingIds = new Map <Id, Building__c> ([SELECT Id
                                               FROM Building__c]).keySet();

        Test.startTest();
        uas = uaSelector.getUserAttributesByBuildingId(buildingIds);
        Test.stopTest();

        System.assertEquals(1, uas.size(), 'Should get 1 user attribute');
    }
}