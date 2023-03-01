/**
 * @description methods for the Location trigger, specifically the trac_Location class
 * @name trac_LocationHandler
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-07-30
 */

public without sharing class trac_LocationHandler {
    
    // After update
    public static void processAllQueueDml(Map<String, trac_LocationWrapper> locationsWrapper) {
        System.debug(JSON.serialize(locationsWrapper));
        List<Location_Queue__c> lqsToInsert = new List<Location_Queue__c>();
        List<Location_Queue__c> lqsToUpdate = new List<Location_Queue__c>();
        List<Location_Queue__c> lqsToDelete = new List<Location_Queue__c>();

        for (String idx : locationsWrapper.keySet()) {
            trac_LocationWrapper locationWrap = locationsWrapper.get(idx);

            // create new queues
            if (!locationWrap.queueTypesToAdd.isEmpty()) {
                for (Location_Queue_Type__mdt mdt : locationWrap.queueTypesToAdd) {
                    String queueName = mdt.Queue_Name_Prefix__c + ': ' + locationWrap.location.Name;
                    if (queueName.length() > 40) {
                        queueName = queueName.substring(0, 40);
                    }
                    Location_Queue__c lq = new Location_Queue__c(
                            Queue_Prefix__c = mdt.Queue_Name_Prefix__c,
                            Queue_Developer_Name__c = generateDevName(queueName),
                            Queue_Label__c = queueName,
                            Location__c = locationWrap.location.Id);
                    locationWrap.prefixToQueue.put(mdt.Queue_Name_Prefix__c,lq);
                    lqsToInsert.add(lq);
                }
            }

            // is location name changed
            if (locationWrap.oldLocation != null && locationWrap.location.Name != locationWrap.oldLocation.Name) {
                for (Location_Queue__c lq : locationWrap.prefixToQueue.values()) {
                    String queueName = (lq.Queue_Prefix__c + ': ' + locationWrap.location.Name);
                    Integer length = queueName.length() >= 40 ? 40 : queueName.length();
                    lq.Queue_Label__c = queueName.substring(0, length);
                    lqsToUpdate.add(lq);
                }
            }

            if (!locationWrap.roqueQueues.isEmpty()) {
                lqsToDelete.addAll(locationWrap.roqueQueues);
            }
        }


        insert lqsToInsert;
        update lqsToUpdate;
        delete lqsToDelete;
    }


    public static String generateDevName(String input) {
        String output = input.trim().replaceAll('[^A-Za-z0-9 ]', '').replaceAll('[\\s]+', '_');
        if (output.length() > 40) {
            output = output.substring(0, 40);
        }
        return output;
    }
}