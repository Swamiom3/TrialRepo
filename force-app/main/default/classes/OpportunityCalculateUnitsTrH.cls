/*************************************************************************************************************************************
    Author      :   ---
    Description :   This class is handling units calculation on Opportunities
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR            DETAIL
    2          10 Mar, 2022    Pawel Biszczak    Refactor
**************************************************************************************************************************************/
public with sharing class OpportunityCalculateUnitsTrH extends SObjectTriggerHandler{
    private final List<Opportunity> newRecords; 

    public OpportunityCalculateUnitsTrH() {
        this((List<Opportunity>) Trigger.new); 
    }

    @TestVisible
    private OpportunityCalculateUnitsTrH(List<Opportunity> newRecords) {
        this.newRecords = newRecords; 
    }

    public override void beforeInsert() {
        this.populateQuantity();
        this.calculateQuantities(); 
    }
    
    public override void beforeUpdate() {
        this.populateQuantity();
    }

    private void calculateQuantities() {
        for (Opportunity item : newRecords) {
            if (item.Original_Quantity__c == null) {
                continue;
            }
            CalculateUnitsService service = new CalculateUnitsService(item.Original_Quantity__c, item.Opportunity_Creation_Source__c);
            item.Interested_in_Number_of_Desks__c = service.getDesks();
        }
    }

    private void populateQuantity() {
        for (Opportunity item : newRecords) {
            if (String.isNotBlank(item.Type__c) && item.Type__c != GlobalConstants.WEWORK) {
                continue; 
            }
            if (String.isNotBlank(item.Type__c) && item.Type__c == GlobalConstants.WEWORK && item.Original_Quantity__c == null ) {
                item.Original_Quantity__c = item.Interested_in_Number_of_Desks__c; 
            }
        }
    }
}