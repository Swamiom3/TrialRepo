/************************************************************************************************************************************
Author         :    Mikolaj Juras
Description    :    AsyncTourSetWorldTour class to set world Tour Checkbox ST-8267
                    When more than 1 tour is booked for a PNM in the same Market, we need to flag the original tour and future tours as 'World Tour'
History        :
----------------------------------------------------------------------------------------------------------------------------------
VERSION        DATE                AUTHOR                    DETAIL
1            12 May 2021         Mikolaj Juras             Initial Development     
**************************************************************************************************************************************/
public with sharing class AsyncTourSetWorldTour implements Queueable {
    
    @TestVisible 
    Set<String> portfolioNames;
    @TestVisible 
    Set<Id> contactIds;
    @TestVisible
    private static ServiceAppointmentSelector servAppSelector = new ServiceAppointmentSelector();
            
    @TestVisible 
    private AsyncTourSetWorldTour(Set<String> portfolioNames, Set<Id> contactIds) {
        this.portfolioNames = portfolioNames;
        this.contactIds = contactIds;
    }

    public static void checkWorldTourFlag(Set<String> portfolioNames, Set<Id> contactIds){
        if(System.isFuture() || System.isBatch()) {
            setWorldTourFlag(portfolioNames, contactIds);
            return;
        }
        if(System.isQueueable() || Test.isRunningTest()) {
            setWorldTourFuture(portfolioNames, contactIds);
            return;
        }
        setWorldTourQueueable(portfolioNames, contactIds);
    }

    public void execute(QueueableContext context){
        List<ServiceAppointment> toursToUpdate = getServiceAppointmentsToUpdate(portfolioNames, contactIds);
        updateTourWithoutTrigger(toursToUpdate);
    }

    public static void setWorldTourFlag(Set<String> portfolioNames, Set<Id> contactIds) {
        List<ServiceAppointment> toursToUpdate = getServiceAppointmentsToUpdate(portfolioNames, contactIds);
        updateTourWithoutTrigger(toursToUpdate);
    }

    @future
    public static void setWorldTourFuture(Set<String> portfolioNames, Set<Id> contactIds) {
        setWorldTourFlag(portfolioNames, contactIds);
    }

    @TestVisible 
    private static void setWorldTourQueueable (Set<String> portfolioNames, Set<Id> contactIds) {
        System.enqueueJob(new AsyncTourSetWorldTour(portfolioNames, contactIds));
    }

    @TestVisible 
    private static Map <String, Set<Id>> buildPortfolioNamePrimaryMemberIdKeyTourIdsMap(Set<String> portfolioNames, Set<Id> contactIds) {
        Map <String, Set<Id>> portfolioNamePrimaryMemberIdKeyServiceAppointmentsIds = new Map <String, Set<Id>>();
        for (ServiceAppointment tour : servAppSelector.getServiceAppForContactsAndPortfoliosFilteredByWhere( portfolioNames, contactIds)) {
            String currentKey = tour.Portfolio_Name__c 
                                + tour.ContactId 
                                + tour.CreatedDate.year()
                                + tour.CreatedDate.month()
                                + tour.CreatedDate.day();
            if (portfolioNamePrimaryMemberIdKeyServiceAppointmentsIds.containsKey(currentKey)) {
                portfolioNamePrimaryMemberIdKeyServiceAppointmentsIds.get(currentKey).add(tour.Id);
            } else {
                portfolioNamePrimaryMemberIdKeyServiceAppointmentsIds.put(currentKey, new Set<Id>(new List<Id>{tour.Id}));
            }
        }
        return portfolioNamePrimaryMemberIdKeyServiceAppointmentsIds;
    }

    @TestVisible 
    private static List<ServiceAppointment> getServiceAppointmentsToUpdate(Set<String> portfolioNames, Set<Id> contactIds) {
        Map <String, Set<Id>> portfolioNamePrimaryMemberIdKeyServiceAppointmentsIds = buildPortfolioNamePrimaryMemberIdKeyTourIdsMap(portfolioNames, contactIds);
        List<ServiceAppointment> toursToSetFlag = new List<ServiceAppointment>();
        for (Set<Id> serviceAppointmentIds : portfolioNamePrimaryMemberIdKeyServiceAppointmentsIds.values()) {
            //if there is more that 1 record in set - the World Tour flag need to be set
            if (serviceAppointmentIds.size() > 1) {
                for (Id serviceAppointmentId : serviceAppointmentIds) {
                    ServiceAppointment newTour = new ServiceAppointment (Id = serviceAppointmentId, World_Tour__c = true);
                    toursToSetFlag.add(newTour);
                }
            }
        }
        return toursToSetFlag;
    }

    @TestVisible 
    private static void updateTourWithoutTrigger(List<ServiceAppointment> toursToUpdate) {
        MetadataDrivenTriggerHandler.disableExecution();
        try {
            update toursToUpdate;
        } catch(Exception e){
            ApexDebugLog.logException(e, JSON.serialize(toursToUpdate), 'AsyncTourSetWorldTour', 'async');
            throw new AsyncTourSetWorldException('AsyncTourSetWorldTour record update fail');
        }
        MetadataDrivenTriggerHandler.enableExecution();
    }

    private class AsyncTourSetWorldException extends Exception {}
}