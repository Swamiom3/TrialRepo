/*************************************************************************************************************************************
 Author      :   Arun
 Description :   Helper class for CPQAddPromos
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               03/15/2021       Arun        Initial Deployment
**************************************************************************************************************************************/
public class CPQAddPromosConditionsHelper {
    public Boolean checkInventoryAndAllAccess(SBQQ__QuoteLine__c quoteLine) {
        return quoteLine.SBQQ__RequiredBy__c != null || (quoteLine.Inventory_Id__r == null && quoteLine.SBQQ__ProductFamily__c != CPQConstants.ALL_ACCESS);
    }
    
    public Boolean isM2MOrCommitmentProd(SBQQ__QuoteLine__c quoteLine) {
        return quoteLine.SBQQ__Quote__r.Subscription_Type__c == CPQConstants.SUBSCRIPTION_M2M && quoteLine.SBQQ__Product__r.Name.startsWith(CPQConstants.COMMITMENT);
    }
    
    public Boolean savePromosInitialCheck(List<SBQQ__QuoteLine__c> quoteLines, String quoteId, String response) {
        return quoteLines.isEmpty() || quoteId == null || response ==null;
    }
    
    public Boolean isCommitmentM2MProd(SBQQ__QuoteLine__c quoteLine) {
        return quoteLine.SBQQ__Product__r.Name.startsWith(CPQConstants.COMMITMENT)
            && quoteLine.Commitment_Term__c == null
            && quoteLine.SBQQ__Quote__r.Subscription_Type__c != CPQConstants.SUBSCRIPTION_M2M;
    }
    
    public Boolean checkInventoryAndSubType(SBQQ__QuoteLine__c quoteLine) {
        return quoteLine.Inventory_Id__r == null || quoteLine.SBQQ__RequiredBy__c != null || quoteLine.SBQQ__Quote__r.Subscription_Type__c == CPQConstants.SUBSCRIPTION_M2M;
    }
    
    public Boolean checkInventoryDataPoint(SBQQ__QuoteLine__c quoteLine, Map<String,List<Decimal>> inventoryDatapoints) {
        return !quoteLine.SBQQ__Product__r.Name.startsWith(CPQConstants.COMMITMENT) &&
            inventoryDatapoints.get(quoteLine.Inventory_Id__r.UUID__c)[Integer.valueof(quoteLine.SBQQ__ProductCode__c)-1] != 0;
    }
    
    public Boolean getPromosIntialCheck(SBQQ__QuoteLine__c quoteLine, Map<String,List<Promo_Code__c>> promoCodesWithTypes) {
        return !promoCodesWithTypes.containsKey(quoteLine.Inventory_Id__r.Type__c) || quoteLine.Commitment_Term__c == null;
    }
    
    public Boolean isNotMonthAllAccessProd(SBQQ__QuoteLine__c quoteLine) {
        return !quoteLine.SBQQ__Product__r.Name.startsWith(CPQConstants.MONTH)
            && !quoteLine.SBQQ__Product__r.Name.startsWith(CPQConstants.COMMITMENT) 
            && !quoteLine.SBQQ__Product__r.Name.startsWith(CPQConstants.ALL_ACCESS);
    }
    
    public Boolean checkPromoInventoryUUID(SBQQ__QuoteLine__c quoteLine, Map<String,CPQAddPromosWrapper.PromoSelect> promoWrapperWithInventoryUUID) {
        return promoWrapperWithInventoryUUID.containskey(quoteLine.Inventory_Id__r.UUID__c)
            || promoWrapperWithInventoryUUID.containskey(quoteLine.SBQQ__RequiredBy__r.SBQQ__Product__r.Name)
            || promoWrapperWithInventoryUUID.containskey(quoteLine.SBQQ__Product__r.Name);
    }
}