/************************************************************************************************************************************
    Author      : Shobhit Gahlot
    Description : This class will have all the server side logic of CommunityView sales inquiry
--------------------------------------------------------------------------------------------------------------------------------------
    VERSION                 DATE                    AUTHOR                          DETAIL
    1                       10 June, 2020           Shobhit Gahlot                  Initial Development
*************************************************************************************************************************************/
public without sharing class CommunityViewSalesInquiryServer {
    public static Boolean isInvoker = false;
    private static final String BILLING_ACCOUNT_RECORD_TYPE = 'Billing Account';
    private static final String OPPORTUNITY_RENEWAL_RECORD_TYPE = 'Renewal';
    private static final String CAMPAIGN_OF_INTEREST = '\nPromotion / Campaign of Interest:  ';
    private static final String NOT_AVAILABLE = 'N/A';
    static {
        isInvoker = ApexDebugLog.registerRootInvoker(ApexDebugLog.InvokerType.AURA, 'CommunityViewSalesInquiryServer' + 'saveTaskAndOpportunity', ApexDebugLog.InvokerType.AURA);
    }

    @AuraEnabled
    public static DatabaseResult getBillingAccountRecordType(){
        try{
            return new DatabaseResult(Schema.SObjectType.Account.getRecordTypeInfosByName().get(BILLING_ACCOUNT_RECORD_TYPE).getRecordTypeId());
        } catch(Exception pEx){
            ApexDebugLog.logException(pEx, '', 'CommunityViewSalesInquiryServer', 'getBillingAccountRecordType');
            return (new DatabaseResult(pEx));
        }
    }

    @AuraEnabled
    public static DatabaseResult saveTaskAndOpportunity(Task taskToSave, Opportunity opportunityToSave, CampaignMember campaignMember){
        SavePoint sp = Database.setSavepoint();
        try{
            Id apiUserId = UserUtility.getApiUserId();
            opportunityToSave.OwnerId = apiUserId;
            opportunityToSave.CloseDate = Date.Today();
            opportunityToSave.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(OPPORTUNITY_RENEWAL_RECORD_TYPE).getRecordTypeId();
            insert opportunityToSave;
            taskToSave.Description += CAMPAIGN_OF_INTEREST;  
            if(campaignMember != null){
                Campaign campaign = [SELECT Id, Campaign.Name FROM Campaign WHERE Id = :campaignMember.CampaignId LIMIT 1]; 
                taskToSave.Description += campaign.Name;
            }else {
                taskToSave.Description += NOT_AVAILABLE;
            }
            taskToSave.OwnerId = apiUserId;
            taskToSave.WhatId = opportunityToSave.Id;
            taskToSave.ActivityDate = Date.Today().addDays(1);
            insert taskToSave;
            if(isVaildCampaignMember(campaignMember)){
                insert campaignMember;
            }
            return new DatabaseResult('Task created successfully');
        } catch(Exception pEx){
            LightningComponentController.rollbackTransaction(sp);
            ApexDebugLog.logException(pEx, ' objTask ==>' + taskToSave + '\n objOpportunity=>' + opportunityToSave + ' campaignMember ==>' +campaignMember, 'CommunityViewSalesInquiryServer', 'saveTaskAndOpportunity');
            return (new DatabaseResult(pEx));
        }
    }

    private static Boolean isVaildCampaignMember(CampaignMember campaignMember) {
        if (campaignMember == null) {
            return false;
        }
        return [SELECT Id FROM CampaignMember WHERE ContactId = :campaignMember.ContactId AND CampaignId = :campaignMember.CampaignId].isEmpty();
    }
}