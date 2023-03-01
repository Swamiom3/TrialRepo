/************************************************************************************************************************************
Author         :     Oleksandr Liesnik
Description    :     Trigger Handler for publishing custom Event with Opp Id when Opp Stage changed to Closed Won 
----------------------------------------------------------------------------------------------------------------------------------
VERSION        DATE                AUTHOR                    DETAIL
1              25 Nov 2021         Oleksandr Liesnik         Initial Development
**************************************************************************************************************************************/
public with sharing class OppWonEventPublishTrH extends SObjectTriggerHandler {
    private final Map<Id, Opportunity> newOpportunitiesMap;
    private final Map<Id, Opportunity> oldOpportunitiesMap;
    @TestVisible
    private static Integer closedWonEventsPublished = 0;

    public OppWonEventPublishTrH() {
        this((Map<Id, Opportunity>) Trigger.newMap, (Map<Id, Opportunity>) Trigger.oldMap);
    }

    @TestVisible
    private OppWonEventPublishTrH(Map<Id, Opportunity> newOpportunitiesMap, Map<Id, Opportunity> oldOpportunitiesMap) {
        this.newOpportunitiesMap = newOpportunitiesMap;
        this.oldOpportunitiesMap = oldOpportunitiesMap;
    }

    public override void afterUpdate() {
        publishClosedWonEvents();
        MetadataDrivenTriggerHandler.clearLoopCount('OppWonEventPublishTrH');
    }

    private void publishClosedWonEvents() {
        List<Opportunity_Closed_Won__e> wonOppEvents = new List<Opportunity_Closed_Won__e>();
        for (Opportunity item : newOpportunitiesMap.values()) {
            if (
                (item.isWon && TriggerUtility.isFieldValueChanged(item, oldOpportunitiesMap.get(item.Id), 'isWon')) 
                || (item.StageName == GlobalConstants.OPP_CLOSED_WON_STAGE_NAME 
                && TriggerUtility.isFieldValueChanged(item, oldOpportunitiesMap.get(item.Id), 'StageName'))
            ) {
                wonOppEvents.add(new Opportunity_Closed_Won__e(Opportunity_Id__c = item.Id));
            }
        }
        if (wonOppEvents.isEmpty()) {
            return;
        }

        List<Database.SaveResult> results = EventBus.publish(wonOppEvents);

        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                closedWonEventsPublished++;
            } else {
                for (Database.Error err : sr.getErrors()) {
                    new ApexDebugLog().createLog(new ApexDebugLog.Error('OppWonEventPublishTrH', 'publishClosedWonEvents', null, new OpportunityClosedWonException(err.getMessage())));
                }
            }
        }
    }

    public class OpportunityClosedWonException extends Exception {} 
}