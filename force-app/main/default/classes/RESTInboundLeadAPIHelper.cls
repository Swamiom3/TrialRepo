/*****************************************************************************************************************************
  1. The class has some Q2C comments
  
  /************************************************************************************************************************************
    Author      :   Shivprasad Patil
    Description :   This class helps to exposes the Lead via SFDC's REST API

    History     :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           8 June 2018         Shivprasad Patil          -
    2           1 Match 2021        Oleg Krasko            Refactoring
**************************************************************************************************************************************/
public class RESTInboundLeadAPIHelper {
    public static Boolean isLeadFromWeb = false;
    @TestVisible
    private BuildingSelector buildingSelector = new BuildingSelector();
    private Id marketId; 
    private final String CONTACT_SOBJECT_NAME = 'Contact';
     /****************************************************************************************************************************
    Author              : Shivprasad Patil
    Description         : This method used to get Leads by given email address
    Created Date        : 07,June 2018
    Last Modified By    : Oleg Krasko
    Last Modified Date  : 01, March 2021
   *****************************************************************************************************************************/
    public Lead getRecentLeadByEmail(String email){
        List<Lead> leads = [SELECT Id, CreatedDate, Email, IsConverted, ConvertedContactId, ConvertedAccountId, ConvertedOpportunityId, OwnerId 
                            FROM Lead 
                            WHERE Email =: email 
                            ORDER BY CreatedDate DESC 
                            LIMIT 1];
        return leads.isEmpty() ? null : leads[0];
    }

     /****************************************************************************************************************************
    Author              : Shivprasad Patil
    Description         : This method used to get Contact by given email address
    Created Date        : 07,June 2018
    Last Modified By    : Oleg Krasko
    Last Modified Date  : 01, March 2021
   *****************************************************************************************************************************/
    public Contact getRecentContactByEmail(String email){
        List<Contact> contacts = [SELECT Id, AccountId, Account.Type, OwnerId, Id_kind__c,
                                    (SELECT Id, StageName, Contract_Sent_Date__c, CloseDate 
                                    FROM Opportunities__r)
                                FROM Contact 
                                WHERE Email =: email
                                ORDER BY CreatedDate DESC 
                                LIMIT 1];
        return contacts.isEmpty() ? null : contacts[0];
    }

     /****************************************************************************************************************************
    Author              : Shivprasad Patil
    Description         : This method used to convert array of product interest into string seperated by semi-colon
    Created Date        : 07,June 2018
    Last Modified By    : Oleg Krasko
    Last Modified Date  : 01, March 2021
   *****************************************************************************************************************************/
    private String getProductInterests(List<String> productInterests) {
        return productInterests == null ? '' : String.join(productInterests, ';');
    }

  /****************************************************************************************************************************
    Author              : Shivprasad Patil
    Description         : This method used to insert lead which is coming from web
    Created Date        : 07,June 2018
    Last Modified By    : Oleg Krasko
    Last Modified Date  : 01, March 2021
   *****************************************************************************************************************************/
    public Id insertLeadByWeb(WWTypes.InboundLead inboundLead, RESTInboundLeadAPI.Response response) {
        isLeadFromWeb = true;
        try{
            Lead leadForInsert = setInterestedInDesks(inboundLead, getLeadByMapping(inboundLead, response));
            insert leadForInsert;
            return leadForInsert.Id;
        } catch (Exception excep){
            if (excep instanceof DmlException
           || excep instanceof RESTInboundLeadAPIController.InboundLeadException
            || excep instanceof TypeException) {
                logException(excep, response, inboundLead);
                return null;
            }
            throw excep;
        }
    }

