/**********************************************************************************************************
    Author        :  Vaishnavi Khandar
    Description   :  Controller for REAP Integration component
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE              AUTHOR           
      1         18 November 2021     Vaishnavi Khandar      
**********************************************************************************************************/
public with sharing class ReapIntegrationDetailCmpController {
    
    @AuraEnabled
    public static DatabaseResult updateLeaseDetailsForSpecificBuilding(Id recordId){
        DatabaseResult result;
        try{
            Building__c building = [SELECT Id, Name, UUID__c, Measurement_Unit__c, Date_of_original_lease_agreement__c, Next_Burndown_Date__c, Expiration_Date__c, LastModifiedDate, (SELECT Id, LastModifiedDate, Lease_UUID__c, Area_UUID__c, Location__c, Location_UUID__c, Property_UUID__c, Name, Measurement_Unit__c, Possession_Date__c, Type_of_Lease__c, Lease_Expiration_Date__c, Date_of_lease_agreement__c, Lease_Commencement__c, Rentable_Area__c, Floors__c FROM Building_Lease__r), (SELECT Id, Name, Lease_UUID__c,Lease_financial_security_UUID__c, Building_Lease__c, Building__c, Next_Burndown_Amount__c, Next_Burndown_Date__c, Current_Corporate_Guaranty_Amount__c, Current_Letter_of_Credit_Amount__c FROM Building_Lease_Financial_Details__r) FROM Building__c WHERE Id = :recordId];
            Map<String, Object> reapIntegrationResult = REAPIntegrationUtils.makeCalloutForREAPIntegration(new List<Building__c>{building}, true);
            if(reapIntegrationResult.get('Success') == true && reapIntegrationResult.get('Message') == null){
                result = new DatabaseResult('Building Lease Updated Sucessfully');
            }else if(reapIntegrationResult.get('Message') != null){
               result = new DatabaseResult(reapIntegrationResult.get('Message')); 
            }
            return result;
        }
        catch(Exception pEx){
            return new DatabaseResult('An error occurred. Please contact support.');
        }
    }
}