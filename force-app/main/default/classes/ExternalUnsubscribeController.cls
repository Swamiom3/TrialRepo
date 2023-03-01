/************************************************************************************************************************************
    Author      :   Nicholas Zozaya
    Description :   This class unsubscribes Lead/Contact for a specific email, or logs occurrence of no Lead/Contact found.

    History : 
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                      DETAIL
    1        02 May 2018        Nicholas Zozaya            Initial development
**************************************************************************************************************************************/
public without sharing class ExternalUnsubscribeController {
    
    @AuraEnabled
    public static void doOptOut(String email){
        Savepoint savepointRecord = Database.setSavepoint();
        try{
            List<SObject> recordsToUnsubscribe = new List<SObject>();
            List<SObject> recordsToUpdate = new List<SObject>();
            recordsToUnsubscribe.addAll([ SELECT Id, HasOptedOutOfEmail 
                                          FROM Contact
                                          WHERE Email=:email ]);
            if(recordsToUnsubscribe.isEmpty()) {
                recordsToUnsubscribe.addAll([ SELECT Id, HasOptedOutOfEmail
                                              FROM Lead
                                              WHERE Email = :email ]);
            }
            if(recordsToUnsubscribe.isEmpty() ) {
                ApexDebugLog.logException(new ExtUnsubscribeException('could not find Lead or Contact with email: '+email),'','ExternalUnsubscribeController','doOptOut_nopush');
                return;
            }
            for (SObject record : recordsToUnsubscribe) {
                if (!(Boolean) record.get('HasOptedOutOfEmail')) {
                    record.put('HasOptedOutOfEmail', true);
                    record.put('Marketing_Consent__c', false);
                    recordsToUpdate.add(record);
                }
            }
            if (!recordsToUpdate.isEmpty()) {
                Database.update(recordsToUpdate);
            }
        }catch(Exception e){
            ApexDebugLog.logException(new ExtUnsubscribeException('unhandled exception while unsubscribing email ' +
                                                                  email + ' : EXCEPTION ==> '+e.getMessage()),
                                                                  '', 'ExternalUnsubscribeController', 'doOptOut');
            Database.rollback(savepointRecord);
        }
    }
    public class ExtUnsubscribeException extends Exception{}
}