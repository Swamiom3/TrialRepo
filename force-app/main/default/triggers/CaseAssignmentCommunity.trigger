trigger CaseAssignmentCommunity on Case (after insert) {
    
    Set<Id> setCaseIds = new Set<Id>();
    for(Case eachCase : trigger.new) {
        setCaseIds.add(eachCase.Id);
    }
    List<Case> lstCaseUpdateOwner = new List<Case>();
    Database.DMLOptions dmo = new Database.DMLOptions();
    dmo.AssignmentRuleHeader.useDefaultRule = true;
    for(Case eachCase : [SELECT Id, WeCo_Line_of_Business__c FROM Case WHERE Id IN: setCaseIds]) {
        eachCase.setOptions(dmo);
        lstCaseUpdateOwner.add(eachCase);
    }
    update lstCaseUpdateOwner;
    
    
}