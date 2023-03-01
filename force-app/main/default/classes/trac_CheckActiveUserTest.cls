/**
* Created by sjain on 5/1/2020.
*/

@isTest
public with sharing class trac_CheckActiveUserTest {

    @TestSetup
    public static void createTestData() {
        Id userId = UserInfo.getUserId();
        TLTestFactory factory = new TLTestFactory();

        Group newQueue = (Group) factory.createSObject(new Group(Name = 'Test queue', type = 'Queue'), true);
        GroupMember newGroupMember = (GroupMember) factory.createSObject(new GroupMember(UserOrGroupId = userId, GroupId = newQueue.Id), true);
    }

    @isTest
    public static void checkActiveMemberExistTest() {
        Group grp = [SELECT Id FROM Group WHERE Name = 'Test queue'];
        List<List<String>> returnStatus = trac_CheckActiveUser.checkActiveMemberExist(new List<String>{
                grp.Id
        });
        List<String> returnStatues = returnStatus[0];
        System.assertEquals('True', returnStatues[0], 'No active member found on the queue');
    }
}