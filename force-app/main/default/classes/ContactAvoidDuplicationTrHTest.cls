/*********************************************************************************************************
	Author        :  Swami Onkar 
	Description   :  Test class for ContactAvoidDuplicationOnSameDayTrH
	Issue No.     :  
-----------------------------------------------------------------------------------------------------------
	VERSION        DATE             AUTHOR             DETAIL
	1          27-feb-2023        Swami Onkar       Trigger Refactor
**********************************************************************************************************/
@isTest
public class ContactAvoidDuplicationTrHTest {
    @testSetup
    static void setup() {
        Contact duplicateContact = new Contact(FirstName = 'Duplicate1', LastName = 'User11', Email = 'testuser11@test.com');
        List<Contact> contactList = new List<Contact>();
        contactList.add(duplicateContact); // Add newContact to the list
        insert contactList;
    }
    
    @isTest
    private static void testAvoidDuplicationContact() {
        List<Contact> newContact = getInsertedContact();
        List<Contact> newNegativeContact = getInsertedNegativeTestContact();
        
        Test.startTest();
        Database.insert (newContact , false);
        Database.insert (newNegativeContact , false);
        ContactAvoidDuplicationOnSameDayTrH handlerObj = new ContactAvoidDuplicationOnSameDayTrH();
        handlerObj.newContact = newContact;
        Test.stopTest();
        
        // Verify that the second contact was not inserted and has an error message
        List<Contact> contacts = [SELECT Id, LastName, Email FROM Contact WHERE LastName = 'User11' AND Email = 'testuser11@test.com' AND CreatedDate = TODAY];
        List<Contact> yesterdayContactsFetch = [SELECT Id, LastName, Email FROM Contact WHERE LastName = 'Yesterday' AND Email = 'yesterday@yesterday.com' ];
        System.assertEquals(1, contacts.size() ,'only one will be inserted');
        System.assert(Contacts[0].LastName != newNegativeContact[0].LastName, 'this two list are different with same email but lastname is change');
        System.assertNotEquals(1 , yesterdayContactsFetch.size(), 'cheaking 2 contats will be inseted');
        System.assertNotEquals(newNegativeContact[0].ID, contacts[0].ID, 'there will be id change because two records are different');
    }
    
    private static List <Contact> getInsertedContact(){
        List<Contact> contactList = new List<Contact>();
        Contact duplicateContact = new Contact(FirstName = 'Duplicate1', LastName = 'User11', Email = 'testuser11@test.com');
        contactList.add(duplicateContact); // Add newContact to the list
        return contactList;
    }
    
    private static List <Contact> getInsertedNegativeTestContact(){
        List<Contact> negativeContactList = new List<Contact>();
        Contact duplicateContact = new Contact(FirstName = 'Negative', LastName = 'Test', Email = 'testuser11@test.com');
        negativeContactList.add(duplicateContact); // Add newContact to the list
        return negativeContactList;
    }
    
    private static List <Contact> getYesterdayContacts(){
        List<Contact> insertyesterdayContactListdata = new List<Contact>();
        Contact yesterdayContacts = new Contact(FirstName = 'Mahesh', LastName = 'Yesterday', Email = 'yesterday@yesterday.com');
        insertyesterdayContactListdata.add(yesterdayContacts); // Add newContact to the list
        insert insertyesterdayContactListdata;
        return insertyesterdayContactListdata;
    }
}