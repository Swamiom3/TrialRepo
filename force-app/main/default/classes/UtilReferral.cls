/******************************************************************************************************************** 
    Author      :  Nicholas Zozaya
    Description : Referral Object Utility for testing and general functions
    History     :  
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION                 DATE                    AUTHOR                          ISSUE
    1                   20, May 2019            Nicholas Zozaya                    ST-3977
*********************************************************************************************************************/
public class UtilReferral {
    
/******************************************************************************************************************** 
    Author      :  Nicholas Zozaya
    Description : Construct a referral given a map of parameters
    History     :  
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION                 DATE                    AUTHOR                          ISSUE
    1                   20, May 2019            Nicholas Zozaya                    ST-3977
*********************************************************************************************************************/
    public static Referral__c constructReferral(Map<String, Object> mapFieldApiNameToValues){
        SObject objNewReferral = new Referral__c();
        for(String fieldApiName : mapFieldApiNameToValues.keyset()){
            try{
                objNewReferral.put(fieldApiName, mapFieldApiNameToValues.get(fieldApiName));
            }catch(Exception e){
                throw new ReferralUtilException('issue in UtilReferral.cls constructing new Referral for field '+fieldApiName+' and value '+mapFieldApiNameToValues.get(fieldApiName)+'. Here\'s the error message: '+e.getMessage());
            }
        }
        return (Referral__c) objNewReferral;
    }

    public static Map<Id, Referral__c> getOppIdToReferralMap(Map<Id, Id> mapPrimaryContactIdToOppId, Map<Id, Id> mapConvertedLeadIdToContactId, Map<Id, Referral__c> mapConvertedLeadIdToReferral){
       Map<Id, Referral__c> mapOppIdToReferral = new Map<Id, Referral__c>();
       for(Id leadId : mapConvertedLeadIdToReferral.keyset())
           mapOppIdToReferral.put(mapPrimaryContactIdToOppId.get(mapConvertedLeadIdToContactId.get(leadId)), mapConvertedLeadIdToReferral.get(leadId));
       return mapOppIdToReferral;
    }

/******************************************************************************************************************** 
    Author      :  Nicholas Zozaya
    Description : Update/Insert a Referral w/ new Opp details
    History     :  
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION                 DATE                    AUTHOR                          ISSUE
    1                   20, May 2019            Nicholas Zozaya                    ST-3977
    2                   15, Jan 2021            Tomasz Sadowski                    ST-7056
*********************************************************************************************************************/
   public static Referral__c getReferralForConversionOpp(Opportunity opp, Referral__c ref, String contactId){
       String portalEvent =  (opp.Opportunity_Creation_Source__c != 'From Add Opportunity' && opp.Opportunity_Creation_Source__c != 'From Create Opportunity') ? 'Journey Conversion - Tour' : 'Journey Conversion';
       String conId = String.isBlank(contactId) ? opp.Primary_Member__c : contactId;
        if(ref.Opportunity__c == null){ // lead conversion
            try{
                ref.Opportunity__c = opp.Id;
                ref.Building_Interested_In__c = opp.Building__c;
                ref.Referral_Portal_Event__c = portalEvent;
                ref.Referral_Contact__c = conId;
                return ref;
            }catch(Exception e){
                throw new ReferralUtilException('issue in UtilReferral.updateReferralOnConversionOpp() - error message: '+e.getMessage()+'===> stack trace: '+e.getStackTraceString());
            }
        }else{ // non-lead-related-journey conversion
            try{ 
                return UtilReferral.constructReferral(new Map<String, Object>{'Opportunity__c' => opp.Id, 
                'Building_Interested_In__c' => opp.Building__c, 'Referral_Portal_Event__c' => portalEvent,
                 'Referral_Contact__c' => conId, 'Referrer__c' => ref.Referrer__c});
            }catch(Exception e){
                throw new ReferralUtilException('issue in UtilReferral.updateReferralOnConversionOpp() - error message: '+e.getMessage()+'===> stack trace: '+e.getStackTraceString());
            }
        }
    }

/******************************************************************************************************************** 
    Author      :  Nicholas Zozaya
    Description : Get Referral custom metadata
    History     :  
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION                 DATE                    AUTHOR                          ISSUE
    1                   20, May 2019            Nicholas Zozaya                    ST-3977
*********************************************************************************************************************/
    public static Map<String, Integer> getReferralMetadataSettings(){
        return (Map<String, Integer>) JSON.deserialize([SELECT Data__c FROM MetadataSetting__mdt WHERE DeveloperName = 'Referral_Settings'].Data__c, Map<String, Integer>.class);  
    }

    public class ReferralUtilException extends Exception{}
}