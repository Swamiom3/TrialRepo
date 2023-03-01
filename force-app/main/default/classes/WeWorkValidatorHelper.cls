/************************************************************************************************************************************
    Author 		: 	Ajaysinh Chauhan
    Description : 	

    History:
	----------------------------------------------------------------------------------------------------------------------------------
	VERSION		DATE				AUTHOR					DETAIL											Issue No.
    1			08 Feb 2018			Ajaysinh Chauhan		Initial Developement.							-
**************************************************************************************************************************************/
@isTest
public class WeWorkValidatorHelper {
    public static void createTerritoryStructure(){
        Profile weworkSystemAdmin = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        
        Map<String,Object> mapRegionSalesManager = new Map<String,Object>();
        mapRegionSalesManager.put('LastName','TestRegionSalesManager');
        mapRegionSalesManager.put('Username','TestRegionSalesManager@weworkexample.com');
        mapRegionSalesManager.put('Email','testregionsalesmanager@weworkexample.com');
        User RegionSalesManager = TestingUtility.insertUserWithAssert(weworkSystemAdmin.Id, mapRegionSalesManager, true);
        
        Map<String,Object> mapTerritorySalesManager = new Map<String,Object>();
        mapTerritorySalesManager.put('LastName','TestTerritorySalesManager');
        mapTerritorySalesManager.put('Username','TestTerritorySalesManager@weworkexample.com');
        mapTerritorySalesManager.put('Email','testterritorysalesmanager@weworkexample.com');
        User TerritorySalesManager = TestingUtility.insertUserWithAssert(weworkSystemAdmin.Id, mapTerritorySalesManager, true);
        
        Map<String,Object> mapPortfolioSalesManager = new Map<String,Object>();
        mapPortfolioSalesManager.put('LastName','TestPortfolioSalesManager');
        mapPortfolioSalesManager.put('Username','TestPortfolioSalesManager@weworkexample.com');
        mapPortfolioSalesManager.put('Email','testportfoliosalesmanager@weworkexample.com');
        User PortfolioSalesManager = TestingUtility.insertUserWithAssert(weworkSystemAdmin.Id, mapPortfolioSalesManager, true);
        
        Map<String,Object> mapConsumerQueueOwner = new Map<String,Object>();
        mapConsumerQueueOwner.put('LastName','TestConsumerQueueOwner');
        mapConsumerQueueOwner.put('Username','TestConsumerQueueOwner@weworkexample.com');
        mapConsumerQueueOwner.put('Email','testconsumerqueueowner@weworkexample.com');
        User ConsumerQueueOwner = TestingUtility.insertUserWithAssert(weworkSystemAdmin.Id, mapConsumerQueueOwner, true);
        
        Map<String,Object> mapMidmarketQueueOwner = new Map<String,Object>();
        mapMidmarketQueueOwner.put('LastName','TestMidmarketQueueOwner');
        mapMidmarketQueueOwner.put('Username','TestMidmarketQueueOwner@weworkexample.com');
        mapMidmarketQueueOwner.put('Email','testmidmarketqueueowner@weworkexample.com');
        User MidmarketQueueOwner = TestingUtility.insertUserWithAssert(weworkSystemAdmin.Id, mapMidmarketQueueOwner, true);
        
        Map<String,Object> mapEnterpriseQueueOwner = new Map<String,Object>();
        mapEnterpriseQueueOwner.put('LastName','TestEnterpriseQueueOwner');
        mapEnterpriseQueueOwner.put('Username','TestEnterpriseQueueOwner@weworkexample.com');
        mapEnterpriseQueueOwner.put('Email','testenterprisequeueowner@weworkexample.com');
        User EnterpriseQueueOwner = TestingUtility.insertUserWithAssert(weworkSystemAdmin.Id, mapEnterpriseQueueOwner, true);
        
        Map<String,Object> mapClusterSalesManager = new Map<String,Object>();
        mapClusterSalesManager.put('LastName','TestClusterSalesManager');
        mapClusterSalesManager.put('Username','TestClusterSalesManager@weworkexample.com');
        mapClusterSalesManager.put('Email','testclustersalesmanager@weworkexample.com');
        User ClusterSalesManager = TestingUtility.insertUserWithAssert(weworkSystemAdmin.Id, mapClusterSalesManager, true);
        
        Map<String,Object> mapClusterSalesLead = new Map<String,Object>();
        mapClusterSalesLead.put('LastName','TestClusterSalesLead');
        mapClusterSalesLead.put('Username','TestClusterSalesLead@weworkexample.com');
        mapClusterSalesLead.put('Email','testclustersaleslead@weworkexample.com');
        User ClusterSalesLead = TestingUtility.insertUserWithAssert(weworkSystemAdmin.Id, mapClusterSalesLead, true);
        
        Map<String,Object> mapCommunitySalesLead = new Map<String,Object>();
        mapCommunitySalesLead.put('LastName','TestCommunitySalesLead');
        mapCommunitySalesLead.put('Username','TestCommunitySalesLead@weworkexample.com');
        mapCommunitySalesLead.put('Email','testcommunitysaleslead@weworkexample.com');
        User CommunitySalesLead = TestingUtility.insertUserWithAssert(weworkSystemAdmin.Id, mapCommunitySalesLead, true);
        
        Region__c regn = new Region__c(Name='Test Region',Region__c='Test Region',Regional_Sales_Manager__c=RegionSalesManager.Id);
        insert regn;
        System.assert(regn.Id!=null, 'Region not inserted');
        
        Territory__c tertry = new Territory__c(Name='Test Territory',Territory__c='Test Territory',RegionID__c=regn.Id,Territory_Sales_Manager__c=TerritorySalesManager.Id);
        insert tertry;
        System.assert(tertry.Id!=null, 'Territory not inserted');
        
        Market__c mrkt = new Market__c(Name='Delhi',Portfolio__c='Delhi',TerritoryId__c=tertry.Id,Portfolio_Sales_Manager__c=PortfolioSalesManager.Id);
        insert mrkt;
        System.assert(mrkt.Id!=null, 'Portfolio not inserted');

        Cluster__c clstr = new Cluster__c(Name = 'Test Cluster', 
                                          Cluster_Sales_Manager__c = ClusterSalesManager.Id,
                                          Sales_Lead__c = ClusterSalesLead.Id, 
                                          RecordTypeid = Schema.SObjectType.Cluster__c.getRecordTypeInfosByName().get('Sales Cluster').getRecordTypeId());
        insert clstr;
        System.assert(clstr.Id!=null, 'Cluster not inserted');
        
        Building__c bldng = new Building__c(Name='Test Building Tour',Community_Lead__c = CommunitySalesLead.Id, Cluster__c=clstr.Id,Market__c=mrkt.Id,UUID__c=UUIDHandler.generateVersion4());
        insert bldng;
        System.assert(bldng.Id!=null, 'Building not inserted');
        
    }
    public static Database.SaveResult insertWithAssert(sObject record){
        Database.SaveResult result = Database.insert(record);
        return result;
    }
    public static Database.SaveResult updateWithAssert(sObject record){
		Database.SaveResult result = Database.update(record);
        return result;
    }
    public static Database.SaveResult[] insertListWithAssert( List<sObject> sObjectsList)
    {
        Database.SaveResult[] arrSaveResult = Database.insert( sObjectsList);
        for(Database.SaveResult saveResult : arrSaveResult)
            System.assert( saveResult.isSuccess(),'Object Not Inserted : '+saveResult.getErrors());
        return arrSaveResult;
    }
    public static Database.SaveResult[] updateListWithAssert( List<sObject> sObjectsList)
    {
        Database.SaveResult[] arrUpdateResult = Database.update( sObjectsList);
        for(Database.SaveResult saveResult : arrUpdateResult)
            System.assert( saveResult.isSuccess(),'Object Not Updated : '+ saveResult.getErrors());
        return arrUpdateResult;
    }
    public static Map<String,Object> fillDefaultInboundLeadPayload(Map<String,Object> mapData){
        mapData.put('product_interests',new List<String>{'Office Space'});
        mapData.put('product_line','WeWork');
        mapData.put('locale','US');
        mapData.put('country_code','US');
        mapData.put('tour_date',system.today().addDays(1));
        mapData.put('tour_time','09:00AM');
        mapData.put('account_uuid','cvdsvcds');
        mapData.put('contact_uuid','vcdfsvdfs');
        return mapData;
    }
    
}