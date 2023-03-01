/************************************************************************************************************************************
    Author      :   Jitesh Adwani
    Description :   This class will contain TestMethod for UnomyInformationController.
	Issue No    : 	ST-3523
    History		:
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1          5 Mar 2019		    Jitesh             Initial Developement
**************************************************************************************************************************************/
@isTest
public with sharing class UnomyInformationControllerTest {
/************************************************************************************************************************************
    Author         : Jitesh Adwani
    Description    : This method is used verifyInsertUpdateCampaignNamingConvention().
    Created Date   : 5 Mar 2019
    Issue No       : ST-3523
**************************************************************************************************************************************/
    @TestSetup
    static void makeData(){
        Integer count = 0;
        List<Lead> lstUpdateLeads = new List<Lead>();
        List<Lead> lstLeads = TestingUtility.getRecords(new Map<String, Object> {'objName'=>'Lead', 'numberOfRecords'=>4});
        List<CI_Company__c> lstUnomyCompany = TestingUtility.getRecords(new Map<String, Object> {'objName'=>'unomy', 'numberOfRecords'=>4, 'doInsert'=>true});
        for(Lead objLead : lstLeads){
            objLead.CI_Company__c = lstUnomyCompany[count].Id;
            lstUpdateLeads.add(objLead);
        }
        TestingUtility.updateListWithAssert(lstUpdateLeads);
        System.assertEquals(4, lstLeads.size());
    }
/************************************************************************************************************************************
    Author         : Jitesh Adwani
    Description    : This method is used verifyInsertUpdateCampaignNamingConvention().
    Created Date   : 5 Mar 2019
    Issue No       : ST-3523
**************************************************************************************************************************************/
    public static testMethod void verifyGetDataByRecordId(){
        List<Lead> lstLeads = new List<Lead>([SELECT Id, CI_Company__c FROM Lead]);
        System.assertEquals(4, lstLeads.size());
        CI_Company__c objUnomyCompany = [SELECT Id, Name, Size__c, Industry__c, Revenue__c, Location_Address__c, Website__c FROM CI_Company__c WHERE Id =: lstLeads[0].CI_Company__c];
        Map<String, Object> result = (Map<String, Object>)UnomyInformationController.getUnomyInformation(lstLeads[0].Id).data;
        CI_Company__c objUnomyCompanyResult = (CI_Company__c)result.get('UnomyCompanyRecord');
        System.assert(objUnomyCompanyResult.Id != null);
        System.assertEquals(lstLeads[0].CI_Company__c, objUnomyCompany.Id);
        System.assertEquals(lstLeads[0].CI_Company__c, objUnomyCompany.Id);
        System.assertEquals(objUnomyCompany.Id, objUnomyCompanyResult.Id);
        System.assertEquals(objUnomyCompany.Name, objUnomyCompanyResult.Name);
        System.assertEquals(objUnomyCompany.Size__c, objUnomyCompanyResult.Size__c);
        System.assertEquals(objUnomyCompany.Industry__c, objUnomyCompanyResult.Industry__c);
        System.assertEquals(objUnomyCompany.Revenue__c, objUnomyCompanyResult.Revenue__c);
    }
}