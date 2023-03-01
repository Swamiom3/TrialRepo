/*********************************************************************************************************************************
Author      :   Vaishnavi Khandar
Description :   This class is used to schedule jobs to process records for REAP Integration.
__________________________________________________________________________________________________________________________________
History
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL                                          Issue No.
1           15 Novemeber 2021   Vaishnavi Khandar       Initial Developement.                              -
*********************************************************************************************************************************/
public class ScheduledBatchForREAPIntergration implements Schedulable{
    public Integer batchSize = 1;
    
    public ScheduledBatchForREAPIntergration(){
    }
    
    public void execute(SchedulableContext ctx){
        BatchToUpdateREAPDetailsOnBuildingLease scheduleBatch = new BatchToUpdateREAPDetailsOnBuildingLease();
        Database.executeBatch(scheduleBatch, this.batchSize);
    }
}