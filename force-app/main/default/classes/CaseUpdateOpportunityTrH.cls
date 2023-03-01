/************************************************************************************************************************************
    Author      :     Roshan Kankrayane
    Description :     This class contains the business logic of Copy values from REA Case into Opportunity Record on Closed-Won
    Issue No    :     ST-5795
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION          DATE                AUTHOR                    DETAIL
    1                27 Feb 2020         Roshan Kankrayane         Initial Development
    2                15 Jun 2021         Tomasz Sadowski           ST-8436 - Migration to new trigger framework
**************************************************************************************************************************************/
public class CaseUpdateOpportunityTrH extends SObjectTriggerHandler{
    @TestVisible
    private List<Case> newCases;
    @TestVisible
    private Map<Id, Case> oldCasesMap;
    
    public CaseUpdateOpportunityTrH() {
        this(
            (List<Case>) Trigger.new,
            (Map<Id, Case>) Trigger.oldMap
        );
    }
    
    @TestVisible
    private CaseUpdateOpportunityTrH(List<Case> newCases, Map<Id, Case> oldCasesMap) {
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
    
    public override void afterUpdate() {
        updateOpportunities();
    }

    public void updateOpportunities() {
        updateOppFieldOnClosedWon(prepareCaseActors());
    }

    private List<Case> prepareCaseActors() {
        List<Case> filteredCases = new List<Case>();
        MetadataSetting__mdt caseMetadata = Settings.getMetadataSettingByDevName('CaseStatusUpdateToOppMapping');
        CaseMetadataWrapper caseData = new CaseMetadataWrapper();
        if (caseMetadata != null && String.isNotBlank(caseMetadata.Data__c)) {
            caseData = (CaseMetadataWrapper) JSON.deserialize(caseMetadata.Data__c, CaseMetadataWrapper.class);            
            Set<String> allowedStatuses = new Set<String>(); 
            if (caseData.allowedStatus != null) {
                for (String actualStatus : caseData.allowedStatus) {
                    allowedStatuses.add(actualStatus.toLowerCase());  
                } 
            }
            Map<String, Id> recordTypeNameToId = WeworkEngine.getMapObjectRecordTypeId('Case');
            Set<Id> allowedRecordTypeIds = new Set<Id>(); 
            if (caseData.allowedRecordTypes != null && !recordTypeNameToId.isEmpty()) {
                for (String actualRecordTypeName : caseData.allowedRecordTypes) {
                    allowedRecordTypeIds.add(recordTypeNameToId.get(actualRecordTypeName));  
                } 
            }
            for (Case caseRecord : newCases) {
                Case oldCase = oldCasesMap?.get(caseRecord.Id);
                if (caseRecord.Opportunity__c == null || oldCase == null || !TriggerUtility.isFieldValueChanged(caseRecord, oldCase, 'Status')) {
                    continue;
                }
                Boolean isStatusAllowed = !allowedStatuses.isEmpty() && allowedStatuses.contains(caseRecord.Status.toLowerCase());
                Boolean isRecordTypeAllowed = !allowedRecordTypeIds.isEmpty() && allowedRecordTypeIds.contains(caseRecord.RecordTypeId);
                if (isRecordTypeAllowed && isStatusAllowed) {
                    filteredCases.add(caseRecord);
                }
            }
        }
        return filteredCases;
    }
    
    public static void updateOppFieldOnClosedWon(List<Case> filteredCases) {
        if (filteredCases.isEmpty()) {
            return;
        }
        Map<Id, Opportunity> opportunityIdToOpportunity = new Map<Id, Opportunity>();
        for (Case caseRecord : filteredCases) {
            opportunityIdToOpportunity.put(caseRecord.Opportunity__c, new Opportunity(
                Id = caseRecord.Opportunity__c,
                Actual_Deal_Margin__c = caseRecord.Actual_Guardrail_Margin__c
            ));   
        }
        //dml.add(opportunityIdToOpportunity.values(), DmlConsolidator.Operation.FOR_UPDATE);
        update opportunityIdToOpportunity.values();
    }
    
    public class CaseMetadataWrapper{
        Set<String> allowedStatus;
        Set<String> allowedRecordTypes;
    }
}