/**
 * @description unit tests for the trac_CaseActionMenuController class
 * @name trac_CaseActionMenuControllerTest
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-10-24
 */

@IsTest
private class trac_CaseActionMenuControllerTest {
    static final TLTestFactory factory = new TLTestFactory();
    static final String CASESUBJECT = 'MYCASE';

    static final String ADMIN_UNIQUE = 'test-admin-user';
    static final String DOMAIN = '@test-weco.test';

    static final String REGION_NAME = 'Region';
    static final String TERRITORY_NAME = 'Territory';
    static final String BUILDING_NAME = 'Building1234qwerasdfzxcvasdfqwer1234';

    @TestSetup
    static void setup() {
        User admin = TLTestUtils.createUsers('System Administrator',1)[0];
        admin.Username = ADMIN_UNIQUE + DOMAIN;
        admin.CommunityNickname = ADMIN_UNIQUE;

        insert admin;

        Test.startTest();
        Location__c region = (Location__c) factory.createSObject(new Location__c(Name=REGION_NAME,RecordTypeId=trac_LocationConstants.RTID_REGION),true);
        Location__c territory = (Location__c) factory.createSObject(new Location__c(Name=TERRITORY_NAME,RecordTypeId=trac_LocationConstants.RTID_TERRITORY,Region__c=region.Id),true);
        factory.createSObject(new Location__c(Name=BUILDING_NAME,RecordTypeId=trac_LocationConstants.RTID_BUILDING,Territory__c=territory.Id),true);
        Test.stopTest();

        List<Group> queues = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND  DeveloperName = :'CM_'+BUILDING_NAME];
        update new Group(Id=queues[0].Id,Email='asdf@asdf.asdf');

        Case cs = (Case) factory.createSObject(new Case(Subject = CASESUBJECT, OwnerId = queues[0].Id),false);
        insert cs;
    }


    @IsTest
    static void testLoadButtonInfo() {
        User user = [SELECT Id FROM User WHERE Username = :ADMIN_UNIQUE+DOMAIN];
        List<Group> queues = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND  DeveloperName = :'CM_'+BUILDING_NAME];
        Case cs = [SELECT Id FROM Case WHERE Subject = :CASESUBJECT];
        insert new GroupMember(GroupId = queues[0].Id, UserOrGroupId = user.Id);

        Map<String,Boolean> attributeMap = trac_CaseActionMenuController.loadButtonInfo(cs.Id);
        System.assertEquals(true,attributeMap.get(trac_CaseActionMenuController.KEY_FEE),'The user is not using a salesforce licensed profile');
    }
}