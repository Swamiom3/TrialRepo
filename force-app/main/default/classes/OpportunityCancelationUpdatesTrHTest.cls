@isTest
public class OpportunityCancelationUpdatesTrHTest {
    @testSetup
    private static void makeData(){
        Account account = TestingUtility.createAccount('Acme', true);
        Building__c building = new Building__c(
            Name = 'testbuild-001',
            Building_ID__c = 'test234',
            UUID__c = 'test234',
            Time_Zone__c ='America/Denver'
         );
        insert building;
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Building_Id__c = building.Id,
            SBQQ__PricebookId__c = standardPricebook.Id,
            SBQQ__Account__c = account.Id
        );
        insert quote;
        ServiceContract serviceContract = new ServiceContract(
            Name = 'Test Service Contract',
            AccountId = account.Id,
            SBQQSC__Quote__c = quote.Id,
            StartDate = System.Now().date() - 1,
            EndDate = System.Now().date() + 10,
            Pricebook2Id = standardPricebook.Id,Building_Id__c =building.Id,
            SBQQSC__PreserveBundleStructureUponRenewals__c = true
        );
        insert serviceContract;
        Opportunity closedWonOpportunity = TestingUtility.createOpportunity(account.Id, false);
        closedWonOpportunity.SBQQSC__AmendedServiceContract__c = serviceContract.Id;
        insert closedWonOpportunity;
        Opportunity cancelationOpportunity = TestingUtility.createOpportunity(account.Id, false);
        cancelationOpportunity.SBQQSC__AmendedServiceContract__c = serviceContract.Id;
        cancelationOpportunity.Amendment_Opportunity_Type__c ='Cancellation';
        cancelationOpportunity.Replacement_Opportunity__c = closedWonOpportunity.Id;
        insert cancelationOpportunity;
        
    }
    @isTest
    private static void testOpportunityCancelUpdatesPositive(){
        Opportunity opportunity = [SELECT Id,StageName FROM Opportunity LIMIT 1];
        opportunity.StageName = 'Closed Won';
        opportunity.Amendment_Opportunity_Type__c ='Replacement';
        update opportunity;
        Opportunity updatedOpportunity =[SELECT Id, StageName FROM Opportunity WHERE Amendment_Opportunity_Type__c ='Cancellation' LIMIT 1];
        System.assert(updatedOpportunity.StageName=='Closed Won', 'Cancellation Opportunity not updated successfully');
    }
    
    @isTest
    private static void testOpportunityCancelUpdatesNegative(){
        Opportunity opportunity = [SELECT Id,StageName FROM Opportunity LIMIT 1];
        opportunity.StageName = 'Draft';
        opportunity.Amendment_Opportunity_Type__c ='Replacement';
        update opportunity;
        Opportunity updatedOpportunity =[SELECT Id, StageName FROM Opportunity WHERE Amendment_Opportunity_Type__c ='Cancellation' LIMIT 1];
        System.assert(updatedOpportunity.StageName!='Closed Won', 'Cancellation Opportunity updated successfully');
    }
}