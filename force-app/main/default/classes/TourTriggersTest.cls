/************************************************************************************************************************************
Author      :   Shobhit Gahlot
Description :   This class will contain test methods of Geography triggers.
History:
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE              AUTHOR                  DETAIL
1.0         06 Feb 2020       Shobhit Gahlot        Modification according to new test structure
*************************************************************************************************************************************/
@isTest
public class TourTriggersTest {
    private static TaskSelector taskSelector = new TaskSelector();

    @TestSetup
    static void initData(){
        Account acc = new Account();
        acc.Name = 'Test John';
        insert acc;
        Map<String, Object> mapContactFieldValues = new Map<String, Object>();
        List<Contact> lstContacts = new List<Contact>();
        mapContactFieldValues.put('firstname', 'test');
        mapContactFieldValues.put('lastname', 'Contact');
        mapContactFieldValues.put('AccountId', acc.Id);
        mapContactFieldValues.put('email', 'joinus@wework.com');
        mapContactFieldValues.put('Status__c', 'active');
        mapContactFieldValues.put('UUID__c', 'UUID1');
        lstContacts.add((Contact)TestingUtility.createTestRecords(Contact.sObjectType,mapContactFieldValues,false));
        mapContactFieldValues.put('firstname', 'test');
        mapContactFieldValues.put('lastname', 'Contact1');
        mapContactFieldValues.put('email', 'testUser@wework.com');
        mapContactFieldValues.put('Status__c', 'active');
        mapContactFieldValues.put('UUID__c', 'UUID2');
        lstContacts.add((Contact)TestingUtility.createTestRecords(Contact.sObjectType, mapContactFieldValues, false));
        TestingUtility.insertListWithAssert(lstContacts);
        ServiceAppointment appointment = new ServiceAppointment();
        appointment.ContactId = lstContacts[0].Id;
        appointment.ParentRecordId = acc.Id;
        appointment.Status = 'Scheduled';
        appointment.SchedStartTime = system.today().addDays(3);
        appointment.Tour_Outcome__c = 'Tour Interested';
        appointment.Target_Move_In_Date__c = system.today().addDays(4);
        appointment.Product_Interests__c = 'Dedicated Desk;Hot Desk';
        appointment.Tour_Outcome_Notes__c = 'Test Notes';
        appointment.Objections__c = 'Too Expensive;Other';
        insert appointment;
        String appId = appointment.Id;
        ServiceAppointment appointment1 = [SELECT Id,Status,No_Follow_Up__c FROM ServiceAppointment WHERE Id=:appId];
        TestingUtility.getRecords(new Map<String, Object>{'objName'=>'Referral', 'numberOfRecords'=>3});
        TestingUtility.getRecords(new Map<String, Object>{'objName'=>'Reservable', 'numberOfRecords'=>5});
        Test.startTest();
        TestingUtility.getRecords(new Map<String, Object>{'objName'=>'Task', 'numberOfRecords'=>3});
        List<SObject> toursAndOpportunities = new List<SObject>();
        toursAndOpportunities.add(appointment);
        List<Contact> contacts = [SELECT Id, Name, Email FROM Contact LIMIT 5];
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'WeWork System Administrator'];
        Map<String, Object> usersData = new Map<String, Object>();
        usersData.put('LastName','testweworkuser1');
        usersData.put('Username','wework'+TestingUtility.createStringValue()+'@example.com');
        usersData.put('Email', contacts[0].Email);
        usersData.put('IsActive', true);
        User insertedUser = TestingUtility.insertUserWithAssert(profiles[0].Id, usersData, true);
        UserUtility.refreshUsers();
        List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
        List<ServiceAppointment> toursToInsert = new List<ServiceAppointment>();
        for(SObject singleRecord : toursAndOpportunities){
            if(String.valueOf(singleRecord.getSObjectType()).toLowerCase() == 'opportunity'){
                opportunitiesToInsert.add((Opportunity)singleRecord);
            }else{
                toursToInsert.add((ServiceAppointment)singleRecord);
            }
        }
        System.assert(!toursToInsert.isEmpty(), 'List of tours to insert should not be empty.');
        Integer count = 0;
        for(Opportunity opportunityRecord: opportunitiesToInsert){
            opportunityRecord.Assignment_Status__c = 'Completed';
            if(count == 0){
                opportunityRecord.OwnerId = insertedUser.Id;
            }
            count++;
        }
        TestingUtility.insertListWithAssert(opportunitiesToInsert);
        checkSOQLLimitassert('initData');
        
