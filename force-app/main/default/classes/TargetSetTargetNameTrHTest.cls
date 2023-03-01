/*************************************************************************************************
    Author        :  Krishna Somwanshi
    Description   :  Test class for TargetSetTargetNameTrH
    Issue No.     :  ST-9152
    History       :
--------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR               Issue No      DETAIL
    1          30 sept 2021    Krishna Somwanshi    ST-9152       Refactor
**************************************************************************************************/
@isTest
public class TargetSetTargetNameTrHTest {

    @testSetup
    static void setup() {
        Id userAttriRT = (ID)WeworkEngine.getObjectRecordTypeId('User_Attribute__c', 'User History');
        List<User> users = [SELECT Id, Name FROM User WHERE isActive=true LIMIT 2];
        List<User_Attribute__c> lstObjUserAttr =  new List<User_Attribute__c>(); 
        lstObjUserAttr.add(new User_Attribute__c(User__c=users[0].Id, As_of_Date__c=System.today(), 
                                             End_Date__c=System.today()+5, RecordTypeId=userAttriRT, Sales_Team__c = 'Accounts - Strategic'));
        lstObjUserAttr.add(new User_Attribute__c(User__c=users[1].Id, As_of_Date__c=System.today(), 
                                             End_Date__c=System.today()+5, RecordTypeId=userAttriRT, Sales_Team__c = 'Accounts - Strategic'));
        TestingUtility.insertListWithAssert(lstObjUserAttr);
        List<sObject> lstObjects = new List<sObject>();
        lstObjects.addAll(getRawTestPeriodRecords());
        lstObjects.addAll(getRawTestTargetsRecords());
        TestingUtility.insertListWithAssert(lstObjects);
    }

