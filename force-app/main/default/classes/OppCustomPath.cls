/********************************************************************************************************************
   Name              : OppCustomPath
   Description       : OppCustomPath apex for the oppCustomSalesPath component for more details see the jira ticket.

   Revision History  :-
   Created/Modified by                     Created/Modified Date       Requested by                  Technical Design Proposal
   ---------------------------------------------------------------------------------------------------------------------
   1. Rashad Saeed (initial implementation)      22 SEP 2019               WeWork                           CSI-2274
   2. Tomasz Sadowski (stage based validations)  31 SEP 2020               WeWork                           ST-6772
   ---------------------------------------------------------------------------------------------------------------------
********************************************************************************************************************/
public class OppCustomPath {
    private final static Set<String> PROFILES_IF_OPP_IS_ClOSED = new Set<String>{'System_Administrator', 'WeWork_System_Administrator', 'WeWork_GrowthOps',
                                                                                 'WeWork_System_Administrator_New_Layout', 'WeWork_Region_Admin_China', 'WeWork_Support_and_Operations'};
    private final static Set<String> PROFILES_IF_OPP_IS_OPEN = new Set<String>{'System_Administrator', 'WeWork_System_Administrator'};
    private static List<Validation_Rule_Restriction__mdt> validationRuleResctrictions;
    private final static String CLOSED_STAGE = 'Closed';
    private final static String MOVE_BACK_VALIDATION = 'MoveBackValidation';
    private final static String MOVE_FORWARD_VALIDATION = 'MoveForwardValidation';
    private final static String TECH_SERVICES_OMIT_REASON = 'Tech_Services_Omit_Reason__c';
    @AuraEnabled(cacheable=true)
    public static Map<String,List<Opportunity_Stage_Required_Fields__mdt>> getOppField(String stageName, String stepName, Boolean isLargeDeal, Boolean isRenewal, String recordId, String recordTypeId) {
        String strRecordDevName = Schema.SObjectType.opportunity.getRecordTypeInfosById().get((id)recordTypeId).getDeveloperName();
        strRecordDevName.toLowerCase();
        Set<String> duplicateFieldsFinder = new Set <String>();
        Map<String, Id> stageNameOppStageMdtId = new Map<string, Id>();
        Map<String, List<Opportunity_Stage_Required_Fields__mdt>> stageMap = new Map<String,List<Opportunity_Stage_Required_Fields__mdt>>();
        Map<Id, Opportunity_Stages__mdt> oppStages = new Map<Id, Opportunity_Stages__mdt> (
            [SELECT Id, MasterLabel, Order_Number__c, (SELECT Field_API_Name__c, Not_Requiered__c, Display_Order__c FROM Opportunity_Stage_Required_Fields__r WHERE Is_Large_Deal__c =: isLargeDeal AND Is_Renewal__c =: isRenewal) FROM Opportunity_Stages__mdt ORDER BY Order_Number__c]);
        for (Id oppStageid: oppStages.keyset()) {
            stageNameOppStageMdtId.put(oppStages.get(oppStageid).MasterLabel, (Id)oppStageid);
        }
        Id stageNameId = stageNameOppStageMdtId.get(stageName);
        Id stepNameId = stageNameOppStageMdtId.get(stepName);
        Integer stepOrderNumber = (Integer)oppStages.get(stepNameId).Order_Number__c;
        Integer stageOrderNumber = (Integer)oppStages.get(stageNameId).Order_Number__c;
        if(!hasPermissionToChangeStage(stageName, stepName, stepOrderNumber, stageOrderNumber, stageMap)) {
            return stageMap;
        }
		if ((stepOrderNumber - stageOrderNumber) < 0) {
            Opportunity_Stage_Required_Fields__mdt tempCMT = new Opportunity_Stage_Required_Fields__mdt();
            tempCMT.Field_API_Name__c = 'Stage_Move_Back_Reason__c';
            tempCMT.Not_Requiered__c = false;
            tempCMT.Display_Order__c = 1;
            stageMap.put(stageName,new List<Opportunity_Stage_Required_Fields__mdt> {tempCMT});
            stageMap.put('Moving Backward',new List<Opportunity_Stage_Required_Fields__mdt> {});
            return openModal(stageMap, RecordId);
        } else {
            for (Id oppStageid : oppStages.keySet()) {
                Opportunity_Stages__mdt stageNameObj = oppStages.get(oppStageid);
                if (Integer.valueOf(stageOrderNumber) < Integer.valueOf(oppStages.get(oppStageid).Order_Number__c)
                    && stepName <> stageName 
                    && Integer.valueOf(stepOrderNumber) >= Integer.valueOf(oppStages.get(oppStageid).Order_Number__c)) {
                    for (Opportunity_Stage_Required_Fields__mdt requiredField : stageNameObj.Opportunity_Stage_Required_Fields__r) {
                        if (!duplicateFieldsFinder.contains(requiredField.Field_API_Name__c)) {
                            duplicateFieldsFinder.add(requiredField.Field_API_Name__c);
                            String thisStage = oppStages.get(oppStageid).MasterLabel;
                            if (!stageMap.containsKey(thisStage)) {
                                stageMap.put(thisStage, new List<Opportunity_Stage_Required_Fields__mdt> {requiredField});
                            }
                            else {
                                stageMap.get(thisStage).add(requiredField);
                            }
                        }
                    }
                }
            }
        }
        return openModal(stageMap, RecordId);
    }

