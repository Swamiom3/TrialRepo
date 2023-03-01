/**
 * @description indicates whether a given user id is assigned to a permission set
 * @name trac_PermissionSetAssigned
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-11-11
 */

global with sharing class trac_PermissionSetAssigned {
    @InvocableMethod(Label='Is User Assigned Permission Set')
    public static List<String> findAssignment(List<Inputs> inputs) {
        String userId = inputs[0].userId;
        String permSetDevName = inputs[0].permissionSetName;
        List<PermissionSetAssignment> assignments = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :userId AND PermissionSet.Name = :permSetDevName];
        return new List<String>{String.valueOf(assignments.size() > 0)};
    }

    global class Inputs {
        @InvocableVariable(Label='User Id' Required=true)
        global String userId;
        @InvocableVariable(Label='Permission Set API Name' Required=true)
        global String permissionSetName;
    }
}