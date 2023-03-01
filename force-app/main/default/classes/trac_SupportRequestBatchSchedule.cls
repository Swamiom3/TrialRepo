/**
 * @description Scheduler class for trac_SupportRequestBatch - It runs in every 6 hours
 * @name trac_SupportRequestBatchSchedule
 * @author Shubham Jain, Traction on Demand
 * @date 2020-01-21
 */

global with sharing class trac_SupportRequestBatchSchedule implements Schedulable {
    global void execute(SchedulableContext SC) {
        trac_SupportRequestBatch b = new trac_SupportRequestBatch();
        Database.executeBatch(b, 200);
    }
}