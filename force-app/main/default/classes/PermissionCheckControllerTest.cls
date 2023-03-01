@isTest
public class PermissionCheckControllerTest {
    
    @isTest
    static void getUserPermissionCheckControllerTest(){
        
        Profile testProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];   
        Profile testProfile1 = [SELECT Id FROM Profile WHERE Name='WeWork Sales User'];
        Profile testProfile2 = [SELECT Id FROM Profile WHERE Name='WeWork Inside Sales'];
        
        User testUser = new user(alias = 'test', email='rejex@example.com', 
                                emailencodingkey='UTF-8', firstName='test', lastname='rejex', languagelocalekey='en_US',
                                localesidkey='en_IN', profileid = testProfile.Id, country='India',
                                timezonesidkey='Asia/Kolkata', username='rejex@example.com'); 
        insert testUser;
        
        User testUser1 = new user(alias = 'test1', email='kollar@example.com', 
                                emailencodingkey='UTF-8', firstName='john', lastname='kollar', languagelocalekey='en_US',
                                localesidkey='en_IN', profileid = testProfile1.Id, country='India',
                                timezonesidkey='Asia/Kolkata', username='kollar@example.com'); 
        insert testUser1;
        
        User testUser2 = new user(alias = 'test2', email='krampt@example.com',  
                                emailencodingkey='UTF-8', firstName='jully', lastname='krampt', languagelocalekey='en_US',
                                localesidkey='en_IN', profileid = testProfile2.Id, country='India',
                                timezonesidkey='Asia/Kolkata', username='krampt@example.com'); 
        insert testUser2;
        
        Lead testLead = new lead();
        testLead.Email = 'testlead@gmail.com';
        testLead.Phone = '57050987657';
        testLead.LastName = 'test last name';
        insert testLead;
        
        Journey__c testJourney = new Journey__c();
        testJourney.Name = 'test Journey';
        testJourney.OwnerId = testUser.Id;
        testJourney.Primary_Lead__c = testLead.Id;
        testJourney.NMD_Next_Contact_Date__c = System.today();
        insert testJourney;
        
        Journey__c testJourney1 = new Journey__c();
        testJourney1.Name = 'test Journey';
        testJourney1.OwnerId = testUser1.Id;
        testJourney1.Primary_Lead__c = testlead.Id;
        testJourney1.NMD_Next_Contact_Date__c = System.today();
        insert testJourney1;
        
        Boolean resultLeadOwnerTstUser = PermissionCheckController.getUserPermissionCheckController(testJourney.Id, testUser.Id);
        Boolean resultLeadOwnerNotTstUser1 = PermissionCheckController.getUserPermissionCheckController(testJourney1.Id, testUser1.Id);
        Boolean resultLeadOwnerNotTstUse2 = PermissionCheckController.getUserPermissionCheckController(testJourney.Id, testUser2.Id);
        
        system.assertEquals(true, resultLeadOwnerTstUser);
        system.assertEquals(true, resultLeadOwnerNotTstUser1);
        system.assertEquals(false, resultLeadOwnerNotTstUse2);
    }
}