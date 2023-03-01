/**
 * @description apex test class for the ChecklistCaseComponent
 * @author Shubham Jain, Traction on Demand
 * @date 2019-08-11
 */

@isTest
public class trac_ChecklistCaseComponentCtrlTest {

    public static List <Map <String, String>> lstMaps = new List <Map <String, String>>();
    public static final TLTestFactory factory = new TLTestFactory();
    
    @testSetup
    static void unitTest() {
        Case objCase = (Case) factory.createSObject(new Case(Subject = 'Test Case', RecordTypeId = TLOrgConstants.SUPPORT_REQUEST_RECORD_TYPE_ID), true);
        Group grp = (Group) factory.createSObject(new Group(Name = 'CMTestGroup1 : Building', DeveloperName = 'CMTestGroup1', Type = 'Queue'), true);
              
        Building__c building = new Building__c();
        building.Name = 'Building';
        insert building;
        
        Blob beforeblob = Blob.valueOf('Unit Test Attachment Body');
        
        ContentVersion objContentVersion = new ContentVersion(title = 'test content trigger', PathOnClient = 'test', VersionData = beforeblob);
        insert objContentVersion;
        
        ContentVersion objContentVer = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :objContentVersion.Id];

        ContentDocumentLink objContentLink = new ContentDocumentLink(LinkedEntityId = objCase.Id, ShareType = 'V', ContentDocumentId = objContentVer.ContentDocumentId);
        insert objContentLink;
        
    }
    
    @isTest
    static void callMethods() {
        Case testCase = [SELECT Id FROM Case WHERE Subject = 'Test Case' LIMIT 1];
        Map <String, String> mapUploadedFileIds = new Map <String, String>();
        
        ContentDocument objContentDocument = [SELECT Id FROM ContentDocument LIMIT 1];

        mapUploadedFileIds.put('documentId', String.valueOf(objContentDocument.Id));
        lstMaps.add(mapUploadedFileIds);
        
        Test.startTest();
        List<trac_ChecklistCaseComponentController.CategoryWrapper> categories = trac_ChecklistCaseComponentController.getCategoryWrappers();
        String returnedString = trac_ChecklistCaseComponentController.createCaseRecord(testCase.Id, lstMaps);
        String recordType = trac_ChecklistCaseComponentController.getRecordTypeId();
        Test.stopTest(); 
        
        system.assert(categories.size() > 0);
        system.assert(returnedString == testCase.Id);
    }
    
    @isTest static void getLocationById(){
        Group grp = [SELECT Id FROM Group WHERE Name = 'CMTestGroup1 : Building'];
        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];

        User u = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = 'cjilag1234423@test.com',
            Alias = 'batman',
            Email='testtermsconditions1234423@kaplan.com',
            EmailEncodingKey='UTF-8',
            Firstname='Bruce',
            Lastname='Wayne',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago');
        insert u;

        System.runas(u) {
            GroupMember grpMembers = (GroupMember) factory.createSObject(new GroupMember(GroupId = grp.Id, UserOrGroupId = UserInfo.getUserId()), true);
            
            Id locId = [SELECT Id FROM Building__c LIMIT 1].Id;
            Location_Queue__c locQueue = new Location_Queue__c();
            locQueue.Queue_Label__c = 'Test';
            locQueue.Queue_Id__c = grp.Id;
            locQueue.Building_Id__c = locId;
            insert locQueue;
 
            Integer listReturnSize = trac_ChecklistCaseComponentController.getLocation().size();
        }
    }
    
    @isTest
    static void unitTestException() {
        List<Building__c> lstLocation = [SELECT Id FROM Building__c];
        test.startTest();
        String s = trac_ChecklistCaseComponentController.createCaseRecord (null, lstMaps);
        test.stopTest();
        String expected = null;
        System.assertEquals(expected, s);
    }

    @isTest
    static void getContactIdTest() {
        Contact testContact = new Contact();
        testContact.FirstName = 'Test';
        testContact.LastName = 'Test';
        testContact.Email = UserInfo.getUserEmail();
        insert testContact;

        test.startTest();
        Id testId = trac_ChecklistCaseComponentController.getContactId();
        test.stopTest();
        system.assert(!String.isEmpty(testId));
    }
}