    static List<Targets__c> getRawTestTargetsRecords(){
        List<User> users = [SELECT Id, Name FROM User WHERE isActive=true LIMIT 2];
        List<Building__c> lstBuildings = (List<Building__c>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Building__c', 'numberOfRecords' => 1,'doInsert' => true});
        Account objAccount = TestingUtility.createAccount(new Map<String, Object>{'Name' => 'TestAcc', 'Named_Account_Segment__c'=>'Global Account','ownerId'=>userInfo.getUserId()}, true);
        Account objAccount2 = TestingUtility.createAccount(new Map<String, Object>{'Name' => 'TestAcc2', 'Named_Account_Segment__c'=>'Global Account','ownerId'=>userInfo.getUserId()}, true);
        List<Period__c> lstPeriod = [SELECT Id, Name FROM Period__c LIMIT 2];
        Map<String, Id> targetsRecordTypeNameId = TestingUtility.getRecordTypeMapByName(Targets__c.sObjectType);
        List<Targets__c> lsttargets = new List<Targets__c>();
        lsttargets.add(new Targets__c(Target_Period_Type__c='Weekly', Account__c = objAccount.Id, Target_Period_Date__c= Date.newInstance(2021, 10, 05), Units__c=10, ACV__c=15, Segment__c = 'Small / Market', Building__c=lstBuildings[0].Id, RecordTypeId = targetsRecordTypeNameId.get('Building Goals')));
        lsttargets.add(new Targets__c(Target_Period_Type__c='Monthly', Target_Period_Date__c= Date.newInstance(2021, 10, 05), Units__c=10, ACV__c=15, Account__c=objAccount.Id, RecordTypeId = targetsRecordTypeNameId.get('Account Goals')));
        lsttargets.add(new Targets__c(Target_Period_Type__c='Annually', Account__c = objAccount.Id, Account_Owner__c = objAccount.Owner.Name, Target_Period_Date__c= Date.newInstance(2021, 10, 15), Units__c=10, ACV__c=15, Sales_Accepted_Opportunities__c = 1, User__c= users[0].Id, RecordTypeId = targetsRecordTypeNameId.get('Rep Goals')));
        lsttargets.add(new Targets__c(Target_Period_Type__c='Quarterly', Account__c = objAccount.Id, Target_Period_Date__c= Date.newInstance(2021, 10, 05), Units__c=10, ACV__c=15, RecordTypeId = targetsRecordTypeNameId.get('Global Sales Goal')));
        return lsttargets;
    }
    
    static List<Period__c> getRawTestPeriodRecords() {
        Map<String, Id> mapperiodRecordTypes = TestingUtility.getRecordTypeMapByName(Period__c.sObjectType);
        List<Period__c> lstPeriods = new List<Period__c>();
        lstPeriods.add(new Period__c(Start_Date__c = Date.newInstance(2021, 10, 01), End_Date__c = Date.newInstance(2021, 10, 31),RecordTypeId = mapperiodRecordTypes.get('Monthly'),Name = 'MonthlyPeriod'));
        lstPeriods.add(new Period__c(Start_Date__c = Date.newInstance(2021, 01, 01), End_Date__c = Date.newInstance(2021, 12, 31),RecordTypeId = mapperiodRecordTypes.get('Annually'),Name = 'AnnualPeriod'));
        return lstPeriods;
    }
    
	public static List<Targets__c> getTargetsRecords() {
        return [SELECT Id, Name, RecordType.Name, Building__c, Account__c, User__c, User__r.Name, Portfolio__c, Units__c, ACV__c, 
                Account_Owner__c, Sales_Function__c, Units_High__c, Units_Low__c, ACV_High__c, 
                ACV_Low__c, Target_Period_Type__c, Period__c, Segment__c, Target_Name__c, Target_Period_Date__c FROM Targets__c];
    }
    
    @isTest
    static void testTargetsRecords(){
        Test.startTest();
        List<Targets__c> lstInsertedTargets = getTargetsRecords();
        Map<String, Targets__c> mapsObjectForUpdate = new Map<String, Targets__c>();
        testUpdatePeriodType(lstInsertedTargets, mapsObjectForUpdate);
        Test.stopTest();
        testUpdateAssert(getTargetsRecords());
    }
    
    private static void testUpdatePeriodType(List<Targets__c> lsttargetsInserted,Map<String, sobject> mapsObjectForUpdate){
    List<Account> lstAccount = [SELECT Id, Name FROM Account WHERE Name ='TestAcc2' LIMIT 1];
    List<User> users = [SELECT Id, Name FROM User WHERE isActive=true LIMIT 2];
    Period__c period = [SELECT ID, NAME FROM Period__c WHERE RecordType.Name = 'Annually' LIMIT 1];
    for(Targets__c objTarget: lsttargetsInserted){
    	Map<String, Id> targetsRecordTypeNameId = TestingUtility.getRecordTypeMapByName(Targets__c.sObjectType);
        if(objTarget.RecordTypeId == targetsRecordTypeNameId.get('Account Goals')){
            objTarget.Period__c = period.Id;
            objTarget.Target_Period_Type__c = 'Annually';
            mapsObjectForUpdate.put(objTarget.Account__c, objTarget);
        }
        if(objTarget.RecordTypeId == targetsRecordTypeNameId.get('Rep Goals')){
            objTarget.User__c = users[0].Id;
            mapsObjectForUpdate.put(objTarget.User__c, objTarget);
        }
        if(objTarget.RecordTypeId == targetsRecordTypeNameId.get('Building Goals')){
            objTarget.Segment__c = 'Large / Portfolio';
            mapsObjectForUpdate.put(objTarget.Segment__c, objTarget);
        }
        if(objTarget.RecordTypeId == targetsRecordTypeNameId.get('Global Sales Goal')){
            objTarget.Target_Period_Type__c = 'Annually';
            mapsObjectForUpdate.put(objTarget.Segment__c, objTarget);
        }
    }
        Update mapsObjectForUpdate.values();
    }
    
    private static void testUpdateAssert(List<Targets__c> insertedTargets) {
        Period__c objAnnualPeriod = [SELECT Id FROM Period__c WHERE RecordType.Name = 'Annually'];
        List<User> users = [SELECT Id, Name FROM User WHERE IsActive = TRUE LIMIT 2];
        Map<String, Id> targetsRecordTypeNameId = TestingUtility.getRecordTypeMapByName(Targets__c.sObjectType);
        for(Targets__c targetUpdated: insertedTargets){
            if(targetUpdated.RecordTypeId == targetsRecordTypeNameId.get('Account Goals')){
                System.assertEquals('Account Goal-TestAcc-AnnualPeriod', targetUpdated.Target_Name__c);
                System.assertEquals(objAnnualPeriod.Id, targetUpdated.Period__c);
            }
            if(targetUpdated.RecordTypeId == targetsRecordTypeNameId.get('Rep Goals')){
                System.assertEquals('Rep Goal-'+users[0].Name+'-AnnualPeriod', targetUpdated.Target_Name__c);
            }
        }
    }
       
}