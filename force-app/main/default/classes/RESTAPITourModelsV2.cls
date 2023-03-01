/************************************************************************************************************************************
    Author      :   Dipak Pawar
    Description :   This class contains the wrappers of all versions for Tour API
    
    History     :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              DETAIL
    1           19 June 2018        Dipak Pawar         Initial Developement
**************************************************************************************************************************************/
global class RESTAPITourModelsV2 extends RESTAPIModel {

    global class Input {
        global String tour_id;
        global String building_id;
        global String start_time;
        global String end_time;
        global String booked_by_id;
        global String toured_by_id;
        global String source;
        global String last_name;
        global String first_name;
        global String email;
        global String phone;
        global String lead_source;
        global String number_of_desks;
        global String utm_campaign_id;
        global String utm_campaign;
        global String utm_content;
        global String utm_medium;
        global String utm_source;
        global String utm_term;
        global String referral_id;
        global String lead_source_detail;
        global String company_name;
        global String company_size;
        global String company_industry;
        global String quick_quote_location;
        global String notes;
        global String referral_code; 
        global String promo_code; 
        global String[] buildings_interested_uuids = new String[]{};
        global String desks_interested_min;
        global String desks_interested_size;
        global String desks_interested_max;
        global String desks_interested_range;
        global Date tour_date;
        global String tour_time;
        global String tour_building_uuid;
        global String tour_notes;
        global String tour_uuid;
        global String tour_completed_by;
        global String tour_completed_by_sfid;
        global String tour_completed_by_uuid;
        global String tour_completed_by_name;		
        global String contact_uuid;
        global String primary_member;
        global String original_tour;
        global String original_tour_uuid;
        global String journey_sfid;
        global String[] product_interests = new String[]{};
        global String product_line;
        global String tour_format;
        global String locale;
        global String country_code;
        global String referrer;
        global String referrer_sfid;
        global String lead_source_details;
        global Boolean contact_referrer_only;
        global String booked_by_contact_id;
        global String assigned_host; 
        global String hosted_by;
        global Boolean booked_by_sales_lead;
        global String opportunity_id; 
        global String move_in_time_frame;        
        global String t_and_cs_consent;
        global String marketing_consent;
        global String affiliates_consent;        
        global String referral_fail_reason;
        global String alternate_building_id;
        global String pnm_sentiment;
        global String service_resource_id;
    }
    
    global class Response {
        global String payload;
        global Boolean success;
        global String message;
    }

    global class GetTimeSlotsRequest {
        public String building_id; 
        public String tour_format;
        public String start_time;
        public String end_time;
    }

    global class AvailableTimeSlot {
        public Id territoryId;
        public Id serviceResourceId;
        public Integer remainingAppointments;
        public String startTime;
        public String endTime;
    }
}