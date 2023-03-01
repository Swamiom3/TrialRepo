/**
 * @description Unit tests for the Invitation class
 * @see Invitation
 * @author Daniel Labonte, Traction on Demand
 * @date 2020-06-02
 */

@IsTest
private class InvitationTest {
    @IsTest
    static void testBehavior() {
        SObject cs = new TLTestFactory().createSObject(new Case(), true);

        medallia_xm__Invitation__c invitation = new medallia_xm__Invitation__c(medallia_xm__ParentId__c = cs.Id);
        insert invitation;

        invitation = [
                SELECT Id, Support_Request__c
                FROM medallia_xm__Invitation__c
                WHERE Id = :invitation.Id
        ];
        
        System.assertEquals(cs.Id, invitation.Support_Request__c,
                'The Support Request was not set on the invitation');
    }
}