/**
 * @description trigger for the membership (asset) object
 * @name trac_MembershipTrigger
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-09-04
 */

trigger trac_MembershipTrigger on Asset (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    SObjectDomain.triggerHandler(new trac_Membership());
}