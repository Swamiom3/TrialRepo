/************************************************************************************************************
* @description : Handler class of FeedCommentTrigger
* @author      : Cloud Journey
* @date        : 2021-02-19
* **********************************************************************************************************/
public class FeedCommentTriggerHandler {
    /************************************************************************************************************
* @description : Method that updates the Parent Case's Post Time Field
* @author      : Cloud Journey
* @date        : 2021-02-19
* **********************************************************************************************************/
    public static void updateParentCaseFields(List<FeedComment> newFeedCommentList){
        List<Case> caseToBeUpdatedList = new List<Case>();
        Map<Id, FeedComment> caseToFeedCommentMap = new Map<Id,FeedComment>();
        
        for(FeedComment comment: newFeedCommentList){
            //Check if the Parent Id is a Case
            if(comment.ParentId.getSObjectType().getDescribe().getName() == 'Case'){
                caseToFeedCommentMap.put(comment.ParentId, comment);
            }
        }

        if(caseToFeedCommentMap.size() > 0){
            for(Case parentCase : [SELECT Id,Latest_Post_Time__c,User_with_Latest_Communication__c FROM Case WHERE Id IN:caseToFeedCommentMap.keySet()]){
                if(parentCase.Latest_Post_Time__c != system.now()){
                    parentCase.Latest_Post_Time__c = system.now();
                    parentCase.User_with_Latest_Communication__c = caseToFeedCommentMap.get(parentCase.Id).InsertedById;
                    caseToBeUpdatedList.add(parentCase);
                }
            }
        }

        if(caseToBeUpdatedList.size() > 0){
            update caseToBeUpdatedList;
        }
    }
}