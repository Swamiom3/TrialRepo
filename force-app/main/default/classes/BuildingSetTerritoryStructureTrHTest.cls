/*********************************************************************************************************
    Author        :  Krishna Somwanshi
    Description   :  Test class for BuildingSetTerritoryStructureTrH
    Issue No.     :  ST-8736
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1          24-Aug-2021      Krishna Somwanshi     Refactor
**********************************************************************************************************/
@isTest
public class BuildingSetTerritoryStructureTrHTest {

    @isTest
    private static void setTerritoryStructuretestInsert() {
        User assignedUser = UserUtility.getUserById(UserInfo.getUserId());
        List<Cluster__c> clusters = getInsertedClusters();
        List<Region__c> regions = getInsertedRegions(assignedUser);
        List<Territory__c> territories = getInsertedTerritories(regions, assignedUser);
        List<Market__c> portfolios = getInsertedPortfolios(territories);
        List<Building__c> buildings = getInsertedBuildings();
        
        List<Cluster__c> mockedClusters = new List<Cluster__c>{
            new Cluster__c(Id = clusters[0].Id, Name = 'Test Cluster 1', Cluster_Sales_Manager__c = assignedUser.Id, Cluster_Sales_Manager__r = assignedUser, Sales_Lead__c = assignedUser.Id, Sales_Lead__r = assignedUser),//positive mocking
            new Cluster__c(Id = clusters[1].Id, Name = 'Test Cluster 2', Cluster_Sales_Manager__c = assignedUser.Id, Cluster_Sales_Manager__r = assignedUser, Sales_Lead__c = assignedUser.Id, Sales_Lead__r = assignedUser),//positive mocking
            new Cluster__c(Id = clusters[2].Id),//negative mocking
            new Cluster__c(Id = clusters[3].Id)//negative mocking
        };    
    
        List<Market__c> mockedPortfolios = new List<Market__c>{
            new Market__c(Id = portfolios[0].Id, Sub_Territory__c = mockedClusters[0].Id, Sub_Territory__r = mockedClusters[0], TerritoryID__c = territories[0].Id, TerritoryID__r = territories[0], Portfolio_Sales_Manager__c = assignedUser.Id, Portfolio_Sales_Manager__r = assignedUser),//positive mocking
            new Market__c(Id = portfolios[1].Id, Sub_Territory__c = mockedClusters[1].Id, Sub_Territory__r = mockedClusters[1], TerritoryID__c = territories[1].Id, TerritoryID__r = territories[0], Portfolio_Sales_Manager__c = assignedUser.Id, Portfolio_Sales_Manager__r = assignedUser),//positive mocking
            new Market__c(Id = portfolios[2].Id),//negative mocking
            new Market__c(Id = portfolios[3].Id)//negative mocking
        };
        
        List<Building__c> mockedBuildings = new List<Building__c>{
            new Building__c(Id = buildings[0].Id, Cluster__c = mockedClusters[0].Id, Cluster__r = mockedClusters[0], Market__c = mockedPortfolios[0].Id, Market__r = mockedPortfolios[0], Community_Lead__c = assignedUser.Id, Community_Lead__r = assignedUser, Community_Sales_Lead__c = assignedUser.Id, Community_Sales_Lead__r = assignedUser, Responsible_CM__c = assignedUser.Id, Responsible_CM__r = assignedUser),
            new Building__c(Id = buildings[1].Id, Cluster__c = mockedClusters[1].Id, Cluster__r = mockedClusters[1], Market__c = mockedPortfolios[1].Id, Market__r = mockedPortfolios[1], Community_Lead__c = assignedUser.Id, Community_Lead__r = assignedUser, Community_Sales_Lead__c = assignedUser.Id, Community_Sales_Lead__r = assignedUser, Responsible_CM__c = assignedUser.Id, Responsible_CM__r = assignedUser),
            new Building__c(Id = buildings[2].Id, Market__c = mockedPortfolios[2].Id, Market__r = mockedPortfolios[2], Community_Lead__c = assignedUser.Id, Community_Lead__r = assignedUser, Community_Sales_Lead__c = assignedUser.Id, Community_Sales_Lead__r = assignedUser, Responsible_CM__c = assignedUser.Id, Responsible_CM__r = assignedUser),
            new Building__c(Id = buildings[3].Id, Community_Lead__c = assignedUser.Id, Community_Lead__r = assignedUser, Community_Sales_Lead__c = assignedUser.Id, Community_Sales_Lead__r = assignedUser, Responsible_CM__c = assignedUser.Id, Responsible_CM__r = assignedUser)
        };
        
        Test.startTest();
        BuildingSetTerritoryStructureTrH setSalesTerritories = new BuildingSetTerritoryStructureTrH();
        setSalesTerritories.newBuildings = mockedBuildings;
        setSalesTerritories.clusterSelector = (ClusterSelector) 
                                            MockService.createMock(ClusterSelector.class,
                                                                   new Map<String, Object>{
                                                                       'getClustersById' => clusters
                                                                   });
        setSalesTerritories.portfolioSelector = (PortfolioSelector) 
                                            MockService.createMock(PortfolioSelector.class,
                                                                   new Map<String, Object>{
                                                                       'getPortfoliosById' => mockedPortfolios
                                                                   });
        setSalesTerritories.SetTerritoryStructure();
        setSalesTerritories.beforeInsert();
        Test.stopTest();
        portfolioAssertion(mockedBuildings, mockedPortfolios, territories);
        clusterAssertion(mockedBuildings, clusters);
        communityLeadAssertion(mockedBuildings);
    }
    
