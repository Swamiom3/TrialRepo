@isTest
public class TargetsTriggersTest {

    static List<User> users;

    @testSetup
    static void setup() {
        Test.startTest();
        Id userAttriRT = (ID)WeworkEngine.getObjectRecordTypeId('User_Attribute__c', 'User History');
        List<User> users = [SELECT Id FROM User WHERE isActive=true LIMIT 2];
        List<User_Attribute__c> lstObjUserAttr =  new List<User_Attribute__c>(); 
        lstObjUserAttr.add(new User_Attribute__c(User__c=users[0].Id, As_of_Date__c=System.today(), 
                                            End_Date__c=System.today()+5, RecordTypeId=userAttriRT));
        lstObjUserAttr.add(new User_Attribute__c(User__c=users[1].Id, As_of_Date__c=System.today(), 
                                            End_Date__c=System.today()+5, RecordTypeId=userAttriRT));
        TestingUtility.insertListWithAssert(lstObjUserAttr);
        List<sObject> lstObjects = new List<sObject>();
        lstObjects.addAll(getRawTestPeriodRecords());
        lstObjects.addAll(getRawTestTargetsRecords());
        TestingUtility.insertListWithAssert(lstObjects);
    }
    public static List<Targets__c> getTargetsRecords(){
        return [SELECT Id, Name, RecordType.Name, Building__c, Account__c, User__c, Portfolio__c, Units__c, ACV__c, 
                Account_Owner__c, Sales_Function__c, Units_High__c, Units_Low__c, ACV_High__c, 
                ACV_Low__c, Target_Period_Type__c, Period__c FROM Targets__c];
    }
    
    static List<Period__c> getRawTestPeriodRecords(){
        Map<String, Id> mapperiodRecordTypes = TestingUtility.getRecordTypeMapByName(Period__c.sObjectType);
        List<Period__c> lstPeriods = new List<Period__c>();
        lstPeriods.add(new Period__c(Start_Date__c = Date.newInstance(2020, 04, 01), End_Date__c = Date.newInstance(2020, 04, 30),RecordTypeId = mapperiodRecordTypes.get('Monthly'),Name = 'MonthlyPeriod'));
        lstPeriods.add(new Period__c(Start_Date__c = Date.newInstance(2020, 01, 01), End_Date__c = Date.newInstance(2020, 12, 31),RecordTypeId = mapperiodRecordTypes.get('Annually'),Name = 'AnnualPeriod'));
        return lstPeriods;
    }
    static List<Targets__c> getRawTestTargetsRecords(){
        List<Building__c> lstBuildings = (List<Building__c>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Building__c', 'numberOfRecords' => 1,'doInsert' => true});
        Account objAccount = TestingUtility.createAccount(new Map<String, Object>{'Name' => 'TestAcc', 'Named_Account_Segment__c'=>'Global Account','ownerId'=>userInfo.getUserId()}, true);
        Account objAccount2 = TestingUtility.createAccount(new Map<String, Object>{'Name' => 'TestAcc2', 'Named_Account_Segment__c'=>'Global Account','ownerId'=>userInfo.getUserId()}, true);
        List<User> users = [SELECT Id FROM User WHERE isActive=true LIMIT 2];
        List<Period__c> lstPeriod = [SELECT Id, Name FROM Period__c LIMIT 2];
        Map<String, Id> mapTargetsRecordTypes = TestingUtility.getRecordTypeMapByName(Targets__c.sObjectType);
        List<Targets__c> lsttargets = new List<Targets__c>();
        lsttargets.add(new Targets__c(Target_Period_Type__c='Weekly', Account__c = objAccount.ID, Target_Period_Date__c= Date.newInstance(2020, 04, 15), Units__c=10, ACV__c=15, Segment__c = 'Small / Market', Building__c=lstBuildings[0].Id, RecordTypeId = mapTargetsRecordTypes.get('Building Goals')));
        lsttargets.add(new Targets__c(Target_Period_Type__c='Monthly', Target_Period_Date__c= Date.newInstance(2020, 04, 15), Units__c=10, ACV__c=15, Account__c=objAccount.Id, RecordTypeId = mapTargetsRecordTypes.get('Account Goals')));
        lsttargets.add(new Targets__c(Target_Period_Type__c='Annually', Account__c = objAccount.ID, Target_Period_Date__c= Date.newInstance(2020, 04, 15), Units__c=10, ACV__c=15, Sales_Accepted_Opportunities__c = 1, User__c= users[0].Id, RecordTypeId = mapTargetsRecordTypes.get('Rep Goals')));
        lsttargets.add(new Targets__c(Target_Period_Type__c='Quarterly', Account__c = objAccount.ID, Target_Period_Date__c= Date.newInstance(2020, 04, 15), Units__c=10, ACV__c=15, RecordTypeId = mapTargetsRecordTypes.get('Global Sales Goal')));
        return lsttargets;
    }
    @isTest
    static void testTargetsRecords(){
        Test.startTest();
        List<Targets__c> lstInsertedTargets = getTargetsRecords();
        Map<String, Targets__c> mapsObjectForUpdate = new Map<String, Targets__c>();
        if(!mapsObjectForUpdate.values().isEmpty()){
            update mapsObjectForUpdate.values();
        }
        Test.stopTest(); 
    }
}