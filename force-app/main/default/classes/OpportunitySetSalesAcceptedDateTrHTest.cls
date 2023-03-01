/*********************************************************************************************************
    Author        :  Ashish Sharma
    Description   :  Test class for OpportunitySetSalesAcceptedDateTrH
    Issue No.     :  TWSPG-14140
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1           08-Sept-2022      Ashish Sharma    Initial development 
**********************************************************************************************************/
@isTest
public class OpportunitySetSalesAcceptedDateTrHTest {
    @isTest
    public static void setSalesAcceptedDatePositiveTest() {
        Opportunity testOpp = TestingUtility.createOpportunity(TestUtility.getFakeId(Account.getSObjectType()), false);
        testOpp.Id = TestUtility.getFakeId(Opportunity.getSObjectType());
        
        Opportunity updatedOpp = new Opportunity(
            Id = testOpp.Id,
            StageName = 'Selling',
            Sales_Accepted_Date_N__c = null
        );
        
        OpportunitySetSalesAcceptedDateTrH instance = new OpportunitySetSalesAcceptedDateTrH(new List<Opportunity>{updatedOpp}, 
                                                                                             new Map<Id, Opportunity>{testOpp.Id => testOpp});
        instance.beforeUpdate();
        System.assertEquals(System.today(), updatedOpp.Sales_Accepted_Date_N__c, 'Sales Accepted date should be populated.');
    }
    
    @isTest
    public static void setSalesAcceptedDateNegativeTest() {
        Opportunity testOpp = TestingUtility.createOpportunity(TestUtility.getFakeId(Account.getSObjectType()), false);
        testOpp.Id = TestUtility.getFakeId(Opportunity.getSObjectType());
        testOpp.StageName = 'Closing';
            
        Opportunity updatedOpp = new Opportunity(
            Id = testOpp.Id,
            StageName = 'Selling',
            Sales_Accepted_Date_N__c = null
        );
        
        OpportunitySetSalesAcceptedDateTrH instance = new OpportunitySetSalesAcceptedDateTrH();
        instance.newOpportunities = new List<Opportunity>{updatedOpp};
        instance.oldOpportunitiesMap = new Map<Id, Opportunity>{testOpp.Id => testOpp};
        instance.beforeUpdate();
        System.assertEquals(null, updatedOpp.Sales_Accepted_Date_N__c, 'Sales Accepted date should be null.');
    }
}