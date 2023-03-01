/************************************************************************************************************************************
    Author        : Liubomyr Mishchykha
    Description   : Business logic for tour booking that is used from different entry points.
    History:
----------------------------------------------------------------------------------------------------------------------------------
    VERSION       DATE          AUTHOR                DETAIL                  ISSUE
    1             1/26/21       Liubomyr Mishchykha   Initial Developement    ST-10000    
**************************************************************************************************************************************/
public inherited sharing class TourBookingService {
    ServiceAppointmentEndpointService saes;
    private Map<Id, Contact> idsToContacts;
    private Journey__c tourJourney;
    @TestVisible
    private Building__c tourBuilding;
    @TestVisible
    private RESTAPITourModelsV2.Input body;
    private ServiceTerritorySelector buildingTourInfoSelector;
    private ServiceAppointmentSelector tourSelector;
    private ContactSelector contSelector;
    private OpportunityContactRoleSelector oppContRoleSelector;
    private OpportunitySelector oppSelector;
    private BuildingSelector buildSelector;
    private ServiceResourceSelector srSelector;
    @TestVisible
    private String startTime;
    @TestVisible
    private String endTime;
    private Id buildingTourInfoId;
    private Id opportunityId;
    private Boolean isReschedule;
    private Savepoint sp;

    @TestVisible
    private TourBookingService() {} 

    public TourBookingService(RESTAPITourModelsV2.Input body) {
        this.body = body;
        checkMandatoryFields();
        getBuildingInfo();
        convertDatetimeStringToGMT();
    }

    private void checkMandatoryFields() {
        if (String.isBlank(body.building_id)) {
            throw new TourBookingException('Required field "building_id" is missing!');
        }
        if (String.isBlank(body.service_resource_id)) {
            throw new TourBookingException('Required field "service_resource_id" is missing!');
        }
        if (String.isBlank(body.start_time)) {
            throw new TourBookingException('Required field "start_time" is missing!');
        }
        isReschedule = String.isNotBlank(body.tour_id);
        // TODO: to make dynamic after tour format selection will be available in ww.com
        body.tour_format = ServiceAppointmentConstants.TOUR_FORMAT_IN_PERSON;
        // body.tour_format = String.isBlank(body.tour_format) ? ServiceAppointmentConstants.TOUR_FORMAT_IN_PERSON : body.tour_format;
    }

    @TestVisible
    private void convertDatetimeStringToGMT() {
        startTime = ((DateTime) JSON.deserialize('"' + getTimeWithTimeZone(body.start_time, tourBuilding.Time_Zone__c) + '"', Datetime.class)).formatGMT(GlobalConstants.DATE_FORMAT_GMT);
        if (String.isNotBlank(body.end_time)) {
            endTime = ((DateTime) JSON.deserialize('"' + getTimeWithTimeZone(body.end_time, tourBuilding.Time_Zone__c) + '"', Datetime.class)).formatGMT(GlobalConstants.DATE_FORMAT_GMT);
        }
    }

    private String getTimeWithTimeZone(String inputDateTime, String timeZone) {
        String convTime = DateUtilities.getTimeWithTimeZone(inputDateTime, timeZone);
        //check for half-hour offsets
        Integer index = convTime.lastIndexOf('5');
        if (index != convTime.length() - 2) {
            return convTime;
        }
        return convTime.substring(0, index) + '3' + convTime.substring(index + 1, convTime.length());
    }

    public String getTourBookingRequest() {
        return isReschedule ? getTourReschedulingRequest() : getNewTourBookingRequest();
    }

    private String getNewTourBookingRequest() {
        sp = Database.setSavepoint();
        try {
            Contact tourContact = convertLead();
            return createNewTourPayload(tourContact, opportunityId);
        } catch (Exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }

    private String getTourReschedulingRequest() {
        return createRescheduleTourPayload();
    }

    @TestVisible
    private void getBuildingInfo() {
        buildSelector = new BuildingSelector();
        List<Building__c> buildings = buildSelector.getBuildingsByUuidWithTourSchedules(String.isNotBlank(body.building_id) 
                                                                                            ? body.building_id
                                                                                            : isReschedule
                                                                                                ? getTourBuildingUUIDId(getExistingTourId(body.tour_id))
                                                                                                : null);                                                                              
        if (buildings?.isEmpty() == true) {
            throw new TourBookingException('Invalid building Id provided');
        }
        tourBuilding = buildings[0];
        buildingTourInfoSelector = new ServiceTerritorySelector();
        List<ServiceTerritory> buildingTourInfos = buildingTourInfoSelector.getServiceTerritoriesByBuilding(tourBuilding.Id);
        if (buildingTourInfos.isEmpty()) {
            throw new TourBookingException('No active building tour information found');
        }
        buildingTourInfoId = buildingTourInfos[0].Id;
    }

    private String getTourBuildingUUIDId(Id tourId) {
        tourSelector = new ServiceAppointmentSelector();
        return tourSelector.getBuildingUUIDByTourId(tourId);
    }

    @TestVisible
    private Contact convertLead() {
        Map<String, Id> convertedData = LeadConverterHelper.manageLead(body);  
        Opportunity tourOpportunity;
        Contact tourContact = getContactById(convertedData.get('contactId'));
        if (String.isBlank(tourContact?.AccountId) && convertedData.containsKey('accountId')) {
            tourContact.AccountId = convertedData.get('accountId');
            idsToContacts.remove(tourContact?.Id);
        }
        tourOpportunity = getOrCreateOpportunity(body, tourContact.AccountId, tourContact?.Id);
        upsert new List<SObject>{ tourContact, tourOpportunity };
        oppContRoleSelector = new OpportunityContactRoleSelector();
        if (oppContRoleSelector.getOpportunityContactRolesByOpportunityAndContact(tourOpportunity.Id, tourContact.Id).isEmpty()) {
            insert new OpportunityContactRole(
                        OpportunityId = tourOpportunity.Id,
                        ContactId = tourContact?.Id,
                        Role = GlobalConstants.OPP_CONTACT_ROLE_MAIN_CONTACT
            );
        }
        opportunityId = tourOpportunity.Id;
        tourJourney = getTourRelatedJourney(OpportunityHelper.objPayloadJourney, tourContact?.Id);
        return tourContact;
    }

    private Contact getContactById(String contactId) {
        if (String.isBlank(contactId)) {
            return null;
        }
        if (idsToContacts == null || idsToContacts.isEmpty() || !idsToContacts.containsKey(contactId)) {
            idsToContacts = getContacts(new Set<Id>{contactId});
        }
        return idsToContacts.get(contactId);
    }

    private Map<Id, Contact> getContacts(Set<Id> contactIds){
        if (idsToContacts == null) {
            idsToContacts = new Map<Id, Contact>();
        }         
        contSelector = new ContactSelector();        
        idsToContacts.putAll(new Map<Id, Contact>(contSelector.getContactsWithAccountFieldsByIdsOrLoggedInUserEmail(contactIds)));
        return idsToContacts;
    }

    private Journey__c getTourRelatedJourney(Journey__c journey, Id primaryContactId){
        if (journey == null) {
            journey = OpportunityHelper.getJourneyForMapping(tourBuilding, primaryContactId, false);
        }
        Journey__c latestModifiedJourney = LeadTriggerHandler.objLatestModifiedJourney;
        if (journey == null && tourJourney == null) {
            journey = latestModifiedJourney != null
                            ? latestModifiedJourney
                            : (OpportunityHelper.lstJourneys != null && !OpportunityHelper.lstJourneys.isEmpty())
                                ? OpportunityHelper.lstJourneys[0]
                                : null;
            tourJourney = null;
        }
        return journey;
    }

    private Opportunity getOrCreateOpportunity(RESTAPITourModelsV2.Input body, Id accountId, Id contactId) {
        Opportunity newOpportunity;
        if (String.isNotBlank(body.opportunity_id)) {
            oppSelector = new OpportunitySelector();
            List<Opportunity> opportunities = oppSelector.getOpportunityLocationFieldsById(body.opportunity_id);
            if (!opportunities.isEmpty()) {
                newOpportunity = opportunities[0];
            } else {
                throw new TourBookingException('Invalid Opportunity Id specified');
            }
        } else {
            newOpportunity = OpportunityHelper.getLatestOpenOpportunity(accountId, contactId, tourBuilding);
            Journey__c payloadJourney;
            if (String.isNotBlank(body.journey_sfid)) {
                payloadJourney = [SELECT Id FROM Journey__c WHERE Id = :Id.valueOf(body.journey_sfid)];
            } else {
                payloadJourney = OpportunityHelper.getJourneyForMapping(tourBuilding, contactId, false);
            }
            if (newOpportunity == null) {
                newOpportunity = payloadJourney != null
                                    ? OpportunityHelper.createOpportunity(payloadJourney.Id, contactId, GlobalConstants.OPPORTUNITY_STAGE_QUALIFYING)
                                    : OpportunityHelper.createOpportunity(contactId, GlobalConstants.OPPORTUNITY_STAGE_QUALIFYING);
            }
            newOpportunity.Opportunity_Creation_Source__c = GlobalConstants.OPPORTUNITY_CREATION_SOURCE_FROM_TOUR;
            newOpportunity.Tour_Scheduled__c = System.today();
            newOpportunity.Tour_Notes__c = body.notes;
            newOpportunity.Building__c = tourBuilding?.Id;
            if (newOpportunity.Interested_in_Number_of_Desks__c == null || newOpportunity.Interested_in_Number_of_Desks__c == 0) {
                newOpportunity.Interested_in_Number_of_Desks__c = body.number_of_desks != null ? Integer.valueOf(body.number_of_desks) : getLowerSize(body.company_size);
            }
        }
        if (newOpportunity.Building__c == null) {        
            newOpportunity.Building__c = tourBuilding?.Id;     
        }
        Set<String> locationInterested = new Set<String>();
        if (String.isNotBlank(newOpportunity.Locations_Interested__c)) {
            locationInterested.addAll(newOpportunity.Locations_Interested__c.split(';'));
        }
        locationInterested.add(tourBuilding.Name);
        newOpportunity.Locations_Interested__c = String.join(new List<String>(locationInterested), ';');
        UtilSObject.trimTooLongPicklist(newOpportunity, Opportunity.Locations_Interested__c);
        return newOpportunity;
    }

    private String createNewTourPayload(Contact tourContact, Id opportunityId) {            
        saes = new ServiceAppointmentEndpointService();
        return saes.setSAParentId(tourContact.AccountId)
                    .setSAField('Interested_in_Number_of_Desks__c', String.valueOf(tourJourney?.Interested_in_Number_of_Desks__c))
                    .setSAField('Opportunity_Id__c', opportunityId)
                    .setSAField('Building_Id__c', tourBuilding?.Id)
                    .setSAField('Tour_Notes__c', tourJourney?.Description__c)
                    .setSAField('Promo_Code__c', body.promo_code)
                    .setSAField('Product_Interests__c', tourJourney?.Product_Interests__c)
                    .setSAField('Journey_Id__c', tourJourney?.Id)
                    .setSAField('Locale__c', tourJourney?.Locale__c)
                    .setSAField('Move_In_Time_Frame__c', body.move_in_time_frame)
                    .setSAField('Referral_Fail_Reason__c', String.isNotBlank(body.referral_fail_reason)
                                                                ? body.referral_fail_reason.length() > 255
                                                                    ? body.referral_fail_reason.substring(0, 255)
                                                                    : body.referral_fail_reason
                                                                : null)
                    .setSAField('Tour_Format__c', body.tour_format)
                    .setSAField('Status', 'Scheduled')
                    .setSAField('SchedStartTime', startTime)
                    .setSAField('SchedEndTime', endTime)
                    .setSAField('ServiceTerritoryId', buildingTourInfoId)
                    .setSAField('ContactId', tourContact.Id)
                    .setSAField('Street', tourBuilding?.Address__c)
                    .setSAField('City', tourBuilding?.City__c)
                    .setSAField('State', tourBuilding?.State__c)
                    .setSAField('Country', tourBuilding?.Country__c)
                    .setSAField('PostalCode', tourBuilding?.Postal_Code__c)
                    .setSAField('Tour_Source__c', String.isBlank(body.source)
                                                    ? GlobalConstants.TOUR_SOURCE_WWDC
                                                    : body.source)
                    .setSAField('Phone', body.phone)
                    .setSAField('Email', body.email)
                    .setSAField('OwnerId', getServiceResourceUserId())
                    .setSAField('WorkTypeId', SalesforceSchedulerUtility.getBuildingTourFormatWorkTypeId(tourBuilding.Id, body.tour_format))
                    .setServiceResource(body.service_resource_id)
                    .preparePayload();
    }

    private String createRescheduleTourPayload() {
        saes = new ServiceAppointmentEndpointService();
        return saes.setServiceAppointmentId(getExistingTourId(body.tour_id))
                    .setSAField('SchedStartTime', startTime)
                    .setSAField('SchedEndTime', endTime)
                    .setSAField('OwnerId', getServiceResourceUserId())
                    .setSAField('WorkTypeId', SalesforceSchedulerUtility.getBuildingTourFormatWorkTypeId(tourBuilding.Id, body.tour_format))
                    .setServiceResource(body.service_resource_id)
                    .preparePayload();
    }

    private Id getServiceResourceUserId() {
        srSelector = new ServiceResourceSelector();
        Id relatedUserId = srSelector.getServiceResourceWithUserById(Id.valueOf(body.service_resource_id))?.RelatedRecordId;
        if (String.isBlank(relatedUserId)) {
            throw new TourBookingException('No User was found for specified Host');
        }
        return relatedUserId;
    }

    private Id getExistingTourId(String tourId) {
        if (String.isEmpty(tourId) || Id.valueOf(tourId).getSobjectType() == ServiceAppointment.SObjectType) {
            return tourId;
        }
        tourSelector = new ServiceAppointmentSelector();
        //temporary logic for transition period, to delete once it's over
        Id existingTourId = tourSelector.getTourByUUID(tourId)?.Id;
        if (String.isBlank(existingTourId)) {
            throw new TourBookingException('Tour with provided Id does not exist');
        }
        return existingTourId;
    }

    @TestVisible
    private Integer getLowerSize(String companySize) {
        if (String.isBlank(companySize)) {
            return 0;
        }
        Integer lowerSize;
        companySize = companySize.replace(',', '')
                                 .replace('desks', '')
                                 .replace('desk', '')
                                 .replace('<', '')
                                 .deleteWhitespace();
        if (companySize.contains('-')) {
            lowerSize = Integer.valueOf(companySize.split('-')[0]);
        } else if (companySize.contains('+')) {
            lowerSize = Integer.valueOf(companySize.split('\\+')[0]);
        } else {
            lowerSize = Integer.valueOf(companySize);
        }
        return lowerSize;
    }

    @TestVisible
    private class AppointmentCandidatesOutput {
        @TestVisible
        List<Id> resources;
        @TestVisible
        DateTime startTime;
        @TestVisible
        DateTime endTime;
        @TestVisible
        Id territoryId;
    }

    public class TourBookingException extends Exception {}
}