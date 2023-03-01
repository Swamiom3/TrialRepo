/**
 * @description invocable class to add a user to a case team by bypassing permissions
 * @name trac_AddCaseTeamMember
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-10-28
 */

global without sharing class trac_AddCaseTeamMember {
    @InvocableMethod(Label='Add Case Team Member' Description='Pass in a case id, user id, and role id')
    global static void getCaseNumber(List<Inputs> inputs) {
        try {
            String caseId = inputs[0].caseId;
            String userId = inputs[0].userId;
            String roleId = inputs[0].roleId;

            insert new CaseTeamMember(ParentId=caseId, MemberId=userId, TeamRoleId=roleId);
        }
        catch (Exception e) {
            System.debug(e.getMessage());
        }
    }

    global class Inputs {
        @InvocableVariable(Label='Case Record Id' Required=true)
        global String caseId;
        @InvocableVariable(Label='User Id' Required=true)
        global String userId;
        @InvocableVariable(Label='Case Role Id' Required=true)
        global String roleId;
    }

    class trac_GetCaseNumberException extends Exception {}
}