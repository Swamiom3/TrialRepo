/************************************************************************************************************************************
    Author      :   Salesforce
    Description :   This class contains methods used in opportunityCustomBanner lwc component
   ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
       1        10 May 2022         Salesforce          Initial Developement
 **************************************************************************************************************************************/
public with sharing class OpportunityCustomBannerController {    
   
    @AuraEnabled
    public static Boolean enableOpportunityCustomBanner(Id opportuntiyId){
        Opportunity opportunityRec = new OpportunitySelector().getOpportunityById(opportuntiyId, new List<String>{'Id', 'Building__r.Country__c'});
        Set<String> migratedRegions = new Set<String>();
        Map<String, Regional_Migration__mdt> allRegionalMigration = Regional_Migration__mdt.getAll();        
        for(String countryLabel: allRegionalMigration.keyset()){
            if(allRegionalMigration.get(countryLabel).Region_Enabled__c){
                migratedRegions.add(allRegionalMigration.get(countryLabel).MasterLabel);
            }
        }
        return (!migratedRegions.contains(opportunityRec.Building__r.Country__c)? true: false);
    }
}