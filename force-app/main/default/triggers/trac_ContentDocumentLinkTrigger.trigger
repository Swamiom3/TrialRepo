/**
 * @description Apex class trac_ContentDocumentLinkTrigger
 * @author Daniel Labonte, Traction on Demand
 * @date 2020-03-03
 */

trigger trac_ContentDocumentLinkTrigger on ContentDocumentLink (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    SObjectDomain.triggerHandler(new trac_ContentDocumentLink());
}