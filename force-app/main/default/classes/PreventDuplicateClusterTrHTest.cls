/************************************************************************************************************************************
    Author      :   Krishana Tupe	
    Description :   This class is used to unit test the functionality of PreventDuplicateClusterTrH class.
					i.e. It's used to prevent users to create/update a cluster record with duplicate name and record type.
	Issue No    : 	ST-6929
    History		:	
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                	AUTHOR                  	DETAIL
    1           10 September 2020    	Krishana Tupe             	Initial Developement
**************************************************************************************************************************************/
@isTest
public class PreventDuplicateClusterTrHTest {
    private final static Id WEWORK_SYS_ADMIN_PROFILE_ID = [SELECT Id FROM Profile WHERE Name = 'Wework System Administrator'].Id;
    private final static String CLUSTER_USER1_LASTNAME = 'TestClusterSalesManager1';
    private final static String CLUSTER_USER1_USERNAME = 'testclustersalesmanager1@weworkexample.com';
    private final static String CLUSTER_USER1_EMAIL = 'testclustersalesmanager1@xample.com';
    private final static String CLUSTER_USER2_LASTNAME = 'TestClusterSalesManager1';
    private final static String CLUSTER_USER2_USERNAME = 'testclustersalesmanager2@weworkexample.com';
    private final static String CLUSTER_USER2_EMAIL = 'testclustersalesmanager2@xample.com';
    private final static Map<String, Schema.RecordTypeInfo> CLUSTER_RECORD_TYPE_INFO =  Schema.SObjectType.Cluster__c.getRecordTypeInfosByDeveloperName();
    private final static Id CLUSTER_GROUP_RECORD_TYPE_ID = CLUSTER_RECORD_TYPE_INFO.get('Cluster_Group').getRecordTypeId();
    private final static Id SALES_CLUSTER_RECORD_TYPE_ID = CLUSTER_RECORD_TYPE_INFO.get('Sales_Cluster').getRecordTypeId();
    private final static Id SUB_TERRITORY_RECORD_TYPE_ID = CLUSTER_RECORD_TYPE_INFO.get('Sub_Territory').getRecordTypeId();    
    private final static String CLUSTER1_NAME = 'Test Cluster 1';
    private final static String CLUSTER2_NAME = 'Test Cluster 2';
    private final static String ERROR_MESSAGE = System.Label.Duplicate_Cluster_Error_Message;
    
    @testSetup
    private static void setupTestData(){
        List<User> usersForClusters = new List<User>();
        usersForClusters.add(generateUserRecord(CLUSTER_USER1_LASTNAME, CLUSTER_USER1_USERNAME, CLUSTER_USER1_EMAIL));
        usersForClusters.add(generateUserRecord(CLUSTER_USER2_LASTNAME, CLUSTER_USER2_USERNAME, CLUSTER_USER2_EMAIL));
        TestingUtility.insertListWithAssert(usersForClusters);
        
        List<Cluster__c> newClusterRecordsToInsert = new List<Cluster__c>();
        newClusterRecordsToInsert.add(makeClusterRecord(CLUSTER1_NAME, usersForClusters[0].Id,  usersForClusters[1].Id, CLUSTER_GROUP_RECORD_TYPE_ID));
        newClusterRecordsToInsert.add(makeClusterRecord(CLUSTER1_NAME, usersForClusters[0].Id,  usersForClusters[1].Id, CLUSTER_GROUP_RECORD_TYPE_ID));
        newClusterRecordsToInsert.add(makeClusterRecord(CLUSTER2_NAME, usersForClusters[0].Id,  usersForClusters[1].Id, SALES_CLUSTER_RECORD_TYPE_ID));
        Database.insert(newClusterRecordsToInsert, false);         
    }
    