    private static Map<String,List<Opportunity_Stage_Required_Fields__mdt>> openModal(Map<String,List<Opportunity_Stage_Required_Fields__mdt> > fieldsMap, String RecordId) {
        if (fieldsMap.isEmpty()) {
            return fieldsMap;
        }
        Id oppId = (Id)RecordId;
        Set<String> oppFields = new Set<String>();
        Boolean isByPassedProfile = checkIfProfileIsByPassed();
        for (String key :fieldsMap.keySet()) {
            for (Opportunity_Stage_Required_Fields__mdt stageFields : fieldsMap.get(key)) {
                if (stageFields.Not_Requiered__c == false || TECH_SERVICES_OMIT_REASON == stageFields.Field_API_Name__c) {
                    oppFields.add(stageFields.Field_API_Name__c);
                }
                //ST-6210
                if(isByPassedProfile && stageFields.Field_API_Name__c.equalsIgnoreCase('Actual_Start_Date__c')) {
                    stageFields.Not_Requiered__c = true;
                }
            }
        }

        if (!oppFields.isEmpty()) {
            List<String> oppFieldsStr = new List<String>();
            oppFieldsStr.addAll(oppFields);
            String query ='select ';
            query+=  String.join(oppFieldsStr, ', ');
            query+=  ' from opportunity where id ='+'\''+oppId+'\'';
            Opportunity theOpp = Database.query(query);
            for (String fieldName : oppFieldsStr) {
                if (theOpp.get(fieldName) == null) {
                    fieldsMap.put('Open Modal', new List<Opportunity_Stage_Required_Fields__mdt> {});
                    return fieldsMap;
                }
            }
        }
        if (!fieldsMap.containsKey('Open Modal') && !fieldsMap.containsKey('Moving Backward'))
            return new Map<String,List<Opportunity_Stage_Required_Fields__mdt>>();
        return fieldsMap;
    }
    private static Boolean checkIfProfileIsByPassed() {
        String strLabel = Label.Bypassed_Profiles_for_Actual_Start_Date;
        Set<Id> setBypassedIds = new Set<Id>((List<Id>)strLabel.split(','));
        if (!setBypassedIds.isEmpty()) {
            return setBypassedIds.contains(UserInfo.getProfileId());
        }
        return false;
    }
    
    private static Boolean hasPermissionToChangeStage(String stageName, String stepName, Integer stepOrderNumber, Integer stageOrderNumber, Map<String, List<Opportunity_Stage_Required_Fields__mdt>> stageMap) {
        Set<Id> allowedProfileIdsIfOppIsOpen = getAllowedProfileIdsIfOppIsOpen();
        Set<Id> allowedProfileIdsIfOppIsClosed = getAllowedProfileIdsIfOppIsClosed();
        Boolean isClosed = stageName.containsIgnoreCase(CLOSED_STAGE);
        Boolean isOpenStep = (stepName != CLOSED_STAGE);
        Boolean isStepBack = (stepOrderNumber - stageOrderNumber < 0);
        Boolean isStageSkipped = (stepOrderNumber - stageOrderNumber > 1);
        Boolean isAllowedToChangeStageBack = FeatureManagement.checkPermission('Allowed_to_move_opportunity_stage_back');
        Id currentUserProfileId = UserInfo.getProfileId();
        if(isClosed && isStepBack && !isAllowedToChangeStageBack && !allowedProfileIdsIfOppIsClosed.contains(currentUserProfileId)) {
            stageMap.put(MOVE_BACK_VALIDATION, new List<Opportunity_Stage_Required_Fields__mdt>());
            return false;
        } else if(!isClosed && isStepBack && !isAllowedToChangeStageBack && !allowedProfileIdsIfOppIsOpen.contains(currentUserProfileId)) {
            stageMap.put(MOVE_BACK_VALIDATION, new List<Opportunity_Stage_Required_Fields__mdt>());
            return false;
        } else if(isOpenStep && isStageSkipped && !allowedProfileIdsIfOppIsOpen.contains(currentUserProfileId)) {
            stageMap.put(MOVE_FORWARD_VALIDATION, new List<Opportunity_Stage_Required_Fields__mdt>());
            return false;
        }
        return true;
    }
    
    private static Set<Id> getAllowedProfileIdsIfOppIsOpen() {
        Set<Id> allowedProfileIdsIfOppIsOpen = new Set<Id>();
        for(Validation_Rule_Restriction__mdt validationResctriction : getValidationRuleResctrictions()) {
            if(PROFILES_IF_OPP_IS_OPEN.contains(validationResctriction.DeveloperName)) {
                allowedProfileIdsIfOppIsOpen.add(validationResctriction.Salesforce_Id__c); 
            }
        }
        return allowedProfileIdsIfOppIsOpen;
    }
    
    private static Set<Id> getAllowedProfileIdsIfOppIsClosed() {
        Set<Id> allowedProfileIdsIfOppIsClosed = new Set<Id>();
        for(Validation_Rule_Restriction__mdt validationResctriction : getValidationRuleResctrictions()) {
            if(PROFILES_IF_OPP_IS_ClOSED.contains(validationResctriction.DeveloperName)) {
                allowedProfileIdsIfOppIsClosed.add(validationResctriction.Salesforce_Id__c); 
            }
        }
        return allowedProfileIdsIfOppIsClosed;
    }
    
    private static List<Validation_Rule_Restriction__mdt> getValidationRuleResctrictions() {
        if (validationRuleResctrictions == null || validationRuleResctrictions.isEmpty()) {
            validationRuleResctrictions = [SELECT Salesforce_Id__c, DeveloperName 
                                           FROM Validation_Rule_Restriction__mdt 
                                           WHERE DeveloperName IN :PROFILES_IF_OPP_IS_OPEN OR DeveloperName IN :PROFILES_IF_OPP_IS_ClOSED];
        }
        return validationRuleResctrictions;
    }
}