/**********************************************************************************************************
    Author        :  Vaishnavi Khandar
    Description   :  Test for REAP Integration component Controller
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE              AUTHOR           
      1         18 November 2021     Vaishnavi Khandar      
**********************************************************************************************************/
@isTest
public class ReapIntegrationDetailCmpControllerTest {
    
    @testSetup
    public static void testSetup(){
        Test.startTest();
        REAPIntegrationUtilsTest.testSetupHelper();
        Test.stopTest();
    }
    
    @isTest
    public static void LightningComponentControllerMethod2(){
        List<Building__c> buildings = [SELECT Id, UUID__c FROM Building__c WHERE Name='Test Building for Lease'];
        Test.setMock(HttpCalloutMock.class, new MockHttpResponeGeneratorForREAPAPI());
        DatabaseResult result = ReapIntegrationDetailCmpController.updateLeaseDetailsForSpecificBuilding(buildings[0].Id);
        System.assertEquals(result.Success, true);
        try {
            ReapIntegrationDetailCmpController.updateLeaseDetailsForSpecificBuilding(null);
        } catch(Exception ex) {
            System.assertNotEquals(null, ex);
        }
    }
    
}