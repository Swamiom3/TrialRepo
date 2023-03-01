/**********************************************************************************************************
    Author        :  Salesforce
    Description   :  This is a test class for BuildingAssociateServiceTerritoryTrH.
    Issue No.     :  TWSPG-2142
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE          AUTHOR           DETAIL
      1         21-July-2021    Salesforce      TWSPG-2142
**********************************************************************************************************/
@isTest
private class BuildingAssociateServiceTerritoryTrHTest {
    @testSetup
    static void setup(){
      OperatingHours testOpHour = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday');
      insert testOpHour;
      Building__c testBuildng = new Building__c(Name = 'Test Building', No_Longer_in_Use__c=false, Address__c='123 Mission St', City__c='california', Country__c='USA', Postal_Code__c='90168', State__c='california', Time_Zone__c='America/New_York');
      TestingUtility.insertWithAssert(testBuildng, 'Building not inserted');

      testBuildng = new Building__c(Name = 'Test Building without TimeZone', No_Longer_in_Use__c=false, Address__c='123 Mission St', City__c='california', Country__c='USA', Postal_Code__c='90168', State__c='california');
      TestingUtility.insertWithAssert(testBuildng, 'Building not inserted');
    }

    @isTest
    private static void validateServiceTerritoryInsert() {
      Building__c testBuildng = [SELECT Id FROM Building__c WHERE Name = 'Test Building'];
      Building__c testKoreaBuildng = new Building__c(Name = 'Test Korea Building', No_Longer_in_Use__c=false, Address__c='123 Mission St', City__c='Seul', Country__c='South Korea', Postal_Code__c='90168', State__c='california', Time_Zone__c='America/New_York');
      TestingUtility.insertWithAssert(testKoreaBuildng, 'Building not inserted');
      ServiceTerritory testServiceTerritory= [SELECT Id, Building_Id__c, Name FROM ServiceTerritory WHERE Building_Id__r.Name = 'Test Building'];
      ServiceTerritory testKoreaServiceTerritory= [SELECT Id, Country, Name FROM ServiceTerritory WHERE Building_Id__r.Name = 'Test Korea Building'];
      System.assertEquals('Test Building', testServiceTerritory.Name, 'The building name should be Test Building');
      System.assertEquals('Korea', testKoreaServiceTerritory.Country, 'The building country was not set to Korea');
    }    

    @isTest
    private static void validateServiceTerritoryUpdate() {
      Building__c testBuildng = [SELECT Id FROM Building__c WHERE Name = 'Test Building'];
      testBuildng.Name='Test Building 1';
      update testBuildng;
      ServiceTerritory testServiceTerritory= [SELECT Id, Building_Id__c, Name FROM ServiceTerritory WHERE Building_Id__r.Name = 'Test Building 1'];
      System.assertEquals('Test Building 1', testServiceTerritory.Name, 'The Service Territory name should be Test Building 1');
    }

    @isTest
    private static void validateServiceTerritory_test_negative() {
      // The below test covers the negative scenario if the timezone on the building is empty then it will be defaulted to GMT for OperatingHours
      Building__c testBuildng = [SELECT Id FROM Building__c WHERE Name = 'Test Building without TimeZone'];      
      OperatingHours testOperatingHours = [SELECT Id, TimeZone FROM OperatingHours WHERE Building_Id__c =: testBuildng.Id AND Host_Id__c = null];
      System.assertEquals('GMT', testOperatingHours.TimeZone, 'The OperatingHours Time Zone should be GMT');
    }
        
}