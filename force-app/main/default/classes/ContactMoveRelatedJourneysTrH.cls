/************************************************************************************************************************************
    Author        : Krishana Tupe
    Description    : This class move the Related journyes of Lead to Contact on Contact Creation(after insert).
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION          DATE                 AUTHOR                  DETAIL                                    ISSUE
    1                19 Aug 2019          Krishana Tupe           Initial Developement                      ST-4504
    2                12 April 2021        Tomasz Sadowski         Migration to new trigger framework        ST-8042
**************************************************************************************************************************************/
public class ContactMoveRelatedJourneysTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Contact> newContacts;
    @TestVisible
    private JourneySelector journeySelector = new JourneySelector();
    @TestVisible
    private Map<String, Contact> emailToContact;

    public ContactMoveRelatedJourneysTrH() {
        this(
            (List<Contact>) Trigger.new
        );
    }

    @TestVisible
    private ContactMoveRelatedJourneysTrH(List<Contact> newContacts) {
        this.newContacts = newContacts;
    }

    public override void afterInsert() {
        moveRelatedJourneysAndUpdate();
    }
    
    @TestVisible
    private void moveRelatedJourneysAndUpdate() {
       updateJourneys(moveRelatedJourneys());
    }

    @TestVisible
    private List<Journey__c> moveRelatedJourneys() {
        getEmailToContactsByPrimaryEmails();
        if (emailToContact.isEmpty()) {
            return new List<Journey__c>();
        }
        List<Journey__c> journeysToUpdate = getJourneysForUpdatePrimaryContactAndLead(journeySelector.getJourneysByPrimaryEmailsWhenPrimaryLeadPresented(new List<String>(emailToContact.keySet())));
        return journeysToUpdate;
    }

    private void updateJourneys(List<Journey__c> journeysToUpdate) {
        if(journeysToUpdate.isEmpty()) {
            return;
        }
        this.dml.add(journeysToUpdate, DmlConsolidator.Operation.FOR_UPDATE);
    }

    @TestVisible
    private List<Journey__c> getJourneysForUpdatePrimaryContactAndLead(List<Journey__c> journeysFromPrimaryEmails) {
        if(journeysFromPrimaryEmails.isEmpty()) {
            return new List<Journey__c>();
        }
        List<Journey__c> journeysToUpdate = new List<Journey__c>();
        for (Journey__c journey : journeysFromPrimaryEmails) {
            journey.Primary_Contact__c = emailToContact.get(journey.Primary_Email__c).Id;
            journey.Primary_Lead__c = null;
            journeysToUpdate.add(journey);
        }
        return journeysToUpdate;
    }

    @TestVisible
    private void getEmailToContactsByPrimaryEmails() {
        emailToContact = new Map<String, Contact>();
        for (Contact contact : newContacts) {
            if (String.isNotBlank(contact.Email)) {
                emailToContact.put(contact.Email, contact);
            }
        }
    }
}