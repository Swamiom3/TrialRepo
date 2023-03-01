/**
 * @description trigger for the Location sobject
 * @name trac_LocationTrigger
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-07-30
 */

trigger trac_LocationTrigger on Location__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    //SObjectDomain.triggerHandler(new trac_Location());
}