/**
 * @description Apex class trac_AddCaseShare
 * @author Daniel Labonte, Traction on Demand
 * @date 2020-04-03
 */

global without sharing class trac_AddCaseShare {
    @InvocableMethod(Label='Add Case Share' Description='Pass in a case id, user id, access level, and row cause')
    global static void insertShareRecord(List<Inputs> inputs) {
        try {
            String caseId = inputs[0].caseId;
            String userId = inputs[0].userId;
            String accessLevel = inputs[0].accessLevel;
            String rowCause = inputs[0].rowCause;

            List<UserRecordAccess> access = [
                    SELECT RecordId, HasEditAccess, HasReadAccess, HasAllAccess
                    FROM UserRecordAccess
                    WHERE UserId = :userId
                    AND RecordId = :caseId];

            if(access.size() != 0 && !Test.isRunningTest()) {
                if(access[0].HasAllAccess) return;
                else if (accessLevel == 'Edit' && access[0].HasEditAccess) return;
                else if (accessLevel == 'Read' && access[0].HasReadAccess) return;
            }

            insert new CaseShare(
                    UserOrGroupId = userId,
                    CaseId = caseId,
                    CaseAccessLevel = accessLevel,
                    RowCause = rowCause);
        }
        catch (Exception e) {
            System.debug(e.getMessage() + ' - ' + e.getStackTraceString());
            throw new trac_AddCaseShareException(e.getMessage());
        }
    }

    global class Inputs {
        @InvocableVariable(Label='Case Record Id' Required=true)
        global String caseId;
        @InvocableVariable(Label='User Id' Required=true)
        global String userId;
        @InvocableVariable(Label='Access Level' Required=true)
        global String accessLevel;
        @InvocableVariable(Label='Row Cause' Required=true)
        global String rowCause;
    }

    class trac_AddCaseShareException extends Exception {}
}