    @isTest
    private static void setTerritoryStructuretestUpdate() {
        User assignedUser = UserUtility.getUserById(UserInfo.getUserId());
        List<Cluster__c> clusters = getInsertedClusters();
        List<Region__c> regions = getInsertedRegions(assignedUser);
        List<Territory__c> territories = getInsertedTerritories(regions, assignedUser);
        List<Market__c> portfolios = getInsertedPortfolios(territories);
        List<Building__c> buildings = getInsertedBuildings();
        
        List<Cluster__c> mockedClusters = new List<Cluster__c>{
            new Cluster__c(Id = clusters[0].Id, Name = 'Test Cluster 1', Cluster_Sales_Manager__c = assignedUser.Id, Cluster_Sales_Manager__r = assignedUser, Sales_Lead__c = assignedUser.Id, Sales_Lead__r = assignedUser),//positive mocking
            new Cluster__c(Id = clusters[1].Id, Name = 'Test Cluster 2', Cluster_Sales_Manager__c = assignedUser.Id, Cluster_Sales_Manager__r = assignedUser, Sales_Lead__c = assignedUser.Id, Sales_Lead__r = assignedUser),//positive mocking
            new Cluster__c(Id = clusters[2].Id),//negative mocking
            new Cluster__c(Id = clusters[3].Id)//negative mocking
        };
        
        List<Market__c> mockedPortfolios = new List<Market__c>{
            new Market__c(Id = portfolios[0].Id, Sub_Territory__c = mockedClusters[0].Id, Sub_Territory__r = mockedClusters[0] ,TerritoryID__c = territories[0].Id, TerritoryID__r = territories[0], Portfolio_Sales_Manager__c = assignedUser.Id, Portfolio_Sales_Manager__r = assignedUser),//positive mocking
            new Market__c(Id = portfolios[1].Id, Sub_Territory__c = mockedClusters[1].Id, Sub_Territory__r = mockedClusters[1] ,TerritoryID__c = territories[1].Id, TerritoryID__r = territories[1], Portfolio_Sales_Manager__c = assignedUser.Id, Portfolio_Sales_Manager__r = assignedUser),//positive mocking
            new Market__c(Id = portfolios[2].Id),//negative mocking
            new Market__c(Id = portfolios[3].Id)//negative mocking
        };
        
        List<Building__c> mockedBuildings = new List<Building__c>{
            new Building__c(Id = buildings[0].Id, Cluster__c = mockedClusters[0].Id, Cluster__r = mockedClusters[0], Market__c = mockedPortfolios[0].Id, Market__r = mockedPortfolios[0], Community_Lead__c = assignedUser.Id, Community_Lead__r = assignedUser, Community_Sales_Lead__c = assignedUser.Id, Community_Sales_Lead__r = assignedUser, Responsible_CM__c = assignedUser.Id, Responsible_CM__r = assignedUser),
            new Building__c(Id = buildings[1].Id, Cluster__c = mockedClusters[1].Id, Cluster__r = mockedClusters[1], Market__c = mockedPortfolios[1].Id, Market__r = mockedPortfolios[1], Community_Lead__c = assignedUser.Id, Community_Lead__r = assignedUser, Community_Sales_Lead__c = assignedUser.Id, Community_Sales_Lead__r = assignedUser, Responsible_CM__c = assignedUser.Id, Responsible_CM__r = assignedUser),
            new Building__c(Id = buildings[2].Id, Market__c = mockedPortfolios[2].Id, Market__r = mockedPortfolios[2], Community_Lead__c = assignedUser.Id, Community_Lead__r = assignedUser, Community_Sales_Lead__c = assignedUser.Id, Community_Sales_Lead__r = assignedUser, Responsible_CM__c = assignedUser.Id, Responsible_CM__r = assignedUser),
            new Building__c(Id = buildings[3].Id, Community_Lead__c = assignedUser.Id, Community_Lead__r = assignedUser, Community_Sales_Lead__c = assignedUser.Id, Community_Sales_Lead__r = assignedUser, Responsible_CM__c = assignedUser.Id, Responsible_CM__r = assignedUser)
        };
        
        Test.startTest();
        BuildingSetTerritoryStructureTrH setSalesTerritories = new BuildingSetTerritoryStructureTrH();
        setSalesTerritories.newBuildings = mockedBuildings;
        setSalesTerritories.oldBuildingsMap = new Map<Id, Building__c>(buildings);
        setSalesTerritories.clusterSelector = (ClusterSelector) 
                                            MockService.createMock(ClusterSelector.class,
                                                                   new Map<String, Object>{
                                                                       'getClustersById' => mockedClusters
                                                                   });
        setSalesTerritories.portfolioSelector = (PortfolioSelector) 
                                            MockService.createMock(PortfolioSelector.class,
                                                                   new Map<String, Object>{
                                                                       'getPortfoliosById' => mockedPortfolios
                                                                   });
        setSalesTerritories.SetTerritoryStructure();
        setSalesTerritories.beforeUpdate();
        Test.stopTest();
        portfolioAssertion(mockedBuildings, mockedPortfolios, territories);
        clusterAssertion(mockedBuildings, mockedClusters);
        communityLeadAssertion(mockedBuildings);
    }
    
