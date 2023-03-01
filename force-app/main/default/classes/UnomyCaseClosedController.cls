public without sharing class UnomyCaseClosedController {

    @AuraEnabled
    public static Case loadCaseRecord(Id recordId) {
        if (recordId == null) {
            return null;
        }
        Case c = null;
        try {
            c = [SELECT Status, Approval_Status__c FROM Case WHERE Id=: recordId LIMIT 1][0];
        } catch (Exception ex) {
            System.debug(ex);
        }
        return c;
    }
    
    @AuraEnabled
    public static void closeCaseRecord(Id recordId, String subCategory, String description, Boolean approve, String rejectedReason) {
        if (recordId == null) {
            return;
        }
        Case c = null;
        ProcessInstance approval = null;
        try {
            c = [SELECT Status FROM Case WHERE Id=: recordId LIMIT 1][0];
        } catch (Exception ex) {
            System.debug(ex);
        }
        c.Status = 'Closed';
        c.Case_Type__c = subCategory;
        c.Description = description;  
        c.Approval_Status__c = approve == true ? 'Approved' : 'Rejected';
        c.Rejected_Reason__c = rejectedReason;
        update c;
        approveOrRejectRecord(recordId, approve);
        
    }
    
    @AuraEnabled
    public static List<String> getPickListValuesIntoList(){
       List<String> pickListValuesList= new List<String>();
		Schema.DescribeFieldResult fieldResult = Case.Rejected_Reason__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
			pickListValuesList.add(pickListVal.getLabel());
		}     
		return pickListValuesList;
    }
    
    @AuraEnabled
    public static Boolean isUserAuthorizedApprover() {
        List<GroupMember> lstGroupMembers = [SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = 'SalesOps_Support'];
        Map<Id, GroupMember> mapAuthorizedApprovers = new Map<Id, GroupMember>();
        for (GroupMember mem : lstGroupMembers) {
            mapAuthorizedApprovers.put(mem.UserOrGroupId, mem);
        }
        if (mapAuthorizedApprovers.containsKey(UserInfo.getUserId())) {
            return true;
        }
        return false;
    }
    
    public static void approveOrRejectRecord(Id recordId, Boolean approve) {
        if (recordId == null) {
            return;
        }
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        if (approve == true) {
            req.setAction('Approve');
            req.setComments('Approving request for Unomy data override');
        } else {
            req.setAction('Reject');
            req.setComments('Rejecting request for Unomy data override');
        }
        ProcessInstanceWorkitem pItem = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: recordId LIMIT 1][0];
        req.setWorkitemId(pItem.Id);
        Approval.ProcessResult result = Approval.process(req);        
    }    
}