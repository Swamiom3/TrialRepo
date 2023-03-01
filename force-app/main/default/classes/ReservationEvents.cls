/************************************************************************************************************************************
Author      :   Tayo Chestnut
Description :   This apex class create JSON for Workday Platform Events
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION      DATE         AUTHOR              DETAIL
    1            09/28/2021   Tayo Chestnut     Execute from Flow
**************************************************************************************************************************************/
public with sharing class ReservationEvents {
	
    @InvocableMethod (label='JSON Reservation Lines' description='JSON Listing of Child Lines' category='Spaceman')
    public static void publishSpacemanReservations(List<Request> requests) {
        String outputJSON;
        List<Reservations__e> reservationEvents = new List<Reservations__e>();
        List<Database.SaveResult> results = new List<Database.SaveResult>();
        List<Apex_Debug_Log__c> apexLogs = new List<Apex_Debug_Log__c>();
        
        for(Request req: requests){
            outputJSON = JSON.serialize(req.reservations);
            if(req.reservations.isEmpty()){
                reservationEvents.add(new Reservations__e(Details__c = outputJSON));
            }else{
                reservationEvents.add(new Reservations__e(Details__c = outputJSON, is_Valid__c = 'Valid'));
            }
            
        }

        results = EventBus.publish(reservationEvents);

        for (Database.SaveResult sr : results) {    
            if (!sr.isSuccess()) {
                for(Database.Error err : sr.getErrors()) {
                    Apex_Debug_Log__c newLog = new Apex_Debug_Log__c();
                    newLog.Affected_User__c = UserInfo.getUserId();
                    newLog.Estimated_Fix__c = 'Data Issue';
                    newLog.Type__c = 'Error';
                    newLog.Message__c = 'Reservation Error: ' + err.getStatusCode() + ': ' + err.getMessage();
                    newLog.Status__c = 'Open';
                    apexLogs.add(newLog);          
                }
            }    
        }

        if(!apexLogs.isEmpty()){
            insert apexLogs;
        }
    }

    public class Request{
        @InvocableVariable
        public List<SpacemanReservations> reservations;
        
    }
}