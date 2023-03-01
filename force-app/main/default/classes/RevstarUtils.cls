/************************************************************************************************************************************
    Author      :   Chandra Teja 
    Description :   This class contains all the reusable methods related to update revstar price on lineitem feature.
    History     :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           12 June 2020        Chandra Teja        Initial Developement
**************************************************************************************************************************************/
public class RevstarUtils {
    public static Map<String, Decimal> mapIsoCodeAndConversionRate;
    private static final String REVSTAR_PRICE = 'RevStar_Price';
    private static final String REVSTAR_CURRENCY = 'Currency';
    public static final String PRODUCT_CODE = 'PROF-000900';
    private static final String VTS_OPPORTUNITY_CREATION_SOURCE = 'VTS';
    /****************************************************************************************************************************
        Author              : Chandra Teja
        Description         : This method is used to fetch revstar price by making callout and update revstar price on lineitem.
        Created Date        : 12 June 2020
        Last Modified Date  : 14 August 2020
        Last Modified By    : Oleg Krasko (Added logic based on ST-6784)
   *****************************************************************************************************************************/
    public static void updateLineItemsWithRevstarPrice(List<OpportunityLineItem> lstOppLineItemsToCallout){
        if(lstOppLineItemsToCallout.isEmpty()){
            return ;
        }
        Map<String, Object> mapRevstarResult = new Map<String, Object>();
        List<OpportunityLineItem> lstOppLineItemsToDelete = new List<OpportunityLineItem>();
        List<OpportunityLineItem> lstOppLineItemsToInsert = new List<OpportunityLineItem>();
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        Map<Id, String> lineItemToCurrency = new Map<Id, String>();
        try{
            for(OpportunityLineItem objLineItem: lstOppLineItemsToCallout){
                    mapRevstarResult = makeCalloutForRevstarPrice((String)objLineItem.Opportunity.Building_uuid__c,
                    objLineItem.Opportunity.Opportunity_Creation_Source__c == VTS_OPPORTUNITY_CREATION_SOURCE ? 
                                                                        (Integer) objLineItem.Opportunity.Requirement_Quantity__c :
                                                                        (Integer) objLineItem.Opportunity.Interested_in_Number_of_Desks__c);
                if(mapRevstarResult != NULL && !mapRevstarResult.isEmpty()){
                    String currencyIsoCode = String.valueOf(mapRevstarResult.get(REVSTAR_CURRENCY));
                    if (String.isNotBlank(currencyIsoCode)) {
                        lineItemToCurrency.put(objLineItem.Id, currencyIsoCode);
                    }
                    opportunitiesToUpdate.add(new Opportunity(Id = objLineItem.OpportunityId, CurrencyIsoCode = currencyIsoCode));
                    updateRevstarDetailsOnLineItem(mapRevstarResult, objLineItem, 
                                                   objLineItem.Opportunity.CurrencyISOCode);
                    lstOppLineItemsToDelete.add(objLineItem);
                }
            }
            if(!lstOppLineItemsToDelete.isEmpty() && !lineItemToCurrency.isEmpty() && lstOppLineItemsToDelete.size() == lineItemToCurrency.size()){
                lstOppLineItemsToInsert = lstOppLineItemsToDelete.deepClone();
                List<PricebookEntry> priceBookEntries = [
                    SELECT Id, CurrencyIsoCode FROM PricebookEntry 
                    WHERE Product2Id IN (SELECT Id FROM Product2 WHERE IsActive = true AND Productcode = :PRODUCT_CODE)
                    AND CurrencyIsoCode IN :lineItemToCurrency.values()
                ];
                Map<String, Id> currencyToPriceBookEntry = new Map<String, Id>();
                for (PricebookEntry entry : priceBookEntries) {
                    currencyToPriceBookEntry.put(entry.CurrencyIsoCode, entry.Id);
                }
                for (Integer i = 0; i < lstOppLineItemsToInsert.size(); i++) {
                    lstOppLineItemsToInsert[i].PricebookEntryId = currencyToPriceBookEntry.get(lineItemToCurrency.get(lstOppLineItemsToDelete[i].Id));
                }
                //in order to update CurrencyIsoCode on Opportunity level it needs to delete OpportunityLineItem record related first
                delete lstOppLineItemsToDelete;
                update opportunitiesToUpdate;
                insert lstOppLineItemsToInsert;
            }
        }catch(Exception pEx) {
            ApexDebugLog.logException(pEx,JSON.serialize(lstOppLineItemsToDelete), 'RevstarUtils', 
                                      'updateLineItemsWithRevstarPrice');            
        }
    }
    /****************************************************************************************************************************
        Author              : Chandra Teja
        Description         : This method is used to update the callout result on fields of lineitem.
        Created Date        : 12 June 2020
   *****************************************************************************************************************************/
    public static void updateRevstarDetailsOnLineItem(Map<String, Object> mapRevstarResult, OpportunityLineItem objLineItem, 
                                                      String oppCurrency){
        if(mapRevstarResult == NULL || mapRevstarResult.isEmpty() || mapRevstarResult.get('Success') == NULL){
            return ;
        }
    }
    
