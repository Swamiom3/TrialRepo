/************************************************************************************************************************************
Author      :   Rohit Nimase
Description :   This class is used to test BatchToUpdateGMTOffsetOnBuilding.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                    AUTHOR                  DETAIL
1           14 Feb 2020             Rohit Nimase            Initial Developement
**************************************************************************************************************************************/
@istest
public class BatchToUpdateGMTOffsetOnBuildingTest {

    /************************************************************************************************************************************
        Author              :   Rohit Nimase
        Description         :   This method is used to create the test data.
        Created Date        :   14 Feb 2020
        Issue No.           :   ST-5593, ST-5705
    **************************************************************************************************************************************/
    @TestSetup
    public static void initData(){
        //SalesConsoleSettings.createSettings();
        BatchToUpdateGMTOffsetOnBuilding objBatchData = new BatchToUpdateGMTOffsetOnBuilding();
        List<String> lstOfDSTTimezones = new List<String>(objBatchData.dSTTimezones); 
        List<String> lstOfNoDSTTimezones = new List<String>(objBatchData.noDSTTimezones); 
        List<Building__c>  lstBuildings = new List<Building__c>();
        for(Integer count=0; count <= 4; count++){
            Building__c objBuilding = new Building__c(Name = 'testBuilding'+count, Country__c = 'USA', Portfolio_Name__c = 'test portfolio', CurrencyIsoCode = 'USD', UUID__c = 'buildingUUID'+count, City__c = 'test');
            if(!lstOfDSTTimezones.isEmpty() && count <=2){
                objBuilding.Time_Zone__c = lstOfDSTTimezones[count];
            }else if(!lstOfNoDSTTimezones.isEmpty() && count > 2){
                objBuilding.Time_Zone__c = lstOfNoDSTTimezones[count];
            }
            lstBuildings.add(objBuilding);
        }
        TestingUtility.insertRecordsWithAssert(lstBuildings, false);
    }
    
    /************************************************************************************************************************************
        Author              :   Rohit Nimase
        Description         :   This method is used to test building are updated with required timezones.
        Created Date        :   14 Feb 2020
        Issue No.           :   ST-5593, ST-5705
    **************************************************************************************************************************************/
    @isTest
    public static void verifyUpdateGMTOffsetOnBuilding(){
        
        List<Building__c> lstBuildingsWithoutGMTOffset = [SELECT Id, Time_Zone__c, GMT_Offset__c FROM Building__c];
        for(Building__c objBuild : lstBuildingsWithoutGMTOffset){
            System.assert(objBuild.GMT_Offset__c == null);
        }
        
        Test.startTest();
        BatchToUpdateGMTOffsetOnBuilding objBatchData = new BatchToUpdateGMTOffsetOnBuilding();
        Database.executeBatch(objBatchData, 100);
        Test.stopTest();
        
        List<Building__c> lstBuildingsUpdatedGMTOffset = [SELECT Id, Time_Zone__c, GMT_Offset__c FROM Building__c];
        for(Building__c objBuild : lstBuildingsUpdatedGMTOffset){
            if(!objBatchData.dSTTimezones.isEmpty() && objBatchData.dSTTimezones.contains(objBuild.Time_Zone__c)){
                System.assert(objBuild.GMT_Offset__c != null);
            }else if(!objBatchData.noDSTTimezones.isEmpty() && objBatchData.noDSTTimezones.contains(objBuild.Time_Zone__c)){
                System.assert(objBuild.GMT_Offset__c != null);
            }else{
                System.assert(objBuild.GMT_Offset__c == null);
            }
            
        }
    }
}