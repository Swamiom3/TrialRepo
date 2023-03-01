/************************************************************************************************************************************
Author      :   Chandra Teja
Description :   This class contains logic to update case status of support record type to accepted if owner of case is user
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                    AUTHOR                      DETAIL
1           26 October 2020         Chandra Teja                Initial Developement
2           18 Jun 2021             Tomasz Sadowski             ST-8436 - Migration to new trigger framework (cleanup)
**************************************************************************************************************************************/
public class CaseUpdateStatusTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Case> newCases;
    @TestVisible
    private Map<Id, Case> oldCasesMap;
    @TestVisible
    private static final Id SUPPORT_REC_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support - Sales').getRecordTypeId();
    @TestVisible
    private static final String CASE_STATUS_ACCEPTED = 'Accepted';
    @TestVisible
    private static final String CASE_STATUS_NEW = 'New';
    @TestVisible
    private static final String CASE_STATUS_CLOSED = 'Closed';
    
    public CaseUpdateStatusTrH() {
        this(
            (List<Case>) Trigger.new,
            (Map<Id, Case>) Trigger.oldMap
        );
    }
    
    @TestVisible
    private CaseUpdateStatusTrH(List<Case> newCases, Map<Id, Case> oldCasesMap) {
        this.newCases = this.returnOnlyObjectWithValidRT(Case.SObjectType, 
                                                                           newCases,
                                                                           CaseConstants.CASE_SALES_RECORD_TYPE);
        if (this.context == TriggerContext.AFTER_INSERT
            || this.context == TriggerContext.BEFORE_INSERT) {
            return;
        }
        List<Case> oldCasesLit = this.returnOnlyObjectWithValidRT(Case.SObjectType, 
                                                                   oldCasesMap.values(),
                                                                   CaseConstants.CASE_SALES_RECORD_TYPE);
        this.oldCasesMap = new Map<Id, Case>(oldCasesLit);
    }
    
    public override void beforeInsert() {
        updateSupportCaseStatusOnInsert();
    }
    
    public override void beforeUpdate() {
        updateSupportCaseStatusOnUpdate();
    }
    
    public void updateSupportCaseStatusOnInsert() {
        for (Case newCase: newCases) {
            if (newCase.RecordTypeId != SUPPORT_REC_TYPE_ID || String.valueOf(newCase.OwnerId).startsWith(GlobalConstants.GROUP_ID_PREFIX)) {
                continue;
            }
            newCase.Status = CASE_STATUS_ACCEPTED;
        }
    }
    
    public void updateSupportCaseStatusOnUpdate() {
        for (Case newCase: newCases) {
            Case oldCase = oldCasesMap.get(newCase.Id);
            if (newCase.RecordTypeId != SUPPORT_REC_TYPE_ID) {
                continue;
            }
            if (newCase.Status != CASE_STATUS_CLOSED && String.valueOf(newCase.OwnerId).startsWith(GlobalConstants.USER_ID_PREFIX)
                    && String.valueOf(oldCase.OwnerId).startsWith(GlobalConstants.GROUP_ID_PREFIX)) {
                newCase.Status = CASE_STATUS_ACCEPTED;
            }
            if (String.valueOf(newCase.OwnerId).startsWith(GlobalConstants.GROUP_ID_PREFIX) && String.valueOf(oldCase.OwnerId).startsWith(GlobalConstants.USER_ID_PREFIX)) {
                newCase.Status = CASE_STATUS_NEW;
            }
        }
    }
}