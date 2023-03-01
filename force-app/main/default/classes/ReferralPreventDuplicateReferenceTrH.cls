/************************************************************************************************************************************
	Author 		: Krishana Tupe
	Description : This class contains unit tests for validating the behavior of Apex classes and triggers.
----------------------------------------------------------------------------------------------------------------------------------
	VERSION			DATE				AUTHOR					DETAIL							
    1				01 February 2018    Krishana Tupe	        Refactor			
**************************************************************************************************************************************/
public class ReferralPreventDuplicateReferenceTrH extends SObjectTriggerHandler {
    private final String ERROR_MESSAGE = System.Label.Referral_Duplication_Reference_Error;
    @TestVisible
    private List<Referral__c> newReferrals;
    
    public ReferralPreventDuplicateReferenceTrH() {
        this(
            (List<Referral__c>) Trigger.new
        );
    }
    
    @TestVisible
    private ReferralPreventDuplicateReferenceTrH(List<Referral__c> newReferrals) {
        this.newReferrals = newReferrals;
    }
    
    @TestVisible
    private ReferralSelector referralSelector = new ReferralSelector();
    
    public override void beforeInsert() {
        preventDuplicateActiveReference();
    }
    
    public void preventDuplicateActiveReference(){
        Map<String, Referral__c> referralByReferralEmails = new Map<String, Referral__c>();
        Set<string> referralEmails = new Set<string>();
        for(Referral__c currentReferral : newReferrals){
            if(String.isBlank(currentReferral.Referral_Email__c)){
                continue;
            }
            referralEmails.add(currentReferral.Referral_Email__c);
            if(referralByReferralEmails.containsKey(currentReferral.Referral_Email__c.toLowerCase())){
                currentReferral.Name.addError(ERROR_MESSAGE);
            }else{
                referralByReferralEmails.put(currentReferral.Referral_Email__c.toLowerCase(), currentReferral);
            }
        }
        if(referralEmails.isEmpty()){
            return;
        }
        for(Referral__c duplicateReferral : referralSelector.getReferralsByReferralEmail(referralEmails)){
            Referral__c currentReferral = referralByReferralEmails.get(duplicateReferral.Referral_Email__c.toLowerCase());
            if (currentReferral?.CreatedDate?.date().daysBetween(System.today()) <= GlobalConstants.REFERRAL_RESUBMISSION_INTERVAL) {
                currentReferral.addError(ERROR_MESSAGE);
            }
        }
    }        
}