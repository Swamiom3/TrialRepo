/************************************************************************************************************************************
    Author        : Krishana Tupe
    Description    : This class will contain buisness logic of Contact/Contact trigger which updates Email Domain on the Contact/Contact record.
----------------------------------------------------------------------------------------------------------------------------------
    VERSION            DATE                AUTHOR                    DETAIL                                    ISSUE
    1                08 April 2019        Krishana Tupe            Initial Developement
    2                12 April, 2021        Tomasz Sadowski            Migration to new trigger framework        ST-8042
**************************************************************************************************************************************/
public with sharing class ContactSetEmailDomainTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Contact> newContacts;
    @TestVisible
    private Map<Id, Contact> oldContactsMap;

    public ContactSetEmailDomainTrH() {
        this(
            (List<Contact>) Trigger.new,
            (Map<Id, Contact>) Trigger.oldMap
        );
    }

    @TestVisible
    private ContactSetEmailDomainTrH(List<Contact> newContacts, Map<Id, Contact> oldContactsMap) {
        this.newContacts = newContacts;
        this.oldContactsMap = oldContactsMap;
    }

    public override void beforeInsert() {
        EmailHelper.setEmailDomain(newContacts, null);
    }

    public override void beforeUpdate() {
        EmailHelper.setEmailDomain(newContacts, oldContactsMap);
    }
}