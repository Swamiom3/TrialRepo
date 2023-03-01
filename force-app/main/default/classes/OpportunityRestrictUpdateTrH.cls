/************************************************************************************************************************************
    Author      :   Salesforce
    Description :   This class handles the logic to restrict the Users if they try to edit an opportunity is not part of Migrated country
   --------------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
       1        10 May 2022         Salesforce          Initial Developement
 **************************************************************************************************************************************/
public with sharing class OpportunityRestrictUpdateTrH extends SObjectTriggerHandler {
    
    @TestVisible
    private List<Opportunity> newOpportunities;
    @TestVisible
    private Map<Id, Opportunity> oldOpportunitiesMap;
    @TestVisible
    private Set<String> migratedRegions = new Set<String>();

    @TestVisible
    private MetadataUtils mtdtUtils = new MetadataUtils();
    
    private final String FIELD_API_NAME_COMPLETED_TOURS = 'Number_of_Completed_Tours__c';
    private final String FIELD_API_NAME_OPEN_TOURS = 'Number_of_Open_Tours__c';
    private final String FIELD_API_NAME_TOTAL_TOURS = 'Total_Number_of_Tour__c';
    private final String REGIONAL_MIGRATION_EXEMPTION = 'Regional_Migration_Exemption__c';
    @TestVisible
    private final String ERROR_MESSAGE = 'This record is managed in the other instance and should only be updated there. Contact support if you have any questions';
    
    @TestVisible
    private static final Boolean VALIDATION_BYPASS_USER_INTEGRATION = FeatureManagement.checkPermission('Validation_Bypass_User_Integration');
    @TestVisible
    private static final Boolean CAN_EDIT_REFERRAL_FIELD = FeatureManagement.checkPermission('Can_Edit_Referral_Field_Opportunity');
    @TestVisible
    private static final Id SYS_ADMIN_PROFILE_ID = Validation_Rule_Restriction__mdt.getInstance('System_Administrator').Salesforce_Id__c;
    @TestVisible
    private static final Id WEWORK_SYS_ADMIN_PROFILE_ID = Validation_Rule_Restriction__mdt.getInstance('WeWork_System_Administrator').Salesforce_Id__c;
    @TestVisible
    private static final Id WEWORK_SUPPORT_AND_OPS_PROFILE_ID = Validation_Rule_Restriction__mdt.getInstance('WeWork_Support_and_Operations').Salesforce_Id__c;
    
    public OpportunityRestrictUpdateTrH() {
        this((List<Opportunity>) Trigger.new, (Map<Id, Opportunity>) Trigger.oldMap);
    }

    @TestVisible
    private OpportunityRestrictUpdateTrH(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunitiesMap) {
        this.newOpportunities = newOpportunities;
        this.oldOpportunitiesMap = oldOpportunitiesMap;
    }
    
    public override void beforeUpdate(){
        preventOpportunityUpdate();
    }

    @TestVisible
    private void preventOpportunityUpdate(){
        if(bypassValidation()) {
            return;
        }
        setMigratedRegions();

        List<Opportunity> opportunitiesToValidate = new List<Opportunity>();
        Set<Id> oppBuildingIds = new Set<Id>();
        for(Opportunity newopportunity : newOpportunities){
            if(newopportunity.Building__c != null){
                opportunitiesToValidate.add(newopportunity);
                oppBuildingIds.add(newopportunity.Building__c);
            }
        }
        if(opportunitiesToValidate.isEmpty() || oppBuildingIds.isEmpty()){
            return;
        }

        BuildingSelector buildingSelector = new BuildingSelector();
        Map<Id, Building__c> buildingRecords = new Map<Id, Building__c>(buildingSelector.getBuildingsById(new List<Id>(oppBuildingIds)));
        for(Opportunity newOpp: opportunitiesToValidate){
            Opportunity oldOpp = oldOpportunitiesMap.get(newOpp.Id);    
            validateRecord(buildingRecords.get(newOpp.Building__c).Country__c, newOpp, oldOpp);
        }
    }

    private void validateRecord(String country, Opportunity newOpp, Opportunity oldOpp){
        if(!migratedRegions.contains(country)
            && (!newOpp.Regional_Migration_Exemption__c && !TriggerUtility.isFieldValueChanged(newOpp, oldOpp, REGIONAL_MIGRATION_EXEMPTION))
            && !TriggerUtility.isFieldValueChanged(newOpp, oldOpp, FIELD_API_NAME_COMPLETED_TOURS)
            && !TriggerUtility.isFieldValueChanged(newOpp, oldOpp, FIELD_API_NAME_OPEN_TOURS)
            && !TriggerUtility.isFieldValueChanged(newOpp, oldOpp, FIELD_API_NAME_TOTAL_TOURS)){
                newOpp.addError(ERROR_MESSAGE);
        }
    }

    private Boolean bypassValidation(){
        return (VALIDATION_BYPASS_USER_INTEGRATION
                || CAN_EDIT_REFERRAL_FIELD
                || (SYS_ADMIN_PROFILE_ID == UserInfo.getProfileId())
                || (WEWORK_SYS_ADMIN_PROFILE_ID == UserInfo.getProfileId())
                || (WEWORK_SUPPORT_AND_OPS_PROFILE_ID == UserInfo.getProfileId())
                );
    }

    private void setMigratedRegions(){
        Map<String, Regional_Migration__mdt> allRegionalMigration = mtdtUtils.getAllRegions();
        for(String countryLabel: allRegionalMigration.keySet()){
            if(allRegionalMigration.get(countryLabel).Region_Enabled__c){
                migratedRegions.add(allRegionalMigration.get(countryLabel).MasterLabel);
            }
        }
    }
}