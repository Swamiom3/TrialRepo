/************************************************************************************************************************************
	Author		: 	Ashish Sharma
	Description	: 	This is a test class for BatchToMergeDuplicateLeads.
	Issue       :   ST-5321
	----------------------------------------------------------------------------------------------------------------------------------
	VERSION		DATE	        		AUTHOR                     	DETAIL
	1	    	17 December 2019		Ashish Sharma             	Initial Developement
**************************************************************************************************************************************/
@isTest
public class BatchToMergeDuplicateLeadsTest {
    public static Id strHoldBackQueueId =  (Id)LeadConverterHelper.getHoldBackQueueId();
    @testSetup 
    public static void setup() {
        RESTInboundLeadAPIHelper.isLeadFromWeb = true;
        List<Lead> lstLeads = new List<Lead>();
        lstLeads.addAll((List<Lead>)TestingUtility.getRecords(new Map<String, Object> {'objName' => 'lead', 'numberOfRecords' => 1, 'doInsert' => false, 'mapFieldValues' => new Map<String, List<Object>>{'FirstName' => new List<Object>{'testLead'}, 'LastName' => new List<Object>{'lead'}, 'Company' => new List<Object>{'TestCompany'}, 'Email' => new List<Object>{'testLeadMail@test.com'}, 'LeadSource' => new List<Object>{'WeWork.com'}, 'Lead_Source_Detail__c' => new List<Object>{'Book a Tour Form'}, 'Generate_Journey__c' => new List<Object>{true}}}));
        lstLeads.addAll((List<Lead>)TestingUtility.getRecords(new Map<String, Object> {'objName' => 'lead', 'numberOfRecords' => 1, 'doInsert' => false, 'mapFieldValues' => new Map<String, List<Object>>{'FirstName' => new List<Object>{'masterLead'}, 'LastName' => new List<Object>{'lead'}, 'Company' => new List<Object>{'TestCompany'}, 'Email' => new List<Object>{'testLeadMail@test.com'}, 'LeadSource' => new List<Object>{'WeWork.com'}, 'Lead_Source_Detail__c' => new List<Object>{'Book a Tour Form'}, 'Generate_Journey__c' => new List<Object>{true}}}));
        for(Integer i = 0; i < 8; i++) {
            lstLeads.add(lstLeads[0].clone(false, false, false, false));
        }
        TestingUtility.insertListWithAssert(lstLeads);
        System.assertEquals(10, [SELECT Id FROM Lead WHERE isConverted = false AND OwnerId =:strHoldBackQueueId].size());
    }
    
    @isTest 
    public static void testExecuteBatch() {
        List<Lead> lstLeads = [SELECT Id, FirstName FROM Lead WHERE isConverted =  FALSE];
        List<Lead> lstLeadsToUpdate = new List<Lead>();
        for(Lead objLead : lstLeads) {
            if(objLead.FirstName == 'masterLead')
                Test.setCreatedDate(objLead.Id, Datetime.now().addDays(-1));
            lstLeadsToUpdate.add(objLead);
        }
        TestingUtility.updateListWithAssert(lstLeadsToUpdate); 
        Test.startTest();
        Database.executeBatch(new BatchToMergeDuplicateLeads(NULL, NULL, NULL), 1);            
        Test.stopTest();
        lstLeads = [SELECT Id, FirstName FROM Lead WHERE isConverted = FALSE];
        System.assertEquals(1, lstLeads.size());
        System.assertEquals('masterLead', lstLeads[0].FirstName);        
    }
    
    @isTest 
    public static void testScheduleBatch() {
        Test.StartTest();
        BatchToMergeDuplicateLeads objBatchToMergeDuplicateLeads = new BatchToMergeDuplicateLeads(NULL, NULL, NULL);
        String exp = '0 0 23 * * ?';
        String strJobId = System.schedule('BatchToMergeDuplicateLeads from Test class', exp, objBatchToMergeDuplicateLeads);
        System.assert(String.isNotBlank(strJobId), 'Batch not scheduled');
        Test.stopTest();
    }
}