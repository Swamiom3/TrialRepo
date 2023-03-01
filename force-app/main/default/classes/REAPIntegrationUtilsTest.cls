/************************************************************************************************************************************
    Author      :   Vaishnavi Khandar 
    Description :   This class contains the unit test logic for REAPIntegrationUtils class.
    History     :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           18 November 2021    Vaishnavi Khandar      Initial Developement
**************************************************************************************************************************************/
@isTest
public class REAPIntegrationUtilsTest {    
    @testSetup
    public static void initData() {
        Test.startTest();
        testSetupHelper();
        Test.stopTest();
        
    }
    
    public static void testSetupHelper() {
        Building__c testBuilding = new Building__c(Name = 'Test Building for Lease', 
                                                   UUID__c = '53d1032a-332e-11e7-9312-063c4950d72f', 
                                                   Email__c ='testBuilding@wework.com');
        insert testBuilding;
        Building_Lease__c buildingLease = new Building_Lease__c(Lease_UUID__c = 'f7390f20277dd6c334c44b2fcc95c6a1',
                                                                Location__c = testBuilding.Id,
                                                                Location_UUID__c = '4112a913-cffb-413e-816d-5cc7f268257b',
                                                                Property_UUID__c = 'c7d12e59c05f3726305bcab8ef0a8c94',
                                                                Area_UUID__c = 'e0035b2aeda044c9491d73971be295cd',
                                                                Name = 'Test Building forLease Fls 4-5',
                                                                Measurement_Unit__c = 'Per SM');
        insert buildingLease;
    }
    
    @isTest
    static void testLeasedetailsOnBuilding() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponeGeneratorForREAPAPI());
        List<Building__c> buildingRecords = [SELECT Id, Name, UUID__c, Measurement_Unit__c, Date_of_original_lease_agreement__c, Expiration_Date__c, Next_Burndown_Date__c, LastModifiedDate, (SELECT Id, LastModifiedDate, Lease_UUID__c, Area_UUID__c, Location__c, Location_UUID__c, Property_UUID__c, Name, Measurement_Unit__c, Possession_Date__c, Type_of_Lease__c, Lease_Expiration_Date__c, Date_of_lease_agreement__c, Lease_Commencement__c, Rentable_Area__c, Floors__c FROM Building_Lease__r), (SELECT Id, Name, Lease_UUID__c,Lease_financial_security_UUID__c, Building_Lease__c, Building__c, Next_Burndown_Amount__c, Next_Burndown_Date__c, Current_Corporate_Guaranty_Amount__c, Current_Letter_of_Credit_Amount__c FROM Building_Lease_Financial_Details__r) FROM Building__c WHERE Name = 'Test Building for Lease'];
        REAPIntegrationUtils.makeCalloutForREAPIntegration(buildingRecords, false);
        Test.stopTest();
        REAPIntegrationUtils.getQueryBySetting();
        checkAsserts();
    }

    
    public static void checkAsserts() {
        List<Building__c> buildingRecords = [SELECT Id, Name, UUID__c, Measurement_unit__c,LastModifiedDate, Date_of_original_lease_agreement__c, Expiration_Date__c, Next_Burndown_Date__c FROM Building__c WHERE Name = 'Test Building for Lease'] ;
        List<Building_Lease__c> buildingLeaseRecords = [SELECT Id, Lease_UUID__c, Area_UUID__c, Location__c, Location_UUID__c, Property_UUID__c, Name, Measurement_Unit__c, Possession_Date__c, Type_of_Lease__c, Lease_Expiration_Date__c, Date_of_lease_agreement__c, Lease_Commencement__c, Rentable_Area__c, Floors__c FROM Building_Lease__c WHERE Location__c =: buildingRecords[0].Id];
        List<Building_Lease_Financial_Details__c> buildingLeaseFinancialRecords = [SELECT Id, Lease_UUID__c, Lease_financial_security_UUID__c, Building__c, Next_Burndown_Amount__c, Next_Burndown_Date__c, Current_Corporate_Guaranty_Amount__c, Current_Letter_of_Credit_Amount__c FROM Building_Lease_Financial_Details__c WHERE Building__c =: buildingRecords[0].Id];
        System.assertEquals(3, buildingLeaseRecords.size());
        System.assertEquals(2, buildingLeaseFinancialRecords.size());
        //Check all the fields assert for Building Lease record
        System.assertEquals('f7390f20277dd6c334c44b2fcc95c6a1', buildingLeaseRecords[0].Lease_UUID__c);
        System.assertEquals(buildingRecords[0].Id,  buildingLeaseRecords[0].Location__c);
        System.assertEquals('4112a913-cffb-413e-816d-5cc7f268257b', buildingLeaseRecords[0].Location_UUID__c);
        System.assertEquals('c7d12e59c05f3726305bcab8ef0a8c94', buildingLeaseRecords[0].Property_UUID__c);
        System.assertEquals('e0035b2aeda044c9491d73971be295cd', buildingLeaseRecords[0].Area_UUID__c);
        System.assertEquals('Test Building for Lease  Fls 4-5', buildingLeaseRecords[0].Name);
        System.assertEquals('Per SM', buildingLeaseRecords[0].Measurement_Unit__c);
        System.assertEquals('2017-12-15', String.valueOf(buildingLeaseRecords[0].Possession_Date__c));
        System.assertEquals('Net Pass Through', buildingLeaseRecords[0].Type_of_Lease__c);
        System.assertEquals('2033-11-30', String.valueOf(buildingLeaseRecords[0].Lease_Expiration_Date__c));
        System.assertEquals('2017-12-13', String.valueOf(buildingLeaseRecords[0].Date_of_lease_agreement__c));
        System.assertEquals('2018-07-01', String.valueOf(buildingLeaseRecords[0].Lease_Commencement__c));
        System.assertEquals(51661.34, buildingLeaseRecords[0].Rentable_Area__c);
        System.assertEquals('Fls 4-5', buildingLeaseRecords[0].Floors__c);
        
        //Check all the fields assert for Building Lease Financial record
        System.assertEquals('f7390f20277dd6c334c44b2fcc95c6a1', buildingLeaseFinancialRecords[0].Lease_UUID__c);
        System.assertEquals('977b6f1acbcf7a9fc983623b3beb28c5', buildingLeaseFinancialRecords[0].Lease_financial_security_UUID__c);
        System.assertEquals(buildingRecords[0].Id,  buildingLeaseFinancialRecords[0].Building__c);
        System.assertEquals(10514874.2546504, buildingLeaseFinancialRecords[0].Next_Burndown_Amount__c);
        System.assertEquals('2022-07-01', String.valueOf(buildingLeaseFinancialRecords[0].Next_Burndown_Date__c));
        System.assertEquals(13600644.182528, buildingLeaseFinancialRecords[0].Current_Corporate_Guaranty_Amount__c);
        System.assertEquals(0, buildingLeaseFinancialRecords[0].Current_Letter_of_Credit_Amount__c);
        
        //Check all the fields assert for Building record
        System.assertEquals(buildingLeaseRecords[0].Measurement_Unit__c, buildingRecords[0].Measurement_unit__c);
        System.assertEquals(buildingLeaseRecords[0].Date_of_lease_agreement__c, buildingRecords[0].Date_of_original_lease_agreement__c);
        System.assertEquals('2020-08-31', String.valueOf(buildingRecords[0].Expiration_Date__c));
    }
}