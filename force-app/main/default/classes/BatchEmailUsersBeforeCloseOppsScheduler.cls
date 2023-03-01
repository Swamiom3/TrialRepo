/*************************************************************************************************************************************************
Name              :BatchEmailUsersBeforeCloseOppsScheduler.cls 
Description       : Scheduler for BatchEmailUsersBeforeCloseOpps
					this batch should be run weekly. 

Revision History  :-
Created/Modified by                     Created/Modified Date       Requested by                  Technical Design Proposal
---------------------------------------------------------------------------------------------------------------------------------------------------
1. Rashad Saeed (initial implementation)     27 AUG 2019                 WeWork                              CSI-2327                      
---------------------------------------------------------------------------------------------------------------------------------------------------
**************************************************************************************************************************************************/
global class BatchEmailUsersBeforeCloseOppsScheduler implements Schedulable{ 
    final static Id Enterprise_SolutionsId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('New Business').getRecordTypeId();
    @ReadOnly 
    global void execute (SchedulableContext ctx){ 
        List<AggregateResult> query = new list <AggregateResult>();
        if (test.isRunningTest())
            query = [select ownerId from opportunity group by ownerId limit 10];
        else
            query = [select ownerId from opportunity where
                                           recordTypeId <> :Enterprise_SolutionsId
                                           and (stageName ='Qualifying' or stageName = 'Selling')
                                           and closeDate < TODAY
                                           and ((lastModifiedDate < LAST_N_DAYS:90 and LastActivityDate = null)
                                                or (lastModifiedDate < LAST_N_DAYS:90 and LastActivityDate < LAST_N_DAYS:90 and LastActivityDate <> null) 
                                               )
                                           group by ownerId
                                          ]; 
        set<Id> userIds = new set<Id>(); 
        for(AggregateResult ar : query){ 
            userIds.add ((Id)ar.get('ownerId')); 
        } 
        Database.executeBatch(new BatchEmailUsersBeforeCloseOpps(userIds)); 
    } 
}