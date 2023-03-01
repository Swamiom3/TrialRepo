/************************************************************************************************************************************
    Author         :     Roshan Kankrayane
    Description    :     This class will contains test methods for TrOpportunityFlowToTriggers.
    Issue No       :     ST-5715
    History        :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION            DATE                    AUTHOR                          DETAIL
    1                Feb 20 2020             Roshan Kankrayane               Initial Development
    2                Mar  2 2020             Mikołaj Juras                   Add test method for updateOpportunityCloseDate method     
**************************************************************************************************************************************/
@isTest
public class TrOpportunityFlowToTriggersTest implements IProcessTestHandler {

    public void handleTest(List<sObject> triggerNew, Map<Id, sObject> triggerOldMap, Map<String, sobject> mapsObjectForUpdate, String event) {
        Map<String, Opportunity> mapOpportunities = mapsObjectForUpdate != null ? (Map<String, Opportunity>)mapsObjectForUpdate : null;
        Switch on event.toLowerCase(){
            when 'insertassert'{
                verifyOppFlowToTriggerOnInsert((List<Opportunity>) triggerNew);
            }
            when 'updatevalues'{
                verifyOppFlowToTriggerValuesUpdate((List<Opportunity>) triggerNew, mapOpportunities);
            }
            when 'updateassert'{
               verifyOppFlowToTriggerOnUpdate((List<Opportunity>) triggerNew, mapOpportunities);
            }
        }
    }

    private void verifyOppFlowToTriggerOnInsert(List<Opportunity> triggerNew){
        List<OpportunityTeamMember> lstOppTeamMember = [SELECT Id, TeamMemberRole FROM OpportunityTeamMember WHERE Opportunity.Contract_UUID__c = '6565'];
        for(Opportunity objOpp : triggerNew){
            if(objOpp.Contract_UUID__c == '6565'){
                //Verify Create Opportunity team member of Partners
                System.assert(lstOppTeamMember.Size() > 0, 'Opportunity should have team members.');
                System.assertEquals('Co-Owner', lstOppTeamMember[0].TeamMemberRole, 'Team Member should be a Co-owner');
            }
        }
    }

    private void verifyOppFlowToTriggerValuesUpdate(List<Opportunity> triggerNew, Map<String, Opportunity> mapsObjectForUpdate){
        Opportunity objOpp = [SELECT Id FROM Opportunity WHERE Contract_UUID__c = '012' LIMIT 1];
        Lead objLead = [SELECT Id FROM Lead LIMIT 1];
        Building__c objBuilding = [SELECT Id, Email__c FROM Building__c WHERE UUID__c = 'testBuilding2' LIMIT 1];
        objBuilding.Email__c = 'we-pe-54877@wework.com';
        update objBuilding;
        for(Opportunity objOpportunity : triggerNew) {
            if(objOpportunity.Contract_UUID__c == '123'){
                objOpportunity.StageName = 'Closed Lost';
                objOpportunity.Lost_Reason__c = 'Pricing';
                mapsObjectForUpdate.put(objOpportunity.Contract_UUID__c, objOpportunity);
            }else if(objOpportunity.Contract_UUID__c == '456'){
                objOpportunity.StageName = 'Tour Complete';
                mapsObjectForUpdate.put(objOpportunity.Contract_UUID__c, objOpportunity);
            }else if(objOpportunity.Contract_UUID__c == '011'){
                objOpportunity.StageName = 'Tour Scheduled';
                objOpportunity.Building__c = objBuilding.Id;
                objOpportunity.Lead_Id__c = objLead.Id;
                mapsObjectForUpdate.put(objOpportunity.Contract_UUID__c, objOpportunity);
            }else if(objOpportunity.Contract_UUID__c == '116'){
                objOpportunity.Actual_Start_Date__c = system.today();
                objOpportunity.StageName = 'Contract Signed';
                mapsObjectForUpdate.put(objOpportunity.Contract_UUID__c, objOpportunity);
            }else if(objOpportunity.Contract_UUID__c == '013'){
                objOpportunity.StageName = 'Closed Won';
                mapsObjectForUpdate.put(objOpportunity.Contract_UUID__c, objOpportunity);
            }
        }
    }

    private void verifyOppFlowToTriggerOnUpdate(List<Opportunity> triggerNew, Map<String, Opportunity> mapsObjectForUpdate){
        Building__c objBuilding = [SELECT Id, Email__c FROM Building__c WHERE UUID__c = 'testBuilding2' LIMIT 1];
        Lead objLead = [SELECT Id FROM Lead LIMIT 1];
        Case objCase = [SELECT Id, Status, Opportunity_Stage_Field_Update__c FROM Case WHERE Opportunity__r.Contract_UUID__c = '123' LIMIT 1];
        List<OpportunityTeamMember> lstOppTeamMember = [SELECT Id, TeamMemberRole FROM OpportunityTeamMember WHERE Opportunity.Contract_UUID__c = '014'];
        //This is used to verify update Opportunity CloseDate as Today when StageName changed to 'Closed Lost'.
        System.assertEquals(System.today(), mapsObjectForUpdate.get('123').CloseDate);
        //This is used to verify update Opportunity Move_Out_Building__c as Opportunity Old_Opportunity__c.Building__c when Old_Opportunity__c gets changed.
        System.assertEquals(mapsObjectForUpdate.get('012').Building__c, mapsObjectForUpdate.get('116').Move_Out_Building__c);
        //This is used to verify update Account Date_of_First_Business__c as Opportunity CloseDate when Date_of_First_Business__c = NULL
        //and Account_Type__c is ORG.
        System.assertEquals(System.today(), mapsObjectForUpdate.get('013').Account.Date_of_First_Business__c);
        System.assertEquals('Closed Lost', objCase.Status);
        System.assertEquals(mapsObjectForUpdate.get('123').StageName, objCase.Opportunity_Stage_Field_Update__c);
        //This is used to verify Opportunity Updated_from_Closed_Won__c as TRUE when StageName changed to 'Closed Won'.
        System.assertEquals(TRUE, mapsObjectForUpdate.get('013').Updated_from_Closed_Won__c);
    }

    @isTest
    public static void verifyUpdateOpportunityCloseDate() {
        
        Date testCloseDate = System.today().addDays(10);
        String oppSourceTypeAutomatic = 'Auto Renewal';
        String oppSourceTypeVTS = 'VTS';
        TrOpportunityFlowToTriggers oppToFlowTr = new TrOpportunityFlowToTriggers();

        Opportunity opportunity = TestingUtility.createOpportunity(new Map<String,Object>{'name' => 'Test Opportunity 2'}, false);
        opportunity.CloseDate = testCloseDate;
        opportunity.Opportunity_Creation_Source__c = OppSourceTypeAutomatic;

        oppToFlowTr.updateOpportunityCloseDate(opportunity);

        System.assertEquals(System.today().addMonths(1) , opportunity.CloseDate, 'CloseDate shoul be set to today + 1 month');

        opportunity.CloseDate = testCloseDate;
        opportunity.Opportunity_Creation_Source__c = oppSourceTypeVTS;

        oppToFlowTr.updateOpportunityCloseDate(opportunity);

        System.assertEquals(testCloseDate , opportunity.CloseDate, 'CloseDate should remain unchanged');
    }
}