/**
* @description Test class for the trac_LocationWrapper
* @date 2021-10-06
*/
@isTest
public class trac_LocationWrapperTest {
    public static final TLTestFactory factory = new TLTestFactory();
    
    @isTest
    public static void trac_LocationWrapperTest(){
        Id buildingRecordTypeId = Schema.SObjectType.Location__c.getRecordTypeInfosByDeveloperName().get('Building').getRecordTypeId();
        
        Location__c objLocation = new Location__c();
        objLocation.Name = 'Building';
        objLocation.RecordTypeId = buildingRecordTypeId;
        insert objLocation;
        
        Building__c objBuild = new Building__c();
        objLocation.Name = 'Building';
        insert objBuild;
        
        List<Location_Queue__c> locationQueueList = new List<Location_Queue__c>();
        
        Location_Queue__c locationQueue = new Location_Queue__c(
            Location__c = objLocation.Id,
            Building_Id__c = objBuild.Id,
            Queue_Developer_Name__c = 'TEST_Building_Name',
            Queue_Label__c = 'TEST: Building Name',
            Queue_Prefix__c = 'FM'
        );
        locationQueueList.add(locationQueue);
        
        insert locationQueueList;
        
        Test.startTest();
        trac_LocationWrapper controller1 = new trac_LocationWrapper(objLocation, objLocation);
        controller1.setAllQueues(locationQueueList, buildingRecordTypeId);
         trac_LocationHandler tracloc= new trac_LocationHandler();
        Map<String,trac_LocationWrapper> maplist = new Map<String,trac_LocationWrapper>();
        maplist.put('Test',controller1);
        trac_LocationHandler.processAllQueueDml(maplist);
        Test.stopTest();
    }
}