    /****************************************************************************************************************************
    Author              : Shivprasad Patil
    Description         : This method used to insert lead coming from Email2Lead.
    Created Date        : 07,June 2018
    Last Modified By    : Oleg Krasko
    Last Modified Date  : 01, March 2021
   *****************************************************************************************************************************/
    public Set<Id> insertLeadByEmail(set<string> emailIds, Messaging.inboundEmail pEmail, Messaging.InboundEnvelope pEnv){
        List<Lead> newLeads = new List<Lead>();
        for(String emailId: emailIds){
            Lead leadnew = new Lead();
            leadnew.LastName = emailId.substring(0, emailId.indexOf('@'));
            leadnew.Company = this.getContactCompany(pEmail.fromAddress);
            leadnew.Email = emailId;
            leadnew.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Partnership').getRecordTypeId();
            //leadnew.email_origin__c = pEnv.fromAddress;
            leadnew.leadsource = 'Inbound Email';
            leadnew.lead_source_detail__c = 'joinus@wework.com';
            leadnew.Generate_Journey__c = false;
            leadNew.Status = 'Known';
            newLeads.add(leadnew);
        }
        isLeadFromWeb = true;
        insert newLeads;
        return new Map<Id, Lead>(newLeads).keySet();
    }

    private Market__c getMarketByUUID(String marketUUID) {
        List<Market__c> markets = [SELECT Id, Name FROM Market__c WHERE UUID__C =: marketUUID AND No_Longer_in_Use__c = false LIMIT 1];
        return markets.isEmpty() ? null : markets[0];
    }
   /****************************************************************************************************************************
    Author              : Shivprasad Patil
    Description         : This method used field mapping for given payLoad
    Created Date        : 08,June 2018
    Last Modified By    : Oleg Krasko
    Last Modified Date  : 01, March 2021
   *****************************************************************************************************************************/
    private Lead getLeadByMapping(WWTypes.InboundLead inboundLead, RESTInboundLeadAPI.Response response){
        Lead newLead =  new Lead(
            Firstname                              = inboundLead.first_name.split('@')[0],
            Lastname                               = inboundLead.last_name,
            Company                                = inboundLead.company_name,
            Industry                               = inboundLead.company_industry,
            Email                                  = inboundLead.email,
            Phone                                  = inboundLead.phone,
            Leadsource                             = inboundLead.lead_source,
            Lead_Source_Detail__c                  = inboundLead.lead_source_detail,
            UTM_Campaign__c                        = inboundLead.utm_campaign,
            UTM_Content__c                         = inboundLead.utm_content,
            UTM_Medium__c                          = inboundLead.utm_medium,
            UTM_Source__c                          = inboundLead.utm_source,
            UTM_Term__c                            = inboundLead.utm_term,
            Promo_Code__c                          = inboundLead.promo_code,
            Interested_in_Number_of_Desks_Range__c = inboundLead.desks_interested_range,
            Interested_in_Number_of_Desks_Min__c   = (String.isNotBlank(inboundLead.desks_interested_min)) ? Integer.valueOf(inboundLead.desks_interested_min) : null,
            Interested_in_Number_of_Desks_Max__c   = (String.isNotBlank(inboundLead.desks_interested_max)) ? Integer.valueOf(inboundLead.desks_interested_max) : null,
            Locations_interested__c                = BuildingHandler.getMultipicklistValuesFromUUID(inboundLead.buildings_interested_uuids),
            description                            = inboundLead.notes,
            Locale__c                              = inboundLead.locale,
            Country_Code__c                        = inboundLead.country_code,
            //Product_Line__c                        = inboundLead.product_line,
            Product_Interests__c                   = getProductInterests(inboundLead.product_interests),
            Market__c                              = inboundLead.market,
            Generate_Journey__c                    = inboundLead.generate_journeys == false ? false : true,
            Move_In_Time_Frame__c                  = inboundLead.move_in_time_frame,
            Ts_and_Cs_Consent__c                   = checkIsValidBoolean(inboundLead.t_and_cs_consent,'t_and_cs_consent'),
            //Affiliate_Consent__c                   = checkIsValidBoolean(inboundLead.affiliates_consent,'affiliates_consent'),
            Marketing_Consent__c                   = checkIsValidBoolean(inboundLead.marketing_consent,'marketing_consent'),
            Referral_Fail_Reason__c                = (String.isNotBlank(inboundLead.referral_fail_reason) && 
                                                                        inboundLead.referral_fail_reason.length() > 255) ? 
                                                                            inboundLead.referral_fail_reason.substring(0, 255) : inboundLead.referral_fail_reason,
            Campaign_Id__c                         = getCampaignId(inboundLead.campaign_sfid),
            LeadSource_Sub_Type__c                 = inboundLead.lead_source_subtype, //Issue ST-3222
            Contact_Broker__c                      = inboundLead.contact_referrer_only == null ? false : true,
            Personal_Mailing_Street__c             = inboundLead.lead_address?.street,
            Personal_Mailing_City__c               = inboundLead.lead_address?.city,
            Personal_Mailing_State__c              = inboundLead.lead_address?.state,
            Personal_Mailing_PostalCode__c         = inboundLead.lead_address?.zip,
            Personal_Mailing_Country__c            = inboundLead.lead_address?.country,
            Full_URL__c                            = inboundLead.full_url,
            Create_Source__c                       = inboundLead.create_source,
            Submission_Timestamp__c                = String.isNotBlank(inboundLead.submission_timestamp) ? DateTime.parse(inboundLead.submission_timestamp) : null,
            First_Referring_Domain__c              = inboundLead.first_referring_domain,
            DCLID__c                               = inboundLead.google_analytics?.dclid,
            GACLIENTID__c                          = String.isNotBlank(inboundLead.google_analytics?.gaclientid) ? inboundLead.google_analytics.gaclientid : inboundLead.google_analytics?.google_id,
            GAUSERID__c                            = inboundLead.google_analytics?.gauserid,
            GATRACKID__c                           = inboundLead.google_analytics?.gatrackid,
            GCLID__c                               = inboundLead.google_analytics?.gclid,
            GCLSRC__c                              = inboundLead.google_analytics?.gclsrc,
            Segment_ID__c                          = inboundLead.segment_id,
            //Heap_ID__c                             = inboundLead.heap_id,
            Email_SHA256__c                        = inboundLead.email_sha256,
            //SAPI_Submission_Id__c                  = inboundLead.sapi_submission_id,
            Reservable_Interested_In_Uuid__c       = inboundLead.reservable_interested_in_uuid,
            LoyaltyProgram__c                      = inboundLead.loyalty_program,
            LoyaltyNumber__c                       = inboundLead.loyalty_number
        );
        if(String.isNotBlank(inboundLead.market)){
            List<Market__c> markets = [SELECT Id, Name, UUID__c FROM Market__c WHERE Name =: inboundLead.market AND No_Longer_in_Use__c = false LIMIT 1];
            if(!markets.isEmpty()){
                newLead.Portfolio_Interested_In__c = markets[0].Id;
            }
        }else if(inboundLead.market_uuids != null && !inboundLead.market_uuids.isEmpty() && String.isNotBlank(inboundLead.market_uuids[0])) {
            Market__c market = getMarketByUUID(inboundLead.market_uuids[0]);
            newLead.Market__c = market?.Name;
            newLead.Portfolio_Interested_In__c = market?.Id;
        }else{
            newLead.Portfolio_Interested_In__c = marketId;
        }
        return newLead;
    }

