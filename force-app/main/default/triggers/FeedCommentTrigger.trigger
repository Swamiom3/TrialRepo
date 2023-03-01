/************************************************************************************************************
* @description : Trigger for FeedComment Object
* @author      : Cloud Journey
* @date        : 2021-02-19
* **********************************************************************************************************/
trigger FeedCommentTrigger on FeedComment (after insert) {
    if(trigger.isAfter){
        if(trigger.isInsert){
            FeedCommentTriggerHandler.updateParentCaseFields(trigger.new);
        }
    }
}