/************************************************************************************************************************************
    Author      :   Maciej Miłosz	
    Description :   Based on Simon Goodyear trigger framework
                    https://developer.salesforce.com/blogs/2019/08/live-coding-with-simon-goodyear.html
                    This is the trigger envoker, and should be used in SObject specific triggers to get
                    handlers based on custom metadata records
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           13/08/2020          Maciej Miłosz           Trigger redesign
    2           15/04/2021          Liubomyr Mishchykha     Implemented DML consolidation
**************************************************************************************************************************************/
public class MetadataDrivenTriggerHandler extends SObjectTriggerHandler {

    @TestVisible
    private static Map<String, List<Trigger_Configuration__mdt>> sObjectNameToTriggerHandlerConfugurations = new Map<String, List<Trigger_Configuration__mdt>>();
    @TestVisible
    private String sObjectType;
    @TestVisible
    private static Map<String, List<Trigger_Configuration__mdt>> triggerConfigurationsByObjectApiName;

    public override void run() { 
        if(!this.isExecutable() || shouldBypassTriggersForUser()){
            System.debug('MetadataDrivenTriggerHandler:-Test run method if condition');
            return;
        }
        
        sObjectType = getSObjectType();
        registerDmlConsolidator(DmlConsolidatorDefault.getInstance());
        registerDmlConsolidator(DmlConsolidatorPartialSuccess.getInstance());
        System.debug('MetadataDrivenTriggerHandler:-Test Outside run method condition ');
        runTriggerHandlers();
		
    }

    private String getSObjectType() {
        if (Test.isRunningTest() && sObjectType != null) {
            System.debug('metadata :- getsobject method if block for test');
            return sObjectType;
        }
        if(Trigger.new != null){
            System.debug('MetaDatacls :- getsobject method if block');
            return Trigger.new[0].getSObjectType().getDescribe().getName();
        } else {
            System.debug('MetaDatacls :- getsobject method else');
            return Trigger.old[0].getSObjectType().getDescribe().getName();
        }
    }

    @TestVisible
    private void runTriggerHandlers(){
		System.debug('metadatacls :- runTriggerHandler method running');
        List<Trigger_Configuration__mdt> sObjectTriggerConfigurations = getSObjectTriggerConfigurations();
        for (Trigger_Configuration__mdt triggerHandlerConfiguration : sObjectTriggerConfigurations) {
            if(!triggerHandlerConfiguration.Active__c){
				System.debug('metadatacls :- runTriggerHandler method running if block for active_c metadata check');
                continue;
            }
            SObjectTriggerHandler handler;
            Type handlerType = Type.forName(triggerHandlerConfiguration.Implementing_Class__c);
            try{
                handler = ((SObjectTriggerHandler) handlerType.newInstance()).registerDmlConsolidator(this.dml).registerDmlConsolidator(this.dmlPartial);
            } catch (NullPointerException npe) {
                ApexDebugLog.logException((Exception) npe, triggerHandlerConfiguration.Implementing_Class__c, 'MetadataDrivenTriggerHandler', 'runTriggerHandlers: no such class as ' + triggerHandlerConfiguration.Implementing_Class__c);
                continue;
            } catch (TypeException invalidTypeException) {
                ApexDebugLog.logException((Exception) invalidTypeException, triggerHandlerConfiguration.Implementing_Class__c, 'MetadataDrivenTriggerHandler', 'runTriggerHandlers:invalidType: ' + triggerHandlerConfiguration.Implementing_Class__c +' is not a instance of SObjectTriggerHandler');
                continue;
            }
            if (triggerHandlerConfiguration.Is_Forced_Execution__c) {
                handler.forceExecution();
				System.debug('metadatacls :- runTriggerHandler method running Is_Forced_Execution__c checking');
            }
            handler.run();
        }
        this.dml.run();
        this.dmlPartial.run();
    }

    @TestVisible
    private List<Trigger_Configuration__mdt> getSObjectTriggerConfigurations(){
		System.debug('metadatatcls:- getSObjectTriggerConfigurations method running');
        if(!sObjectNameToTriggerHandlerConfugurations.containsKey(sObjectType)){
		System.debug('metadatatcls:- getSObjectTriggerConfigurations method running if block');
            addSObjectTriggerConfiguration();
        }
        return sObjectNameToTriggerHandlerConfugurations.get(sObjectType);
    }

    @TestVisible
    private Boolean shouldBypassTriggersForUser(){
        System.debug('MetadataDrivenTriggerHandler:-Test  shuldbypassforuser method condition');
        return FeatureManagement.checkPermission('Bypass_Triggers');
    }

    private void addSObjectTriggerConfiguration(){
		System.debug('metadatatcls:- addSObjectTriggerConfiguration method running');
        sObjectNameToTriggerHandlerConfugurations.put(sObjectType, getTriggerHandlers());
    }

    private List<Trigger_Configuration__mdt> getTriggerHandlers(){
		System.debug('metadatatcls:- getTriggerHandlers method running');
        fetchTriggerConfiguration();
        return (triggerConfigurationsByObjectApiName.containsKey(sObjectType)) ?
                                                                        triggerConfigurationsByObjectApiName.get(sObjectType)
                                                                        : new List<Trigger_Configuration__mdt>();
    }


    private static void fetchTriggerConfiguration() {
        if(triggerConfigurationsByObjectApiName != null) {
            System.debug('metadatatcls:- fetchTriggerConfiguration method running if method');
            return;
        }
        triggerConfigurationsByObjectApiName = new Map<String, List<Trigger_Configuration__mdt>>();
        for (Trigger_Configuration__mdt configurationRecord : [SELECT Implementing_Class__c,
                                                                      Object_API_Name__c,
                                                                      Order_of_Execution__c,
                                                                      Is_Forced_Execution__c,
                                                                      Active__c
                                                               FROM Trigger_Configuration__mdt
                                                               WHERE Event_Time__c = null
                                                               ORDER BY Order_of_Execution__c]) {
			System.debug('metadatatcls:- fetchTriggerConfiguration method running if method');
            if(!triggerConfigurationsByObjectApiName.containsKey(configurationRecord.Object_API_Name__c)) {
				System.debug('metadatatcls:- fetchTriggerConfiguration method running Object_API_Name__c check');
                triggerConfigurationsByObjectApiName.put(configurationRecord.Object_API_Name__c, new List<Trigger_Configuration__mdt>());
            }
            triggerConfigurationsByObjectApiName.get(configurationRecord.Object_API_Name__c).add(configurationRecord);
			System.debug('metadatatcls:- fetchTriggerConfiguration after triggerConfigurationsByObjectApiName at last method running Object_API_Name__c check');
        }
    }
}