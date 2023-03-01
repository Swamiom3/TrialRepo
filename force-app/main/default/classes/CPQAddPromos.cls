/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class calls AddPromos Service.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           10 AUG 2021         Salesforce            Initial Developement
2           11 Mar 2022         Arun Vadduri          Refactor
**************************************************************************************************************************************/
public with sharing class CPQAddPromos {
    public static Map<String,String> quoteLineWithTerm;
    private static Map<String,CPQAddPromosWrapper.PromoSelect> promoWrapperWithInventoryUUID = new Map<String,CPQAddPromosWrapper.PromoSelect>();
    private static QuoteLineSelector quoteLineSelector = new QuoteLineSelector();
    private static List<SBQQ__QuoteLine__c> workspaceQuoteLines = new List<SBQQ__QuoteLine__c>();
    private static List<SBQQ__QuoteLine__c> allAccessQuoteLines = new List<SBQQ__QuoteLine__c>();
    private static List<SBQQ__QuoteLine__c> m2mQuoteLines = new List<SBQQ__QuoteLine__c>();
    private static Set<String> inventoryTypes = new Set<String>();
    private static Map<String,List<Decimal>> inventoryUUIDwithCurveValues = new  Map<String,List<Decimal>>();
    private static Map<String,Decimal> inventoryUUIDwithBaseDiscounts = new Map<String,Decimal>();
    private static Map<String,List<Decimal>> inventoryDatapoints = new Map<String,List<Decimal>>();
    private static Map<String,Decimal> inventoryBasediscounts = new Map<String,Decimal>();
    private static CPQAddPromosHelper helper = new CPQAddPromosHelper();
    private static CPQAddPromosConditionsHelper conditionHelper = new CPQAddPromosConditionsHelper();
    private static CPQSavePromosAndCurvesHelper savePromosHelper = new CPQSavePromosAndCurvesHelper();
    
    @AuraEnabled
    public static List<CPQAddPromosWrapper.ResponseWithInventory> getPromos(String quoteId,String source){
        Map<String,List<Promo_Code__c>> promoCodesWithTypes = new Map<String,List<Promo_Code__c>>();        
        if(quoteId == null){
            return null;
        }
        String accessToken = AddonProductSvcCallOut.getOAuthJWTToken();
        List<SBQQ__QuoteLine__c> quoteLines = quoteLineSelector.getQuoteLinesByQuoteId(quoteId);        
        validateStartDateAndCommitmentTerm(quoteLines,source);
        compileQuoteLines(quoteLines);        
        promoCodesWithTypes = helper.getpromoCodesWithTypes(inventoryTypes);
        List<CPQAddPromosWrapper.ResponseWrapper> responseWrapper = getPromoCurves(workspaceQuoteLines,source);
        if(responseWrapper==null){
            return null;
        }        
        List<CPQAddPromosWrapper.ResponseWithInventory> responseWithInventoryList = getResponseWithInventory(responseWrapper, promoCodesWithTypes,workspaceQuoteLines);  
        responseWithInventoryList.addAll(helper.getM2MAndAllAccessQuoteLines(allAccessQuoteLines,promoCodesWithTypes));        
        responseWithInventoryList.addAll(helper.getM2MAndAllAccessQuoteLines(m2mQuoteLines,promoCodesWithTypes));
        return responseWithInventoryList;        
    }
    
    private static void compileQuoteLines(List<SBQQ__QuoteLine__c> quoteLines){
        for(SBQQ__QuoteLine__c quoteLine : quoteLines){
            if(conditionHelper.checkInventoryAndAllAccess(quoteLine)){
                continue;
            }
            if(conditionHelper.isM2MOrCommitmentProd(quoteLine)){
                m2mQuoteLines.add(quoteLine);
                inventoryTypes.add(quoteLine.Inventory_Id__r.Type__c);
            }else if(quoteLine.SBQQ__Product__r.Name.startsWith(CPQConstants.COMMITMENT)){
                workspaceQuoteLines.add(quoteLine);
                inventoryTypes.add(quoteLine.Inventory_Id__r.Type__c);
            }            
            if(quoteLine.SBQQ__ProductFamily__c == CPQConstants.ALL_ACCESS){
                inventoryTypes.add(CPQConstants.ALL_ACCESS);
                allAccessQuoteLines.add(quoteLine);
            }            
        }
    }
    private static void validateStartDateAndCommitmentTerm(List<SBQQ__QuoteLine__c> quoteLines,String source){
        if(quoteLines.isEmpty()){
            return;
        }
        for(SBQQ__QuoteLine__c quoteLine : quoteLines){
            if(quoteLine.SBQQ__RequiredBy__c == null && source != CPQConstants.ACTUAL_SOURCE){
                if(conditionHelper.isCommitmentM2MProd(quoteLine)){
                    showErrorMessage(CPQConstants.ERROR_MESSAGE);
                }else if(quoteLine.SBQQ__StartDate__c == null){
                    showErrorMessage(CPQConstants.ERROR_MESSAGE_STARTDATE);
                }
            }
        }
    }
    
    private static void showErrorMessage(String message){
        throw new AuraHandledException(message);
    }

    private static List<CPQAddPromosWrapper.ResponseWithInventory> getResponseWithInventory(List<CPQAddPromosWrapper.ResponseWrapper> responseWrapper, 
                                                                                            Map<String,List<Promo_Code__c>> promoCodesWithTypes,List<SBQQ__QuoteLine__c> quoteLines){
        List<CPQAddPromosWrapper.ResponseWithInventory> responseWithInventoryList = new List<CPQAddPromosWrapper.ResponseWithInventory>();        
        for(SBQQ__QuoteLine__c quoteLine : quoteLines){
            CPQAddPromosWrapper.ResponseWithInventory responseWithInventory = new CPQAddPromosWrapper.ResponseWithInventory();
            if(conditionHelper.checkInventoryAndSubType(quoteLine)){
                continue;
            }
            responseWithInventory.inventoryName = quoteLine.Inventory_Id__r.Name;
            responseWithInventory.promoCodes = helper.getPromoCodes(quoteLine,promoCodesWithTypes);
            responseWithInventory.promoCodesAvailable = !responseWithInventory.promoCodes.isEmpty();
            responseWithInventory.uuid = quoteLine.Inventory_Id__r.UUID__c;
            responseWithInventoryList.add(helper.getTermTypesFromService(responseWithInventory,responseWrapper));
        }
        return responseWithInventoryList;
    }

    private static CPQAddPromosReqWrapper.RequestWrapper getRequestWrap(List<SBQQ__QuoteLine__c> quoteLines,String source){
        CPQAddPromosReqWrapper.RequestWrapper requestWrapper = new CPQAddPromosReqWrapper.RequestWrapper();
        if(quoteLines.isEmpty()){
            return requestWrapper;
        }
        List<CPQAddPromosReqWrapper.RequestWithUUIDandCommimentTerms> requestWithUUIDWrapperList = new List<CPQAddPromosReqWrapper.RequestWithUUIDandCommimentTerms>();
        for(SBQQ__QuoteLine__c quoteLine : quoteLines){
            CPQAddPromosReqWrapper.RequestWithUUIDandCommimentTerms requestWrapperWithUUID = new CPQAddPromosReqWrapper.RequestWithUUIDandCommimentTerms();
            if(quoteLine.SBQQ__RequiredBy__c != null || quoteLine.SBQQ__ProductFamily__c == CPQConstants.ADDONS_PRODUCTFAMILY || quoteLine.SBQQ__Quote__r.Subscription_Type__c == CPQConstants.SUBSCRIPTION_M2M){
                continue;
            }
            requestWrapperWithUUID.uuid = quoteLine.Inventory_Id__r.UUID__c;
            Integer commitmentTerm;
            if(source == 'AddPromos'){
                 commitmentTerm = Integer.valueof(quoteLine.Commitment_Term__c !=null ? quoteLine.Commitment_Term__c:'0');
            }else{
                commitmentTerm = Integer.valueof(quoteLineWithTerm.containsKey(quoteLine.Id) ? quoteLineWithTerm.get(quoteLine.Id) : '0');
            }
           
            requestWrapperWithUUID.commitmentLengths = new List<Integer>{commitmentTerm};
                requestWithUUIDWrapperList.add(requestWrapperWithUUID);
            requestWrapper.discountparam = requestWithUUIDWrapperList;
        }
        return requestWrapper;
    }
    
    private static List<CPQAddPromosWrapper.ResponseWrapper> getPromoCurves(List<SBQQ__QuoteLine__c> quoteLines,String source){
        String accessToken = AddonProductSvcCallOut.getOAuthJWTToken();
        CPQAddPromosReqWrapper.RequestWrapper requestbody = getRequestWrap(quoteLines,source);
        List<CPQAddPromosWrapper.ResponseWrapper> responseWrapper = new List<CPQAddPromosWrapper.ResponseWrapper>();
        Http httpCallout = new Http();
        HttpRequest request = new HttpRequest();        
        request.setEndpoint('callout:Mulesoft_DiscountAPI');
        request.setMethod('POST');
        request.setHeader(CPQConstants.CLIENTID, String.valueof('{!$Credential.UserName}'));
        request.setHeader(CPQConstants.CLIENTSECRET, String.valueof('{!$Credential.Password}'));
        // NOPMD is added below to suppress the PMD warning for setAuthorization
        request.setHeader('Authorization', 'Bearer ' + accessToken); //NOPMD
        request.setHeader('Content-Type', CPQConstants.CONTENT_TYPE);
        request.setBody(JSON.serialize(requestbody));
        HttpResponse response = httpCallout.send(request);
        if(response.getStatusCode() != 200){
            return responseWrapper;
        }
        responseWrapper = (List<CPQAddPromosWrapper.ResponseWrapper>)System.JSON.deserialize(response.getBody(),List<CPQAddPromosWrapper.ResponseWrapper>.class);
        return responseWrapper;
    }
    
    @AuraEnabled
    public static void savePromosAndCurves(String quoteId,String response,String curveSelection, String promoSelection){
        List<SBQQ__QuoteLine__c> quoteLines = quoteLineSelector.getQuoteLinesByQuoteId(quoteId);
        if(conditionHelper.savePromosInitialCheck(quoteLines, quoteId, response)){
            return;
        }
        List<CPQAddPromosWrapper.ResponseWithInventory> responseWrapper = (List<CPQAddPromosWrapper.ResponseWithInventory>)
            System.JSON.deserialize(response,List<CPQAddPromosWrapper.ResponseWithInventory>.class);
        List<CPQAddPromosWrapper.curveSelect> curveWrapper = (List<CPQAddPromosWrapper.curveSelect>)System.JSON.deserialize(curveSelection,List<CPQAddPromosWrapper.curveSelect>.class);
        List<CPQAddPromosWrapper.promoSelect> promoWrapper = (List<CPQAddPromosWrapper.promoSelect>)System.JSON.deserialize(promoSelection,List<CPQAddPromosWrapper.promoSelect>.class);
        CPQSavePromosAndCurvesHelper.SavePromoAndCurveWrapper wrapper = savePromosHelper.getInventoryUUIDsWithCurves(responseWrapper);
        inventoryUUIDwithBaseDiscounts = wrapper.inventoryUUIDwithBaseDiscounts;
        inventoryUUIDwithCurveValues = wrapper.inventoryUUIDwithCurveValues;
        compileSelectedCurvesAndPromos(curveWrapper,promoWrapper);
        updateDiscountOnQuoteLines(quoteLines, inventoryDatapoints, promoWrapperWithInventoryUUID);        
    }
    
    private static void compileSelectedCurvesAndPromos(List<CPQAddPromosWrapper.CurveSelect> curveWrapper,List<CPQAddPromosWrapper.PromoSelect> promoWrapper){
       for(CPQAddPromosWrapper.CurveSelect curveSelect : curveWrapper){
            inventoryDatapoints.put(curveselect.uuid, inventoryUUIDwithCurveValues.get(curveSelect.uuid+'-'+curveSelect.curvename));
            inventoryBasediscounts.put(curveselect.uuid,inventoryUUIDwithBaseDiscounts.get(curveSelect.uuid+'-'+curveSelect.curvename));
        }
        for(CPQAddPromosWrapper.PromoSelect promoSelect : promoWrapper){
            promoWrapperWithInventoryUUID.put(promoSelect.uuid,promoSelect);
        } 
    }
    
    private static void updateDiscountOnQuoteLines(List<SBQQ__QuoteLine__c> quoteLines, Map<String,List<Decimal>> inventoryDatapoints, 
                                                Map<String,CPQAddPromosWrapper.PromoSelect> promoWrapperWithInventoryUUID){
        List<SBQQ__QuoteLine__c> quoteLinestoUpdate = new List<SBQQ__QuoteLine__c>();
        quoteLinestoUpdate.addAll(helper.getQuoteLinesWithPartnerDiscount(quoteLines,inventoryDatapoints));
        quoteLinestoUpdate.addAll(helper.getPromoDiscounts(quoteLines,promoWrapperWithInventoryUUID));
       
        if(!quoteLinestoUpdate.isEmpty()){
            update quoteLinestoUpdate;
        }
    }
}