/************************************************************************************************************************************
    Author 		:   Shubham Nandwana
    Description : 	This class contains method for price handling, called from different classes
    Issue No    :   TWSPG-5410
	----------------------------------------------------------------------------------------------------------------------------------
	VERSION		DATE				AUTHOR					DETAIL
    1			16 November 2021	Shubham Nandwana     	Initial Development	 
**************************************************************************************************************************************/
public class OpportunityPriceService {
    
    public Map<String,PriceBookEntryDetails> getAllAccessPrice(Set<String> productNames, List<String> priceBookIds){
        Map<String,String> productNameToProductCode = getProductToProductCode(productNames);
        if(productNameToProductCode.isEmpty()){
            return null;
        }
        Map<String,PriceBookEntryDetails> productToCurrency = new Map<String,PriceBookEntryDetails>();
        for(PricebookEntry entry : [SELECT Id, Name, CurrencyIsoCode, UnitPrice, 
                                    ProductCode, Pricebook2Id 
                                    FROM PricebookEntry 
                                    WHERE ProductCode IN :productNameToProductCode.values()
                                    AND Pricebook2Id IN : priceBookIds]) {
            productToCurrency.put(getProdPricebookCurrKey(entry.ProductCode, entry.Pricebook2Id),
                                 new PriceBookEntryDetails(entry.Pricebook2Id, entry.CurrencyIsoCode, entry.UnitPrice));
        }
        return productToCurrency;
    }
    
    public Map<String,String> getProductToProductCode(Set<String> productNames){
        Map<String,String> productNameToProductCodes = new Map<String,String>();
        List<OpportunityProductCode__mdt> oppProductCodes = (List<OpportunityProductCode__mdt>) 
            Settings.getFieldsFromMDT('OpportunityProductCode__mdt', '', new Set<String>{'ProductCode__c','ProductName__c'});
        if (oppProductCodes.isEmpty()) {
            return null;
        }
        for (OpportunityProductCode__mdt oppProductCode : oppProductCodes) {
            if(productNames.contains(oppProductCode.ProductName__c)){
                productNameToProductCodes.put(oppProductCode.ProductName__c, oppProductCode.ProductCode__c);
            }
        }
        return productNameToProductCodes;
    }
    
    public String getProdPricebookCurrKey(String productCode, String priceBookId){
        return productCode + '_' + priceBookId;
    }
    
    public class PriceBookEntryDetails{
        public String pricebookId;
        public String currencyVal;
        public Decimal unitPrice;  
        PriceBookEntryDetails(String pricebookId, String currencyVal, Decimal unitPrice){
            this.pricebookId = pricebookId;
            this.currencyVal = currencyVal;
            this.unitPrice = unitPrice;
        }
    }
    
}