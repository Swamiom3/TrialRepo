@isTest
public class trac_SupportRqtBatchScheduleTest {
       static final TLTestFactory factory = new TLTestFactory();
    static final String personAccRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
    @isTest
    public static void testSupportRqtBatchSchedule(){
        RecordType recId = [select Id from RecordType WHERE SObjectType = 'Case' AND DeveloperName='Support_Request' LIMIT 1];    
        List<Case> cases = (List<Case>) factory.createSObjects(new Case(SuppliedEmail = 'test@test.test',RecordTypeId =recId.Id), 2, false);
        insert cases;
        SchedulableContext sc = null;
        Database.BatchableContext BC =null;
        Test.startTest();
        trac_SupportRequestBatch testdata1 = new trac_SupportRequestBatch();
        Database.executeBatch(testdata1,200);
        
        List<Case> caselist = new List<Case>();
    
        RecordType RecordType_id = new RecordType();
        RecordType_id = [select Id,DeveloperName from RecordType where DeveloperName='Support_Request' limit 1];
        Account testAccount = new Account();
		testAccount.Name='Test Account' ;
		insert testAccount;
		
		Contact cont = new Contact();
		cont.FirstName='Test';
		cont.LastName='Test';
		cont.Accountid= testAccount.id;
        cont.Email ='Test@gmail.com';
		insert cont;
        
        for(Integer i=0;i<50;i++){
            Case c= new Case();
            c.RecordTypeId =  Schema.sObjectType.Case.getRecordTypeInfosByName().get('Support Request').getRecordTypeId();
             system.debug('c.RecordTypeId' +   c.RecordTypeId);
            c.RecordType =  RecordType_id;
            system.debug('RecordType_id.Name at line 48' +   RecordType_id.DeveloperName);
            if(c.RecordType.DeveloperName != null)
            c.RecordType.DeveloperName = RecordType_id.DeveloperName;
            c.Status = 'Waiting_on_Support_Request_Submitter';
            c.WeCo_Line_of_Business__c = 'WeWork';
            c.ContactId = cont.Id;
            c.Contact = cont;
            c.Waiting_on_Support_Request_24_hours__c = system.now();
            caselist.add(c);
        }
        system.debug('caselist' + caselist);
        if(caselist.size()>0)
        testdata1.execute(BC,caselist);
        Test.stopTest();
    }
    }