    /****************************************************************************************************************************
    Author              : Shivprasad Patil
    Description         : This method used to set intrested in desks
    Created Date        : 08,June 2018
    Last Modified By    : Oleg Krasko
    Last Modified Date  : 01, March 2021
   *****************************************************************************************************************************/
    private Lead setInterestedInDesks(WWTypes.InboundLead inboundLead, Lead lead){
        if(String.isNotBlank(inboundLead.desks_interested_min)){
            lead.Interested_in_Number_of_Desks__c = Integer.valueof(inboundLead.desks_interested_min);
        }else if(String.isNotBlank(inboundLead.company_size)) {
            lead.Interested_in_Number_of_Desks__c = inboundLead.company_size != 'Unknown' ? this.getCompanySize(inboundLead.company_size) : 0;
        }
        if(inboundLead.tour_building_uuid != null) {
            lead.Building_Interested_In__c = BuildingHandler.getBuildingIdByUUID(inboundLead.tour_building_uuid);
        }
        if(isValidContactId(inboundLead.referrer_sfid)){
            lead.Referrer__c = inboundLead.referrer_sfid;
        }
        lead.Lead_Creation_Source__c = 'External System';
        return lead;
    }

    /****************************************************************************************************************************
    Author              : Shivprasad Patil
    Description         : This method used to get domain of company using email
    Created Date        : 08,June 2018
    Last Modified By    : Oleg Krasko
    Last Modified Date  : 01, March 2021
   *****************************************************************************************************************************/
    private String getContactCompany(String pEmail) {
        return pEmail.indexOf('@') > 0 && pEmail.length() - pEmail.indexOf('@') > 0 ? pEmail.substring(pEmail.indexOf('@') + 1) : pEmail;
    }