    private static List<Cluster__c> getInsertedClusters() {
        List<Cluster__c> testClusters = new List<Cluster__c>();
        for(Integer i = 0; i < 4; i++) {
            testClusters.add(new Cluster__c(
                Id = TestUtility.getFakeId(Cluster__c.getSObjectType())
            ));
        }
        return testClusters;
    }
    
    private static List<Territory__c> getInsertedTerritories(List<Region__c> regions, User user) {
        List<Territory__c> testTerritories = new List<Territory__c>();
        for(Integer i = 0; i < regions.size(); i++) {
            testTerritories.add(new Territory__c(
                Id = TestUtility.getFakeId(Territory__c.getSObjectType()), 
                Name = 'Test Territory '+ i,
                Territory__c = 'Test Territory Name '+ i,
                RegionID__c = regions[i].Id,
                RegionID__r = regions[i],
                Territory_Sales_Manager__c = user.Id,
                Territory_Sales_Manager__r = user
            ));
        }
        return testTerritories;
    }

	private static List<Region__c> getInsertedRegions(User user) {
        List<Region__c> testRegions = new List<Region__c>();
        for(Integer i = 0; i < 4; i++) {
            testRegions.add(new Region__c(
                Id = TestUtility.getFakeId(Region__c.getSObjectType()), 
                Name = 'Region ' + i,
                Region__c = 'Test Region ' + i,
                Regional_Sales_Manager__c = user.id,
                Regional_Sales_Manager__r = user
            ));
    	}
        return testRegions;
    }
    
    private static List<Market__c> getInsertedPortfolios(List<Territory__c> territories) {
        List<Market__c> testPortfolios = new List<Market__c>();
        for(Integer i = 0; i < territories.size(); i++) {
            testPortfolios.add(new Market__c(
                Id = TestUtility.getFakeId(Market__c.getSObjectType()), 
                Name = 'Test Portfolio '+ i,
                TerritoryID__c = territories[i].Id,
        	    TerritoryID__r = territories[i]
            ));
        }
        return testPortfolios;
    }
    
