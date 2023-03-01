/************************************************************************************************************************************
        Author              : Tomasz Sadowski
        Description         : https://jira.weworkers.io/browse/ST-8264
        Last Modified Date  : 12 May 2021
        Last Modified By    : Tomasz Sadowski
        Issue No            : ST-8264
********************************************************************************************************************************/
public with sharing class OpportunityReaCaseTrH extends SObjectTriggerHandler{
    @TestVisible
    private List<Opportunity> newOpportunities;
    @TestVisible
    private Map<Id, Opportunity> oldOpportunitiesMap;
    @TestVisible
    private AccountSelector accountSelector = new AccountSelector();
    @TestVisible
    private CaseSelector caseSelector = new CaseSelector();
    @TestVisible
    private UserAttributeSelector uaSelector = new UserAttributeSelector();
    public final Integer OPP_SIZE_THRESHOLD = Integer.valueOf(Label.Deal_Size_Threshold);
    private final String REA_CASE_DEFAULT_STATUS = 'New';
    private final String REA_CASE_REQUEST_TYPE = 'Deal Structuring';
    private final String REA_SUBJECT_END = 'Deal Structure';
    private final String TRANSACTION_TYPE_NEW = 'New Transaction';
    private final String TRANSACTION_TYPE_RENEWAL = 'Renewal';
    private final String REA_TEAM_QUEUE = 'REA_Team_Queue';
    private final Id REA_CASE_RTID = Schema.SObjectType.Case.getRecordTypeInfosByName().get(GlobalConstants.CASE_RT_NAME_REA).getRecordTypeId();
    private final Id RENEWAL_OPPORTUNITY_RTID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(GlobalConstants.OPP_RT_NAME_RENEWAL).getRecordTypeId();

    public OpportunityReaCaseTrH() {
        this(
            (List<Opportunity>) Trigger.new,
            (Map<Id, Opportunity>) Trigger.oldMap
        );
    }

    @TestVisible
    private OpportunityReaCaseTrH(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunitiesMap) {
        this.newOpportunities = newOpportunities;
        this.oldOpportunitiesMap = oldOpportunitiesMap;
    }
    
    public override void afterInsert() {
        this.createReaCase(); 
    }
    
    public override void afterUpdate() {
        this.createReaCase(); 
        this.closeReaCase(); 
    }
    
    @TestVisible
    private void createReaCase() {
        Set<Id> buildingIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        List<Opportunity> matchingOpportunities = new List<Opportunity>();
        for (Opportunity opportunity : newOpportunities) {
            if (opportunity.AccountId == null || opportunity.Net_Desks__c < OPP_SIZE_THRESHOLD) {
                continue;
            }
            Opportunity oldOpportunity = oldOpportunitiesMap?.get(opportunity.Id);
            if (opportunityMatchesCreateReaConditions(opportunity, oldOpportunity)) {
                buildingIds.add(opportunity.Building__c);
                accountIds.add(opportunity.AccountId);
                matchingOpportunities.add(opportunity);
            }
        }
        if (matchingOpportunities.isEmpty() || buildingIds.isEmpty()) {
            return;
        }
        createAndInsertReaCase(matchingOpportunities, prepareBuildingActors(buildingIds), prepareAccountActors(accountIds));
    }
    
    @TestVisible
    private void closeReaCase() {
        findAndCloseReaCase(prepareOpportunityActors());
    }

    private Map<Id, User_Attribute__c> prepareBuildingActors(Set<Id> buildingIds) {
        Map<Id, User_Attribute__c> buildingIdToUserAttribute = new Map<Id, User_Attribute__c>();
        for (User_Attribute__c ua : uaSelector.getUserAttributesByBuildingId(buildingIds)) {
            if (ua.Building_Team_Role__c != GlobalConstants.USER_ATTRIBUTE_REA) {
                continue;
            }
            buildingIdToUserAttribute.put(ua.Building__c, ua);
        }
        return buildingIdToUserAttribute;
    }
    
    private Map<Id, String> prepareAccountActors(Set<Id> accountIds) {
        Map<Id, String> accountIdToName = new Map<Id, String>();
        for (Account acc : accountSelector.getAccountsById(new List<Id>(accountIds))) {
            accountIdToName.put(acc.Id, acc.Name);
        }
        return accountIdToName;
    }

    private Map<Id, Boolean> prepareOpportunityActors() {
        Map<Id, Boolean> opportunityIdToClosedWon = new Map<Id, Boolean>();
        for (Opportunity opportunity : newOpportunities) {
            if (!opportunity.IsClosed) {
                continue;
            }
            Opportunity oldOpportunity = oldOpportunitiesMap?.get(opportunity.Id);
            if (TriggerUtility.isFieldValueChanged(opportunity, oldOpportunity, 'IsClosed')) {
                opportunityIdToClosedWon.put(opportunity.Id, opportunity.IsWon);
            }
        }
        return opportunityIdToClosedWon;
    }

    private void createAndInsertReaCase(List<Opportunity> matchingOpportunities,
                                        Map<Id, User_Attribute__c> buildingIdToUserAttribute,
                                        Map<Id, String> accountIdToName) {
        List<Case> casesToInsert = new List<Case>();
        for (Opportunity opportunity : matchingOpportunities) {
            Id reaUser = buildingIdToUserAttribute.containsKey(opportunity.Building__c)
                            ? buildingIdToUserAttribute.get(opportunity.Building__c).User__c : getQueueIdByName(REA_TEAM_QUEUE);
            Case newCase = new Case();
            newCase.RecordTypeId = REA_CASE_RTID;
            newCase.OwnerId = reaUser;
            newCase.Status = REA_CASE_DEFAULT_STATUS;
            newCase.Requested_By__c = UserInfo.getUserId();
            newCase.REA_Request_Type__c = REA_CASE_REQUEST_TYPE;
            newCase.Opportunity__c = opportunity.Id;
            newCase.AccountId = opportunity.AccountId;
            newCase.Building_Nearest_Address__c = opportunity.Building__c;
            newCase.Type_of_Transaction__c = opportunity.RecordTypeId == RENEWAL_OPPORTUNITY_RTID ? TRANSACTION_TYPE_RENEWAL : TRANSACTION_TYPE_NEW;
            newCase.Subject = accountIdToName.get(opportunity.AccountId) + ' - ' + REA_SUBJECT_END;
            casesToInsert.add(newCase);
        }
        if (!casesToInsert.isEmpty()) {
            Database.DMLOptions dmlo = new Database.DMLOptions();
            dmlo.assignmentRuleHeader.useDefaultRule = false;
            Database.insert(casesToInsert, dmlo);
        }
    }

    private void findAndCloseReaCase(Map<Id, Boolean> opportunityIdToClosedWon) {
        if (opportunityIdToClosedWon.isEmpty()) {
            return;
        }
        List<Case> casesToClose = new List<Case>();
        for (Case caseRec : caseSelector.getCasesByOpportunityId(opportunityIdToClosedWon.keySet())) {
            if (caseRec.RecordTypeId != REA_CASE_RTID) {
                continue;
            }
            caseRec.Status = opportunityIdToClosedWon.get(caseRec.Opportunity__c) ? GlobalConstants.OPP_CLOSED_WON_STAGE_NAME
                             : GlobalConstants.OPP_CLOSED_LOST_STAGE_NAME;
            casesToClose.add(caseRec);
        }
        if (!casesToClose.isEmpty()) {
            dml.add(casesToClose, DmlConsolidator.Operation.FOR_UPDATE);
        }
    }

    private Boolean opportunityMatchesCreateReaConditions(Opportunity opportunity, Opportunity oldOpportunity) {
        return (((opportunity.RecordTypeId != RENEWAL_OPPORTUNITY_RTID && opportunity.StageName == GlobalConstants.OPPORTUNITY_STAGE_SELLING) 
                    || (opportunity.RecordTypeId == RENEWAL_OPPORTUNITY_RTID && opportunity.StageName == GlobalConstants.OPPORTUNITY_STAGE_NEGOTIATING))
                    && (context == TriggerContext.AFTER_INSERT
                    || (context == TriggerContext.AFTER_UPDATE && TriggerUtility.isFieldValueChanged(opportunity, oldOpportunity, 'StageName'))));
    }
    
    private static Id getQueueIdByName(String queueName) {
        return [SELECT Id FROM Group WHERE Type='Queue' AND DeveloperName = :queueName][0].Id;
    }
}