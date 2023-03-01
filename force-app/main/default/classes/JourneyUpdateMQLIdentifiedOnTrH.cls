/************************************************************************************************************************************
Author      :   Krishana Tupe 	
Description :   This class will contain buisness logic of update MQL_Identified_On__c on Journey .
Issue No    : 	ST-5942
History		:
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  	DETAIL
1           20 March, 2020    	Krishana Tupe             	Initial Developement
2           12 August, 2021    	Andrei Dedovets             Refactored to SObjectTriggerHandler
**************************************************************************************************************************************/
public class JourneyUpdateMQLIdentifiedOnTrH extends SObjectTriggerHandler {
    
    @TestVisible
    private static final String WORKSPACE = 'Workspace';
    @TestVisible
    private List<Journey__c> newJourneys;
    @TestVisible
    private Map<Id, Journey__c> oldJourneysMap;

    public JourneyUpdateMQLIdentifiedOnTrH(){
        this(
            (List<Journey__c>) Trigger.new,
            (Map<Id, Journey__c>) Trigger.oldMap
        );
    }

    @TestVisible
    private JourneyUpdateMQLIdentifiedOnTrH(List<Journey__c> newJourneys, Map<Id, Journey__c> oldJourneysMap){
        this.newJourneys = newJourneys;
        this.oldJourneysMap = oldJourneysMap;
    }

    public override void beforeInsert() {
        setMQLIdentifiedOn();
    }
    
    public override void beforeUpdate() {
        updateMQLIdentifiedonJourney();
        MetadataDrivenTriggerHandler.clearLoopCount('JourneyUpdateMQLIdentifiedOnTrH');   
    }

    /************************************************************************************************************************************
     Author         	: Andrei Dedovets
     Issue No       	: ST-8423
     Description     	: If journey created via drift integration with owner as user , we are updating the MQL_Identified_On__c field to today date 
     Created Date     	: 9 Aug, 2020
     *******************************************************************************************************************************/
    @TestVisible
    private void setMQLIdentifiedOn() {
        if (Userinfo.getUserId() != Id.valueOf(Settings.getValidationRuleRestrictionSalesforceId('Drift_API_User'))) {
            return;
        }

        for(Journey__c journey : newJourneys) {
            if (journey.OwnerId.getSObjectType() == User.getSObjectType() && journey.Product_Interests__c == WORKSPACE) {
                journey.MQL_Identified_On__c  = Date.today();
            }
        }
    }
    
    /************************************************************************************************************************************
     Author         	: Pradeep Vemula
     Issue No       	: ST-5550
     Description     	: If journey status changes to MQL , we are updating the MQL_Identified_On__c field to the date when the journey status changed.
     Created Date     	: 03-06-2020 
	 Last Modified Date : 20 March, 2020
     Last Modified By  	: Krishana Tupe (ST-5942 : Update MQL Identified On From Known/Engaged to Advanced Stage)
     *******************************************************************************************************************************/
    @TestVisible
    private void updateMQLIdentifiedonJourney(){
        Map<String, Set<String>> mapMQLStatusConfig = getMQLStatusConfigMetadata();
        if(oldJourneysMap == NULL || oldJourneysMap.isEmpty()){  
            return;
        }  
        
        for(Journey__c objNewJourney :  newJourneys){
            String strOldJourneyStatus = (String)oldJourneysMap.get(objNewJourney.Id).get('Status__c');
            if(String.isNotBlank(objNewJourney.Status__c) && String.isNotBlank(strOldJourneyStatus) && mapMQLStatusConfig.keySet().contains(strOldJourneyStatus.toLowerCase()) && objNewJourney.Status__c != strOldJourneyStatus && mapMQLStatusConfig.get(strOldJourneyStatus.toLowerCase()).contains(objNewJourney.Status__c.toLowerCase())){
                objNewJourney.MQL_Identified_On__c = System.today();
            }                    
        }  
    }

    /************************************************************************************************************************************
     Author         	: Krishana Tupe
     Issue No       	: ST-5942
     Description     	: get MQL Identified On Configuration Settings 
     Created Date     	: 20 March, 2020	
     *******************************************************************************************************************************/
    private Map<String, Set<String>> getMQLStatusConfigMetadata(){
        MetadataSetting__mdt objMDTSetting = Settings.getMetadataSettingByDevName('MQLIdentifiedOnConfigSetting');

        return (objMDTSetting != NULL &&  String.isNotBlank(objMDTSetting.Data__c)) ?
                (Map<String, Set<String>>)JSON.deserialize(objMDTSetting.Data__c.toLowerCase(), Map<String, Set<String>>.class) :
                new Map<String, Set<String>>();
    }
}