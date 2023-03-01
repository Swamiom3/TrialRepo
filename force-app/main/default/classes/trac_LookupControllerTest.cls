@isTest
public class trac_LookupControllerTest {
    @isTest 
    public static void testLookupController() {
        String sobjectType='Case';
        String searchTerm = 'QUEUE NAME';
        String nameField;
        String icon;
        List<String> selectedIds =new List<String>();
        Group testGroup = new Group(Name='QUEUE NAME', Type='Queue');
        insert testGroup;
        //Associating queue with group AND to the Case object
        QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Case');
        insert testQueue;
        selectedIds.add(testQueue.Id);
        Test.startTest();
        trac_LookupController.search(sobjectType,searchTerm,nameField, icon,selectedIds);
        Test.stopTest();
    } 
}