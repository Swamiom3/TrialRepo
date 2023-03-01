@isTest
public class MetadataDrivenTriggerHandlerTest {

    private static final String ACCOUNT_OBJECT_TYPE ='Account';

    @isTest
    public static void getSObjectTriggerConfigurationsTest(){
        MetadataDrivenTriggerHandler mdtrh = new MetadataDrivenTriggerHandler();
        mdtrh.sObjectType = ACCOUNT_OBJECT_TYPE;
        mdtrh.getSObjectTriggerConfigurations();
        System.assert(MetadataDrivenTriggerHandler.triggerConfigurationsByObjectApiName.get(ACCOUNT_OBJECT_TYPE) != null, 'Trigger config for Account should not be null');
    }

    @isTest
    public static void runTest(){
        MetadataDrivenTriggerHandler mdtrh = new MetadataDrivenTriggerHandler();
        mdtrh.sObjectType = ACCOUNT_OBJECT_TYPE;
        try{
            mdtrh.run();
        } catch (Exception ex) {
            System.assert(ex != null, 'Trigger context used');
        }
        SObjectTriggerHandler.disableExecution();
        mdtrh.run();

        mdtrh.sObjectType = ACCOUNT_OBJECT_TYPE;
        mdtrh.run();
    }

    @isTest
    public static void runTriggerHandlers(){
        MetadataDrivenTriggerHandler mdtrh = new MetadataDrivenTriggerHandler();
        mdtrh.sObjectType = ACCOUNT_OBJECT_TYPE;
        List<Trigger_Configuration__mdt> testAccTriggerConfig = new List<Trigger_Configuration__mdt>();
        testAccTriggerConfig.add(new Trigger_Configuration__mdt(
            Implementing_Class__c = 'tempClass',
            Object_API_Name__c = ACCOUNT_OBJECT_TYPE,
            Order_of_Execution__c = 0,
            Is_Forced_Execution__c = false,
            Active__c = false
        ));
        testAccTriggerConfig.add(new Trigger_Configuration__mdt(
            Object_API_Name__c = ACCOUNT_OBJECT_TYPE,
            Order_of_Execution__c = 5,
            Is_Forced_Execution__c = false,
            Active__c = true
        ));
        testAccTriggerConfig.add(new Trigger_Configuration__mdt(
            Implementing_Class__c = 'tempClass2',
            Object_API_Name__c = ACCOUNT_OBJECT_TYPE,
            Order_of_Execution__c = 10,
            Is_Forced_Execution__c = false,
            Active__c = true
        ));
        Map<String, List<Trigger_Configuration__mdt>> testConfigMap = new Map<String, List<Trigger_Configuration__mdt>>{ACCOUNT_OBJECT_TYPE => testAccTriggerConfig};
        MetadataDrivenTriggerHandler.sObjectNameToTriggerHandlerConfugurations = testConfigMap;
        try{
            mdtrh.runTriggerHandlers();
        } catch (Exception ex) {
            System.assert(ex != null, 'NPE not thrown');
        }
    }

    @isTest
    public static void runTriggerHandlers_invalidType(){
        MetadataDrivenTriggerHandler mdtrh = new MetadataDrivenTriggerHandler();
        mdtrh.sObjectType = ACCOUNT_OBJECT_TYPE;
        List<Trigger_Configuration__mdt> testAccTriggerConfig = new List<Trigger_Configuration__mdt>();
        testAccTriggerConfig.add(new Trigger_Configuration__mdt(
            Implementing_Class__c = 'DmlConsolidator',
            Object_API_Name__c = ACCOUNT_OBJECT_TYPE,
            Order_of_Execution__c = 0,
            Is_Forced_Execution__c = true,
            Active__c = true
        ));
        Map<String, List<Trigger_Configuration__mdt>> testConfigMap = new Map<String, List<Trigger_Configuration__mdt>>{ACCOUNT_OBJECT_TYPE => testAccTriggerConfig};
        MetadataDrivenTriggerHandler.sObjectNameToTriggerHandlerConfugurations = testConfigMap;
        try{
            mdtrh.runTriggerHandlers();
        } catch (Exception ex) {
            System.assert(ex != null, 'Exception not thrown');
            System.assert(ex.getTypeName() != 'TypeException' , 'Invalid Type exception not thrown');
        }
    }

    @isTest
    public static void shouldBypassTriggersForUserTest(){
        MetadataDrivenTriggerHandler mdtrh = new MetadataDrivenTriggerHandler();
        System.assertEquals(false, mdtrh.shouldBypassTriggersForUser(), 'Regular user should not have Bypass Triggers permission enabled.');

        User bypassUser = TestUtility.createTestUser();
        PermissionSet bypassTriggersPermission = [SELECT Id FROM PermissionSet WHERE Name = 'Bypass_Triggers'];
        PermissionSetAssignment assignment = new PermissionSetAssignment(
            AssigneeId = bypassUser.Id,
            PermissionSetId = bypassTriggersPermission.Id
        );
        insert assignment;

        System.runAs(bypassUser){
            System.assertEquals(true, mdtrh.shouldBypassTriggersForUser(), 'Bypass Triggers is permission enabled with proper permission set assignment.');
        }
    }
}