/************************************************************************************************************************************
    Author         : Oleg Krasko
    Description    : This class provides the logic to populate External ID during insert event for dedicated set of SObjects
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1              15 Feb, 2022    Oleg Krasko        Initial Deployment
**************************************************************************************************************************************/
public with sharing class SObjectDataConfigTrH extends SObjectTriggerHandler{
    private List<SObject> sObjects;
    @TestVisible
    private final String EXTERNAL_ID_API_NAME = 'External_Id__c';
    
    public SObjectDataConfigTrH() {
        this(Trigger.new);
    }

    @TestVisible
    private SObjectDataConfigTrH(List<SObject> sObjects){
        this.sObjects = sObjects;
    }

    public override void beforeInsert(){
        new ExternalIdCompositionService(
            sObjects,
            new Set<String>{'Name'},
            EXTERNAL_ID_API_NAME
        ).assignExternalID();
    }
}