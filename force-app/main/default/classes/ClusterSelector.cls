/*********************************************************************************************************
    Author        :  Krishna Somwanshi
    Description   :  Selector class for Cluster object
    Issue No.     :  ST-8736
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1          24-Aug-2021      Krishna Somwanshi    Initial development 
**********************************************************************************************************/
public inherited sharing class ClusterSelector extends SObjectSelector {
    
    private static final List<String> DEFAULT_FIELDS = new List<String>{'Id',
                                                                        'Name'};
                                                                             
    public ClusterSelector() {
        super(Cluster__c.getSObjectType());
    }
    
    public override Set<String> getDefaultFields(){
        return new Set<String>(DEFAULT_FIELDS);
    }
    
    public List<Cluster__c> getClustersById(List<Id> ids){
        if (ids == null || ids.isEmpty()) {
            return new List<Cluster__c>();
        }
        List<String> fields = new List<String>{'Id',
                                               'Name',
                                               'Cluster_Sales_Manager__r.Full_Name__c',
                                               'Cluster_Sales_Manager__r.Email',
                                               'Sales_Lead__r.Full_Name__c',
                                               'Sales_Lead__r.Email'};
        String clusterSalesRT = Schema.SObjectType.Cluster__c.getRecordTypeInfosByName().get('Sales Cluster').getRecordTypeId();
        String whereClause = '(Id IN : ids AND RecordTypeId =: clusterSalesRT)';
        return (List<Cluster__c>) getSObjects(fields, whereClause, new List<Object>{ids, clusterSalesRT});
    }
}