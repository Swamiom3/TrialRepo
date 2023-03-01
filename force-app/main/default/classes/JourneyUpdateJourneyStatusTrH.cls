/*********************************************************************************************************
    Author        :  Shobhit Gahlot
    Description   :  If Journey inserted as Known or Accepted and count of activities more than one then 
                     Journey status save as Working.
    Issue No.     :  ST-8957
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1          09-Sept-2021      Shobhit Gahlot     Trigger Refactor
**********************************************************************************************************/
public class JourneyUpdateJourneyStatusTrH extends SObjectTriggerHandler {
    @TestVisible
   private List<Journey__c> newJourneys;
  
    public JourneyUpdateJourneyStatusTrH() {
        this((List<Journey__c>) Trigger.new);
    }
    @TestVisible
    private JourneyUpdateJourneyStatusTrH(List<Journey__c> newJourney) {
        this.newJourneys = newJourney;
    }
    public override void beforeUpdate() {
        journeyUpdateJourneyStatusReach();
    }
    private void journeyUpdateJourneyStatusReach() {
        for (Journey__c journey : newJourneys) {
            if ((journey.Status__c == GlobalConstants.JOURNEY_STATUS_KNOWN || journey.Status__c == GlobalConstants.JOURNEY_STATUS_ACCEPTED) && journey.Count_of_Activities__c >= 1) {
                journey.Status__c = GlobalConstants.JOURNEY_STATUS_WORKING;
            }
        }
    }
}