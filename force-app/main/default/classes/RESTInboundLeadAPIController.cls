/************************************************************************************************************************************
    Author      :   Pranay Jadhav
    Description :   This class having logic to handle the Lead via SFDC's REST API

    History     :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                   DETAIL
    1           8 June 2018         Pranay Jadhav              -
    2           1 March 2021        Krasko Oleg            refactoring
**************************************************************************************************************************************/
public class RESTInboundLeadAPIController {
    private WWTypes.InboundLead inboundLead;
    private Messaging.InboundEmail inboundEmail;
    private Messaging.InboundEnvelope envelope;
    private Lead lead;
    private Contact contact;
    private RESTInboundLeadAPIHelper leadAPIHelper;
    
    public RESTInboundLeadAPIController(WWTypes.InboundLead inboundLead){
        this.inboundLead = inboundLead;
        leadAPIHelper = new RESTInboundLeadAPIHelper();
    }
    
    public RESTInboundLeadAPIController(Messaging.InboundEmail inboundEmail, Messaging.InboundEnvelope env){
        this.inboundEmail = inboundEmail;
        envelope = env;
    }
    
    /************************************************************************************************************************************
        Author      :   Pranay Jadhav
        Description :   This method handle inbound email request and insert lead if it satisfies all criteria.

        History:
        ----------------------------------------------------------------------------------------------------------------------------------
        VERSION     DATE                AUTHOR                  DETAIL
        1           8 June 2018         Pranay Jadhav             -
        2           1 March 2021        Krasko Oleg            refactoring
    **************************************************************************************************************************************/
    public Set<Id> handleInboundEmailRequest(){
        Set<String> emailIds = new Set<String>();
        if(inboundEmail.toAddresses?.isEmpty() == false) {
            emailIds.addAll(inboundEmail.toAddresses);
        }
        for(String emailId : emailIds){
            if(emailId.endsWith('apex.salesforce.com') || emailId.endsWith('apex.sandbox.salesforce.com')){
                emailIds.remove(emailId);
            }
        }
        if(inboundEmail.ccAddresses?.isEmpty() == false){
            emailIds.addAll(inboundEmail.ccAddresses);
        }
        if(!emailIds.isEmpty()){
            return new RESTInboundLeadAPIHelper().insertLeadByEmail(emailIds, inboundEmail, envelope);
        }  
        return null;
    }
    
    /************************************************************************************************************************************
        Author 		: 	Pranay Jadhav
        Description : 	This method handles post request coming from rest api.
        
        History:
        ----------------------------------------------------------------------------------------------------------------------------------
        VERSION		DATE				AUTHOR					DETAIL
        1           8 June 2018         Pranay Jadhav            -
        2           1 March 2021        Krasko Oleg            refactoring
    **************************************************************************************************************************************/
    public Id handlePostRequest(RESTInboundLeadAPI.Response response){
        if(String.isNotBlank(inboundLead?.email)){
            lead = leadAPIHelper.getRecentLeadByEmail(inboundLead.email);
            contact = leadAPIHelper.getRecentContactByEmail(inboundLead.email);
        }
        if (String.isNotBlank(inboundLead?.referrer_sfid)) {
            try {
                validateLead();
                validateContact();
            } catch (Exception excep) {
                if (excep instanceof InboundLeadException
                || excep instanceof DmlException
                || excep instanceof StringException) {
                    leadAPIHelper.logException(excep, response, inboundLead);
                    return null;
                }
                throw excep;
            }
        }
        return leadAPIHelper.insertLeadByWeb(inboundLead, response);
    }
    
    /************************************************************************************************************************************
        Author 		: 	Pranay Jadhav
        Description : 	This method responsible to validate lead as per business requirements.
        
        History:
        ----------------------------------------------------------------------------------------------------------------------------------
        VERSION		DATE				AUTHOR					DETAIL
        1           8 June 2018         Pranay Jadhav             -
        2           1 March 2021        Krasko Oleg            refactoring
    **************************************************************************************************************************************/

    private void validateLead(){
        Id referrerId = Id.valueOf(inboundLead.referrer_sfid);
        if(lead != null){
            if(lead.CreatedDate.date().daysBetween(System.today()) <= 60){
                throw new InboundLeadException('A lead with given email was already submitted in last 60 days');
            } else {
                lead.Referrer__c = referrerId;
                lead.Contact_Broker__c = inboundLead.contact_referrer_only;
            }
        }
        if(inboundLead.email != null && ReferenceHandler.getActiveReference(inboundLead.email) == null){
            Sales_Console_Setting__mdt referenceSettingsObject = SalesConsoleSettings.get('ReferenceSettings');
            if(referenceSettingsObject == null) {
                return;
            }
            List<Contact> referrerContacts = [SELECT Id, Type__c FROM Contact WHERE Id =: referrerId];
            ReferenceSettings refferenceSettingData = (ReferenceSettings)JSON.deserialize(referenceSettingsObject.Data__c, ReferenceSettings.class);
            Referral__c referral = new Referral__c();
            referral.Referral_Email__c = inboundLead.email;
            referral.Expires_On__c = System.today().addDays(refferenceSettingData.expireafter);
            if(inboundLead?.lead_source_detail == refferenceSettingData.ReferralSource.LeadSourceDetail) {
                referral.Referral_Source__c = inboundLead.lead_source_detail;  
            } else if(inboundLead?.lead_source == refferenceSettingData.ReferralSource.LeadSource) {
                referral.Referral_Source__c = inboundLead.lead_source;
            } else {
                referral.Referral_Source__c = refferenceSettingData.ReferralSource.Other;
            }
            if(!referrerContacts.isEmpty()) {
                referral.Referrer_Type__c = referrerContacts[0].Type__c;
            }
            referral.Referrer__c = referrerId;
            referral.Start_Date__c = System.today();
            insert referral;
        }
    }

    private void validateContact(){
        if(contact == null){
            return;
        }
        if(contact.Account.Type == 'Member' || contact.Account.Type == 'Previous Member') {
            throw new InboundLeadException('A member with given email already exists');
        }
        for(Opportunity opportunityItem : contact.Opportunities__r){
            Integer contractSentDateDiff, contractSignedDateDiff;
            contractSentDateDiff = opportunityItem.Contract_Sent_Date__c?.daysBetween(System.today());
            if(opportunityItem.StageName == GlobalConstants.OPP_CLOSED_WON_STAGE_NAME) {
                contractSignedDateDiff = opportunityItem.CloseDate.daysBetween(System.today());
            }
            if(contractSentDateDiff < 60 || contractSignedDateDiff < 60){
                throw new InboundLeadException('Person has a contract sent/signed in last 60 days');
            }
        }
    }
   
    private class ReferenceSettings {
        private Integer expireafter {get; set;}
        private ReferralSource referralSource {get; set;}    
    }
    private class ReferralSource {
        private String LeadSourceDetail {get; set;}
        private String LeadSource {get; set;}
        private String Other {get; set;}
    }
    public class InboundLeadException extends Exception {}

}