    /****************************************************************************************************************************
        Author              : Chandra Teja
        Description         : This method is used to make callout to revstar api and return the fetched result.
        Created Date        : 12 June 2020
   *****************************************************************************************************************************/
    public static Map<String, Object> makeCalloutForRevstarPrice(String building_uuid, Integer quantity){
        Map<String, Object> mapRevstarResult = new Map<String, Object>();
        if(String.isNotBlank(building_uuid) && quantity != NULL){
            try{
                String endPoint = APIConnection.getEndPointWithEnv('RevStarAPI');
                APIConnection req = new APIConnection(endPoint);
                req.setEndPointParams(new list <String>{building_uuid, String.valueof(quantity)});
                HttpResponse resp = req.sendRequest('');
                if(resp != NUll){
                    Map<String, Object> jsonResponse = (Map<String, Object>)JSON.deserializeUntyped(resp.getBody());
                    if(resp.getStatusCode() == 200){
                        if(jsonResponse.get('status') == 200){
                            mapRevstarResult.put('RevStar_Price', jsonResponse.get('price'));
                            mapRevstarResult.put('Success', true);
                            mapRevstarResult.put('PriceType', jsonResponse.get('priceType'));
                            mapRevstarResult.put('Currency', jsonResponse.get('currency'));
                            return mapRevstarResult;
                        }
                    }   
                }
            }
            catch (Exception pEx) {
                ApexDebugLog.logException(pEx,'building uuid==>'+building_uuid + 'quantity==>'+quantity, 
                                          'RevstarUtils', 'makeCalloutForRevstarPrice');            
            }
            mapRevstarResult.put('Success', false);
            return mapRevstarResult;
        }
        return mapRevstarResult;
    }
    /****************************************************************************************************************************
        Author              : Chandra Teja
        Description         : This method is used to fetch the metadata record that is used for extend smart price feature.
        Created Date        : 12 June 2020
   *****************************************************************************************************************************/
    public static Map<String, String> getExtendRevstarPriceMetadata(){
        MetadataSetting__mdt objMetadataSetting = Settings.getMetadataSettingByDevName('ExtendRevstarPrice');
        Map<String, String> mapExtendRevstarpriceSettings;
        if(objMetadataSetting != null){
            mapExtendRevstarpriceSettings = (Map<String, String>)JSON.deserialize
                (objMetadataSetting.Data__c, Map<String, String>.class);
        }
        return mapExtendRevstarpriceSettings;
    }
    
    /****************************************************************************************************************************
        Author              : Chandra Teja
        Description         : This method is used to get the limit for records according to the context(future/batch/schedule).
        Created Date        : 12 June 2020
   *****************************************************************************************************************************/
    public static Integer getLimitFromSetting(String limitContext, Map<String, String> mapExtendRevstarPriceSettings){
       Integer calloutLimit  = Integer.valueOf(mapExtendRevstarPriceSettings.get(limitContext));
        return (calloutLimit != NULL ? calloutLimit : 10);
    }
    /****************************************************************************************************************************
        Author              : Chandra Teja
        Description         : This method is used to get the key that is used in the static variable used to 
                              update the revstar price from add opportunity page.
        Created Date        : 12 June 2020
   *****************************************************************************************************************************/
    public static String getKeyForRevstarResult(Opportunity objOpportunity){
        return (String)objOpportunity.Building__c+String.valueOf(objOpportunity.Interested_in_Number_of_Desks__c);
    }
}