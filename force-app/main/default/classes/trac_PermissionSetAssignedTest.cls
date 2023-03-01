/**
 * @description ${DESCRIPTION}
 * @name trac_PermissionSetAssignedTest
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-11-19
 */

@IsTest
private class trac_PermissionSetAssignedTest {
    @IsTest
    static void testFindAssignment() {
        User user = TLTestUtils.createUsers('System Administrator',1,true)[0];
        PermissionSet permSet = new PermissionSet(Name='My_Test_Permission_Set', Label='My Test Permission Set');
        insert permSet;
        PermissionSetAssignment assignment = new PermissionSetAssignment(AssigneeId=user.Id,PermissionSetId=permSet.Id);
        insert assignment;

        trac_PermissionSetAssigned.Inputs inputs = new trac_PermissionSetAssigned.Inputs();
        inputs.userId = user.Id;
        inputs.permissionSetName = permSet.Name;

        List<String> returnedVal = trac_PermissionSetAssigned.findAssignment(new List<trac_PermissionSetAssigned.Inputs>{inputs});
        System.assert(returnedVal[0] == 'true');
    }
}