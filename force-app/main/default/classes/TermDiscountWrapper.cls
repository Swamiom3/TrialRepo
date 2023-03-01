/*************************************************************************************************************************************
 Author      :   Arun
 Description :   This is a wrapper class for TermBasedDiscountController
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               11/18/2021       Arun        Initial Deployment
 **************************************************************************************************************************************/
public class TermDiscountWrapper {
    @AuraEnabled
    public String displayItem {get; set;}
    @AuraEnabled
    public String quoteLineId {get; set;}
    @AuraEnabled
    public String inventoryName {get; set;}
    @AuraEnabled
    public Date startDate {get;set;}
    @AuraEnabled
    public SBQQ__QuoteLine__c quoteLineRecord {get; set;}
    @AuraEnabled
    public Boolean isCommitmentWorkSpace{get; set;}
    @AuraEnabled
    public String promoName {get; set;}
    @AuraEnabled
    public Boolean startDateDisable{get; set;}
    @AuraEnabled
    public TermCommitmentWrapper commitmentTermData {get; set;}
    
    public TermDiscountWrapper(String displayItem, String inventoryName, TermCommitmentWrapper commitmentTermData, 
                               SBQQ__QuoteLine__c quoteLineRecord, Boolean isCommitmentWorkSpace, Boolean startDateDisable) {
        this.displayItem = displayItem;
        this.quoteLineId = quoteLineRecord.Id;
        this.inventoryName = inventoryName;
        this.commitmentTermData = commitmentTermData;
        this.startDate = quoteLineRecord.SBQQ__StartDate__c;
        this.quoteLineRecord = quoteLineRecord;
        this.isCommitmentWorkSpace =isCommitmentWorkSpace;
        this.promoName = quoteLineRecord.Promo_Code_Id__r.Name;
        this.startDateDisable = startDateDisable;
    }
}