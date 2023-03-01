/************************************************************************************************************************************
    Author          : Dipak Pawar
    Description     : This class contains business logic of Restart Journeys for Tours
    History:
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           11 Dec 2018         Dipak Pawar             Initial Developement.(ST-3213)
    2           18 Jan 2019         Dipak Pawar             Modify Logic for NMD users and for Non NMD Users.(ST-3352)
    3           12 Feb 2019         Shivprasad Patil        Modify Logic for NMD users and for Non NMD Users.(ST-3397)
    4           15 Mar 2019         Ashish Mishra           Modify to stop updating status of newly created Journey as Manual Outreach and
                                                            update Restart Journey checkbox as true.
    5           30 Jul 2021         Tomasz Sadowski         Migration to new trigger framework
**************************************************************************************************************************************/
public with sharing class TourRestartJourneyTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<ServiceAppointment> newTours;
    @TestVisible
    private Map<Id, ServiceAppointment> oldToursMap;

    @TestVisible
    private BuildingSelector buildingSelector = new BuildingSelector();
    static Map<Id, Contact> contactIdToContact;
    private Map<Id, Contact> contactsWithJourneys;
    
    public TourRestartJourneyTrH(){
        this((List<ServiceAppointment>) Trigger.new, (Map<Id, ServiceAppointment>) Trigger.oldMap);
    }
    
    @TestVisible
    private TourRestartJourneyTrH(List<ServiceAppointment> newTours, Map<Id, ServiceAppointment> oldToursMap) {
        this.newTours = newTours;
        this.oldToursMap = oldToursMap;
    }

    public override void afterUpdate() {
        restartJourneyForTours();
    }

    private void restartJourneyForTours() {
        Set<String> setTourStatuses = new Set<String>{GlobalConstants.TOUR_NO_SHOW};
        Set<Id> locationIds = new Set<Id>();
        Set<Id> tourPrimaryMembers = new Set<Id>();
        Set<Id> bookedByContactIds = new Set<Id>();
        Set<Id> mappingJourneyIds =  new Set<Id>();
        Set<Id> mappingContactIds =  new Set<Id>();
        List<ServiceAppointment> toursForRestartJourney = new List<ServiceAppointment>();
        for (ServiceAppointment tour : newTours) {
            ServiceAppointment oldTour = oldToursMap.get(tour.Id);
            if ( (tour.No_Follow_Up__c != true) && String.isNotBlank(tour.ContactId) && String.isNotBlank(tour.Status) 
                    && !setTourStatuses.contains(oldTour.Status) && setTourStatuses.contains(tour.Status) ) {    
                tourPrimaryMembers.add(tour.ContactId);
                bookedByContactIds.add(tour.CreatedById);
                toursForRestartJourney.add(tour);
                locationIds.add(tour.Building_Id__c);
                if (String.isNotBlank(tour.Journey_Id__c)) {
                    mappingJourneyIds.add(tour.Journey_Id__c);
                } else {
                    mappingContactIds.add(tour.ContactId); 
                }
            }
        }
        if (toursForRestartJourney.isEmpty()) {
            return;
        }
        Map<Id, Id> tourIdToOwnerId = getTourJourneyOwners(toursForRestartJourney, bookedByContactIds, tourPrimaryMembers, locationIds, mappingJourneyIds);
        Map<Id, sObject> contactIdToJourney;
        Map<Id, sObject> journeyIdToJourney;
        if (!mappingContactIds.isEmpty()) {
            contactIdToJourney = getJourneysToRestart(mappingContactIds, 'Contact');
        }
        if (!mappingJourneyIds.isEmpty()) {
            journeyIdToJourney = getJourneysToRestart(mappingJourneyIds, 'Journey');
        }
        List<Journey__c> journeysToInsert = createJourneysToInsert(toursForRestartJourney, tourIdToOwnerId, contactIdToJourney, journeyIdToJourney);
        if (!journeysToInsert.isEmpty()) {
            insert journeysToInsert;
        }
    }

    private List<Journey__c> createJourneysToInsert(List<ServiceAppointment> toursForRestartJourney, Map<Id, Id> tourIdToOwnerId, Map<Id, sObject> contactIdToJourney, Map<Id, sObject> journeyIdToJourney) {
        List<Journey__c> journeysToInsert = new List<Journey__c>();
        for (ServiceAppointment tour : toursForRestartJourney) {
            Contact tourPrimaryMember = contactIdToContact.get(tour.ContactId);
            Journey__c journey = String.isNotBlank(tour.Journey_Id__c) ? (Journey__c) (journeyIdToJourney.get(tour.Journey_Id__c)).clone(false, true, false, false)
                                 : (Journey__c) (contactIdToJourney.get(tour.ContactId)).clone(false, true, false, false);
            String journeyName = tourPrimaryMember.Name + ((String.isNotBlank(tour.Building_Id__c)
                                 && String.isNotBlank(BuildingUtility.getBuildingById(tour.Building_Id__c).City__c)) ? '-' + BuildingUtility.getBuildingById(tour.Building_Id__c).City__c : '')
                                    + (String.isNotBlank(tourPrimaryMember.LeadSource) ? '-' + tourPrimaryMember.LeadSource : '');
            journey.Name = journeyName.abbreviate(80);
            journey.Primary_Contact__c = tour.ContactId;
            journey.NMD_Next_Contact_Date__c = System.today();
            journey.OwnerId = tourIdToOwnerId.get(tour.Id);
            journey.Status__c = journey.OwnerId.getSObjectType() == User.SObjectType ? GlobalConstants.JOURNEY_STATUS_ACCEPTED : GlobalConstants.JOURNEY_STATUS_MQL;
            journey.Restart_Journey_Reason__c = tour.Status;
            if (String.isNotBlank(tour.Journey_Id__c)) {
                journey.Original_Journey__c = tour.Journey_Id__c;   
            }
            if (journey.Restart_Journey_Reason__c == GlobalConstants.TOUR_CANCELLED) {
                journey.Marketing_Suppression_Reason__c = GlobalConstants.TOUR_REASON_CANCELLED;
            } else if (journey.Restart_Journey_Reason__c == GlobalConstants.TOUR_NO_SHOW) {
                journey.Marketing_Suppression_Reason__c = GlobalConstants.TOUR_REASON_NO_SHOW;
            }
            journey.Building_Interested_In__c = tour.Building_Id__c;
            Set<String> locationsInterested = new Set<String>();
            if (tour.Building_Id__c != null) {
                locationsInterested.add(BuildingUtility.getBuildingById(tour.Building_Id__c).Name);   
            }
            journeysToInsert.add(journey);
        }
        return journeysToInsert;
    }

    private Map<Id, sObject> getJourneysToRestart(Set<Id> tourPrimaryMembers, String mappingObject) {
        return mappingObject == 'Contact' ? FieldMappingsHelper.getMappings(tourPrimaryMembers, 'FieldMappings_ContactToJourney') : FieldMappingsHelper.getMappings(tourPrimaryMembers, 'FieldMappings_JourneyToJourney');
    }

    private Map<Id, Id> getTourJourneyOwners(List<ServiceAppointment> toursForRestartJourney, Set<Id> bookedByContactIds, Set<Id> tourPrimaryMembers, Set<Id> locationIds, Set<Id> journeyIds){
        Id unassignedNMDUserQueueId = getUnassignedNMDUserQueueId();
        contactsWithJourneys = getContactsWithJourneys(bookedByContactIds, tourPrimaryMembers, journeyIds);
        Map<Id, Id> bookedByContactIdToUserId = getBookedByContactIdRelatedUsers(bookedByContactIds, tourPrimaryMembers);
        Map<Id, Id> originalJourneyOwners = new Map<Id, Id>();
        Map<Id, Id> relatedJourneyOwners = getOriginalJourneyOwners(toursForRestartJourney, originalJourneyOwners);
        Map<Id, Id> tourIdToJourneyOwner = new Map<Id, Id>();
        for (ServiceAppointment tour : toursForRestartJourney) {
            Id journeyOwnerId;
            if (tour.Journey_Id__c != null) {
                if (bookedByContactIdToUserId.containsKey(tour.CreatedById) && bookedByContactIdToUserId.get(tour.CreatedById) != null) {
                    journeyOwnerId = bookedByContactIdToUserId.get(tour.CreatedById);
                } else if (tour.Journey_Id__c != null && originalJourneyOwners.containsKey(tour.Id)) {
                    journeyOwnerId = originalJourneyOwners.get(tour.Id);
                }
            } else if (relatedJourneyOwners.containsKey(tour.Id)) {
                journeyOwnerId = relatedJourneyOwners.get(tour.Id);
            }
            if (journeyOwnerId == null) {
                journeyOwnerId = unassignedNMDUserQueueId;
            }
            tourIdToJourneyOwner.put(tour.Id, journeyOwnerId);
        }
        return tourIdToJourneyOwner;
    }

    private Map<Id, Id> getBookedByContactIdRelatedUsers(Set<Id> bookedByContactIds, Set<Id> tourPrimaryMembers) {
        Map<Id, Id> bookedByContactIdToUserId = new Map<Id, Id>();
        Id apiUserContactId = getAPIUserContactId();
        Set<Id> profileIds = getNMDProfileIds();
        contactIdToContact = new Map<Id, Contact>();
        for (Contact contact : contactsWithJourneys.values()) {
            if (tourPrimaryMembers.contains(contact.Id)) {
                contactIdToContact.put(contact.Id, contact);
            }
            User usr = UserUtility.getUserByEmail(contact.Email);
            if (usr != null && contact.Id != apiUserContactId && profileIds.contains(usr.ProfileId)) {
                bookedByContactIdToUserId.put(contact.Id, usr.Id);
            }
        }
        return bookedByContactIdToUserId;
    }
    
    private Map<Id, Id> getOriginalJourneyOwners(List<ServiceAppointment> toursForRestartJourney, Map<Id, Id> originalJourneyOwners) {
        Map<Id, Id> relatedJourneyOwners = new Map<Id, Id>();
        if (contactsWithJourneys.isEmpty()) {
            return relatedJourneyOwners;
        }
        for (ServiceAppointment tour : toursForRestartJourney) {
            List<Journey__c> journeys = contactsWithJourneys.get(tour.ContactId)?.Journeys__r;
            if (journeys.isEmpty()) {
                continue;
            }
            Journey__c originalJourney = new Map<Id, Journey__c>(journeys).get(tour.Journey_Id__c);
            if (originalJourney != null) {
                originalJourneyOwners.put(tour.Id, originalJourney.OwnerId);
                continue;
            }
            for (Journey__c journey : journeys) {
                if (journey.Building_Interested_In__c == tour.Building_Id__c) {
                    relatedJourneyOwners.put(tour.Id, journey.OwnerId);
                    break;
                }
            }
        }
        return relatedJourneyOwners;
    }
    
    private Id getAPIUserContactId() {
        //TODO: will soon be changed, most likely to ApiUsersUtils.apiUser.ContactId
        Sales_Console_Setting__mdt apiUserSetting = Settings.get('APIUserContactInfo');
        if (apiUserSetting != null) {
            Map<String, String> keyToSetting = new Map<String, String>();
            keyToSetting = (Map<String, String>) JSON.deserialize(apiUserSetting.Data__c, Map<String, String>.class);
            if (!keyToSetting.isEmpty() && keyToSetting.containsKey('ContactId')){
                return keyToSetting.get('ContactId');
            }
        }
        return null;
    }

    public Id getUnassignedNMDUserQueueId() {
        MetadataSetting__mdt unassignedNmdUsQueueSetting = Settings.getMetadataSetting('Unassigned_NMD_US_Queue');
        if (unassignedNmdUsQueueSetting != null && String.isNotBlank(unassignedNmdUsQueueSetting.Data__c)) {
            return Id.valueOf(unassignedNmdUsQueueSetting.Data__c);
        }
        return UserInfo.getUserId();
    }

    private Set<Id> getNMDProfileIds() {
        Set<Id> allowedProfiles = new Set<Id>();
        allowedProfiles.add(Validation_Rule_Restriction__mdt.getInstance('WeWork_NMD_Admin').Salesforce_Id__c);
        allowedProfiles.add(Validation_Rule_Restriction__mdt.getInstance('WeWork_Inside_Sales').Salesforce_Id__c);
        allowedProfiles.add(Validation_Rule_Restriction__mdt.getInstance('WeWork_NMD_User_Outbound').Salesforce_Id__c);
        allowedProfiles.add(Validation_Rule_Restriction__mdt.getInstance('WeWork_System_Administrator').Salesforce_Id__c);
        return allowedProfiles;
    }
    
    private Map<Id, Contact> getContactsWithJourneys(Set<Id> bookedByContactIds, Set<Id> primaryMembersIds, Set<Id> journeyIds) {
        return new Map<Id, Contact>(
            [SELECT Id, Name, Email, LeadSource,
                    (SELECT Id, OwnerId, Building_Interested_In__c
                     FROM Journeys__r
                     WHERE Owner.IsActive = TRUE AND (Id IN :journeyIds OR Status__c NOT IN (:GlobalConstants.JOURNEY_STATUS_CONVERTED, :GlobalConstants.JOURNEY_STATUS_DEFERRED))
                     ORDER BY LastModifiedDate DESC)
             FROM Contact WHERE Id IN :bookedByContactIds OR Id IN :primaryMembersIds]
        );
    }
}