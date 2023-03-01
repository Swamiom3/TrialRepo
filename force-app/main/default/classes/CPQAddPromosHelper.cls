/*************************************************************************************************************************************
 Author      :   Arun
 Description :   Helper class for CPQAddPromos
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               03/15/2021       Arun        Initial Deployment
**************************************************************************************************************************************/
public inherited sharing class CPQAddPromosHelper {
    private static PromoCodeSelector promoCodeSelector = new PromoCodeSelector();
    private static CPQAddPromosConditionsHelper helper = new CPQAddPromosConditionsHelper();
    
    public Map<String,List<Promo_Code__c>> getpromoCodesWithTypes(Set<String> inventoryTypes){
        Map<String,List<Promo_Code__c>> promoCodesWithTypes = new Map<String,List<Promo_Code__c>>();
        if(inventoryTypes.isEmpty()){
            return promoCodesWithTypes;
        }
        for(Promo_Code__c promoCode : promoCodeSelector.getPromoCodesByExpiryAndPercent(inventoryTypes, date.today(), 0)){
            if(promoCodesWithTypes.containskey(promoCode.Type__c)){
                promoCodesWithTypes.get(promoCode.Type__c).add(promoCode);
            }else{
                promoCodesWithTypes.put(promoCode.Type__c,new List<Promo_Code__c>{promoCode});
            }
        }
        return promoCodesWithTypes;
    }
    
    public List<CPQAddPromosWrapper.ResponseWithInventory> getM2MAndAllAccessQuoteLines(List<SBQQ__QuoteLine__c> quoteLines,Map<String,List<Promo_Code__c>> promoCodesWithTypes){
        List<CPQAddPromosWrapper.ResponseWithInventory> responsewithInventoryList = new List<CPQAddPromosWrapper.ResponseWithInventory>();
        if(quoteLines.isEmpty()){
            return responsewithInventoryList;
        }
        for(SBQQ__QuoteLine__c quoteLine : quoteLines){
            CPQAddPromosWrapper.ResponseWithInventory responsewithInventory = new CPQAddPromosWrapper.ResponseWithInventory();
            CPQAddPromosWrapper.ResponseWrapper responseWrap = new CPQAddPromosWrapper.ResponseWrapper();
            if(quoteLine.Inventory_Id__r != null){
                responsewithInventory.uuid = quoteLine.Inventory_Id__r.UUID__c;
                responsewithInventory.inventoryName = quoteLine.Inventory_Id__r.Name;
                responsewithInventory.promoCodes = promoCodesWithTypes.get(quoteLine.Inventory_Id__r.Type__c);
            }else{
                responsewithInventory.uuid = quoteLine.SBQQ__ProductName__c;
                responsewithInventory.inventoryName = quoteLine.SBQQ__ProductName__c;
                responsewithInventory.promoCodes = promoCodesWithTypes.get(quoteLine.SBQQ__ProductFamily__c);
            }            
            responsewithInventory.curvesAvailable =false;
            responsewithInventory.promoCodesAvailable = responsewithInventory.promoCodes != null ? !responsewithInventory.promoCodes.isEmpty() : false;
            responsewithInventory.response = responseWrap;
            responsewithInventoryList.add(responsewithInventory);
        }
        return responsewithInventoryList;
    }
    
    public CPQAddPromosWrapper.ResponseWithInventory getTermTypesFromService(CPQAddPromosWrapper.ResponseWithInventory responseWithInventory,
                                                                                     List<CPQAddPromosWrapper.ResponseWrapper> responseWrapper){
        
        for(CPQAddPromosWrapper.ResponseWrapper responseWrap : responseWrapper){            
            Integer termTypeLength = 0;
            List<String> termTypes;
            responseWithInventory.curvesAvailable = !responseWrap.discounts.isEmpty();                
            for(CPQAddPromosWrapper.DiscountsWrapper discountWrapper : responseWrap.discounts){
                responseWithInventory.curvesAvailable = !discountWrapper.promotions.isEmpty();
                termTypes= new List<String>();
                if(termTypeLength < Integer.valueof(discountWrapper.termTypeLength)){
                    for(Integer i=1; i<=Integer.valueof(discountWrapper.termTypeLength); i++){
                        termTypes.add(CPQConstants.MONTH+i);
                    }
                }
                termTypeLength = termTypes.size();
                for(CPQAddPromosWrapper.PromotionsWrapper promotionWrapper : discountWrapper.promotions){                    
                    responseWithInventory.curvesAvailable = !promotionWrapper.dataPoints.isEmpty();               
                }
            }
            responseWithInventory.termTypes = termTypes;
            responseWithInventory.response = responseWrap;
            
        }
       
        return responseWithInventory;
    }
    
    public List<Promo_Code__c> getPromoCodes(SBQQ__QuoteLine__c quoteLine, Map<String,List<Promo_Code__c>> promoCodesWithTypes){
        List<Promo_Code__c> promoCodes = new List<Promo_Code__c>();
        if(helper.getPromosIntialCheck(quoteLine, promoCodesWithTypes)){
            return promoCodes;
        }
        Integer commitTerm = quoteLine.SBQQ__StartDate__c.Day()>1 ? Integer.valueof(quoteLine.Commitment_Term__c)+1 : Integer.valueof(quoteLine.Commitment_Term__c);
        for(Promo_Code__c promocode : promoCodesWithTypes.get(quoteLine.Inventory_Id__r.Type__c)){
            if(Integer.valueof(promocode.Duration__c) <= commitTerm){
                promoCodes.add(promocode);
            }
        }
        return promoCodes;        
    }
    
    public List<SBQQ__QuoteLine__c> getQuoteLinesWithPartnerDiscount(List<SBQQ__QuoteLine__c> quoteLines,Map<String,List<Decimal>> inventoryDatapoints){
        List<SBQQ__QuoteLine__c> quoteLinesWithPartnerDiscount = new List<SBQQ__QuoteLine__c>();
        for(SBQQ__QuoteLine__c quoteLine : quoteLines){
            if(helper.isNotMonthAllAccessProd(quoteLine)){               
                continue;
            }
            if(inventoryDatapoints.containskey(quoteLine.Inventory_Id__r.UUID__c)){
                quoteLine.Promo_Code_Id__c = null;                
                if(helper.checkInventoryDataPoint(quoteLine, inventoryDatapoints)){
                    quoteLine.SBQQ__PartnerDiscount__c = inventoryDatapoints.get(quoteLine.Inventory_Id__r.UUID__c)[Integer.valueof(quoteLine.SBQQ__ProductCode__c)-1]*100;
                }
                quoteLinesWithPartnerDiscount.add(quoteLine);
            }
        }
        return quoteLinesWithPartnerDiscount;        
    }

    public List<SBQQ__QuoteLine__c> getPromoDiscounts(List<SBQQ__QuoteLine__c> quoteLines,Map<String,CPQAddPromosWrapper.PromoSelect> promoWrapperWithInventoryUUID){
        List<SBQQ__QuoteLine__c> quoteLinesWithPromoDiscounts = new List<SBQQ__QuoteLine__c>();
        for(SBQQ__QuoteLine__c quoteLine : quoteLines){
            if(helper.isNotMonthAllAccessProd(quoteLine)){               
                continue;
            }
            if(helper.checkPromoInventoryUUID(quoteLine, promoWrapperWithInventoryUUID)){
                  quoteLinesWithPromoDiscounts.add(assignPromoDiscounts(quoteLine,promoWrapperWithInventoryUUID));                               
            }
        }
        return quoteLinesWithPromoDiscounts;
    }

    private SBQQ__QuoteLine__c assignPromoDiscounts(SBQQ__QuoteLine__c quoteLine,Map<String,CPQAddPromosWrapper.PromoSelect> promoWrapperWithInventoryUUID){
        String uuid = quoteLine.Inventory_Id__r.UUID__c != null ? quoteLine.Inventory_Id__r.UUID__c : quoteLine.SBQQ__RequiredBy__r.SBQQ__Product__r.Name;
        if(quoteLine.SBQQ__Product__r.Name.startsWith(CPQConstants.MONTH)){
            assignPromoDisocuntsToMonthlyLines(quoteLine,promoWrapperWithInventoryUUID,uuid);                    
        }
        else{
            String parentLineUUID = quoteLine.Inventory_Id__r.UUID__c != null ? quoteLine.Inventory_Id__r.UUID__c : quoteLine.SBQQ__Product__r.Name;
            quoteLine.Promo_Code_Id__c = promoWrapperWithInventoryUUID.get(parentLineUUID).promoId;
        }
        return quoteLine;
    }

    private SBQQ__QuoteLine__c assignPromoDisocuntsToMonthlyLines(SBQQ__QuoteLine__c quoteLine,Map<String,CPQAddPromosWrapper.PromoSelect> promoWrapperWithInventoryUUID,String uuid){
        Integer duration;
        if(quoteLine.SBQQ__RequiredBy__r.SBQQ__StartDate__c != null){
            duration = quoteLine.SBQQ__RequiredBy__r.SBQQ__StartDate__c.day() > 1 ? Integer.valueof(promoWrapperWithInventoryUUID.get(uuid).duration) +1 : Integer.valueof(promoWrapperWithInventoryUUID.get(uuid).duration); 
        }
        if(quoteLine.SBQQ__Quote__r.Subscription_Type__c != CPQConstants.SUBSCRIPTION_M2M && duration < Integer.valueof(quoteLine.SBQQ__ProductCode__c)){
            quoteLine.Promo_Code_Id__c = null;
            quoteLine.SBQQ__PartnerDiscount__c = null;                       
        }else{
            if(quoteLine.SBQQ__Quote__r.Subscription_Type__c == CPQConstants.SUBSCRIPTION_M2M){
                quoteLine.Maximum_Discount__c = null;
                quoteLine.Discount_End_Date__c  = quoteLine.SBQQ__StartDate__c.addMonths(Integer.valueOf(promoWrapperWithInventoryUUID.get(uuid).duration)).toStartofMonth().addDays(-1);
            }
            quoteLine.Promo_Code_Id__c = promoWrapperWithInventoryUUID.get(uuid).promoId;
            quoteLine.SBQQ__PartnerDiscount__c = Decimal.valueof(promoWrapperWithInventoryUUID.get(uuid).percent);
        }
        return quoteLine;
    }
}