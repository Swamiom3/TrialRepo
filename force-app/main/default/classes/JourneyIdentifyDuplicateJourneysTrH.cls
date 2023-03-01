/**********************************************************************************************************
    Author        :  Ashish Sharma
    Description   :  Identify and mark the duplicate journeys that were created the same day.
    Issue No.     :  ST-8162
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE          AUTHOR           DETAIL
      1         23-Apr-2021    Ashish Sharma      ST-8162
**********************************************************************************************************/
public class JourneyIdentifyDuplicateJourneysTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Journey__c> newJourneys;
    private static Set<String> emailsToIgnore = new Set<String>();
    @TestVisible
    private JourneySelector journeySelector = new JourneySelector();
     
    public JourneyIdentifyDuplicateJourneysTrH() {
        this((List<Journey__c>) Trigger.new);
    }
    
    @TestVisible
    private JourneyIdentifyDuplicateJourneysTrH(List<Journey__c> newJourneys) {
        this.newJourneys = newJourneys;
    }
    
    public override void beforeInsert() {
        markDuplicateJourneys();
    }
    
    public override void afterInsert() {
        markDuplicateJourneysInsertedAtSameTime();
    }
    
    private void markDuplicateJourneys() {
        Set<String> emails = new Set<String>();
        Set<String> firstNames = new Set<String>();
        Set<String> lastNames = new Set<String>();
        for(Journey__c journey : newJourneys) {
            if(journey.Primary_Email__c != null) {
                emails.add(journey.Primary_Email__c);
                firstNames.add(journey.First_Name__c);
                lastNames.add(journey.Last_Name__c);
            }
        }
        
        if(emails.isEmpty()) {
            return;
        }
        
        Map<String, Journey__c> emailsToJourneys = new Map<String, Journey__c>();
        for(Journey__c journey : journeySelector.getDuplicateJourneysCreatedToday(new List<String>(emails), new List<String>(firstNames), new List<String>(lastNames))) {
            emailsToJourneys.put(journey.Primary_Email__c, journey);
        }
        
        if(emailsToJourneys.isEmpty()) {
            return;
        }
        
        emailsToIgnore.addAll(emailsToJourneys.keySet());
        for(Journey__c journey : newJourneys) {
            Journey__c masterRec = emailsToJourneys.get(journey.Primary_Email__c);
            if(masterRec != null && isDuplicate(masterRec, journey)) {
                journey.Duplicate_Journey__c = true;
                journey.Master_Journey__c = masterRec.Id;
            }
        }
    }
    
    
    private void markDuplicateJourneysInsertedAtSameTime() {
        Map<String,Journey__c> emailToJourney = new Map<String, Journey__c>();
        List<Journey__c> journeysToUpdate = new List<Journey__c>();
        for(Journey__c journey : newJourneys) {
            if(journey.Primary_Email__c == null || emailsToIgnore.contains(journey.Primary_Email__c) || journey.Duplicate_Journey__c) {
                continue;
            }
            if(emailToJourney.containsKey(journey.Primary_Email__c)) {
                Journey__c masterJourney = emailToJourney.get(journey.Primary_Email__c);
                if(isDuplicate(masterJourney, journey)) {
                    journeysToUpdate.add(new Journey__c(Id = journey.Id, Duplicate_Journey__c = true, Master_Journey__c = masterJourney.Id));
                }
            } else {
                emailToJourney.put(journey.Primary_Email__c, journey);
            }
        }
        
        if(!journeysToUpdate.isEmpty()) {
            update journeysToUpdate;
        }
    }
    
    private Boolean isDuplicate(Journey__c masterJourney, Journey__c newJourney) {
        return (masterJourney.First_Name__c == newJourney.First_Name__c && masterJourney.Last_Name__c == newJourney.Last_Name__c);
    }
}