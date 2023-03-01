@isTest
public with sharing class LeadChangeRelatedJourneyStatusTrHTest {

    @testSetup
    static void setup(){
        Lead l = new Lead(
            Company = 'Accenture',
            LastName = 'warner',
            Email = 'davidwarner@example.com', 
            LeadSource = 'WeWork.cn',
            Generate_Journey__c = true, 
            Marketing_Consent__c = true
        );

        TestingUtility.insertWithAssert(l);

        l.Status = GlobalConstants.JOURNEY_STATUS_DEFERRED;
        l.Unqualified_Reason__c = 'Other';

        TestingUtility.updateWithAssert(l);
    }

    @IsTest
    public static void changeLeadRelatedJourneyStatusTest() {
        List<Lead> newLeads = [SELECT Id, Email, Status, LastName, Unqualified_Reason__c FROM Lead];

        Map<Id, Lead> oldLeadsMap = getLeads(newLeads[0]);

        Test.startTest();
        LeadChangeRelatedJourneyStatusTrH journeyStatus = new LeadChangeRelatedJourneyStatusTrH(newLeads, oldLeadsMap);
        JourneyChangeRelatedLeadStatusTrH.isJourneyUpdated = false;
        journeyStatus.registerDmlConsolidator(DmlConsolidatorDefault.getInstance());
        journeyStatus.afterUpdate();
        Test.stopTest();

        List<Journey__c> journeys = (List<Journey__c>)journeyStatus.dml.recordsToUpdate.values();

        System.assertEquals(newLeads[0].Unqualified_Reason__c, journeys[0].Deferred_Reason__c, 'journey\'s Deferred_Reason__c should be equal to lead\'s Unqualified_Reason__c'); 
    }

    private static Map<Id, Lead>  getLeads(Lead lead) {
        return new Map<Id, Lead>{
            lead.Id => new Lead(
                Id = lead.Id,
                OwnerId = UserInfo.getUserId(),
                LastName = lead.LastName,
                Email = lead.Email,
                Status = GlobalConstants.JOURNEY_STATUS_WORKING
            )
        };
    }
}