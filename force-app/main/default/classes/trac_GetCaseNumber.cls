/**
 * @description method to be called by a flow to get the case number based on id
 *              (sharing rules arent being respected by the flow get record node)
 * @name trac_GetCaseNumber
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-10-16
 */

global without sharing class trac_GetCaseNumber {

    @InvocableMethod(Label='Get Case Number' Description='Pass in a case id to and get returned the case number')
    public static List<String> getCaseNumber(List<Inputs> inputs) {
        try {
            String caseId = inputs[0].caseId;
            List<Case> cases = [
                    SELECT CaseNumber
                    FROM Case
                    WHERE Id = :caseId];
            return new List<String>{
                    cases[0].CaseNumber
            };
        }
        catch (Exception e) {
            return null;
        }
    }

    global class Inputs {
        @InvocableVariable(Label='Case Record Id' Required=true)
        global String caseId;
    }

    class trac_GetCaseNumberException extends Exception {}
}