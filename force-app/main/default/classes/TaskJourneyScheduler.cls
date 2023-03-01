/************************************************************************************************************************************
        Author              : Tomasz Sadowski
        Description         : https://jira.weworkers.io/browse/ST-7657
        Last Modified Date  : 16 Feb 2021
        Last Modified By    : Tomasz Sadowski
        Issue No            : ST-7657
    ********************************************************************************************************************************/
public with sharing class TaskJourneyScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new TaskJourneyBatch(), 200);
    }
}