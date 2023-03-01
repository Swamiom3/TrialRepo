/************************************************************************************************************************************
Author      :   Monika
Description :   This class will contain test methods of OppTeamMemberValidateOriginatingRepTrH and OppTeamMemberValidateMembersTrH.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE              AUTHOR                  DETAIL
1.0         07 Dec 2021    	 Monika        Modification according to new test structure
2.0			03 Jan 2022		 Vamsi		   To Increase the code coverage
*************************************************************************************************************************************/
@isTest
public class OppTeamMemberValidateOriginatingReTest {
    
    Public static testmethod void oppTeamMembertestmethod(){
        
        Account account = TestingUtility.createAccount('Acme', true);
        Id usrId = [SELECT Id FROM User WHERE id=: userinfo.getUserId()].id;
        User runUsr = [SELECT Id FROM User WHERE name != 'System Administrator' LIMIT 1];
        User usr = [SELECT Id FROM User WHERE id=: userinfo.getUserId()];
        
        Set<Id> oppSet;
        Opportunity closedWonOpportunity = TestingUtility.createOpportunity(account.Id, false);
        closedWonOpportunity.OwnerId = usrId;
        insert closedWonOpportunity;
        
        Opportunity cancellationOpportunity = TestingUtility.createOpportunity(account.Id, false);
        cancellationOpportunity.OwnerId = usrId;
        insert cancellationOpportunity;
        
        OpportunityTeamMember oppTeam = New OpportunityTeamMember();
        oppTeam.OpportunityId = closedWonOpportunity.id;
        oppTeam.UserId = usrId;
        oppTeam.TeamMemberRole = 'opp: originating rep';
        oppTeam.TeamMemberCreationSource__c = 'RequestCoOwner';
        insert oppTeam;            
        
        OpportunityTeamMember oppTeamMem = New OpportunityTeamMember();
        oppTeamMem.OpportunityId = cancellationOpportunity.id;
        oppTeamMem.TeamMemberRole = 'opp: originating rep';
        oppTeamMem.UserId = [Select Id from User where id=: userinfo.getUserId()].id;
        oppTeamMem.TeamMemberCreationSource__c = 'RequestCoOwner';
        insert oppTeamMem;
        
        OpportunityTeamMember oppTeamMemb = New OpportunityTeamMember();
        oppTeamMemb.OpportunityId = cancellationOpportunity.id;
        oppTeamMemb.TeamMemberRole = 'all access';
        oppTeamMemb.UserId = [Select Id from User where id=: userinfo.getUserId()].id;
        oppTeamMemb.TeamMemberCreationSource__c = 'RequestCoOwner';
        insert oppTeamMemb;
        
        Map<Id, List<OpportunityTeamMember>> oppIdToMember = new Map<Id, List<OpportunityTeamMember>>();
        Map<Id, OpportunityTeamMember> idOTM = new Map<Id, OpportunityTeamMember>();
        idOTM.put(oppTeam.id,oppTeam);
        idOTM.put(oppTeamMem.id,oppTeamMem);
        
        List<OpportunityTeamMember> validMembers = new List<OpportunityTeamMember>();
        Map<Id, Opportunity> validOpportunities = New Map<Id, Opportunity>();
        validOpportunities.put(closedWonOpportunity.id,closedWonOpportunity);
        validOpportunities.put(cancellationOpportunity.id,cancellationOpportunity);
        
        
        Set<id> opptSet = new Set<id>();
        opptSet.add(cancellationOpportunity.id);            
        List<OpportunityTeamMember> otList = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> otList1 = new List<OpportunityTeamMember>();
        otList.add(oppTeam);
        otList.add(oppTeamMem);            
        oppIdToMember.put(closedWonOpportunity.id,otList);
        
        System.runAs(usr){
            OppTeamMemberValidateOriginatingRepTrH oppTeamValid = new OppTeamMemberValidateOriginatingRepTrH();        
            OppTeamMemberValidateOriginatingRepTrH oppTeamValidTr = new OppTeamMemberValidateOriginatingRepTrH(otList);
            
            oppTeamValidTr.validateOriginatingRepOppTeamMembers();
            oppTeamValidTr.getValidOpportunities(opptSet);
            oppTeamValidTr.isLoggedInUserCoOwner(otList);
            oppTeamValidTr.isLoggedInUserCoOwner(otList1);                        
            oppTeamValidTr.validateOriginatingRep(validOpportunities);            
        }
        Test.startTest();
        System.runAs(runUsr){
            OppTeamMemberValidateMembersTrH oppValidMem = new OppTeamMemberValidateMembersTrH();
            OppTeamMemberValidateMembersTrH oppValidMemb = new OppTeamMemberValidateMembersTrH(otList,idOTM,idOTM);
            oppValidMem.getTeamMembers(opptSet);
            oppValidMemb.validateMembers();
            validMembers = [SELECT Name, OpportunityId, UserId FROM OpportunityTeamMember];
            oppValidMemb.validateAllAccessMembers(oppIdToMember,new List<OpportunityTeamMember>{validMembers.get(0)});
        } 
        Test.stopTest();        
        System.assertNotEquals(NULL, validOpportunities,'Map should have the opportunities');
    }
}