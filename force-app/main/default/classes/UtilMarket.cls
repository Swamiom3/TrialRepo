/**
 * @author Gad Sharon
 * @date 21/04/19
 * @description Util class for the Market__c object.
 */
@isTest
public class UtilMarket
{
    private static Map <String, Object> stMapFields = new Map <String, Object>();

    public static List <Market__c> createMarkets (Integer numberOfRecords, Boolean doInsert) {
        List <Map<String, Object>> ListOfMapFields = new List<Map<String, Object>>();

        for (Integer i = 1; i < numberOfRecords + 1; i++) {
            Map <String, Object> mapMarketFields = new Map <String, Object>(StMapFields);
            mapMarketFields.put('CurrencyIsoCode', 'USD');
            mapMarketFields.put('Name', 'UtilMarket' + String.valueOf(i));
            mapMarketFields.put('UUID__c', 'UtilMarket' + String.valueOf(i));
            ListOfMapFields.add(mapMarketFields);
        }

        return UtilGeneral.createTestRecords(Market__c.sObjectType, ListOfMapFields, doInsert);
    }

/****************************************************************************************************************************
    Author              : Oleg Krasko
    Description         : This method is used to create Market__c test records
    Created Date        : 7/9/2020
*****************************************************************************************************************************/
    public static Market__c createMarketWithTerritory (Id territory, boolean doInsert){
        stMapFields = new Map<String, Object>();
        stMapFields.put('TerritoryID__c', territory);
        return createMarkets(1, doInsert)[0];
    }
}