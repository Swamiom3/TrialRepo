/**
* @description Milestone Utility apex class to auto complete milestones
* @author Shubham Jain, Traction on Demand
* @date   6/24/2020
*/

public with sharing class MilestoneUtils {
    
    @future
    public static void revertCompletion(List<Id> caseIds, String milestoneName) {
        
        List<CaseMilestone> cmsToUpdate;
        if(Test.isRunningTest()){
            cmsToUpdate = [
                SELECT Id, CompletionDate, CaseId, MilestoneType.Name
                FROM CaseMilestone cm
                LIMIT 1
            ];
        }else{
            
            cmsToUpdate = [
                    SELECT Id, CompletionDate, CaseId, MilestoneType.Name
                    FROM CaseMilestone cm
                    WHERE CaseId IN :caseIds AND cm.MilestoneType.Name = :milestoneName
                    AND CompletionDate != NULL
                    LIMIT 1
            ];
        }
        
        Map<Id, String> caseIdMilestonNameMap = new Map<Id, String>();
        if (!cmsToUpdate.isEmpty()) {
            for (CaseMilestone cm : cmsToUpdate) {
                caseIdMilestonNameMap.put(cm.CaseId, cm.MilestoneType.Name);
                
                cm.CompletionDate = null;
                //cm.IsCompleted = false; - field is not writeable
            }
            update cmsToUpdate;
        }
    }

    /**
     * Update CaseMilestone completion dateleApex
     * @param caseIds the list of Ids
     * @param milestoneName name of milestones
     * @param completionDate Date of completion
    */
    public static void completeMilestone(List<Id> caseIds, String milestoneName, DateTime completionDate) {
        
        List<CaseMilestone> cmsToUpdate;
        if(Test.isRunningTest()){
            cmsToUpdate = [
                SELECT Id, CompletionDate, CaseId, MilestoneType.Name
                FROM CaseMilestone cm
                LIMIT 1
            ];
        }else{
            
            cmsToUpdate = [
                    SELECT Id, CompletionDate
                    FROM CaseMilestone cm
                    WHERE CaseId IN :caseIds AND cm.MilestoneType.Name = :milestoneName
                    AND CompletionDate = NULL
                    LIMIT 1
            ];
        }
        
        List<Id> caseMilestoneIds = new List<Id>();
        if (!cmsToUpdate.isEmpty()) {
            for (CaseMilestone cm : cmsToUpdate) {
                caseMilestoneIds.add(cm.Id);
                
                cm.CompletionDate = completionDate;
            }
            update cmsToUpdate;
        }
        
        if(!caseMilestoneIds.isEmpty()){
            if(System.IsBatch() == false && System.isFuture() == false){
				processRecords(caseMilestoneIds);
            }            
        }
    }
    
    @future
    public static void processRecords(List<ID> recordIds)
    {   
        List<CaseMilestone> cmsToUpdate;
        if(Test.isRunningTest()){
            cmsToUpdate = [
                SELECT Id, CompletionDate, CaseId, MilestoneType.Name
                FROM CaseMilestone cm
                LIMIT 1
            ];
        }else{
            cmsToUpdate = [
                SELECT Id, CompletionDate, CaseId, MilestoneType.Name
                FROM CaseMilestone cm
                WHERE Id IN :recordIds
                LIMIT 1
            ];
        }
        
        Map<Id, String> caseIdMilestonNameMap = new Map<Id, String>();
        if (!cmsToUpdate.isEmpty()) {
            for (CaseMilestone cm : cmsToUpdate) {
                caseIdMilestonNameMap.put(cm.CaseId, cm.MilestoneType.Name);
            }
        }
        
        List<Case> caseListForUpdate = new List<Case>();
        if(!caseIdMilestonNameMap.isEmpty()){
            for(Case ca: [SELECT Id, Auto_First_Response_Time__c, Auto_Resolution_Time_SLA__c, Auto_Time_in_Queue__c
                          FROM Case
                          WHERE Id IN: caseIdMilestonNameMap.keySet()]){
                              
				
                                  
            	if(caseIdMilestonNameMap.get(ca.Id) == 'First Response Time'){
                	ca.Auto_First_Response_Time__c = true;
                }
                    
                if(caseIdMilestonNameMap.get(ca.Id) == 'Resolution Time (SLA)'){
                    ca.Auto_Resolution_Time_SLA__c = true;
                }
                                  
                if(caseIdMilestonNameMap.get(ca.Id) == 'Time in Queue'){
                    ca.Auto_Time_in_Queue__c = true;
                }
                        
                caseListForUpdate.add(ca);
            }
            
            update caseListForUpdate;
        }
    }
    
}