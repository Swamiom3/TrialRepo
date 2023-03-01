/************************************************************************************************************
* @description : Test class of FeedCommentTriggerHandler
* @author      : Cloud Journey
* @date        : 2021-02-19
* **********************************************************************************************************/
@isTest
public class FeedCommentTriggerHandlerTest {
	@isTest
    public static void updateParentCaseFieldsTest(){
        Case testCase = new Case();
		insert testCase;
        
        FeedItem testFeed = new FeedItem();
        testFeed.ParentId = testCase.Id;
        testFeed.Body = 'Test Parent Feed';
        insert testFeed;
        
        Test.startTest();
        FeedComment testFeedComment = new FeedComment();
        testFeedComment.FeedItemId = testFeed.Id;
        testFeedComment.CommentBody = 'Test Feed Comment';
        insert testFeedComment;
        Test.stopTest();
        
        Case testUpdateCase = [SELECT Id,Latest_Post_Time__c,User_with_Latest_Communication__c FROM Case WHERE Id=:testCase.Id];
        system.assert(testUpdateCase.Latest_Post_Time__c != null && testUpdateCase.User_with_Latest_Communication__c != null);
    }
}