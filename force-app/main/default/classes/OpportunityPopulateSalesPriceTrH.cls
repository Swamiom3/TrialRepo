/************************************************************************************************************************************
    Author 		:   Shubham Nandwana
    Description : 	This class calls the Voyager API and fills Sale_Price field and Currency
    Issue No    :   TWSPG-5410
	----------------------------------------------------------------------------------------------------------------------------------
	VERSION		DATE				AUTHOR					DETAIL
    1			20 October 2021	    Shubham Nandwana     	Initial Development
**************************************************************************************************************************************/
public class OpportunityPopulateSalesPriceTrH extends SObjectTriggerHandler {

    @TestVisible
    private final List<Opportunity> newOpportunities;
    public OpportunityPopulateSalesPriceTrH() {
        this((List<Opportunity>) Trigger.new);
    }

    @TestVisible
    private OpportunityPopulateSalesPriceTrH(List<Opportunity> newOpportunities) {
        this.newOpportunities = newOpportunities;
    }

    public override void afterInsert() {
        updateSalesPrice();
    }

    private void updateSalesPrice() {
        List<Id> opportunityIds = new List<Id>();
        for (Opportunity opportunity : newOpportunities) {
            if (opportunity.Sales_Price__c == null) {
                opportunityIds.add(opportunity.Id);
            }
        }
        if (!opportunityIds.isEmpty()) {
            makeCalloutForSalesPrice(opportunityIds);
        }
    }

    @future(callout = true)
    public static void makeCalloutForSalesPrice(List<Id> oppIds) {
        Map<Id, String> opportunityToPricebook = new Map<Id, String>();
        List<Opportunity> opportunityRecords = getOpportunityRecords(oppIds);
        Map<Id, List<String>> buildingMapForMismatchEmail = new Map<Id, List<String>>();
        List<String> allAccessPricebookIds = new List<String>();
        Set<String> productNames = new Set<String>();
        List<Opportunity> allAccessOpps = new List<Opportunity>();
        for (Opportunity opportunity : opportunityRecords) {
            if(String.isNotEmpty(opportunity.Pricebook2Id )) {
                opportunityToPricebook.put(opportunity.Id, opportunity.Pricebook2Id);
            }
            if (String.isEmpty(opportunity.Building_uuid__c) 
                    || opportunity.Interested_in_Number_of_Desks__c == null
                    || opportunity.Type__c == null) {
                opportunity.Sales_Price__c = GlobalConstants.DEFAULT_OPP_SALES_PRICE;
                opportunity.CurrencyIsoCode = opportunity.CurrencyIsoCode != null 
                                                 ? opportunity.CurrencyIsoCode 
                                                    : GlobalConstants.DEFAULT_OPP_CURRENCY;
                continue;
            } else if (opportunity.Type__c == GlobalConstants.ALL_ACCESS) {
                allAccessOpps.add(opportunity);
                if (String.isNotBlank(opportunity.Pricebook2Id)) {
                    allAccessPricebookIds.add(opportunity.Pricebook2Id);
                    productNames.add(opportunity.Type__c);
                } else {
                    opportunity.Sales_Price__c = GlobalConstants.DEFAULT_OPP_SALES_PRICE;
                    opportunity.CurrencyIsoCode = GlobalConstants.DEFAULT_OPP_CURRENCY;
                }
                continue;
            }
            String revStarKey = RevstarUtils.getKeyForRevstarResult(opportunity);
            Map<String, Object> mapRevstarResult = new Map<String, Object>();
            mapRevstarResult = RevstarUtils.makeCalloutForRevstarPrice(
                (String) opportunity.Building_uuid__c, (Integer) opportunity.Interested_in_Number_of_Desks__c);
            Exception customExc = (Exception) mapRevstarResult.get('Exception');
            if (customExc != null) {
                throw new OppSalesPricePopulationException(customExc.getMessage());
            }
            String apiCurrencyCode = (String) mapRevstarResult?.get('Currency');
            if (String.isNotBlank((String) mapRevstarResult?.get('Currency'))) {
                opportunity.Sales_Price__c = (Decimal) mapRevstarResult?.get('RevStar_Price');
                opportunity.CurrencyIsoCode = (String) mapRevstarResult?.get('Currency');
            } else {
                opportunity.Sales_Price__c = GlobalConstants.DEFAULT_OPP_SALES_PRICE;
                opportunity.CurrencyIsoCode = opportunity.Building__r?.CurrencyISOCode;
            }
            if (opportunity.Building__c != null && apiCurrencyCode != opportunity.Building__r.CurrencyISOCode) {
                buildingMapForMismatchEmail.put(opportunity.Building__c, new List<String> { opportunity.Building__r.Name, opportunity.Building_uuid__c, opportunity.Building__r.CurrencyISOCode, apiCurrencyCode });
            }
        }

        if (!allAccessOpps.isEmpty()) {
            OpportunityPriceService priceService = new OpportunityPriceService();
            Map<String,String> productNameToProductCode = priceService.getProductToProductCode(productNames);
            Map<String, OpportunityPriceService.PriceBookEntryDetails> productToCurrency = priceService.getAllAccessPrice(productNames,allAccessPricebookIds);
            for (Opportunity opportunity : allAccessOpps) {
                String key = priceService.getProdPricebookCurrKey(productNameToProductCode.get(opportunity.Type__c), opportunity.Pricebook2Id);
                if (productToCurrency != null && productToCurrency.containsKey(key)) {
                    opportunity.CurrencyIsoCode = productToCurrency.get(key).currencyVal;
                    opportunity.Sales_Price__c = productToCurrency.get(key).unitPrice;
                } else {
                    opportunity.Sales_Price__c = GlobalConstants.DEFAULT_OPP_SALES_PRICE;
                    opportunity.CurrencyIsoCode = GlobalConstants.DEFAULT_OPP_CURRENCY;
                }
            }
        }

        if (!opportunityRecords.isEmpty()) {
            Database.update(opportunityRecords);
        }
        if (!opportunityToPricebook.isEmpty()) {
            restorePriceBooks(opportunityToPricebook, opportunityRecords);
        }
        if (!buildingMapForMismatchEmail.isEmpty()) {
            ID jobId = System.enqueueJob(new QueueEmailAlertForBuilding(buildingMapForMismatchEmail));
        }
    }

    private static List<Opportunity> getOpportunityRecords(List<Id> oppIds) {
        return [SELECT Id, Type__c, Sales_Price__c, CurrencyIsoCode, Building__c, Building_uuid__c,
                Interested_in_Number_of_Desks__c, Pricebook2Id, Building__r.Name, Building__r.CurrencyISOCode
                FROM Opportunity
                WHERE Id IN : oppIds];
    }

    private static void restorePriceBooks(Map<Id,String> opportunityToPricebook, List<Opportunity> opportunityRecords) {
        for (Opportunity opportunity : opportunityRecords) {
            if(opportunity.Pricebook2Id != opportunityToPricebook.get(opportunity.Id)) {
                opportunity.Pricebook2Id = opportunityToPricebook.get(opportunity.Id);
            }   
        }
        Database.update(opportunityRecords);
    }

    public class OppSalesPricePopulationException extends Exception {}
}