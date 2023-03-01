/************************************************************************************************************************************
        Author              : Tomasz Sadowski
        Description         : https://jira.weworkers.io/browse/ST-8265
        Last Modified Date  : 24 May 2021
        Last Modified By    : Tomasz Sadowski
        Issue No            : ST-8265
********************************************************************************************************************************/
public class UserAttributeUpdateReaCaseTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<User_Attribute__c> newUserAttributes;
    @TestVisible
    private Map<Id, User_Attribute__c> oldUserAttributesMap;

    public UserAttributeUpdateReaCaseTrH() {
        this(
            (List<User_Attribute__c>) Trigger.new,
            (Map<Id, User_Attribute__c>) Trigger.oldMap
        );
    }

    @TestVisible
    private UserAttributeUpdateReaCaseTrH(List<User_Attribute__c> newUserAttributes, Map<Id, User_Attribute__c> oldUserAttributesMap) {
        this.newUserAttributes = newUserAttributes;
        this.oldUserAttributesMap = oldUserAttributesMap;
    }

    public override void afterInsert() {
        updateReaCases();
    }

    public override void afterUpdate() {
        updateReaCases();
    }

    @TestVisible
    private void updateReaCases() {
        Map<Id, User_Attribute__c> buildingIdToUserAttribute = prepareBuildingActors();
        if (buildingIdToUserAttribute.isEmpty()) {
            return;
        }
        findAndUpdateReaCase(buildingIdToUserAttribute);
    }

    private Map<Id, User_Attribute__c> prepareBuildingActors() {
        Map<Id, User_Attribute__c> buildingIdToUserAttribute = new Map<Id, User_Attribute__c>();
        for (User_Attribute__c ua : newUserAttributes) {
            User_Attribute__c oldUa = oldUserAttributesMap?.get(ua.Id);
            if (ua.Building_Team_Role__c == GlobalConstants.USER_ATTRIBUTE_REA && (context == TriggerContext.AFTER_INSERT
                    || (context == TriggerContext.AFTER_UPDATE && TriggerUtility.isFieldValueChanged(ua, oldUa, 'User__c')))) {
                buildingIdToUserAttribute.put(ua.Building__c, ua);
            }
        }
        return buildingIdToUserAttribute;
    }

    private void findAndUpdateReaCase(Map<Id, User_Attribute__c> buildingIdToUserAttribute) {
        List<Case> casesToUpdate = new List<Case>();
        Id reaCaseRtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(GlobalConstants.CASE_RT_NAME_REA).getRecordTypeId();
        for (Case caseRec : [SELECT Id, Building_Nearest_Address__c, OwnerId FROM Case
                             WHERE Building_Nearest_Address__c IN :buildingIdToUserAttribute.keySet() AND RecordTypeId = :reaCaseRtId]) {
            caseRec.OwnerId = buildingIdToUserAttribute.get(caseRec.Building_Nearest_Address__c).User__c;
            casesToUpdate.add(caseRec);
        }
        if (!casesToUpdate.isEmpty()) {
            dml.add(casesToUpdate, DmlConsolidator.Operation.FOR_UPDATE);
        }
    }
}