/*********************************************************************************************************
    Author        :  Shobhit Gahlot
    Description   :  If a journey is created on a Friday then the NMD next contact date should be the 
                     monday following.
    Issue No.     :  ST-8957
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1          09-Sept-2021      Shobhit Gahlot     Trigger Refactor
**********************************************************************************************************/
public class JourneyWeekendCadenceTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Journey__c> newJourneys;
    @TestVisible
    private Map<Id, Journey__c> newJourneysMap;
    @TestVisible
    Map<String,BusinessHours> businessHoursMap = new Map<String,BusinessHours>();
    @TestVisible
    Map<Id,Id> groupUserIdsMap = new Map<Id,Id>();
    @TestVisible    
    Map<Id,User> usersMap = new Map<Id,User>();
    @TestVisible
    List<Journey__c> journeysToUpdate = new List<Journey__c>();
    @TestVisible
    private static UserSelector userSelector = new UserSelector();
    @TestVisible
    private JourneySelector journeySelector = new JourneySelector();
    
    public JourneyWeekendCadenceTrH(){
        this((List<Journey__c>) Trigger.new, (Map<Id, Journey__c>) Trigger.newMap);
    }
    
    @TestVisible
    private JourneyWeekendCadenceTrH(List<Journey__c> newJourneys, Map<Id, Journey__c> newJourneysMap){
        this.newJourneys = newJourneys;
        this.newJourneysMap = newJourneysMap;
    }

    @TestVisible
    private void weekendCadence() {
        Set<Id> userIds = new Set<Id>();
        Set<Id> queueIds = new Set<Id>();
        prepareBusinessHoursMap();
        List<String> fields = new List<String>{'Id', 'Name', 'NMD_Next_Contact_Date__c', 'CreatedDate', 'OwnerId'};
        List<Journey__c> journeys = journeySelector.getJourneysByIds(fields, new List<Id>(newJourneysMap.keySet()));
        for (Journey__c journey : journeys) {
            if(journey.OwnerId.getSObjectType() == Group.getSObjectType()){
                queueIds.add(journey.OwnerId);
            }else{
                userIds.add(journey.OwnerId);
            }
        }
        if(!userIds.isEmpty()){
            populateUsersMapForUsersIds(userIds);
        }
        if(!queueIds.isEmpty()){
            Set<Id> groupMemberIds = new Set<Id>();
            for(GroupMember groupMember : [SELECT UserOrGroupId, GroupId FROM GroupMember WHERE GroupId IN : queueIds]){
                groupMemberIds.add(groupMember.UserOrGroupId);
                if(!groupUserIdsMap.containsKey(groupMember.GroupId)){
                    groupUserIdsMap.put(groupMember.GroupId, groupMember.UserOrGroupId);
                }
            }
            populateUsersMapForUsersIds(groupMemberIds);
        }
        for(Journey__c journey : journeys){
            if(journey.OwnerId.getSObjectType() != Group.getSObjectType()){
                String businessHoursZone = 'WeWork_'+ usersMap.get(journey.OwnerId).TimeZoneSidKey +'_Business_Hours';
                if(businessHoursMap.containsKey(businessHoursZone)){
                    Timezone timezones = Timezone.getTimeZone(usersMap.get(journey.OwnerId).TimeZoneSidKey);
                    if(!BusinessHours.isWithin(businessHoursMap.get(businessHoursZone).Id, journey.CreatedDate)){
                        getNextContactDate(businessHoursZone, timezones, journey, 'User');
                    }else{
                        getNextContactDate(businessHoursZone, timezones, journey, 'User');
                    }
                }
            }else{
                TimeZone userTmZone = UserInfo.getTimeZone();
                String businessHoursZone ='';
                if(groupUserIdsMap.containsKey(journey.OwnerId) && usersMap.get(groupUserIdsMap.get(journey.OwnerId)) != null){
                    businessHoursZone = 'WeWork_'+ usersMap.get(groupUserIdsMap.get(journey.OwnerId)).TimeZoneSidKey +'_Business_Hours';
                }else{
                    businessHoursZone = 'WeWork_'+ userTmZone.getID() +'_Business_Hours';
                }
                if(businessHoursMap.containsKey(businessHoursZone)){
                    Timezone timez;
                    if(groupUserIdsMap.containsKey(journey.OwnerId) && usersMap.get(groupUserIdsMap.get(journey.OwnerId)) != null){
                        timez = Timezone.getTimeZone(usersMap.get(groupUserIdsMap.get(journey.OwnerId)).TimeZoneSidKey);
                    }else {
                        timez = userTmZone;
                    }
                    if(!BusinessHours.isWithin(businessHoursMap.get(businessHoursZone).Id, journey.CreatedDate)){
                        getNextContactDate(businessHoursZone, timez, journey, 'Group');
                    }else{
                        getNextContactDate(businessHoursZone, timez, journey, 'Group');
                    }
                }
            }
        }
        updateJourneysAvoidingRecursion();
    }

    @TestVisible
    private void updateJourneysAvoidingRecursion(){
        if(journeysToUpdate.isEmpty()){
            return;
        }
        AvoidRecurssion.isExecute = true;
        update journeysToUpdate;
    }

    @TestVisible
    private void populateUsersMapForUsersIds(Set<Id> usersIds){
        for(User userRecord : userSelector.getUsersById(usersIds)){
            if(!usersMap.containsKey(userRecord.Id)){
                usersMap.put(userRecord.Id, userRecord);
            }
        }
    }

    @TestVisible
    private void prepareBusinessHoursMap(){
        for(BusinessHours businessHours:[SELECT Id, Name FROM BusinessHours]){
            if(!businessHoursMap.containsKey(businessHours.Name)){
                businessHoursMap.put(businessHours.Name, businessHours);
            }
        }
    }

    @TestVisible
    private void getNextContactDate(String businessHoursZone, Timezone tz, Journey__c journey, String Owner){
        TimeZone userTmZone = UserInfo.getTimeZone();
        DateTime nextStartDateTime = BusinessHours.nextStartDate(businessHoursMap.get(businessHoursZone).Id, journey.CreatedDate);

        DateTime localDate = nextStartDateTime.addMinutes(tz.getOffset(nextStartDateTime) / (60 * 1000));
        if(Owner == 'User'){
            journey.NMD_Next_Contact_Date__c = date.valueOf(nextStartDateTime.format('yyyy-MM-dd', usersMap.get(journey.OwnerId).TimeZoneSidKey));
        }else if(Owner == 'Group'){
        	journey.NMD_Next_Contact_Date__c = ((groupUserIdsMap.containsKey(journey.OwnerId) && usersMap.get(groupUserIdsMap.get(journey.OwnerId)) != null) ? date.valueOf(nextStartDateTime.format('yyyy-MM-dd', usersMap.get(groupUserIdsMap.get(journey.OwnerId)).TimeZoneSidKey)) : date.valueOf(nextStartDateTime.format('yyyy-MM-dd', userTmZone.getID())));
        }
        journeysToUpdate.add(journey);
    }
}