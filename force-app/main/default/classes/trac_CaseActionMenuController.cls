/**
 * @description apex controller for the Case Action Menu (split and escalate buttons)
 * @name trac_CaseActionMenuController
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-09-30
 */

public with sharing class trac_CaseActionMenuController {
    @TestVisible public static String KEY_FEE = 'feeVisible';
    @TestVisible public static String KEY_USER_IN_QUEUE = 'userInQueue';

    @AuraEnabled
    public static Map<String,Boolean> loadButtonInfo(String caseId) {
        Map<String,Boolean> returnMap = new Map<String, Boolean>();
        User user = [
                SELECT Profile.UserLicense.Name
                FROM User
                WHERE Id = :UserInfo.getUserId()];
        returnMap.put(KEY_FEE,user.Profile.UserLicense.Name == 'Salesforce');

        Case cs = [SELECT OwnerId FROM Case WHERE Id = :caseId];
        if(String.valueOf(cs.OwnerId).startsWith('00G')) {
            List<GroupMember> gms = [SELECT Id FROM GroupMember WHERE GroupId = :cs.OwnerId AND UserOrGroupId = :UserInfo.getUserId()];
            returnMap.put(KEY_USER_IN_QUEUE,gms.size() > 0);
        }
        else {
            returnMap.put(KEY_USER_IN_QUEUE, false);
        }

        return  returnMap;
    }
    

    @AuraEnabled
    public static Boolean assignCaseToUser(String caseId) {
        Database.SaveResult sr = Database.update(new Case(Id = caseId,OwnerId = UserInfo.getUserId()));
        return sr.success;
    }

}