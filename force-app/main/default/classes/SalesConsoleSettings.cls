/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class is used to retrieve the Sales Console Settings from Sales_Console_Setting__mdt object with caching enabled for optimizing.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           23 Jun 2021         Salesforce            Initial Developement
**************************************************************************************************************************************/
public without sharing class SalesConsoleSettings {
    
    // Static map holds the Sales Console Settings by Name
    static Map<String, Sales_Console_Setting__mdt> mapSettingsByName = new Map<String, Sales_Console_Setting__mdt>(); 
    static Set<String> settingNames = new Set<String>();

    
    /*****************************************************************************************************************************************
        Author              :   Salesforce
        Description         :   This method is used to get Sales Console Setting by Name
        Created Date        :   23 Jun 2021
    ******************************************************************************************************************************************/
    public static Sales_Console_Setting__mdt get(String scsName){
        scsName = scsName.toLowerCase();
        if(!mapSettingsByName.containsKey(scsName)){
            List<Sales_Console_Setting__mdt> salesConsoleSettings = [SELECT Id, DeveloperName, MasterLabel, Data__c, Source_Object__c, Destination_Object__c FROM Sales_Console_Setting__mdt];
            if(salesConsoleSettings != null && salesConsoleSettings.size() > 0){
                for(Sales_Console_Setting__mdt scs : salesConsoleSettings){
                    mapSettingsByName.put(scs.DeveloperName.toLowerCase(), scs);
                }
            }
            if(mapSettingsByName.containsKey(scsName))
                return mapSettingsByName.get(scsName);
            else
                settingNames.add(scsName);
            
            return null;
        }       
        return mapSettingsByName.get(scsName);
    }
    
}