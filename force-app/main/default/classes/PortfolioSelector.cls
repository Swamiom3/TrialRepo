/*********************************************************************************************************
    Author        :  Krishna Somwanshi
    Description   :  Selector class for Portfolio object
    Issue No.     :  ST-8736
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1          24-Aug-2021      Krishna Somwanshi    Initial development 
**********************************************************************************************************/
public inherited sharing class PortfolioSelector extends SObjectSelector {
    
    private static final List<String> DEFAULT_FIELDS = new List<String>{'Id',
                                                                        'Name'};
                                                                             
    public PortfolioSelector() {
        super(Market__c.getSObjectType());
    }
    
    public override Set<String> getDefaultFields(){
        return new Set<String>(DEFAULT_FIELDS);
    }
    
    public List<Market__c> getPortfoliosById(List<Id> ids){
        if (ids == null || ids.isEmpty()) {
            return new List<Market__c>();
        }
        List<String> fields = new List<String>{'Id',
                                               'Name',
                                               'Portfolio_Sales_Manager__r.Full_Name__c',
                                               'Portfolio_Sales_Manager__r.Email',
                                               'TerritoryID__r.Territory__c',
                                               'TerritoryID__r.Territory_Sales_Manager__r.Full_Name__c',
                                               'TerritoryID__r.Territory_Sales_Manager__r.Email',
                                               'TerritoryID__r.RegionID__r.Region__c',
                                               'TerritoryID__r.RegionID__r.Regional_Sales_Manager__r.Full_Name__c',
                                               'TerritoryID__r.RegionID__r.Regional_Sales_Manager__r.Email',
                                               'Sub_Territory__c'};
        String whereClause = 'Id IN :ids AND No_Longer_in_Use__c != TRUE';
        return (List<Market__c>) getSObjects(fields, whereClause, new List<Object>{ids});
    }

    public List<Market__c> getPortfolioRegionAndTerritory(Set<Id> portfolioIds){
        if (portfolioIds == null || portfolioIds.isEmpty()) {
            return new List<Market__c>();
        }
        List<String> fields = new List<String>{'Id',
                                               'Region__c',
                                               'Territory__c'};
        String whereClause = 'Id IN :portfolioIds AND No_Longer_in_Use__c != TRUE';
        return (List<Market__c>) getSObjects(fields, whereClause, new List<Object>{portfolioIds});
    }
}