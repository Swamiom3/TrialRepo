/**
 * @description Class for the Case trigger
 * @name trac_Case
 * @author Shubham Jain, Traction on Demand
 * @date 2019-08-27
 */

public with sharing class trac_Case extends SObjectTriggerHandler {
    public static Boolean throwError = true;
     @TestVisible
    private List<Case> newCases;
    @TestVisible
    private Map<Id, Case> oldCasesMap;

    public trac_Case() {
         this(
            (List<Case>) Trigger.new,
            (Map<Id, Case>) Trigger.oldMap
        );    
    }
    
    @TestVisible
    private trac_Case(List<Case> newCases, Map<Id, Case> oldCasesMap) {
        this.newCases = newCases;
        this.oldCasesMap = oldCasesMap;
    }
    
    public void filterCases()
    {
         this.newCases = this.returnOnlyObjectWithValidRT(Case.SObjectType, 
                                                                           this.newCases,
                                                                           CaseConstants.CASE_SALES_RECORD_TYPE);
        if (this.context == TriggerContext.AFTER_INSERT
            || this.context == TriggerContext.BEFORE_INSERT) {
            return;
        }
        List<Case> oldCasesLit = this.returnOnlyObjectWithValidRT(Case.SObjectType, 
                                                                   this.oldCasesMap.values(),
                                                                   CaseConstants.CASE_SALES_RECORD_TYPE);
        this.oldCasesMap = new Map<Id, Case>(oldCasesLit);
    }
    public override void beforeInsert() {
        filterCases();
        if (this.newCases.isEmpty()) {
            return;
        }
        try { // all before update methods go here
            trac_CaseHandler.blockTimeDelay(this.newCases);
            trac_CaseHandler.maskCreditCardNumbers(this.newCases);
            trac_CaseHandler.statusChange(this.newCases);
            trac_CaseHandler.updateTotalHandleTimeOnCaseComplete(this.newCases, null);
        } catch (Exception e) {
            handleErrors(e);
        }
    }
    
    public override void beforeUpdate() {
        filterCases();
        if (this.newCases.isEmpty()) {
            return;
        }
        try { // all before update methods go here
            trac_CaseHandler.statusChange(this.newCases, (Map<Id, Case>) oldCasesMap);
            trac_CaseHandler.changeQueueBuildingUpdated(this.newCases, (Map<Id, Case>) oldCasesMap);
            trac_CaseHandler.ownerIsVendor(this.newCases, (Map<Id, Case>) oldCasesMap);
            trac_CaseHandler.firstResponseTimeChange(this.newCases, (Map<Id, Case>) oldCasesMap);
            trac_CaseHandler.revertCompleteResolutionTimeMilestones(this.newCases, (Map<Id, Case>) oldCasesMap);
            trac_CaseHandler.completeResolutionTimeMilestones(this.newCases);
            trac_CaseHandler.completeFirstResponseMilestones(this.newCases, (Map<Id, Case>) oldCasesMap);
            trac_CaseHandler.completeTimeInQueueMilestones(this.newCases, (Map<Id, Case>) oldCasesMap);
            trac_CaseHandler.updateTotalHandleTimeOnCaseComplete(this.newCases, (Map<Id, Case>) oldCasesMap);
        } catch (Exception e) {
            handleErrors(e);
        }
    }
    
   
    public override void afterUpdate() {
        if (newCases.isEmpty()) {
            return;
        }
    }


    public void handleErrors(Exception e) {
        TLLog.e('EXCEPTION', e.getMessage(), e.getCause(), e.getStackTraceString());
        if (throwError) newCases[0].addError(e.getMessage());
    }

    public class CaseException extends Exception {
    }
}