        for(count = 0; count < opportunitiesToInsert.size(); count++){
            toursToInsert[count].Opportunity_Id__c = opportunitiesToInsert[count].Id;
            setTourDate(null, toursToInsert[count], count);
        }
        ReferenceHandler.clearAlreadyQueriedEmailsForTest();
        Test.stopTest();
    }
    
    @isTest
    public static void tourTriggerHandlerTestNewstructure1() {
        Map<String, ServiceAppointment> toursByUuids = new Map<String, ServiceAppointment>();
        List<ServiceAppointment> insertedTours = getTourRecords(toursByUuids);
        Map<String, ServiceAppointment> toursForUpdate = new Map<String, ServiceAppointment>();
        Test.startTest();
        TestManager.handleTestProcess('ServiceAppointment', insertedTours, null, 'tourTriggerHandlerTestNewstructure1', TestManager.insertAssertEvent);
        TestManager.handleTestProcess('ServiceAppointment', insertedTours, toursForUpdate, 'tourTriggerHandlerTestNewstructure1', TestManager.updateValuesEvent);
        if(!toursForUpdate.values().isEmpty()) {
            update toursForUpdate.values();
        }
        TestManager.handleTestProcess('ServiceAppointment', getTourRecords(toursByUuids), null, 'tourTriggerHandlerTestNewstructure1', TestManager.updateAssertEvent);
        Test.stopTest();
    }
    
    @TestVisible
    static List<ServiceAppointment> getTourRecords(Map<String, ServiceAppointment> toursByUuids){
        for(ServiceAppointment tourRecord : (List<ServiceAppointment>)Database.query('SELECT '+String.join(getTourFields(),',')+' FROM ServiceAppointment')){
            toursByUuids.put(tourRecord.Id, tourRecord);
        }
        return toursByUuids.values().deepClone(true, true, true);
    }
    
    static List<String> getTourFields(){
        Set<String> tourFields = new Set<String>();
        tourFields.add('Id');
        tourFields.add('Status');
        tourFields.add('Opportunity_Id__r.Primary_Member__r.Email');
        tourFields.add('Building_Id__r.Email__c');
        tourFields.add('Building_Id__c');
        tourFields.add('SchedStartTime');
        tourFields.add('ContactId');
        tourFields.add('SchedStartTime');
        tourFields.add('SchedEndTime');
        tourFields.add('Referrer_Id__c');
        tourFields.add('Opportunity_Id__r.AccountId');
        tourFields.add('Journey_Id__c');
        tourFields.add('OwnerId');
        tourFields.add('Product_Interests__c');
        tourFields.add('Is_Decision_Maker__c');
        tourFields.add('CreatedById');
        return new List<String>(tourFields);
    }
    
    static void checkSOQLLimitassert(String methodWithLimitException){
        Integer SOQLLimit = 95;
        System.assert(Limits.getQueries() <= SOQLLimit, methodWithLimitException+ ' has reached SOQL Limit set at '+SOQLLimit+'. Reduce the no. of scenarios tested in each test method.');    
    }
    
    static void restartTour(ServiceAppointment tourToUpdate) {
        if(tourToUpdate != null){
            tourToUpdate.Status = 'No Show';
        }
    }
    
    //This method is dependent on setTourCompletedDate and status is updated to Completed
    static void setTourDate(ServiceAppointment tourRecord, ServiceAppointment tourToUpdate, Integer count){
        if(tourRecord != null){
            System.assert(tourRecord.Status == 'No Show' || tourRecord.Status == 'Cancelled' || tourRecord.Status == 'Completed' || tourRecord.Status == 'Scheduled', 'Wrong tour status.');
            if(tourRecord.Status == 'No Show' || tourRecord.Status == 'Completed'){
                System.assertEquals(System.today(), tourRecord.SchedStartTime);
            } 
        }  
        if(tourToUpdate == null) {
            return;
        }
        if (count == 1 || count == 2) {
            tourToUpdate.Status = 'Scheduled';
        } else if (count == 0) {
            tourToUpdate.Status = 'Completed';
        }
        tourToUpdate.SchedStartTime = null;
    }
  
}