    //This test method is used to verify the duplicate cluster records should not be created with same name and record type.   
    @isTest
    private static void verifyPreventDuplicateClusterCreation(){
        Test.startTest();       
        List<Cluster__c> dbCusters = getDBClusters();        
        System.assert(dbCusters.size() == 2);
        Set<String> userNames = new Set<String>{CLUSTER_USER1_USERNAME, CLUSTER_USER2_USERNAME};
            List<User> usersForClusters = [SELECT Id FROM User WHERE UserName IN: userNames ORDER BY CreatedDate ASC];
        List<Cluster__c> newClusterRecordsToInsert = new List<Cluster__c>();
        newClusterRecordsToInsert.add(makeClusterRecord(CLUSTER1_NAME, usersForClusters[0].Id,  usersForClusters[1].Id, CLUSTER_GROUP_RECORD_TYPE_ID));
        newClusterRecordsToInsert.add(makeClusterRecord(CLUSTER1_NAME, usersForClusters[0].Id,  usersForClusters[1].Id, SALES_CLUSTER_RECORD_TYPE_ID));
        List<Database.SaveResult> saveResults = Database.insert(newClusterRecordsToInsert, false);
        Test.stopTest(); 
        for(Integer index = 0; index < saveResults.size(); index++){
            Database.SaveResult result = saveResults[index];
            if(index == 0){
                System.assertEquals(false, result.isSuccess(), 'record should thrown an exception');
                Database.Error err = result.getErrors()[0];
                System.assert(err.getMessage().contains(ERROR_MESSAGE), 'duplicate record should not be created error message should be thrown');
            }else{
                System.assertEquals(true, result.isSuccess(), 'record should be created successfully');
            }            
        }
        checkFinalDatabaseStateAssertionOfClusters(3, 1, 2); /* Params: 1. #of db cluster, 2. #of clusterGroupTypeRecods, 3. #of salesClusterTypeRecods*/   
    }
    
    //This test method is used to verify the duplicate cluster records should not be updated with same name and record type.   
    @isTest
    private static void verifyPreventDuplicateClusterUpdate(){
        Test.startTest();
        Set<String> userNames = new Set<String>{CLUSTER_USER1_USERNAME, CLUSTER_USER2_USERNAME};
            List<User> usersForClusters = [SELECT Id FROM User WHERE UserName IN: userNames ORDER BY CreatedDate ASC];
        Cluster__c newCluserRecord = makeClusterRecord(CLUSTER1_NAME, usersForClusters[0].Id,  usersForClusters[1].Id, SUB_TERRITORY_RECORD_TYPE_ID);
        insert newCluserRecord;
        newCluserRecord.RecordTypeId = CLUSTER_GROUP_RECORD_TYPE_ID;
        try{
            update newCluserRecord;
        }catch(Exception pEx){            
            System.assert(pEx.getMessage().contains(ERROR_MESSAGE), 'duplicate record should not be created error message should be thrown');
        } 
        Test.stopTest(); 
        checkFinalDatabaseStateAssertionOfClusters(3, 1, 1);  /* Params: 1. #of db cluster, 2. #of clusterGroupTypeRecods, 3. #of salesClusterTypeRecods*/                 
    }
    
    private static void checkFinalDatabaseStateAssertionOfClusters(Integer dBrecordsSize, Integer cluserGroupRecTypeRecordsCount, Integer salesCluserRecTypeRecordsCount){
        List<Cluster__c> dbClusterRecords = getDBClusters();
        System.assert(dbClusterRecords.size() == dBrecordsSize);
        Integer cluserGroupRecTypeCount = 0;
        Integer salesCluserRecTypeCount = 0;
        for(Cluster__c dbClusterRec : dbClusterRecords){
            if(dbClusterRec.RecordTypeId == CLUSTER_GROUP_RECORD_TYPE_ID){
                cluserGroupRecTypeCount++; 
            }else if(dbClusterRec.RecordTypeId == SALES_CLUSTER_RECORD_TYPE_ID){
                salesCluserRecTypeCount++; 
            }
        }
        System.assert(cluserGroupRecTypeCount == cluserGroupRecTypeRecordsCount, 'Cluster Group type cluster records count is not valid in the database.');
        System.assert(salesCluserRecTypeCount == salesCluserRecTypeRecordsCount, 'Sales Cluster type cluster records count is not valid in the database.');
    }
    
    private static List<Cluster__c> getDBClusters(){
        return [SELECT Id, Name, RecordTypeId FROM Cluster__c ORDER BY CreatedDate ASC];
    }
    
    private static User generateUserRecord(String uLastName, String userName, String uEmail){
        Map<String, Object> mapClusterSalesUser = new Map<String, Object>();
        mapClusterSalesUser.put('LastName', uLastName);
        mapClusterSalesUser.put('Username', userName);
        mapClusterSalesUser.put('Email', uEmail);
        return TestingUtility.insertUserWithAssert(WEWORK_SYS_ADMIN_PROFILE_ID, mapClusterSalesUser, false);
    }
    
    private static Cluster__c makeClusterRecord(String clusterName, Id clusterSalesManagerId, Id clusterSalesLeadId, Id cluserRecordTypeId){
        Cluster__c cluserRec = new Cluster__c(Name = clusterName);
        cluserRec.Cluster_Sales_Manager__c = clusterSalesManagerId;
        cluserRec.Sales_Lead__c = clusterSalesLeadId;       
        cluserRec.RecordTypeid = cluserRecordTypeId;        
        return cluserRec;     
    }
    
}