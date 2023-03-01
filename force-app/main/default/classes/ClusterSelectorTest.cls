/*************************************************************************************************************************************
    Author      :   Krishna Somwanshi
    Description :   This class sufficient test coverage for PortfolioSelector class
--------------------------------------------------------------------------------------------------------------------------------------
    VERSION         DATE            AUTHOR              DETAIL
    1               30/8/2021       Krishna Somwanshi   Initial Deployment
**************************************************************************************************************************************/
@isTest
public class ClusterSelectorTest {
    @testSetup
    private static void setup() {
        String clusterSalesRT = Schema.SObjectType.Cluster__c.getRecordTypeInfosByName().get('Sales Cluster').getRecordTypeId();
        Cluster__c cluster = new Cluster__c(Name = 'Test Cluster', RecordTypeId = clusterSalesRT);
        insert cluster;
    }
    @isTest
    public static void getToursByOpportunitiesTest(){
        Cluster__c cluster = [SELECT Id FROM Cluster__c LIMIT 1];
        ClusterSelector clusterSelector = new ClusterSelector();
        System.assert(!clusterSelector.getClustersById(new List<Id>{cluster.Id}).isEmpty(), 'List should not be empty');
    }
}