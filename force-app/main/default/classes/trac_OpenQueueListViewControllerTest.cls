/**
* @description unit tests for the trac_OpenQueueListViewController class
* @name trac_OpenQueueListViewControllerTest
* @author Daniel Labonte, Traction on Demand
* @date 2019-08-03
*/

@IsTest
private class trac_OpenQueueListViewControllerTest {
    static final TLTestFactory factory = new TLTestFactory();
    static User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1];
    static final String GROUP_NAME = 'testgroup';
    
    static List<Group> groups;
    
    
    @TestSetup
    static void setup() {
        List<Group> groups = factory.createSObjects(new Group(),2,false);
        for (Integer i = 0; i < groups.size(); i++) {
            groups[i].Name = GROUP_NAME + i;
        }
        insert groups;
        List<QueueSobject> mappingObjects = new List<QueueSobject>();
        for(Group grp : groups) {
            mappingObjects.add(new QueueSobject(QueueId = grp.Id, SobjectType = 'Case'));
        }
        insert mappingObjects;
        
        //        List<GroupMember> groupMembers =  new List<GroupMember>();
        //        for(Group grp : groups) {
        //            groupMembers.add((GroupMember) factory.createSObject(new GroupMember(GroupId=grp.Id, UserOrGroupId=user.Id), false));
        //        }
        //        insert groupMembers;
        
        
    }
    
    @IsTest
    static void testGetAllCasesForGroups() {
        Id regionRecordTypeId = Schema.SObjectType.Location__c.getRecordTypeInfosByDeveloperName().get('Region').getRecordTypeId();
        Id territoryRecordTypeId = Schema.SObjectType.Location__c.getRecordTypeInfosByDeveloperName().get('Territory').getRecordTypeId();
        Id buildingRecordTypeId = Schema.SObjectType.Location__c.getRecordTypeInfosByDeveloperName().get('Building').getRecordTypeId();
        final String BUIDING_NAME = 'TestBuilding123';
        
        Location__c region = new Location__c(Name = 'Region', RecordTypeId = regionRecordTypeId);
        insert region;
        
        Location__c territory = new Location__c(Name = 'Territory', Region__c = region.Id, RecordTypeId = territoryRecordTypeId);
        insert territory;
        
        Location__c location = new Location__c(Name = BUIDING_NAME, Territory__c = territory.Id, RecordTypeId = buildingRecordTypeId);
        insert location;
        //Location__c region = (Location__c) factory.createSObject(new Location__c(Name = 'Region', RecordTypeId = regionRecordTypeId),true);
        //Location__c territory = (Location__c) factory.createSObject(new Location__c(Name = 'Territory', Region__c = region.Id,RecordTypeId = buildingRecordTypeId),true);
        //Location__c location = (Location__c) factory.createSObject(new Location__c(Name = BUIDING_NAME, Territory__c = territory.Id, RecordTypeId=buildingRecordTypeId),true);
        
        List<Group> selectedGroups = [SELECT Name, Id FROM Group WHERE Name LIKE :('%'+BUIDING_NAME)];
        
        //location.Community_Team_Queue_Id__c = selectedGroups[0].Id;
        //location.Facilities_Queue_Id__c = selectedGroups[1].Id;
        
        Integer CASE_LIMIT = 4;
        String query = 'SELECT Id FROM Group WHERE Name LIKE \'' + GROUP_NAME + '%\'';
        List<Group> myGroups = Database.query(query);
         
        for(Group grp : myGroups) {
            factory.createSObjects(new Case(OwnerId = grp.Id, Subject='test', Description='test'),2,true);
        }
        
        List<Case> myOpenCases;
        Integer caseCount;
        
        Test.startTest();
        System.runAs(user) {
            myOpenCases = trac_OpenQueueListViewController.getAllSObjectsForLocations('Case','Closed,Resolved', CASE_LIMIT, false, new List<String>{'Status'});
            caseCount = trac_OpenQueueListViewController.getRecordCount('Case','Closed,Resolved',false, new List<String>{'Status'});
        }
        Test.stopTest();
        
        System.debug(myOpenCases);
        System.debug(myOpenCases.size());
        
        System.assert(myOpenCases.size() > 0 && myOpenCases.size() <= CASE_LIMIT, 'No cases were found');
        System.assert(caseCount > 0, 'No case records were counted');
    }
}