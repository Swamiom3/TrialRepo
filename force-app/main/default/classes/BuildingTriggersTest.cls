/************************************************************************************************************************************
Author      :   Sunil Bhosale
Description :   This class will contain test methods of Building triggers.

History:

----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE              AUTHOR                  DETAIL
1.0         05 Feb 2020      Sunil Bhosale        Modification according to new test structure

*************************************************************************************************************************************/
@isTest
public class BuildingTriggersTest {
    
    public static final String buildinguuid1 = '123abc';
    public static final String buildinguuid2 = '456def';
    @testSetup
    static void setup(){
        List<sObject> lstSbjectToInsert = new List<sObject>();
        List<Map<String, Object>> lstUserData =  new List<Map<String, Object>>();
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'WeWork System Administrator'];
        lstUserData.add(new Map<String,Object>{'Email' => 'testUser'+1+'@example.com', 'Sales_Role__c' => 'Consumer - SM'});
        lstUserData.add(new Map<String,Object>{'LastName' => 'TestRegionSalesManager', 'Email' => 'testregionsalesmanager@weworkexample.com'});//RegionSalesManager
        lstUserData.add(new Map<String,Object>{'LastName' => 'TestTerritorySalesManager', 'Email' => 'testterritorysalesmanager@weworkexample.com'});//TerritorySalesManager
        lstUserData.add(new Map<String,Object>{'LastName' => 'TestPortfolioSalesManager', 'Email' => 'testportfoliosalesmanager@weworkexample.com'});//PortfolioSalesManager
        lstUserData.add(new Map<String,Object>{'LastName' => 'TestClusterSalesManager', 'Email' => 'testclustersalesmanager@weworkexample.com'});//ClusterSalesManager
        lstUserData.add(new Map<String,Object>{'LastName' => 'TestClusterSalesLead', 'Email' => 'testclustersaleslead@weworkexample.com'});//ClusterSalesLead
        lstUserData.add(new Map<String,Object>{'LastName' => 'TestCommunityLead', 'Email' => 'testcommunitylead@weworkexample.com'});//CommunityLead
        lstUserData.add(new Map<String,Object>{'LastName' => 'TestCommunityManager', 'Email' => 'testcommunitymanager@weworkexample.com'});//CommunityManager
        List<User> lstUsers = TestingUtility.insertUserWithAssert(testProfile.Id, lstUserData, true);
        Test.startTest();
        Region__c objRegion = new Region__c(Name = 'Test Region', Region__c = 'Test Region', Regional_Sales_Manager__c = lstUsers[1].Id);
        TestingUtility.insertWithAssert(objRegion, 'Region not inserted');
        
        Territory__c objTerritory = new Territory__c(Name = 'Test Territory', Territory__c =' Test Territory', RegionID__c = objRegion.Id, Territory_Sales_Manager__c = lstUsers[2].Id);
        TestingUtility.insertWithAssert(objTerritory, 'Territory not inserted');
        
        Market__c objMarket = new Market__c(Name = 'Test Portfolio', Portfolio__c = 'Test Portfolio', TerritoryId__c = objTerritory.Id, Portfolio_Sales_Manager__c = lstUsers[3].Id);
        TestingUtility.insertWithAssert(objMarket, 'Portfolio not inserted');
        
        Id recordTypeId =Schema.SObjectType.Cluster__c.getRecordTypeInfosByName().get('Sales Cluster').getRecordTypeId();
        Cluster__c objCluster = new Cluster__c(Name = 'Test Cluster', Cluster_Sales_Manager__c = lstUsers[4].Id, Sales_Lead__c = lstUsers[5].Id,recordtypeid=recordTypeId);
        TestingUtility.insertWithAssert(objCluster, 'Cluster not inserted');
        
        lstSbjectToInsert.addAll(createRawBuildingRecords(lstUsers, objCluster, objMarket));
        if(!lstSbjectToInsert.isEmpty()){
            insert lstSbjectToInsert;
        }
       
        Account objAccount = new Account(name = 'Test Account');
        TestingUtility.insertWithAssert(objAccount);
        
        Contact objContact = new Contact(
            FirstName = 'FirstNameTest',
            LastName = 'TestContact',
            Email = 'testcontact@example.com',
            AccountId = objAccount.Id
        );           
        TestingUtility.insertWithAssert(objContact);
        objAccount.Primary_Member__c = objContact.Id;
        TestingUtility.updateWithAssert(objAccount);
        
