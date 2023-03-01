/*********************************************************************************************************
	Author        :  Vipul Chaudahari
	Description   :  Generate UUID for new Journey.
	Issue No.     :  ST-8958
	History       :
-----------------------------------------------------------------------------------------------------------
	VERSION        DATE             AUTHOR             DETAIL
	1          09-Sept-2021     Vipul Chaudhari     Trigger Refactor
**********************************************************************************************************/
public class JourneyGenerateUUIDTrH extends SObjectTriggerHandler{
    @TestVisible
    private List<Journey__c> newJourneys;
    public JourneyGenerateUUIDTrH() {
         this((List<Journey__c>) Trigger.new);  
    }
    @TestVisible
    private JourneyGenerateUUIDTrH(List<Journey__c> newJourney){
        this.newJourneys = newJourney;
    }
    public override void beforeInsert(){
        generateUUID();
    }
    private void generateUUID(){
        for (Journey__c journeyRecord : newJourneys) {
            journeyRecord.UUID__c = UUIDHandler.generateVersion4();
        }
    }
}