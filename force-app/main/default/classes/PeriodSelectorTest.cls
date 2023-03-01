/*************************************************************************************************************************************
    Author      :   Krishna Somwanshi
    Description :   This class sufficient test coverage for PeriodSelector class
--------------------------------------------------------------------------------------------------------------------------------------
    VERSION         DATE            AUTHOR              DETAIL
    1               04/10/2021       Krishna Somwanshi   Initial Deployment
**************************************************************************************************************************************/
@isTest
public class PeriodSelectorTest {
    @testSetup
    private static void setup() {
        Date dt = System.today();
        Id recordTypeId = Schema.SObjectType.Period__c.getRecordTypeInfosByName().get('Monthly').getRecordTypeId();
        Period__c period = new Period__c(Name = 'Test Period', Start_Date__c = dt, End_Date__c = dt.addDays(30), RecordTypeId = recordTypeId);
        insert period;
    }
    @isTest
    public static void getToursByOpportunitiesTest(){
        Period__c period = [SELECT Id, Name, Start_Date__c, End_Date__c, RecordType.Name FROM Period__c LIMIT 1];
        PeriodSelector periodSelector = new PeriodSelector();
        System.assert(!periodSelector.getPeriodsByRecordTypeNameStartDateEndDate(new Set<Date>{period.Start_Date__c}, new Set<String>{period.RecordType.Name}, new Set<Date>{period.End_Date__c}).isEmpty(), 'List should not be empty');
    }
}