        Opportunity objOpp = new Opportunity(name = 'Test Opportunity', AccountID = objAccount.Id, Primary_Member__c = objContact.Id, StageName = 'Qualifying', CloseDate = system.today(), Building__c = lstSbjectToInsert[0].Id, Actual_Start_Date__c = Date.today());
        TestingUtility.insertWithAssert(objOpp); 
        Test.stopTest();        
    }
    
    @isTest
    public static void BuildingHandlerTest(){
        List<Building__c> lstInsertedBuildings = getAllBuildingRecords();
        Map<String,Building__c> mapsObjectForUpdate = new Map<String, Building__c>();
        Map<String, Opportunity> mapOpportunity = new Map<String, Opportunity>();
        //------Insert trigger assert--------
       BuildingHandlerTest.test_getSpecificBuildings(lstInsertedBuildings);
       BuildingHandlerTest.test_get_buildings_uuids_by_multipicklist(lstInsertedBuildings);
       BuildingHandlerTest.test_get_buildings_by_uuid(lstInsertedBuildings);
       BuildingHandlerTest.test_get_building_id_by_uuid(lstInsertedBuildings);
        
        //------update trigger values--------
      BuildingHandlerTest.update_get_building_uuid_By_Account(lstInsertedBuildings, mapsObjectForUpdate, mapOpportunity);
        
        Test.startTest();
        if(!mapsObjectForUpdate.values().isEmpty()){
            update mapsObjectForUpdate.values();
        }
        if(!mapOpportunity.values().isEmpty()){
            update mapOpportunity.values();
        }
        Test.stopTest();      
        //------update trigger assert--------
       BuildingHandlerTest.test_update_get_building_uuid_By_Account(lstInsertedBuildings);
    }
    
    /************************************************************************************************************************************
        Description         :   This test method is used to verify New trigger structure triggers test classes  which is related Billing Account triggers.
        Issue No.           :   
        Created Date        :   09 Feb 2020
    **************************************************************************************************************************************/
    @isTest
    public static void buildingTriggerNewStructuredTriggersTest(){
        Test.startTest();
        Map<String,Building__c> mapsObjectForUpdate = new Map<String, Building__c>();
        TestManager.handleTestProcess('Building__c', getAllBuildingRecords(), null, 'buildingTriggerNewStructuredTriggersTest', TestManager.insertAssertEvent);
        TestManager.handleTestProcess('Building__c', getAllBuildingRecords(), mapsObjectForUpdate, 'buildingTriggerNewStructuredTriggersTest', TestManager.updateValuesEvent);
        if(!mapsObjectForUpdate.values().isEmpty()){
            update mapsObjectForUpdate.values();
        }
        Test.stopTest();
        TestManager.handleTestProcess('Building__c',  getAllBuildingRecords(), null, 'buildingTriggerNewStructuredTriggersTest', TestManager.updateAssertEvent);
    }
    
    public static List<Building__c> getAllBuildingRecords(){
        return(List<Building__c>) Database.query('SELECT '+String.join(getBuildingFields(),',')+' FROM Building__c');
    }
    
    public static List<String> getBuildingFields(){
        set<String> setBuildingFields = new set<String>();
        setBuildingFields.add('Id');
        setBuildingFields.add('Name');
        setBuildingFields.add('Cluster_Name__c');
        setBuildingFields.add('Portfolio_Name__c');
        setBuildingFields.add('Territory_Name__c');
        setBuildingFields.add('Region_Name__c');
        setBuildingFields.add('Cluster_Sales_Manager_Name__c');
        setBuildingFields.add('Cluster_Sales_Lead_Name__c');
        setBuildingFields.add('Portfolio_Sales_Manager_Name__c');
        setBuildingFields.add('Territory_Sales_Manager_Name__c');
        setBuildingFields.add('Regional_Sales_Manager_Name__c');
        setBuildingFields.add('Cluster_Sales_Manager_Email__c');
        setBuildingFields.add('Cluster_Sales_Lead_Email__c');
        setBuildingFields.add('Portfolio_Sales_Manager_Email__c');
        setBuildingFields.add('Territory_Sales_Manager_Email__c');
        setBuildingFields.add('Regional_Sales_Manager_Email__c');
        setBuildingFields.add('Community_Lead__c');
        setBuildingFields.add('Responsible_CM__c');
        setBuildingFields.add('Community_Lead__r.Name');
        setBuildingFields.add('Responsible_CM__r.Name');
        setBuildingFields.add('Community_Sales_Lead__c');
        setBuildingFields.add('UUID__c');
        return new List<String>(setBuildingFields);
    }
    
    public static List<Building__c> createRawBuildingRecords(List<User> lstUsers, Cluster__c objCluster, Market__c objMarket){
        List<Building__c> lstBuildings = new List<Building__c>();
        lstBuildings.add(new Building__c(Name = 'B1', Community_Sales_Lead__c = lstUsers[0].Id, UUID__c=buildinguuid1));
        lstBuildings.add(new Building__c(Name = 'B2', UUID__c=buildinguuid2));
        lstBuildings.addAll(TestingUtility.createBuildings(new Map<String, Object>{'Cluster__c' => objCluster.Id, 'Name' => 'Test Name 001'}, 1));
        lstBuildings.addAll(TestingUtility.createBuildings(new Map<String, Object>{'Market__c' => objMarket.Id, 'Name' => 'Test Name 002'}, 1));
        lstBuildings.addAll(TestingUtility.createBuildings(new Map<String, Object>{'Community_Lead__c' => lstUsers[6].Id, 'Name' => 'Test Name 003'}, 1));
        lstBuildings.addAll(TestingUtility.createBuildings(new Map<String, Object>{'Responsible_CM__c' => lstUsers[7].Id, 'Name' => 'Test Name 004'}, 1));
        
        return lstBuildings;
    }

}