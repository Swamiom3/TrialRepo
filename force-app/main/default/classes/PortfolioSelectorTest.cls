/*************************************************************************************************************************************
    Author      :   Krishna Somwanshi
    Description :   This is test class for PortfolioSelector class
--------------------------------------------------------------------------------------------------------------------------------------
    VERSION         DATE            AUTHOR              DETAIL
    1               30/8/2021       Krishna Somwanshi   Initial Deployment
**************************************************************************************************************************************/
@isTest
public class PortfolioSelectorTest {
    private static PortfolioSelector portfolioSelector = new PortfolioSelector();

    @testSetup
    private static void setup() {
        Territory__c territory = new Territory__c(Name = 'Test Territory');
        insert territory;
        Market__c portfolio = new Market__c(Name = 'Test Portfolio', TerritoryID__c = territory.Id);
        insert portfolio;
    }
    @isTest
    public static void getToursByOpportunitiesTest(){
        Market__c portfolio = [SELECT Id FROM Market__c LIMIT 1];
        System.assert(!portfolioSelector.getPortfoliosById(new List<Id>{portfolio.Id}).isEmpty(), 'List should not be empty');
    }

    @isTest
    static void getPortfolioRegionAndTerritoryTest() {
        Market__c portfolio = [SELECT Id FROM Market__c LIMIT 1];
        System.assert(!portfolioSelector.getPortfolioRegionAndTerritory(new Set<Id>{portfolio.Id}).isEmpty(), 'List should not be empty');
    }
}