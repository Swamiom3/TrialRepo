/**
 * @description Apex class trac_LocationQueue
 * @author Daniel Labonte, Traction on Demand
 * @date 2020-05-01
 */

trigger trac_LocationQueueTrigger on Location_Queue__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    SObjectDomain.triggerHandler(new trac_LocationQueue());
}