@isTest
public class trac_CaseRoutingControllerTest {
    static final TLTestFactory factory = new TLTestFactory();
    @isTest
    public static void testCaseRoutingController(){
        List<Object> rules = new List<Object>();
        List<Object> objectList = new List<Object>();
        Map<String,List<String>> prefixestest =  New Map<String,List<String>>();
        Map<String,String> testobjedata1 =new Map<String,String>();
        Map<String,String> activationtest =new Map<String,String>();
        string devname;
        Test.startTest();
        rules = trac_CaseRoutingController.getAllRoutingRules();        
        objectList = trac_CaseRoutingController.getChildCriteria('');
        prefixestest = trac_CaseRoutingController.getPrefixes();
        List<object> objectlist12 = [SELECT Id,DeveloperName,Label,Field__c,Value__c,Is_Active__c
        FROM Case_Routing_Line_Item__mdt];
        testobjedata1 = trac_CaseRoutingController.upsertRoutingRule(rules[0],objectlist12);
        activationtest = trac_CaseRoutingController.routingRuleActivation('Test','Test',true);
        devname = trac_CaseRoutingController.generateDevName('Test');
        String newTest = trac_CaseRoutingController.NewGuid(true);
        Map<String,String> createRoutingFieldMap = new Map<String,String>();
        createRoutingFieldMap = trac_CaseRoutingHelper.createRoutingFieldMap();
        Set<String> setData = new Set<String>();
        setData= trac_CaseRoutingHelper.getRoutingField();
        String testdata1 = trac_CaseRoutingHelper.relationshipToField('Id');
        List<Case> cases = (List<Case>) factory.createSObjects(new Case(SuppliedEmail = 'test@test.test'), 2, false);
        insert cases[0];
        Map<String, String> additionalFields = new Map<String,String>();
        String value;
        String testvalue;
        additionalFields.put('Name','Name');
        Map<String, String> additionalFields1 = trac_CaseRoutingHelper.mockRecord(cases[0],additionalFields);
        Map<String,Integer> testdataupd = new Map<String,Integer>();
        testdataupd.put('Test',1);
        List<String> stringdata = new List<String>();
        stringdata = trac_CaseRoutingHelper.orderListByMapValues(testdataupd);
        testvalue = trac_CaseRoutingHelper.find(additionalFields,value);
        trac_MetadataUtils metaUtil = New trac_MetadataUtils();
        Metadata.DeployResult result = new Metadata.DeployResult();
        result.numberComponentErrors = 1;
        Metadata.DeployCallbackContext context = new Metadata.DeployCallbackContext();
        metaUtil.handleResult(result, context);
        Test.stopTest();
        
        System.assertEquals(new List<String>{'Test'}, stringdata);
        System.assertEquals(null, testvalue);
        System.assertEquals(new Map<String,String>{'id'=>cases[0].Id, 'name'=>'Name', 'subject'=>'Test Case 0', 'suppliedemail'=>'test@test.test'}, additionalFields1);
    }
}