/**
 * Created by sjain on 8/28/2019.
 */

trigger trac_EmailMessageTrigger on EmailMessage (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    SObjectDomain.triggerHandler(new trac_EmailMessage());
}