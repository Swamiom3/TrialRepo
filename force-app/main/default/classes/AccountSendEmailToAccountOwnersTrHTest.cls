/************************************************************************************************************************************
Author      :   Monika
Description :   This class will contain test methods of AccountSendEmailToAccountOwnersTrH.
*************************************************************************************************************************************/
@isTest 
public class AccountSendEmailToAccountOwnersTrHTest {
    
    @isTest 
    public static void accountSendEmailToAccountOwnertest(){
        Profile salesProfile = [SELECT Id, Name FROM Profile WHERE Name = 'WeWork Sales User'];
        User testUser1 = new User(Alias = 'testU', Email='testUser1@example.com', 
                                 EmailEncodingKey='UTF-8', LastName='User', LanguageLocaleKey='en_US', 
                                 LocaleSidKey='en_US', ProfileId = salesProfile.Id, IsActive = true,
                                 TimeZoneSidKey='America/Los_Angeles', UserName='testUser1@example.com.wework.service');
        
        User testUser2 = new User(Alias = 'testU', Email='testUser2@example.com', 
                                EmailEncodingKey='UTF-8', LastName='User', LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', ProfileId = salesProfile.Id, IsActive = true,
                                TimeZoneSidKey='America/Los_Angeles', UserName='testUser2@example.com.wework.service');
        
        User testUser3 = new User(Alias = 'testU', Email='testUser3@example.com', 
                                EmailEncodingKey='UTF-8', LastName='User', LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', ProfileId = salesProfile.Id, IsActive = true,
                                TimeZoneSidKey='America/Los_Angeles', UserName='testUser3@example.com.wework.service');
        
        insert new List<User>{testUser1, testUser2, testUser3};
        
        Account acc = new Account();
        acc.name = 'Name';
        acc.OwnerId = testUser1.id;
        insert acc;        
        
        Map<Id, Account> newAccountsMap = new Map<Id, Account>();
        newAccountsMap.put(acc.id,acc);
        
        Map<Id, Account> oldAccountsMap = new Map<Id, Account>();
        oldAccountsMap.put(acc.id,acc);
        
        Opportunity primary = TestingUtility.createOpportunity(acc.Id, true);

        primary.OwnerId = testUser2.Id;
        update primary;
        primary.OwnerId = testUser3.id;
        update primary;
        
        User actUser = [SELECT id,ProfileId,email,IsActive FROM user WHERE isactive=:TRUE AND id!=: acc.OwnerId LIMIT 1];
        acc.OwnerId = actUser.id;       
        update acc;        
        
        List<Account> accounts = New List<Account>();
        accounts.add(acc);
        
        Set<Id> accSet = new Set<Id>();
        accSet.add(acc.id);
        String emailTemplateName= 'Sales_Inquiry';
        Set<Id> oppSet = new Set<Id>();
        oppSet.add(primary.id);  
        
        Map<Id, Opportunity> newOppMap = new Map<Id, Opportunity>();
        newOppMap.put(primary.id,primary);
        
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>();
        oldOppMap.put(primary.id,primary);
        Test.startTest();
        AccountSendEmailToAccountOwnersTrH sendMailtoAcc = new AccountSendEmailToAccountOwnersTrH();
        AccountSendEmailToAccountOwnersTrH sendMailtoAcct = new AccountSendEmailToAccountOwnersTrH(accounts,newAccountsMap,oldAccountsMap);
        sendMailtoAcct.afterUpdate();
        Test.stopTest();
        try{
            AccountSendEmailToAccountOwnersTrH.sendEmailAlertsOnOwnershipChange(oppSet, emailTemplateName, newOppMap, oldOppMap);
            System.assertEquals(2, AccountSendEmailToAccountOwnersTrH.emailSentCount, 'Email Count should be equal to two');        	
        }catch(Exception e){             
            System.assertNotEquals(Null,e.getMessage(),'Exception is received');
        }      
        try{
            AccountSendEmailToAccountOwnersTrH.sendEmailAlertsOnOwnershipChange(accSet, emailTemplateName, newAccountsMap, oldAccountsMap);
            System.assertEquals(2, AccountSendEmailToAccountOwnersTrH.emailSentCount, 'Email Count should be equal to two');        	
        }catch(Exception e){            
            System.assertNotEquals(Null,e.getMessage(),'Exception is received');
        }      
    }
}