/**
 * @description       : 
 * @author            : Janek Medyk
 * @group             : 
 * @last modified on  : 09-05-2022
 * @last modified by  : Janek Medyk
**/
@isTest
public class OpportunityReaCaseTrHTest {
    @testSetup
    static void initData() {
        BusinessHours hours = [SELECT ID FROM BusinessHours WHERE Name='India (Asia/Kolkata)'];
        Building__c building = UtilBuilding.createBuildings(1, true)[0];
        building.Business_Hours_Id__c = hours.Id;
        building.City__c = 'Paris';
        update building;
        User_Attribute__c ua = new User_Attribute__c(RecordTypeId = (Id)WeworkEngine.getObjectRecordTypeId('User_Attribute__c', 'Building Team'),
                                                    Building__c = building.Id,
                                                    User__c = UserInfo.getUserId(),
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
    private static void reaCaseTest() {
        Opportunity oppty = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        oppty.StageName = 'Closed Won';
        
        Test.startTest();
        update oppty;
        Test.stopTest();

        List<Case> casesAfter = [SELECT Id, Status, REA_Request_Type__c FROM Case WHERE Opportunity__c = :oppty.Id];
        System.assertEquals(1, casesAfter.size(), 'Case was not created.');
        System.assertEquals('Deal Structuring', casesAfter.get(0).REA_Request_Type__c);
        System.assertEquals('Closed Won', casesAfter.get(0).Status);
    }
}