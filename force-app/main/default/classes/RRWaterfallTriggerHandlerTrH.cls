public with sharing class RRWaterfallTriggerHandlerTrH extends SObjectTriggerHandler {
    private List<RightRev__Revenue_Contract_Waterfall__c> newRecords;
    private Map<Id, RightRev__Revenue_Contract_Waterfall__c> oldRecordsMap;
    
    public RRWaterfallTriggerHandlerTrH(){
        this((List<RightRev__Revenue_Contract_Waterfall__c>) Trigger.new, (Map<Id, RightRev__Revenue_Contract_Waterfall__c>) Trigger.oldMap); 
    }
    
    @TestVisible
    private RRWaterfallTriggerHandlerTrH(List<RightRev__Revenue_Contract_Waterfall__c> newRecords, Map<Id, RightRev__Revenue_Contract_Waterfall__c> oldRecordsMap) {
        this.newRecords = newRecords; 
        this.oldRecordsMap = oldRecordsMap;
    }
    
    public override void afterInsert() {
        RRWaterfallTriggerHelper.updateRevenueContract(newRecords);
    }
    
    public override void afterUpdate() {
        RRWaterfallTriggerHelper.updateRevenueContract(newRecords);
    }

}