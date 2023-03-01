/**
 * @description       : 
 * @author            : Janek Medyk
 * @group             : 
 * @last modified on  : 09-05-2022
 * @last modified by  : Janek Medyk
**/
@isTest
public class UserAttributeUpdateReaCaseTrHTest {
    @testSetup
    static void initData() {
        User testUser = UtilUser.createUser([SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id, false);
        testUser.Username = 'test@reatest.com';
        insert testUser;
        BusinessHours hours = [SELECT ID FROM BusinessHours WHERE Name='India (Asia/Kolkata)'];
        Building__c building = UtilBuilding.createBuildings(1, true)[0];
        building.Business_Hours_Id__c = hours.Id;
        building.City__c = 'Paris';
        update building;
        User_Attribute__c ua = new User_Attribute__c(RecordTypeId = (Id)WeworkEngine.getObjectRecordTypeId('User_Attribute__c', 'Building Team'),
                                                    Building__c = building.Id,
                                                    User__c = testUser.Id,
                                                    As_of_Date__c = Date.today(),
                                                    End_Date__c = Date.today().addDays(10),
                                                    Building_Team_Role__c = GlobalConstants.USER_ATTRIBUTE_REA);
        insert ua;
        
        Account acc = UtilAccount.GetNewAccounts(1, true)[0];
        Contact contactForOppty = UtilContact.GetNewContacts(1, acc, true)[0];
        Opportunity oppty = UtilOpportunity.GetNewOpportunity(1, acc, false)[0];
        oppty.Name = 'REA Oppty Test 1';
        oppty.Primary_Member__c = contactForOppty.Id;
        oppty.AccountId = contactForOppty.AccountId;
        oppty.Building__c = building.Id;
        oppty.StageName = GlobalConstants.OPPORTUNITY_STAGE_NEGOTIATING;
        oppty.Interested_in_Number_of_Desks__c = 75;
        oppty.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(GlobalConstants.OPP_RT_NAME_RENEWAL).getRecordTypeId();
        insert oppty;
    }
    
    @isTest
    private static void testCoverage() {
        User_Attribute__c ua = [SELECT Id FROM User_Attribute__c WHERE Building_Team_Role__c = :GlobalConstants.USER_ATTRIBUTE_REA LIMIT 1];
        ua.User__c = UserInfo.getUserId();
        
        Test.startTest();
        update ua;
        Test.stopTest();

        Opportunity oppty = [SELECT Id FROM Opportunity WHERE Interested_in_Number_of_Desks__c = 75 LIMIT 1];
        List<Case> casesAfter = [SELECT Id, OwnerId FROM Case WHERE Opportunity__c = :oppty.Id];
        System.assertEquals(ua.User__c, casesAfter.get(0).OwnerId);
    }
}