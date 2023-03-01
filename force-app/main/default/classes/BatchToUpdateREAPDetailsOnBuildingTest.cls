/************************************************************************************************************************************
    Author      :   Vaishnavi Khandar
    Description :   This class contains the unit test logic for atchToUpdateREAPDetailsOnBuildingLease class.
    History     :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           18 November 2021    Vaishnavi Khandar       Initial Developement
**************************************************************************************************************************************/
@isTest
public class BatchToUpdateREAPDetailsOnBuildingTest {
   
    @testSetup
    static void initData() {
        Test.startTest();
        REAPIntegrationUtilsTest.testSetupHelper();
        Test.stopTest();
    }
    @isTest
    static void testLeasedetailsOnBuilding() {        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponeGeneratorForREAPAPI());
        List<Building__c> buildingRecords = [SELECT Id, Name, UUID__c, Measurement_Unit__c, Date_of_original_lease_agreement__c, Next_Burndown_Date__c, Expiration_Date__c, LastModifiedDate, (SELECT Id, LastModifiedDate, Lease_UUID__c, Area_UUID__c, Location__c, Location_UUID__c, Property_UUID__c, Name, Measurement_Unit__c, Possession_Date__c, Type_of_Lease__c, Lease_Expiration_Date__c, Date_of_lease_agreement__c, Lease_Commencement__c, Rentable_Area__c, Floors__c FROM Building_Lease__r), (SELECT Id, Name, Lease_UUID__c,Lease_financial_security_UUID__c, Building_Lease__c, Building__c, Next_Burndown_Amount__c, Next_Burndown_Date__c, Current_Corporate_Guaranty_Amount__c, Current_Letter_of_Credit_Amount__c FROM Building_Lease_Financial_Details__r) FROM Building__c WHERE Name = 'Test Building for Lease'];
        Database.executeBatch(new BatchToUpdateREAPDetailsOnBuildingLease(), 1);
        Test.stopTest();
        REAPIntegrationUtilsTest.checkAsserts();
    }
}