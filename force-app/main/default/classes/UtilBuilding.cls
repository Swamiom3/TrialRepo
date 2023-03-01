/**
 * @author Gad Sharon
 * @date 01/10/18
 * @description Util class for the Building__c object.
 */
@isTest
public class UtilBuilding {

    private static Map <String, Object> stMapFields = new Map <String, Object>();

    public static List <Building__c> createBuildings (Integer numberOfRecords, Boolean doInsert) {
        List <Map<String, Object>> ListOfMapFields = new List <Map<String, Object>>();

        for (Integer i = 1; i < numberOfRecords + 1; i++) {
            Map <String, Object> mapBuildingFields = new Map <String, Object>(StMapFields);
            mapBuildingFields.put('CurrencyIsoCode', 'USD');
            if (mapBuildingFields.get('Name') == null) {
                mapBuildingFields.put('Name', 'test' + String.valueOf(i));
            }
            ListOfMapFields.add(mapBuildingFields);
        }

        return UtilGeneral.createTestRecords(Building__c.sObjectType, ListOfMapFields, doInsert);
    }

    public static Building__c createBuilding (string name, string city, string country, string state, string timeZone, Id responsibleCM, boolean doInsert) {
        stMapFields.put('Name', name);
        stMapFields.put('City__c', city);
        stMapFields.put('Country__c', country);
        stMapFields.put('State__c', state);
        stMapFields.put('Time_Zone__c', timeZone);
        stMapFields.put('Responsible_CM__c', responsibleCM);
        stMapFields.put('UUID__c', null);

        return createBuildings(1, doInsert)[0];
    }

/****************************************************************************************************************************
    Author              : Oleg Krasko
    Description         : This method is used to create Building__c test records
    Created Date        : 7/9/2020
*****************************************************************************************************************************/
    public static Building__c createBuilding (String uuid, String email, String regionName, boolean doInsert){
        stMapFields = new Map<String, Object>();
        stMapFields.put('UUID__c', uuid);
        stMapFields.put('Email__c', email);
        stMapFields.put('Region_Name__c', regionName);

        return createBuildings(1, doInsert)[0];
    }

/****************************************************************************************************************************
    Author              : Oleg Krasko
    Description         : This method is used to create Building__c test records
    Created Date        : 7/9/2020
*****************************************************************************************************************************/
    public static Building__c createBuilding (String name, boolean doInsert){
        stMapFields = new Map<String, Object>();
        stMapFields.put('Name', name);

        return createBuildings(1, doInsert)[0];
    }

    public static Building__c createBuildingWithMarket (Id marketId, boolean doInsert){
        stMapFields.put('Market__c', marketId);

        return createBuildings(1, doInsert)[0];
    }

/****************************************************************************************************************************
    Author              : Oleg Krasko
    Description         : This method is used to create Building__c test records
    Created Date        : 7/9/2020
*****************************************************************************************************************************/
    public static Building__c createBuildingWithGeography(Id geographyId, boolean doInsert){
        stMapFields = new Map<String, Object>();
        stMapFields.put('Geography__c', geographyId);

        return createBuildings(1, doInsert)[0];
    }

/****************************************************************************************************************************
    Author              : Oleg Krasko
    Description         : This method is used to create Building__c test records
    Created Date        : 7/9/2020
*****************************************************************************************************************************/
    public static Building__c createBuildingWithClusterAndTerritoryAndMarket(Id clusterId, Id subTerritoryId, Id marketId, boolean doInsert){
        stMapFields = new Map<String, Object>();
        stMapFields.put('Cluster__c', clusterId);
        stMapFields.put('Sub_Territory__c', subTerritoryId);
        stMapFields.put('Market__c', marketId);

        return createBuildings(1, doInsert)[0];
    }

/****************************************************************************************************************************
    Author              : Oleg Krasko
    Description         : This method is used to create Cluster__c test records
    Created Date        : 7/9/2020
*****************************************************************************************************************************/
    public static Cluster__c createCluster(String name, Boolean isInsert){
        Cluster__c cluster = new Cluster__c(Name = name);
        if (isInsert) {
            insert cluster;
        }
        return cluster;
    }
/****************************************************************************************************************************
    Author              : Oleg Krasko
    Description         : This method is used to create Territory__c test records
    Created Date        : 7/9/2020
*****************************************************************************************************************************/
    public static Territory__c createTerritory(String name, Id region, Boolean isInsert){
        Territory__c territory = new Territory__c(Name = name, RegionID__c = region);
        if (isInsert) {
            insert territory;
        }
        return territory;
    }
/****************************************************************************************************************************
    Author              : Oleg Krasko
    Description         : This method is used to create Region__c test records
    Created Date        : 7/9/2020
*****************************************************************************************************************************/
    public static Region__c createRegion(String name, Boolean isInsert){
        Region__c region = new Region__c(Name = name);
        if (isInsert) {
            insert region;
        }
        return region;
    }
}