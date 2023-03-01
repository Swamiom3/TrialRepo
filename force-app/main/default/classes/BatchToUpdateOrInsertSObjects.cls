/************************************************************************************************************************************
	Author		: 	Nikhil Mehta
	Description	: 	This batch class is to update record.
	----------------------------------------------------------------------------------------------------------------------------------
	VERSION		DATE	        		AUTHOR                     	DETAIL
	1	    	22 February 2019		Nikhil Mehta             	Initial Developement
**************************************************************************************************************************************/
public class BatchToUpdateOrInsertSObjects implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    public List<sObject> lstRecordsToUpdate;
    public Boolean useForDataMigration = false;
    
  /************************************************************************************************************************************
        Author              :   Nikhil Mehta
        Description         :   Constructor for initialization.
        Created Date  		:   22 February 2019
		Issue No.			:	-
  **************************************************************************************************************************************/    
    public BatchToUpdateOrInsertSObjects(List<sObject> lstRecordsToUpdate){
        this.lstRecordsToUpdate = lstRecordsToUpdate;
    }
    
    /************************************************************************************************************************************
        Author              :   Nikhil Mehta
        Description         :   Constructor for initialization.
        Created Date  		:   23 July 2019
		Issue No.			:	-
  **************************************************************************************************************************************/    
    public BatchToUpdateOrInsertSObjects(List<sObject> lstRecordsToUpdate, Boolean useForDataMigration){
        this.lstRecordsToUpdate = lstRecordsToUpdate;
        this.useForDataMigration = useForDataMigration;
    }
    
  /************************************************************************************************************************************
        Author              :   Nikhil Mehta
        Description         :   Start method of batch.
        Created Date  		:   22 February 2019
		Issue No.			:	-
  **************************************************************************************************************************************/    
    public List<sObject> start(Database.BatchableContext BC){ 
            return lstRecordsToUpdate;
    }
    
  /************************************************************************************************************************************
        Author              :   Nikhil Mehta
        Description         :   this method is used for update.
        Created Date  		:   22 February 2019
		Issue No.			:	-
  **************************************************************************************************************************************/    
    public void execute(Database.BatchableContext BC, List<sObject> lstRecordsToUpdate){
        if(lstRecordsToUpdate != NULL && !lstRecordsToUpdate.isEmpty()){
            if(string.isNotBlank(lstRecordsToUpdate[0].Id)){
                Database.update(lstRecordsToUpdate, false);
            }else{
                Database.insert(lstRecordsToUpdate, false);
            }
        }
    }
    
  /************************************************************************************************************************************
        Author              :   Nikhil Mehta
        Description         :   finish mehod
        Created Date  		:   22 February 2019
		Issue No.			:	-
  **************************************************************************************************************************************/    
    public void finish(Database.BatchableContext BC){
        if(useForDataMigration){
            startBatch();
        }
    }
    
    public static void startBatch(){
        MetadataSetting__mdt objCodeForDataMigrationBatch = Settings.getMetadataSetting('CodeForDataMigrationBatch');
        Map<String, String> mapResult = (Map<String, String>) JSON.deserialize(objCodeForDataMigrationBatch.Data__c, Map<String, String>.class);
        String strCodeUrl = mapResult.get('code');
        String endpointUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v45.0/tooling/executeAnonymous/?anonymousBody=' + EncodingUtil.urlEncode(strCodeUrl, 'UTF-8');
        if(!Test.isRunningTest()){
           LightningComponentController.executeRestQuery(false, 'GET', endpointUrl, new Map<String, String>{'Content-Type'=>'application/json','Accept'=>'application/json', 'Authorization'=>'Bearer '+userInfo.getSessionId()}, ''); 
        }
    }
}