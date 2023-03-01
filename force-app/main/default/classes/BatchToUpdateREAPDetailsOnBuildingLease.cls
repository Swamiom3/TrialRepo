/*********************************************************************************************************************************
Author      :   Vaishnavi Khandar
Description :   This class contains the business logic for REAP Integration API details on Building.
__________________________________________________________________________________________________________________________________
History
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL                                          Issue No.
1			15 November 2021    Vaishnavi Khandar	    Initial Developement.  
*********************************************************************************************************************************/
public class BatchToUpdateREAPDetailsOnBuildingLease implements Database.Batchable<sObject>, Database.AllowsCallouts{
    public String queryString = '';
    public BatchToUpdateREAPDetailsOnBuildingLease(){
        this.queryString = REAPIntegrationUtils.getQueryBySetting();
    }
    /****************************************************************************************************************************
        Author              : Vaishnavi Khandar
        Description         : This method is used to fetch buildinga data.
        Created Date        : 15 November 2021
   *****************************************************************************************************************************/    
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(this.queryString);
    }
    
    /****************************************************************************************************************************
        Author              : Vaishnavi Khandar
        Description         : This method is used to make callout and map the payload details on Building Lease and Building Lease Financial details.
        Created Date        : 15 November 2021
   *****************************************************************************************************************************/    
    public static void execute(Database.BatchableContext bc, List<sObject> buildingIds){
        REAPIntegrationUtils.makeCalloutForREAPIntegration(buildingIds, false);
    }
    
    public void finish(Database.BatchableContext bc){
    }
}