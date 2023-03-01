@isTest
public class ExternalUnsubscribeControllerTest {
    
    @TestSetup
    static void makeData(){
        Map<String, Object> mapData1 =
                        new Map<String, Object>{
                            'doInsert'=>false,
                            'objName' => 'Lead',
                            'Generate_Journey__c' => true,
                            'numberOfRecords' => 1,
                            'mapFieldValues' => new Map<String,List<Object>>{
                                    'FirstName'=>new List<Object>{'First Name Test'},
                                    'LastName'=>new List<Object>{'Test'},
                                    'Company'=>new List<Object>{'a company'},
                                    'HasOptedOutOfEmail'=>new List<Object>{false},
                                    'Email'=> new List<Object>{'testunsubscribelead@email.com'}}
                        };
        Map<String, Object> mapData2 =
                        new Map<String, Object>{
                            'doInsert'=>false,
                            'objName' => 'Contact',
                            'numberOfRecords' => 1,
                            'mapFieldValues' => new Map<String,List<Object>>{
                                    'FirstName'=>new List<Object>{'TestFirstNameContact'},
                                    'LastName'=>new List<Object>{'TestContact'},
                                    'HasOptedOutOfEmail'=>new List<Object>{false},
                                    'Email'=> new List<Object>{'testunsubscribecontact@email.com'}}
                        };
        TestingUtility.insertListWithAssert((List<Lead>)TestingUtility.getRecords(mapData1));
        TestingUtility.insertListWithAssert((List<Contact>)TestingUtility.getRecords(mapData2));
    }

    @isTest
    public static void verifyLeadUnsubscribe(){
        Test.startTest();
        ExternalUnsubscribeController.doOptOut('testunsubscribelead@email.com');
        Test.stopTest();
        
        List<Lead> leads = [SELECT HasOptedOutOfEmail
                            FROM Lead];
        System.assertEquals(1, leads.size(), 'more than 1 Lead found');
        System.assertEquals(true, leads[0].HasOptedOutOfEmail, 'Lead was not opted out');
    }

    @isTest
    public static void verifyContactUnsubscribe(){
        Test.startTest();
        ExternalUnsubscribeController.doOptOut('testunsubscribecontact@email.com');
        Test.stopTest();
        
        List<Contact> contacts = [SELECT HasOptedOutOfEmail FROM Contact];
        System.assertEquals(1, contacts.size(), 'more than 1 Contact found');
        System.assertEquals(true, contacts[0].HasOptedOutOfEmail, 'Contact was not opted out');
    }

    @isTest
    public static void verifyExceptions(){
        Test.startTest();
        ExternalUnsubscribeController.doOptOut('noonehasthisemail@none.com');
        ExternalUnsubscribeController.doOptOut(null);
        Test.stopTest();

        List<Apex_Debug_Log__c> logs = [ SELECT Id
                                         FROM Apex_Debug_Log__c
                                         WHERE Apex_Class__c = 'ExternalUnsubscribeController'];
        List<AsyncApexJob> jobs = [ SELECT Id
                                    FROM AsyncApexJob
                                    WHERE ApexClassId IN (SELECT Id
                                                          FROM ApexClass
                                                          WHERE Name = 'QueueRollbarItemSubmit')];
        System.assertEquals(2, logs.size(), 'expecting 2 logs, but found ==> '+logs.size());
        System.assertEquals(1, jobs.size(), 'looking for 1 async jobs, instead found ==> '+jobs.size());
    }
}