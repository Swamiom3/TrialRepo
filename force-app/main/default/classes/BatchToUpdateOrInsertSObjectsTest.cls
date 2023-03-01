@isTest
public class BatchToUpdateOrInsertSObjectsTest{
    
    @isTest
    Public static void batchToUpdateMethod(){
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorForLightning());
        DatabaseResult result = LightningComponentController.executeRestQuery(false, 'GET','http://example.com/example/test', new Map<String,String>{'Authorization'=>'Standard'},'');
        DatabaseResult result1 = LightningComponentController.executeRestQuery(true, 'GET','http://example1.com/example/test', new Map<String,String>{'Authorization'=>'Standard'},'');
        try{
            result  = LightningComponentController.executeRestQuery(null, 'GET','http://example.com/example/test', new Map<String,String>{'Authorization'=>'Standard'},'');//to verify the exception generated with NULL and wrong data
            System.assert(false);
        } catch(Exception exc){
            System.assertNotEquals(null, exc,'Exception cannot be null');
        }
        Account accountObj = new Account(Name='Test Account');
        insert accountObj;
        
        Account createAccount = new Account(LastName='AccountwithoutInsert');
        
        BatchToUpdateOrInsertSObjects controller = new BatchToUpdateOrInsertSObjects(new List<SObject>{accountObj});
        DataBase.executeBatch(controller); 
        BatchToUpdateOrInsertSObjects controller1 = new BatchToUpdateOrInsertSObjects(new List<SObject>{accountObj},true);
        DataBase.executeBatch(controller1);
        
        Test.stopTest();
        System.assertEquals(new List<SObject>{accountObj}, controller.lstRecordsToUpdate, 'Both Variable must have same object');
        System.assertEquals(true, controller1.useForDataMigration, 'useForDataMigration should be true');
    }
}