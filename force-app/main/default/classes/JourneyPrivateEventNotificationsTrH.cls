/*********************************************************************************************************
	Author        :  Shobhit Gahlot
	Description   :  Journey Lead Source Subtype inserted or updated then email notification gets send to MarketPOC
	Issue No.     :  ST-8957
	History       :
-----------------------------------------------------------------------------------------------------------
	VERSION        DATE            AUTHOR             DETAIL
	1          09-Sept-2021      Shobhit Gahlot     Trigger Refactor
**********************************************************************************************************/
public class JourneyPrivateEventNotificationsTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Journey__c> newJourneys;
    @TestVisible
    private Map<Id, Journey__c> oldJourneys;
    private JourneySelector journeySelector = new JourneySelector();
    
    public JourneyPrivateEventNotificationsTrH() {
        this((List<Journey__c>) Trigger.new, (Map<Id, Journey__c>) Trigger.oldMap);
    }
    
    @TestVisible
    private JourneyPrivateEventNotificationsTrH(List<Journey__c> newJourneys, Map<Id, Journey__c> oldJourneys) {
        this.newJourneys = newJourneys;
        this.oldJourneys = oldJourneys;
    }
    
    public override void afterInsert(){
        sendEmailToMarketPOC();
    }
    
    public override void afterUpdate(){
        sendEmailToMarketPOC();
    }
    
    @TestVisible
    private void sendEmailToMarketPOC() {
        String marketPocEmail;
        List<String> emailAddresses;
        List<String> bccEmails = new List<String>();
        Map<String, Object> privateEventMarketMDT = Settings.getMetadataSettingByDevNameAsMap('PrivateEventMarketMapping');
        if(privateEventMarketMDT == null || privateEventMarketMDT.isEmpty()){
            return;
        }
        Map<String, Object> pocEmailMarketMap = (Map<String, Object>) privateEventMarketMDT.get('poc_emails');
        if(pocEmailMarketMap == null){
            return;
        }
        String orgWideEmailAddress = String.isNotBlank((String)privateEventMarketMDT.get('from_address')) ? (String)privateEventMarketMDT.get('from_address') : 'do_not_reply@wework.com';
        List<Object> leadSources = !((List<Object>)privateEventMarketMDT.get('lead_source')).isEmpty() ? (List<Object>)privateEventMarketMDT.get('lead_source') : new List<Object>{'wework.com'};
        List<Object> leadSourceSubtypes = !((List<Object>)privateEventMarketMDT.get('lead_source_subtype')).isEmpty() ? (List<Object>)privateEventMarketMDT.get('lead_source_subtype') : new List<Object>{'consultation - event space'};
        String defaultEmail = String.isNotBlank((String)privateEventMarketMDT.get('default_email')) ? (String)privateEventMarketMDT.get('default_email') : 'events@wework.com';
        List<OrgWideEmailAddress> orgWideAddress = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :orgWideEmailAddress];                
        if(String.isNotBlank((String)privateEventMarketMDT.get('bcc_email'))){             
            bccEmails.addAll(new Set<String>(((String)privateEventMarketMDT.get('bcc_email')).trim().split(';')));
        }
		EmailTemplate emailTemplate = Settings.getEmailTemplateByDeveloperName('Email_to_market_POC_for_private_eve_lead');
  
        List<Journey__c> journeysWithChangedSource = getLeadSourceChangedJourneys(leadSourceSubtypes, leadSources);
        List<Journey__c> journeys = getJourneysWithMarketingFields(journeysWithChangedSource);
        if(journeys == null){
            return;
        }
        if(emailTemplate == null){
            return;
        }
        Messaging.SingleEmailMessage singleMail;
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        for(Journey__c journey : journeys){
            marketPocEmail = getMarketPOCEmail(journey, pocEmailMarketMap, defaultEmail);
            emailAddresses = new List<String>();
            for(String email: marketPocEmail.split(';')){
                User user = UserUtility.getUserByEmail(email);
                if(user != null){
                    singleMail = getSingleEmailMessage(journey.Id, orgWideAddress, bccEmails, emailTemplate);
                    singleMail.setTargetObjectId(user.Id); 
                    emailsToSend.add(singleMail);
                }else{                          
                    emailAddresses.add(email);
                }
            }
            if(!emailAddresses.isEmpty()){   
                singleMail =  getSingleEmailMessage(journey.Id, orgWideAddress, bccEmails, emailTemplate);
                if(!emailAddresses.isEmpty()){
                    bccEmails.addAll(emailAddresses);
                    singleMail.bccaddresses = bccEmails;
                }else{
                    singleMail.toAddresses = emailAddresses; 
                }
                singleMail.setTargetObjectId(ApiUsersUtils.apiUserId);
                singleMail.setTreatTargetObjectAsRecipient(false);
                emailsToSend.add(singleMail);
            }
        }
        if(!emailsToSend.isEmpty()){
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emailsToSend); 
        }
    }

    private List<Journey__c> getJourneysWithMarketingFields(List<Journey__c> journeys) {
        return journeySelector.getJourneysWithAdditionalFieldsByIds(new List<Id> (new Map<Id, Journey__c>(journeys).keySet()));
    }

    private List<Journey__c> getLeadSourceChangedJourneys(List<Object> leadSourceSubtypes, List<Object> leadSources) {
        List<Journey__c> journeys = new List<Journey__c>();
        for(Journey__c newJourney : newJourneys) {
            Journey__c oldJourney = oldJourneys?.get(newJourney.Id);
            if(String.isNotBlank(newJourney.LeadSource_Sub_Type__c) && String.isNotBlank(newJourney.Lead_Source__c)
               && ((oldJourney == null)
                   || ((oldJourney != null)
                       && (TriggerUtility.isFieldsValueChanged(newJourney, oldJourney, new Set<String> {'LeadSource_Sub_Type__c', 'Lead_Source__c'}))))
               && (leadSources.contains(newJourney.Lead_Source__c.toLowercase()) && leadSourceSubtypes.contains(newJourney.LeadSource_Sub_Type__c.toLowercase()))) {
                journeys.add(newJourney);
            }
        }
        return journeys;
    }
    private Messaging.SingleEmailMessage getSingleEmailMessage(Id journeyId, List<OrgWideEmailAddress> orgWideAddress, List<String> bccEmails, EmailTemplate emailTemplate){
        Messaging.SingleEmailMessage singleMail = new Messaging.SingleEmailMessage();
        singleMail.setTemplateId(emailTemplate.Id);
        singleMail.setWhatId(journeyId);
        if(!orgWideAddress.isEmpty()){
            singleMail.setOrgWideEmailAddressId(orgWideAddress[0].Id);
        }  
        singleMail.setSaveAsActivity(false);
        if(!bccEmails.isEmpty()){
            singleMail.bccAddresses = bccEmails;
        } 
        return singleMail;
    }
    
    private String getMarketPOCEmail(Journey__c journey, Map<String, Object> pocEmailMarketMap, String defaultEmail){
        String marketPocEmail;
        if(String.isNotBlank(journey.Market__c)){
            marketPocEmail = String.isNotBlank((String)pocEmailMarketMap.get(journey.Market__c.toLowercase())) ? (String)pocEmailMarketMap.get(journey.Market__c.toLowercase()) : defaultEmail;
        }else if(String.isNotBlank(journey.Portfolio_Interested_In__r?.Name)){
            marketPocEmail = String.isNotBlank((String)pocEmailMarketMap.get(journey.Portfolio_Interested_In__r.Name.toLowercase())) ? (String)pocEmailMarketMap.get(journey.Portfolio_Interested_In__r.Name.toLowercase()) : defaultEmail;
        }else{
            marketPocEmail = defaultEmail;
        } 
        return marketPocEmail;
    }
}