   /****************************************************************************************************************************
    Author              : Shivprasad Patil
    Description         : This method used to get company size.
    Created Date        : 08,June 2018
    Last Modified By    : Oleg Krasko
    Last Modified Date  : 01, March 2021
   *****************************************************************************************************************************/
    @TestVisible
    private Integer getCompanySize(String size){        
        size = size.replaceAll('(,|desks|desk|people|peoples|<)','');
        size = size.deleteWhitespace();       
        size = size.split('(-|\\+)')[0];       
        try{
            return Integer.valueOf(size);
        }catch(TypeException ex){
            return 1;
        }
    }

   /****************************************************************************************************************************
    Author              : Shivprasad Patil
    Description         : This method wheather boolean value is valid or not.
    Created Date        : 08,June 2018
    Last Modified By    : Oleg Krasko
    Last Modified Date  : 01, March 2021
   *****************************************************************************************************************************/
    private Boolean checkIsValidBoolean(Object flag, String fieldName){            
        if(flag == null){
            return false;
        }
        String input = String.valueOf(flag).toLowerCase();
        switch on input {
            when 'true', '1' {
                return true;
            }
            when 'false', '0', '' {
                return false;
            }
            when else {
                throw new RESTInboundLeadAPIController.InboundLeadException('Invalid boolean or String: ' + input + ' of Field ' + fieldName + ' ');
            }
        }
    }

   /****************************************************************************************************************************
    Author              : Rohit Nimase
    Description         : This method is used to get valid campaignId.
    Created Date        : 25 June 2019
    Issue No.           : STL-638
    Last Modified By    : Oleg Krasko
    Last Modified Date  : 01, March 2021
   *****************************************************************************************************************************/
    private Id getCampaignId(String campaignSFId){
        if (String.isBlank(campaignSFId)) {
            return null;
        }
        Id campaignId = Id.valueOf(campaignSFId);
        
      
        LeadConverterHelper.createCampaignsByIdsFromIdsAndSetting(new Set<Id>{campaignId});
        return LeadConverterHelper.campaignsByIds.containsKey(campaignId) ? campaignId : null;
        
    }

    public void logException(Exception excep, RESTInboundLeadAPI.Response response, WWTypes.InboundLead inboundLead){
        response?.setFailure(excep);
        if(ApexDebugLog.isRootInvoker(ApexDebugLog.InvokerType.API)){
            ApexDebugLog.logException(excep, JSON.serialize(inboundLead),'RESTInboundLeadAPI','doPost');
        }
    }

    private Boolean isValidContactId(String idToValidate){
        if (String.isBlank(idToValidate) ||
            !Pattern.compile('[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}').matcher(idToValidate).matches()) {
            return false;
        }
        try {
            Id id = idToValidate;
            if (id.getSObjectType().getDescribe().getName() != CONTACT_SOBJECT_NAME) {
                return false;
            }
        } catch (StringException excep) {
            return false;
        }
        return true;
    }
}