/**
 * @description trigger for the Case sobject
 * @name trac_CaseTrigger
 * @author Shubham Jain, Traction on Demand
 * @date 2019-08-27
 */

trigger trac_CaseTrigger on Case (before insert, before update, after insert, after update, after undelete) {
    new MetadataDrivenTriggerHandler().run();
}