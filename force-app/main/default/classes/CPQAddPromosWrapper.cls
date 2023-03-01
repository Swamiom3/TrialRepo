/*************************************************************************************************************************************
 Author      :   Arun
 Description :   Wrapper class for CPQAddPromos
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               03/15/2021       Arun        Initial Deployment
**************************************************************************************************************************************/
public class CPQAddPromosWrapper {
	public class CurveSelect{
        public String uuid;
        public String curvename;
    }
    public class PromoSelect{
        public String uuid;
        public String promoId;
        public String percent;
        public String duration;
    }

    public class ResponseWithInventory{
        @AuraEnabled public String inventoryName;
        @AuraEnabled public List<String> termTypes;
        @AuraEnabled  public ResponseWrapper response;
        @AuraEnabled  public List<Promo_Code__c> promoCodes;
        @AuraEnabled  public Boolean curvesAvailable;
        @AuraEnabled  public Boolean promoCodesAvailable;
        @AuraEnabled public String uuid;
    }
    public class ResponseWrapper{
        @AuraEnabled public CurrentPriceWrapper currentPrice;
        @AuraEnabled public List<DiscountsWrapper> discounts;
    }
    public class CurrentPriceWrapper{
        @AuraEnabled  public decimal price;        
    }
    public class DiscountsWrapper{
        @AuraEnabled  public String termTypeLabel;
        @AuraEnabled  public decimal termTypeLength;
        @AuraEnabled  public decimal baseDiscount;
        @AuraEnabled  public List<PromotionsWrapper> promotions;
    }
    public class PromotionsWrapper{
        @AuraEnabled public String name;
        @AuraEnabled public List<DatapointsWrapper> dataPoints; 
    }
    public class DatapointsWrapper{
        @AuraEnabled  public Integer month;
        @AuraEnabled public decimal value;
    }
}