@isTest
public class UnomyFeedbackControllerTest  {
    
    @testSetup
    public static void setup() {
        
        //SalesConsoleSettings.createSettings();                
    }
    
    public static testmethod void testSubmitFeedbackRequestAndGetOpenCaseCreationDate() {
        Account objOrgAccRec1 = new Account(Name = 'orgAccRec1', Number_of_Full_Time_Employees__c = 1000, Account_Type__c = 'Org');
        Account objOrgAccRec2 = new Account(Name = 'orgAccRec2', Number_of_Full_Time_Employees__c = 1000, Account_Type__c = 'Org');
        List<Account> listToInsert = new List<Account>();
        listToInsert.add(objOrgAccRec1);
        listToInsert.add(objOrgAccRec2);
        TestingUtility.insertListWithAssert(listToInsert);
        Integer testFTE = 5000;
        String testHQStreet = '123 Test Street';
        String testHQCity = 'New York';
        String testHQState = 'NY';
        String testHQCountry = 'USA';
        String testRefLink = 'http://google.com';
        List<Id> testFiles = new List<Id>();
        
        UnomyFeedbackController.submitFeedbackRequest(objOrgAccRec2.Id, testFTE, testHQStreet, testHQCity, testHQState, testHQCountry, testRefLink, testFiles);
        ContentVersion contentVersion_1 = new ContentVersion(
            Title = 'test',
            PathOnClient = 'test.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion_1;
        ContentVersion contentVersion_2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion_1.Id LIMIT 1];
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        testFiles.add(documents[0].Id);

        Case fCase = null;
        UnomyFeedbackController.submitFeedbackRequest(null, testFTE, testHQStreet, testHQCity, testHQState, testHQCountry, testRefLink, testFiles);
        UnomyFeedbackController.submitFeedbackRequest('0015500000Y8bhIAAR', testFTE, testHQStreet, testHQCity, testHQState, testHQCountry, testRefLink, testFiles);
        UnomyFeedbackController.submitFeedbackRequest(objOrgAccRec1.Id, testFTE, testHQStreet, testHQCity, testHQState, testHQCountry, testRefLink, testFiles);
        List<Case> cases = [SELECT Id, CreatedDate, User_inputed_Account_FTE__c, User_inputed_HQ_Street__c, User_inputed_HQ_City__c, User_inputed_HQ_State__c, User_inputed_HQ_Country__c, Status, Approval_Status__c FROM Case WHERE AccountId =: objOrgAccRec1.Id LIMIT 1];
        if (!cases.isEmpty()) {
            fCase = cases[0];
            System.debug(fCase);
        }
        System.assertEquals(testFTE, fCase.User_inputed_Account_FTE__c);
        System.assertEquals(testHQStreet, fCase.User_inputed_HQ_Street__c);
        System.assertEquals(testHQCity, fCase.User_inputed_HQ_City__c);
        System.assertEquals(testHQState, fCase.User_inputed_HQ_State__c);
        System.assertEquals(testHQCountry, fCase.User_inputed_HQ_Country__c);
        System.assertEquals(UnomyFeedbackController.getOpenCaseCreationDate(objOrgAccRec1.Id).split('\\|')[0], String.valueOf(fCase.CreatedDate));
        System.assertEquals(null, UnomyFeedbackController.getOpenCaseCreationDate('0015500000Y8bhIAAR'));
        Case loadedCase = UnomyCaseClosedController.loadCaseRecord(fCase.Id);
        System.assert(!UnomyCaseClosedController.getPickListValuesIntoList().isEmpty());
        System.assertEquals(loadedCase.Id, fCase.Id);
        User thisUser = new User(Id=UserInfo.getUserId());
		Profile p = [SELECT Id FROM Profile WHERE Name = 'WeWork System Administrator'];
        User authUser = new User(Alias = 'standt',
                                 Email = 'standarduser@testorg.com',
                                 EmailEncodingKey = 'UTF-8',
                                 LastName = 'Testing',
                                 LanguageLocaleKey = 'en_US',
                                 LocaleSidKey = 'en_US',
                                 ProfileId = p.Id,
                                 TimeZoneSidKey = 'America/Los_Angeles',
                                 UserName = 'testuser@enzigmatest.com');
        System.runAs(thisUser) {
            insert authUser;
            Group authGroup = [SELECT Id FROM Group WHERE Type='Queue' AND DeveloperName='SalesOps_Support'];
            GroupMember authMember = new GroupMember(
            	UserOrGroupId = authUser.Id,
                GroupId = authGroup.Id
            );
            insert authMember;
        }
        System.runAs(authUser) {
            System.assertEquals(true, UnomyCaseClosedController.isUserAuthorizedApprover());
            UnomyCaseClosedController.closeCaseRecord(fCase.Id, 'Company Mismatch', 'Test description', true, null);
        }
    }

    public static testmethod void testReenrichRecordAndDeletePushTopic() {
        Account objOrgAccRec1 = new Account(Name = 'orgAccRec', Number_of_Full_Time_Employees__c = 1000, Account_Type__c = 'Org', Website='test.com', LinkedIn_Url__c = 'linkedin.com/company/testcom');
        TestingUtility.insertWithAssert(objOrgAccRec1);
        System.assertEquals(null, UnomyFeedbackController.reenrichRecord(null));
        System.assertEquals(null, UnomyFeedbackController.reenrichRecord('0015500000Y8bhIAAR'));
        String pushTopicName = UnomyFeedbackController.reenrichRecord(objOrgAccRec1.Id);
        System.assert(pushTopicName != null);
        UnomyFeedbackController.deletePushTopic(pushTopicName);
        List<PushTopic> ptList = [SELECT Name FROM PushTopic WHERE Name =: pushTopicName];
        System.assert(ptList.isEmpty());
    }
    
    public static testmethod void testLoadAccountFromLookupId() {
        Account objOrgAccRec1 = new Account(Name = 'orgAccRec', Number_of_Full_Time_Employees__c = 1000, Account_Type__c = 'Org');
        Account a = null;
        TestingUtility.insertWithAssert(objOrgAccRec1);
        
        Contact objContact1 = new Contact(firstname = 'John',lastname = 'Rambo',email = 'john.con1@example.com', AccountId = objOrgAccRec1.Id, Status__c = 'active');
        TestingUtility.insertWithAssert(objContact1);
		a = UnomyFeedbackController.loadAccountFromLookupId(objContact1.AccountId);
		System.assert(a != null);
        System.assertEquals(null, UnomyFeedbackController.loadAccountFromLookupId('0015500000Y8bhIAAR'));
    }
}