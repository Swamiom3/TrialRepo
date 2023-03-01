@isTest
public class TestManager {
    public static final String insertAssertEvent = 'insertassert';
    public static final String updateValuesEvent = 'updatevalues';
    public static final String updateAssertEvent = 'updateassert';
    
    public static void handleTestProcess(String objectAPIName, List<sobject> lstObjects, Map<String, sobject> mapsObjectForUpdate, String testMethodName, String event){
        List<Trigger_Configuration__mdt> lstProcessesToTest = getMetadata(objectAPIName, testMethodName);
        List<sobject> triggerNew;
        for(Trigger_Configuration__mdt objTriggerConfig : lstProcessesToTest) {
            TestingUtility.checkLimits();
            triggerNew = lstObjects;
            SObjectTriggerHandler.clearLoopCount();
            if(event == insertAssertEvent.toLowerCase() && objTriggerConfig.Event_Type__c == 'Insert'){
                callTestMethod(triggerNew, null, mapsObjectForUpdate, objTriggerConfig, event);
            }else if(event == updateValuesEvent.toLowerCase() && objTriggerConfig.Event_Type__c == 'Update'){
                callTestMethod(triggerNew, null, mapsObjectForUpdate, objTriggerConfig, event);
            }else if(event == updateAssertEvent.toLowerCase() && objTriggerConfig.Event_Type__c == 'Update'){
                callTestMethod(triggerNew, null, mapsObjectForUpdate, objTriggerConfig, event);
            }
        }
    }
    
    Private static void callTestMethod(List<sobject> triggerNew, Map<Id, sObject> triggerOldMap,  Map<String, sobject> mapsObjectForUpdate, Trigger_Configuration__mdt objTriggerConfig, String event){
        try {	
            Type t;
            IProcessTestHandler testHandler;
            t = Type.forName(objTriggerConfig.Test_Class_Name__c);
            testHandler = (IProcessTestHandler)t.newInstance();
            SObjectTriggerHandler.clearLoopCount();
            testHandler.handleTest(triggerNew, triggerOldMap, mapsObjectForUpdate, event);
        }
        catch(Exception ex) {
            ApexDebugLog.logException(ex, '', 'TestManager', 'callTestMethod');
        }
    }
    Private static List<Trigger_Configuration__mdt> getMetadata(String objectAPIName, String testMethodName){
        List<Trigger_Configuration__mdt> lstProcessesToTest;
        if(lstProcessesToTest == null ){
            lstProcessesToTest = [SELECT Testing_Method_Name__c, Test_Class_Name__c, Object_API_Name__c, Order_of_Execution__c,
                                  Event_Type__c FROM Trigger_Configuration__mdt
                                  WHERE Object_API_Name__c =: objectApiName
                                  AND Testing_Method_Name__c =: testMethodName AND Test_Class_Name__c != null
                                  order BY Order_of_Execution__c]; 
        }
        return lstProcessesToTest;
    } 
}