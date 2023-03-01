/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for GroupMemberSelector class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             DETAIL
    1          13 Apr, 2021    Pawel Biszczak     Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class GroupMemberSelectorTest {
    private static GroupMemberSelector groupMemberSelector = new GroupMemberSelector();

    @testSetup
    static void makeData(){
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData.put('objName', 'User');
        recordsData.put('numberOfRecords', 1);
        TestingUtility.getRecords(recordsData);

        Group testGroup = new Group();
        testGroup.Name = 'testGroup';
        TestingUtility.insertWithAssert(testGroup);
    }

    @isTest
    static void shouldGetRecordsByGroupIds(){
        List<GroupMember> groupMembers;

        Test.startTest();
        Group onlyGroup = [SELECT Id
                           FROM Group
                           WHERE Name = 'testGroup'
                           LIMIT 1];
        User onlyUser = [SELECT Id
                         FROM User
                         WHERE LastName LIKE '%testUser%'
                         LIMIT 1];
        GroupMember groupMember1 = new GroupMember();
        groupMember1.GroupId = onlyGroup.Id;
        groupMember1.UserOrGroupId = onlyUser.Id;
        TestingUtility.insertWithAssert(groupMember1);
        GroupMember onlyGroupMember = [SELECT Id, GroupId
                                       FROM GroupMember WHERE id =: groupMember1.id
                                       LIMIT 1];
        groupMembers = groupMemberSelector.getGroupMembersByGroupIds(new List<Id>{ onlyGroupMember.GroupId });
        Test.stopTest();

        System.assertEquals(onlyGroupMember.Id, groupMembers[0].Id, 'Should have same value');
    }
}