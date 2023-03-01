/**********************************************************************************************************
    Author        :  Salesforce
    Description   :  This is a test class for OperatingHoursController.
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR           DETAIL
    1              04-Aug-2021    Salesforce       TWSPG-96
**********************************************************************************************************/
@isTest
private class OperatingHoursControllerTest {
    @testSetup
    static void setup(){        
        Building__c testBuildng = new Building__c(Name = 'Test Building', No_Longer_in_Use__c=false, Address__c='123 Mission St', City__c='california', Country__c='USA', Postal_Code__c='90168', State__c='california', Time_Zone__c='America/New_York');
        TestingUtility.insertWithAssert(testBuildng, 'Building not inserted');
    }

    @isTest
    private static void getBuildingOperatingHours_text_positive() {
        Building__c testBuildng = [SELECT Id FROM Building__c WHERE Name = 'Test Building'];
        OperatingHours oHour = [SELECT Id, Name FROM OperatingHours WHERE Building_Id__c =: testBuildng.Id AND Host_Id__c = null LIMIT 1];
        OperatingHoursController.getBuildingOperatingHours (testBuildng.Id);
        System.assertEquals('Test Building - Operating Hours', oHour.Name, 'The OperatingHours record name should be Test Building - Operating Hours');
    }

    @isTest
    private static void getBuildingOperatingHours_text_negative() {
        String operatingHoursStr = OperatingHoursController.getBuildingOperatingHours ('');
        System.assertEquals('[]', operatingHoursStr, 'The OperatingHours should be emplty');
    }
}