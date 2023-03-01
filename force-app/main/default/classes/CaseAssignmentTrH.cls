/************************************************************************************************************************************
    Author      :     Rupesh Patil
    Description :     This class will contain the test methods of TrCaseAssignment
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION      DATE                AUTHOR             Issue No        DETAIL
    1            4 March 2019        Chandra Teja       ST-3452         Initial Development
    3            17 Jun 2021         Tomasz Sadowski    ST-8436         Migration to new trigger framework
    3            29 Nov 2021         Tomasz Sadowski    ST-9189         Migration to OrgC
**************************************************************************************************************************************/
public class CaseAssignmentTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Case> newCases;
    @TestVisible
    private Id reaCaseRtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(GlobalConstants.CASE_RT_NAME_REA).getRecordTypeId();
    
    public CaseAssignmentTrH() {
        this(
            (List<Case>) Trigger.new
        );
    }
    
    @TestVisible
    private CaseAssignmentTrH(List<Case> newCases) {
        this.newCases = this.returnOnlyObjectWithValidRT(Case.SObjectType, 
                                                               newCases,
                                                               CaseConstants.CASE_SALES_RECORD_TYPE);
    }
    
    public override void afterInsert() {
        this.setMaxLoopCount(1);
        fireAssignment(new Map<Id, Case>(this.newCases).keySet());
    }
    
    @future
    public static void fireAssignment(Set<Id> idsToFireCaseAssignment) {
        Id reaCaseRtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(GlobalConstants.CASE_RT_NAME_REA).getRecordTypeId();
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        dmo.EmailHeader.triggerUserEmail = true;
        List<Case> casesToFireAssignment = [SELECT Id FROM Case WHERE Id IN :idsToFireCaseAssignment AND RecordTypeId = :reaCaseRtId];
        Database.update(casesToFireAssignment, dmo);
    }
}