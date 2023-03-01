/************************************************************************************************************************************
    Author : Salesforce
    Description : This class is used to populate scheduled start time in service appointment
   ----------------------------------------------------------------------------------------------------------------------------------
    VERSION		DATE			AUTHOR		DETAIL                          ISSUE
    1	      		24 Aug, 2021		Salesforce      Initial Developement		TWSPG-2494
**************************************************************************************************************************************/
public with sharing class ServiceAppointmentTriggerHandler extends SObjectTriggerHandler {
    @TestVisible
    private List<ServiceAppointment> newServiceAppointments;
    
    @TestVisible
    private Map<Id, ServiceAppointment> oldAppointmentsMap;
    
    @TestVisible
    private Map<Id, ServiceAppointment> newAppointmentsMap;
    private BuildingSelector buildSelector = new BuildingSelector();
    
    
    public ServiceAppointmentTriggerHandler() {
        this((List<ServiceAppointment>) Trigger.new, (Map<Id, ServiceAppointment>) Trigger.newMap, (Map<Id, ServiceAppointment>) Trigger.oldMap);        
    }
    
    @TestVisible
    private ServiceAppointmentTriggerHandler(List<ServiceAppointment> newServiceAppointments, 
                                                Map<Id, ServiceAppointment> newAppointmentsMap,
                                                Map<Id, ServiceAppointment> oldAppointmentsMap) {
        this.newServiceAppointments = newServiceAppointments;
        this.newAppointmentsMap = newAppointmentsMap;
        this.oldAppointmentsMap = oldAppointmentsMap;
    }
    public override void beforeInsert() {
        populateScheduledStartTime((List<serviceAppointment>)newServiceAppointments);

      }
    public override void beforeUpdate() {
        populateScheduledStartTime((List<serviceAppointment>)newServiceAppointments);

   }
     public override void afterUpdate() {
         if(Test.isRunningTest()|| System.isBatch()){
            countServiceAppointments(JSON.serialize((List<ServiceAppointment>)newServiceAppointments));
        }else{
            callCountSerAppointment(JSON.serialize((List<ServiceAppointment>)newServiceAppointments)); 
        }  
      
    }

    public override void afterInsert() {
         if(Test.isRunningTest()|| System.isBatch()){
            countServiceAppointments(JSON.serialize((List<ServiceAppointment>)newServiceAppointments));
            
        } else {
            callCountSerAppointment(JSON.serialize((List<ServiceAppointment>)newServiceAppointments)); 
        }   

    }
   private void populateScheduledStartTime(List<serviceAppointment> serviceAppointments){
       Set<Id> buildingIds= new Set<Id>();
        for(serviceAppointment servappointment:serviceAppointments){
            buildingIds.add(servappointment.Building_Id__c);
           
         }
         if(buildingIds.isEmpty()){
             return;
         }
        
        Map<Id,Building__c> buildingIdToBuilding = new  Map<Id,Building__c>(buildSelector.getBuildingsWithTimeZoneByIds(buildingIds));
   
        for(serviceAppointment servappointment:serviceAppointments){
            if(buildingIdToBuilding.containsKey(servappointment.Building_Id__c)){
                servappointment.Scheduled_Start_Time__c = servappointment.SchedStartTime.format('h:mm a', buildingIdToBuilding.get(servappointment.Building_Id__c).Time_Zone__c);
                if (servappointment.SchedEndTime != null) {
                    servappointment.Scheduled_End_Time__c = servappointment.SchedEndTime.format('h:mm a', buildingIdToBuilding.get(servappointment.Building_Id__c).Time_Zone__c);
                }
            }
        }
        }
        
    

    /************************************************************************************************************************************
        Author              : Salesforce
        Description         : This method is used for call Count Tour
        Last Modified Date  : 24 August 2021.
        Last Modified By    : Salesforce
    ********************************************************************************************************************************/
    private static void callCountSerAppointment(string triggerServiceAppointmentlst){
        if(System.isFuture()) {
            callCountServAppointmentNoFuture(triggerServiceAppointmentlst);
        } else {
            callCountServAppointmentFuture(triggerServiceAppointmentlst);
        }
    }

    @future
    private static void callCountServAppointmentFuture(String triggerServiceAppointmentlst){
        ServiceAppointmentTriggerHandler.countServiceAppointments(triggerServiceAppointmentlst);
    }

    private static void callCountServAppointmentNoFuture(String triggerServiceAppointmentlst){
        ServiceAppointmentTriggerHandler.countServiceAppointments(triggerServiceAppointmentlst);
    }

    /**
     * Update count of service appointments on contact and change status of journey.
     * 
     */
    private static void countServiceAppointments(String triggerServiceAppointmentlst){
        Set<Id> primaryContacts = new Set<Id>();
        List<ServiceAppointment> triggerServiceAppointments = (List<ServiceAppointment>)JSON.deserialize(triggerServiceAppointmentlst, List<ServiceAppointment>.class); 
        for(ServiceAppointment servapp : triggerServiceAppointments){
            if(servapp.contactid != null){
                primaryContacts.add(servapp.contactid);
            }    
        }    
        if(primaryContacts.isEmpty()){
            return;            
        }
        List<Contact> contactsToBeUpdated = new List<Contact>();
        Integer countScheduledServiceAppointments;
        Integer countCompletedServiceAppointments;
        Integer countOtherServiceAppointments;
        for(Contact conrec : [SELECT Id, Name, (SELECT Id, Status FROM ServiceAppointments) 
                              FROM Contact Where Id IN : primaryContacts]){
            
            countScheduledServiceAppointments = 0;
            countCompletedServiceAppointments = 0;
            countOtherServiceAppointments = 0;
            for(ServiceAppointment servapp : conRec.ServiceAppointments){
                if(servapp.Status == 'Scheduled'){
                    countScheduledServiceAppointments += 1;
                }else if(servapp.Status == 'Completed'){
                    countCompletedServiceAppointments += 1;
                }else{
                    countOtherServiceAppointments += 1;
                }
            }
            contactsToBeUpdated.add(new Contact(Id = conRec.Id,Total_Scheduled_Tours__c = countScheduledServiceAppointments, Total_Completed_Tours__c = countCompletedServiceAppointments, Other_Tours_Count__c = countOtherServiceAppointments));
        }
        if(!contactsToBeUpdated.isEmpty()){
            update contactsToBeUpdated;
        }   
    }
    
}