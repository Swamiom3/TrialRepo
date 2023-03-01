/************************************************************************************************************************************
    Author         :     Shivprasad Patil
    Description    :     This class helps to exposes the Lead via SFDC's REST API

    History        :     
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE                AUTHOR                    DETAIL
    1            8 June 2018           Shivprasad Patil          -
**************************************************************************************************************************************/
public class RESTInboundLeadAPIHelper_v2 {
    @TestVisible
    private BuildingSelector buildingSelector = new BuildingSelector();
    public static Map<String, Market__c> marketsByUUIDs = new Map<String, Market__c>();
    private WWTypes.InboundLead inboundLead;
    private Lead referralLead;
    private static final String UNKNOWN = 'Unknown';
    private Journey__c latestJourney;
    @TestVisible
    private JourneySelector journeySelector = new JourneySelector();

    public RESTInboundLeadAPIHelper_v2(WWTypes.InboundLead inboundLead){
        this.inboundLead = inboundLead;
    }

    public Journey__c getLatestJourney() {
        List<String> fields = new List<String>{'Id', 'CreatedDate', 'Primary_Email__c', 'Lead_Source_Detail__c', 'Primary_Lead__c', 'Primary_Contact__c', 'Referrer__c'};
        List<Journey__c> existingJourney = journeySelector.getJourneysByEmailWithOrderByCreatedDate(fields, new List<String>{inboundLead.email});
        latestJourney = existingJourney.isEmpty() ? null : existingJourney[0];
        return latestJourney;
    }

    private String getProductInterests(List<String> productInterests) {
        return productInterests == null || productInterests.isEmpty() ? '' : String.join(productInterests, ';');
    }
    /* Commented as methods are not used 
    private String getMarketNamesForUUIds(List<String> marketUUIds){
        Set<String> distinctMarketUUIDs = new Set<String>(marketUUIds);
        distinctMarketUUIDs.remove('');
        if(distinctMarketUUIDs.isEmpty()){
            return null;
        }
        List<String> marketNames = new List<String>();
        for(Market__c market : [SELECT Id, Name, UUID__c FROM Market__c WHERE UUID__c IN :distinctMarketUUIDs AND No_Longer_in_Use__c <> TRUE]){
            marketNames.add(market.Name);
            marketsByUUIDs.put(market.UUID__c, market);
        }
        if(marketNames.isEmpty()){
            return null;  
        }
        return String.join(marketNames,';');
    }

    private String getMarketNamesForBuildings(List<String> buildingsUUIDs){
        List<String> marketNames = new List<String>();
        Set<String> distinctBuildingsUUIDs = new Set<String>(buildingsUUIDs);
        if(distinctBuildingsUUIDs.isEmpty()){
            return null;
        }
        for(Building__c  building : buildingSelector.getBuildingsByUuid(distinctBuildingsUUIDs)){
            marketNames.add(building.Market__r.Name);
        }
        if(marketNames.isEmpty()){
            return null;
        }
        return String.join(marketNames,';');
    }
    */
    
    public Map<Id,Id> insertLeadByWeb() {
        RESTInboundLeadAPIHelper.isLeadFromWeb = true;
        createReferralLead();
        insert referralLead;
        
        Id relatedReferralId = insertRelatedReferral();
        Journey__c journey = getLatestJourney();
        if (journey != null && journey.Referrer__c != referralLead.Referrer__c) {
            journey.Referrer__c = referralLead.Referrer__c;
        	update journey;
        }
        
        return new Map<Id, Id> {referralLead.Id => relatedReferralId};
    }

    private void createReferralLead(){
        Integer referralExpirationWindow = UtilReferral.getReferralMetadataSettings().get('REFERRAL_EXPIRATION_WINDOW');
        referralLead = getLeadByMapping();
        setInterestedInDesks();
        referralLead.Referral_Start_Date__c = Date.today();
        referralLead.Referral_Expiration_Date__c = Date.today().addDays(referralExpirationWindow);
    }    

    private Id insertRelatedReferral(){
        Set<Id> referrerId = new Set<Id>();
        referrerId.add(referralLead.Referrer__c);
        ContactSelector contactSelector = new ContactSelector();
        List<Contact> referrerContact = contactSelector.getContactsByIds(referrerId);
        Referral__c relatedReferral = UtilReferral.constructReferral(new Map<String, Object>{
                                                                        'Referrer__c' => referralLead.Referrer__c,
                                                                        'Building_Interested_In__c' => referralLead.Building_Interested_In__c,
                                                                        'Lead__c' => latestJourney == null ? referralLead.Id : latestJourney.Primary_Lead__c,
                                                                        'Referral_Contact__c' => latestJourney?.Primary_Contact__c,
                                                                        'Referral_Source__c' => referralLead.LeadSource,
                                                                        'Name' => referralLead.Name,
                                                                        'Referral_Email__c' => referralLead.Email,
                                                                        'Referral_Portal_Event__c' => 'Referral Lead Submitted',
                                                                        'Referrer_Type__c' => (!referrerContact.isEmpty() ? referrerContact[0].Type__c : '')});
        insert relatedReferral;
        return relatedReferral.Id;
    }
    