    private static List<Building__c> getInsertedBuildings() {
        List<Building__c> testBuildings = new List<Building__c>();
        for(Integer i = 0; i < 4; i++) {
            testBuildings.add(new Building__c(
                Id = TestUtility.getFakeId(Building__c.getSObjectType()),
                Name = 'Test Building ' + i
            ));
        }
        return testBuildings;
    }
    
    private static void portfolioAssertion(List<Building__c> buildings, List<Market__c> portfolios, List<Territory__c> territories) {
        for(Integer i = 0; i < buildings.size(); i++) {
            Building__c building = buildings[i];
        	Market__c portfolio = portfolios[i];
            System.assertEquals(building.Sub_Territory__c, portfolio.Sub_Territory__c, 'Sub Territory on Building and Portfolio is not same');
        	System.assertEquals(building.Portfolio_Name__c, portfolio.Name, 'Name on Building and Portfolio is not same');
        	System.assertEquals(building.Territory_Name__c, portfolio.TerritoryID__r.Territory__c, 'Territory Name on Building and Territory is not same');
        	System.assertEquals(building.Region_Name__c, portfolio.TerritoryID__r.RegionID__r.Region__c, 'Region Name on Building and Region is not same');
        	System.assertEquals(building.Portfolio_Sales_Manager_Name__c, portfolio.Portfolio_Sales_Manager__r.Full_Name__c, 'Portfolio Sales Manager Name on Building and Portfolio is not same');
        	System.assertEquals(building.Territory_Sales_Manager_Name__c, portfolio.TerritoryID__r.Territory_Sales_Manager__r.Full_Name__c, 'Territory Sales Manager Name on Building and Territory is not same');
        	System.assertEquals(building.Regional_Sales_Manager_Name__c, portfolio.TerritoryID__r.RegionID__r.Regional_Sales_Manager__r.Full_Name__c, 'Regional Sales Manager Name on Building and Region is not same');
        	System.assertEquals(building.Portfolio_Sales_Manager_Email__c, portfolio.Portfolio_Sales_Manager__r.Email, 'Portfolio Sales Manager Email on Building and Portfolio is not same');
        	System.assertEquals(building.Territory_Sales_Manager_Email__c, portfolio.TerritoryID__r.Territory_Sales_Manager__r.Email, 'Territory Sales Manager Email on Building and Territory is not same');
        	System.assertEquals(building.Regional_Sales_Manager_Email__c, portfolio.TerritoryID__r.RegionID__r.Regional_Sales_Manager__r.Email, 'Regional Sales Manager Email on Building and Region is not same');            
        }
    }
    
    private static void clusterAssertion(List<Building__c> buildings, List<Cluster__c> clusters) {
        for(Integer i = 0; i < buildings.size(); i++) {
            Building__c building = buildings[i];
        	Cluster__c cluster = clusters[i];
            System.assertEquals(building.Cluster_Name__c, cluster.Name, 'Name on Building and Cluster is not same');
        	System.assertEquals(building.Cluster_Sales_Manager_Name__c, cluster.Cluster_Sales_Manager__r.Full_Name__c, 'Cluster Sales Manager Name on Building and Cluster is not same');
        	System.assertEquals(building.Cluster_Sales_Lead_Name__c, cluster.Sales_Lead__r.Full_Name__c, 'Cluster Sales Lead Name on Building and Cluster is not same');
        	System.assertEquals(building.Cluster_Sales_Manager_Email__c, cluster.Cluster_Sales_Manager__r.Email, 'Cluster Sales Manager Email on Building and Cluster is not same');
        	System.assertEquals(building.Cluster_Sales_Lead_Email__c, cluster.Sales_Lead__r.Email, 'Cluster Sales Lead Email on Building and Cluster is not same');
        }
    }
    
    private static void communityLeadAssertion(List<Building__c> buildings){
       for(Integer i = 0; i < buildings.size(); i++) {
            Building__c building = buildings[i];
            System.assertEquals(building.Community_Lead_Name__c, building.Community_Lead__r.Name, 'Community Lead Name on Building and Community Lead is not same');
        	System.assertEquals(building.Community_Manager_Name__c, building.Responsible_CM__r.Name, 'Community Manager Name on Building and Responsible CM is not same');
       }
    }   
}