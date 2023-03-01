/************************************************************************************************************************************
    Author         :     Pranay Jadhav
    Description    :     This class having logic to handle the Lead via SFDC's REST API
    History        :    
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE                AUTHOR                    DETAIL
    1            8 June 2018           Pranay Jadhav             -
    2           15th May 2019          Nicholas Zozaya           v2 implementation
**************************************************************************************************************************************/
public class RESTInboundLeadAPIController_v2 {
    private WWTypes.InboundLead inboundLead;
    private Lead recentLeadByEmail;
    private Contact recentContactByEmail;
    private Journey__c latestJourney;

    @TestVisible
    private static Integer REFERRAL_EXPIRATION_TERM_DAYS = GlobalConstants.REFERRAL_RESUBMISSION_INTERVAL;
    @TestVisible
    private static String LEAD_REFERRED_IN_THE_LAST_N_DAYS_ERROR = String.format('A lead with given email was already referred in the last {0} days',
                                                                                    new List<Object>{ REFERRAL_EXPIRATION_TERM_DAYS });
    private String LEAD_OR_CONTACT_ALREADY_EXISTS_ERROR = 'A lead or contact with given email already exists';
    
    public RESTInboundLeadAPIController_v2(WWTypes.InboundLead inboundLead){
        this.inboundLead = inboundLead;
    }

    public Map<Id, Id> handlePostRequest(){
        RESTInboundLeadAPIHelper_v2 helper = new RESTInboundLeadAPIHelper_v2(inboundLead);

        if(String.isNotBlank(inboundLead?.email)){
            latestJourney = helper.getLatestJourney();
        }
        if (inboundLead?.lead_source_detail == 'Referral Portal') {
            if (latestJourney?.Lead_Source_Detail__c == inboundLead.lead_source_detail
                    && latestJourney?.CreatedDate.date().daysBetween(System.today()) <= REFERRAL_EXPIRATION_TERM_DAYS) {
                throw new InboundLeadException(LEAD_REFERRED_IN_THE_LAST_N_DAYS_ERROR);
            }
        } else if (latestJourney != null) {
            throw new InboundLeadException(LEAD_OR_CONTACT_ALREADY_EXISTS_ERROR);
        }
        return helper.insertLeadByWeb();
    }
    
    public class InboundLeadException extends Exception {}
}