    private Lead getLeadByMapping(){
        Lead newLead = new Lead(
            Firstname                               = inboundLead.first_name,
            Lastname                                = inboundLead.last_name,
            Company                                 = inboundLead.company_name,
            Industry                                = inboundLead.company_industry,
            Email                                   = inboundLead.email,
            Phone                                   = inboundLead.phone,
            LeadSource                              = inboundLead.lead_source,
            Lead_Source_Detail__c                   = inboundLead.lead_source_detail,
            UTM_Campaign__c                         = inboundLead.utm_campaign,
            UTM_Content__c                          = inboundLead.utm_content,
            UTM_Medium__c                           = inboundLead.utm_medium,
            UTM_Source__c                           = inboundLead.utm_source,
            UTM_Term__c                             = inboundLead.utm_term,
            Promo_Code__c                           = inboundLead.promo_code,
            //Company_Size__c                         = inboundLead.company_size,
            Interested_in_Number_of_Desks_Range__c  = (String.isNotBlank(inboundLead.desks_interested_range)) ? inboundLead.desks_interested_range :  null,
            Interested_in_Number_of_Desks_Min__c    = (String.isNotBlank(inboundLead.desks_interested_min)) ? Integer.valueOf(inboundLead.desks_interested_min) : null,
            Interested_in_Number_of_Desks_Max__c    = (String.isNotBlank(inboundLead.desks_interested_max)) ? Integer.valueOf(inboundLead.desks_interested_max) : null,
            Locations_Interested__c                 = BuildingHandler.getMultipicklistValuesFromUUID(inboundLead.buildings_interested_uuids),
            //Last_Inbound_Lead_Received_at__c        = Datetime.now(),
            Description                             = inboundLead.notes,
            Locale__c                               = inboundLead.locale,
            //Quick_Quote_Location__c                 = inboundLead.quick_quote_location,
            Country_Code__c                         = inboundLead.country_code,
            //Product_Line__c                         = inboundLead.product_line,
            Product_Interests__c                    = getProductInterests(inboundLead.product_interests),
            Market__c                               = inboundLead.market,
            Generate_Journey__c                     = inboundLead.generate_journeys == false ? false : true,
            Move_In_Time_Frame__c                   = inboundLead.move_in_time_frame,
            Ts_and_Cs_Consent__c                    = checkIsValidBoolean(inboundLead.t_and_cs_consent), 
            //Affiliate_Consent__c                    = checkIsValidBoolean(inboundLead.affiliates_consent),
            Marketing_Consent__c                    = checkIsValidBoolean(inboundLead.marketing_consent), 
            Referral_Fail_Reason__c                 = getFailReason(),
            Campaign_Id__c                          = String.isNotBlank(inboundLead.campaign_sfid) ? inboundLead.campaign_sfid : null,
            LeadSource_Sub_Type__c                  = inboundLead.lead_source_subtype,
            Contact_Broker__c                       = inboundLead.contact_referrer_only != null ? inboundLead.contact_referrer_only : false,
            Personal_Mailing_Street__c              = String.isNotBlank(inboundLead.lead_address?.street) ? inboundLead.lead_address.street : null,
            Personal_Mailing_City__c                = String.isNotBlank(inboundLead.lead_address?.city) ? inboundLead.lead_address.city : null,
            Personal_Mailing_State__c               = String.isNotBlank(inboundLead.lead_address?.state) ? inboundLead.lead_address.state : null,
            Personal_Mailing_PostalCode__c          = String.isNotBlank(inboundLead.lead_address?.zip) ? inboundLead.lead_address.zip : null,
            Personal_Mailing_Country__c             = String.isNotBlank(inboundLead.lead_address?.country) ? inboundLead.lead_address.country : null,
            Reservable_Interested_In_Uuid__c        = inboundLead.reservable_interested_in_uuid
            );
        if(String.isNotBlank(inboundLead.market)){
            List<Market__c> markets = [SELECT Id 
                                       FROM Market__c 
                                       WHERE Name = :inboundLead.market 
                                             AND No_Longer_in_Use__c <> true 
                                       LIMIT 1];
            if(!markets.isEmpty()){
                newLead.Portfolio_Interested_In__c = markets[0].Id;
            }
        }else{
            newLead.Portfolio_Interested_In__c = (inboundLead.market_uuids != null && !marketsByUUIDs.isEmpty()) ? marketsByUUIDs.values()[0].Id : null;
        }  
        return newLead;
    }

    private String getFailReason(){
        if(String.isBlank(inboundLead.referral_fail_reason)){
            return null;
        }
        if(inboundLead.referral_fail_reason.length() > 255){
            return inboundLead.referral_fail_reason.substring(0, 255);
        }
        return inboundLead.referral_fail_reason;
    }

    private void setInterestedInDesks(){
        if(String.isNotBlank(inboundLead.desks_interested_min)){
            referralLead.Interested_in_Number_of_Desks__c = Integer.valueof(inboundLead.desks_interested_min);
        }else if(String.isNotBlank(inboundLead.company_size)){
            referralLead.Interested_in_Number_of_Desks__c = inboundLead.company_size != UNKNOWN ? getCompanySize(inboundLead.company_size) : 0; 
        }
        if(inboundLead.tour_building_uuid != null){
            referralLead.Building_Interested_In__c = BuildingHandler.getBuildingIdByUUID(inboundLead.tour_building_uuid);
        }
        if(String.isNotBlank(inboundLead.referrer_sfid) && inboundLead.referrer_sfid.length() >= 15){
            referralLead.Referrer__c = inboundLead.referrer_sfid;
            referralLead.Contact_Broker__c = inboundLead.contact_referrer_only != null ? inboundLead.contact_referrer_only : false;
        }
    }

    @TestVisible
    private Integer getCompanySize(String size){
        size = size.replaceAll('(,|desks|desk|people|peoples|<)','');
        size = size.deleteWhitespace();
        size = size.split('(-|\\+)')[0];
        try{
            return Integer.valueOf(size);
        }catch(Exception ex){
            return 1;
        }
    }

    private Boolean checkIsValidBoolean(Object flag){
        if(flag == null){
            return false;
        }
        String flagValue = String.valueOf(flag);
        return (flagValue == 'true' || flagValue == '1');
    }
    
    public class ReferralException extends Exception {}
}