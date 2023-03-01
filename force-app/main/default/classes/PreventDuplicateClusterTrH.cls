/************************************************************************************************************************************
    Author      :   Krishana Tupe	
    Description :   This class will used to prevent users to create/update
					a cluster record with duplicate name and record type.
	Issue No    : 	ST-6929
    History		:	
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                	AUTHOR                  	DETAIL
    1           10 September 2020    	Krishana Tupe             	Initial Developement
**************************************************************************************************************************************/
public class PreventDuplicateClusterTrH extends SObjectTriggerHandler{    
    private final String ERROR_MESSAGE = System.Label.Duplicate_Cluster_Error_Message;
    @TestVisible
    private List<Cluster__c> newClusters;
    @TestVisible
    private Map<Id, Cluster__c> oldClustersMap;    
    @TestVisible    
    
    public PreventDuplicateClusterTrH(){
        this((List<Cluster__c>) Trigger.new, (Map<Id, Cluster__c>) Trigger.oldMap);
    }
    
    @TestVisible
    private PreventDuplicateClusterTrH(List<Cluster__c> newClusters, Map<Id, Cluster__c> oldClustersMap){
        this.newClusters = newClusters;
        this.oldClustersMap = oldClustersMap;            
    }
    
    public override void beforeInsert(){
        preventDuplicateCluster();
    }
    
    public override void beforeUpdate(){
        preventDuplicateCluster();
    }
    
    private void preventDuplicateCluster(){     
        Map<String, Cluster__c> uniqueCriteriaKeyToCluster = new Map<String, Cluster__c>();
        Set<String> newCluserNames = new Set<String>();
        Set<Id> newCluserRecordTypeIds = new Set<Id>();   
        for(Cluster__c newClusterRec : newClusters){
            Cluster__c oldClusterRec = (oldClustersMap == null || oldClustersMap.isEmpty()) ? null : oldClustersMap.get(newClusterRec.Id);
            if(!isValidClusterRecord(newClusterRec, oldClusterRec)){
                continue;
            }
            newCluserNames.add(newClusterRec.Name);
            newCluserRecordTypeIds.add(newClusterRec.RecordTypeId);
            String uniqueKey = getClusterMatchingUniqueKey(newClusterRec);
            if (uniqueCriteriaKeyToCluster.containsKey(uniqueKey)){
                newClusterRec.Name.addError(ERROR_MESSAGE);
            }else{
                uniqueCriteriaKeyToCluster.put(uniqueKey, newClusterRec);
            }
        }
        if(newCluserNames.isEmpty()){
            return;
        }
        for(Cluster__c dbClusterRec : [SELECT Name, RecordTypeId FROM Cluster__c WHERE Name IN :newCluserNames OR RecordTypeId IN :newCluserRecordTypeIds]){
            String uniqueKey = getClusterMatchingUniqueKey(dbClusterRec);
            Cluster__c newClusterRec = uniqueCriteriaKeyToCluster.get(uniqueKey);
            if (newClusterRec != null){
                newClusterRec.Name.addError(ERROR_MESSAGE);
            }
        }
    }
    
    public Boolean isValidClusterRecord(Cluster__c newClusterRec, Cluster__c oldClusterRec){
        if(oldClusterRec == null){  //for insert context
            return true;
        }
        return (Settings.isChanged(newClusterRec.Name, oldClusterRec.Name) || 
                Settings.isChanged(newClusterRec.RecordTypeId, oldClusterRec.RecordTypeId));
    }
    
    private String getClusterMatchingUniqueKey(Cluster__c clusterRec){
        return (clusterRec.Name+'-'+clusterRec.RecordTypeId).toLowerCase();
    }    
}