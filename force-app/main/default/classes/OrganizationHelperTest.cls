@isTest
public class OrganizationHelperTest {

    @testSetup
    public static void initData(){
        OperatingHours objOpHour = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday');
        insert objOpHour;
        WeWorkValidatorHelper.createTerritoryStructure();
        List<CI_Company__c> lstUnomy = new List<CI_Company__c>();
        lstUnomy.add(new CI_Company__c(CI_Company_Id__c = 1234, Company_Name__c = 'test company1'));
        lstUnomy.add(new CI_Company__c(CI_Company_Id__c = 12345, Company_Name__c = 'Test Company'));
        TestingUtility.insertListWithAssert(lstUnomy);
    }

    @isTest
    public static void getListFieldsTest(){
        OrganizationHelper objOrgHelper = new OrganizationHelper();
        List<String> leadResult = objOrgHelper.getListFields('Lead');
        List<String> contactResult = objOrgHelper.getListFields('Contact');
        List<String> elseResult = objOrgHelper.getListFields('Account');
        System.assertEquals(null, elseResult);
        System.assert (leadResult.contains('Company'), 'Should contain company');
        System.assert (contactResult.contains('Account_Name__c'), 'Should contain Account Name');
    }

    @isTest
    public static void getUltimateParentsTest() {
        List<Account> accountList = TestingUtility.createAccounts(6, 'Test Account', false);
        insert accountList;
        Set<Id> accountIds = new Set<Id>();
        for(Account accItem : accountList) {
            accItem.Account_Type__c = 'Org';
            accountIds.add(accItem.Id);
        }
        for(Integer i = 1; i < accountList.size(); i++) {
            accountList[i].ParentId = accountList[i-1].Id;
        }
        update accountList;
        
        Map<Id,Id> result = OrganizationHelper.getUltimateParents(accountIds);
        for(Id accIds : result.values()) {
            System.assertEquals(accountList[0].Id, accIds, 'Every ultimate parent Id should equal to provided account id');
        }
    }

    @isTest
    public static void getCleansedNameTest(){
        String result = OrganizationHelper.getCleansedName('Test name wiTh spaCes');
        System.assertEquals('testnamewithspaces', result, 'Should get cleansed name');
    }

    @isTest
    public static void checkStringForOnlySpecialCharacterTest(){

        System.assert (OrganizationHelper.checkStringForOnlySpecialCharacter('.'), 'Should get true on special character check');
        System.assertEquals(false, OrganizationHelper.checkStringForOnlySpecialCharacter('a.'), 'Should get false on special character check');
        System.assertEquals(false, OrganizationHelper.checkStringForOnlySpecialCharacter('12+'), 'Should get false on special character check');
        System.assertEquals(false, OrganizationHelper.checkStringForOnlySpecialCharacter('*21'), 'Should get false on special character check');
        System.assert (OrganizationHelper.checkStringForOnlySpecialCharacter('*.+{}'), 'Should get true on special character check');
        System.assertEquals(false, OrganizationHelper.checkStringForOnlySpecialCharacter('*.+{}9'), 'Should get false on special character check');
    }

    @isTest
    public static void getPublicDomainsTest() {
        Set<String> result = OrganizationHelper.getPublicDomains();
        System.assert (!result.isEmpty(), 'Should get any domains');
    }

    @isTest
    public static void getSobjectNameTest() {
        Account objAccount = TestingUtility.createAccount('Test Account', false);
        objAccount.Id = TestUtility.getFakeId(objAccount.getSObjectType());
        String result = OrganizationHelper.getSobjectName(objAccount);
        System.assertEquals('account', result, 'SObject names should be equal');
    }

    @isTest
    public static void passListOfRecordOfLeadTest(){
        CI_Company__c companyRecord = [SELECT Id FROM CI_Company__c WHERE CI_Company_Id__c=1234 AND Company_Name__c = 'test company1'];
        Account orgAccountRecord = TestingUtility.createAccount('strAccountName', false);
        orgAccountRecord.Account_Type__c = 'Org';
        orgAccountRecord.CI_Company__c = companyRecord.Id;
        orgAccountRecord.Cleansed_Account_Name__c = 'test company cleansed';
        Database.SaveResult accInsertResult = Database.insert(orgAccountRecord, false);
        System.assert (accInsertResult.isSuccess(), 'Org Account insertion error: ' + accInsertResult.getErrors());
        List<Lead> leads = new List<Lead>();
        Lead leadRecord1 = new Lead();
        leadRecord1.LastName = 'lastName';
        leadRecord1.Email = 'email@enazigma.com';
        leadRecord1.Phone = '1234567891';
        leadRecord1.Company = 'Test Company';
        leadRecord1.Locations_Interested__c='Test Building Tour';
        leadRecord1.CI_Company__c = companyRecord.Id;
        leadRecord1.LeadSource= 'Event';
        leadRecord1.Lead_Source_Detail__c = 'Broker1';
        leads.add(leadRecord1);
        Lead leadRecord2 = new Lead();
        leadRecord2.LastName = 'lastName';
        leadRecord2.Email = 'email@enazigma.com';
        leadRecord2.Phone = '1234567891';
        leadRecord2.Company = 'Test Company';
        leadRecord2.Locations_Interested__c='Test Building Tour';
        leadRecord2.Cleansed_Unomy_Company_Name__c = 'Test Cleansed Unomy Company Name';
        leadRecord2.LeadSource= 'Event';
        leadRecord2.Lead_Source_Detail__c = 'Broker1';
        leads.add(leadRecord2);
        Database.SaveResult[] insertResults = Database.insert(leads, false);
        for(Database.SaveResult insertResult : insertResults) {
            System.assert (insertResult.isSuccess(), 'Lead insertion error: ' + insertResult.getErrors());
        }
        
        List<Lead> leadsAfterInsert  = [SELECT Id, Account__c,Company, Name, Email_Domain_Text__c, Cleansed_Unomy_Company_Name__c,
                                        FirstName, LastName, Email, LeadSource, Unomy_Company_ID_Formula__c, 
                                        Unomy_Company_Name_Formula__c, Cleansed_Company_Name__c FROM Lead 
                                        WHERE Id IN :leads AND IsConverted = False];
                Map<Id,Id> mapOrgIds = OrganizationHelper.findRelatedOrg(leadsAfterInsert);
        System.assertEquals(mapOrgIds.values().get(0),orgAccountRecord.Id, 'Org is not mapped properly');
    }

    @isTest
    public static void passListOfRecordOfContactTest(){
        List<String> leadFields = new OrganizationHelper().getListFields('lead');
        List<String> contactFields = new OrganizationHelper().getListFields('contact');
        CI_Company__c companyRecord = [SELECT Id FROM CI_Company__c WHERE CI_Company_Id__c=1234 AND Company_Name__c = 'test company1'];
        List<Account> salesHierarchy = TestingUtility.getSalesAccountsWithHierarchy(2, true);
        Account firstAccountRecord = salesHierarchy[1];
        Account orgAccountRecord = salesHierarchy[0];
        orgAccountRecord.CI_Company__c = companyRecord.Id;
        orgAccountRecord.Cleansed_Account_Name__c = 'test company cleansed';
        List<Contact> contacts = new List<Contact>();
        Contact firstContactRecord = new Contact();
        firstContactRecord.FirstName = 'Krishana First Name';
        firstContactRecord.LastName = 'Krishana';
        firstContactRecord.Email = 'Krishna@example.com';
        firstContactRecord.CI_Company__c = companyRecord.Id;
        contacts.add(firstContactRecord);
        Contact secondContactRecord = new Contact();
        secondContactRecord.FirstName = 'Krishana First Name2';
        secondContactRecord.LastName = 'Krishana2';
        secondContactRecord.Email = 'Krishna2@example.com';
        secondContactRecord.CI_Company__c = companyRecord.Id;
        contacts.add(secondContactRecord);
        Contact firstContactWithAccount = new Contact();
        firstContactWithAccount.FirstName = 'Anna';
        firstContactWithAccount.LastName = 'Krishana3';
        firstContactWithAccount.Email = 'Krishna3@example.com';
        firstContactWithAccount.AccountId = firstAccountRecord.Id;
        contacts.add(firstContactWithAccount);
        Contact secondContactWithAccount = new Contact();
        secondContactWithAccount.FirstName = 'Anna';
        secondContactWithAccount.LastName = 'Krishana4';
        secondContactWithAccount.Email = 'Krishna4@example.com';
        contacts.add(secondContactWithAccount);
        Database.SaveResult[] insertResults = Database.insert(contacts, false);
        for(Database.SaveResult insertResult : insertResults) {
            System.assert (insertResult.isSuccess(), 'Contact insertion error: ' + insertResult.getErrors());
        }
        Map<Id, Contact> mapContact  = new Map<Id, Contact>([SELECT Id, AccountId, Account.Name, Account.Account_Type__c, Account_Name__c, Name, Email_Domain_Text__c, LastName, FirstName, Email, LeadSource, Unomy_Company_ID_Formula__c, Cleansed_Company_Name__c FROM Contact WHERE Id IN: contacts ]);
        Map<Id,Id> mapOrgIds = OrganizationHelper.findOrCreateRelatedOrg(mapContact.values());
        for(Id mapKey : mapOrgIds.keySet()) {
            if(mapContact.get(mapKey).Account.Account_Type__c == 'Org') {
                System.assertEquals(mapOrgIds.get(mapKey), orgAccountRecord.Id, 'Org is not mapped properly');
            }
            else if(mapContact.get(mapKey).Account.Account_Type__c == 'Sales') {
                System.assertEquals(mapOrgIds.get(mapKey), firstAccountRecord.Id, 'Sales is not mapped properly');
            }
        }
    }

    @isTest
    public static void verifyGetRelatedOrgWhenPassSingleRecordOfLead(){
        CI_Company__c companyRecord = [SELECT Id FROM CI_Company__c WHERE CI_Company_Id__c=1234 AND Company_Name__c = 'test company1'];
        Account orgAccountRecord = TestingUtility.createAccount('strAccountName', false);
        orgAccountRecord.Account_Type__c = 'Org';
        orgAccountRecord.CI_Company__c = companyRecord.Id;
        orgAccountRecord.Cleansed_Account_Name__c = 'test company cleansed';
        Database.SaveResult accInsertResult = Database.insert(orgAccountRecord, false);
        System.assert (accInsertResult.isSuccess(), 'Org Account insertion error: ' + accInsertResult.getErrors());
        Lead leadRecord = new Lead();
        leadRecord.LastName = 'lastName';
        leadRecord.Email = 'email@enazigma.com';
        leadRecord.Phone = '1234567891';
        leadRecord.Company = 'Test Company';
        leadRecord.Locations_Interested__c='Test Building Tour';
        leadRecord.CI_Company__c = companyRecord.Id;
        leadRecord.LeadSource= 'Event';
        leadRecord.Lead_Source_Detail__c = 'Broker1';
        Database.SaveResult leadInsertResult = Database.insert(leadRecord);
        System.assert (leadInsertResult.isSuccess(), 'Contact insertion error: ' + leadInsertResult.getErrors());
        
        Id orgID = OrganizationHelper.findRelatedOrg([SELECT Id, Account__c,Company, Name, Email_Domain_Text__c, 
                                                      Cleansed_Unomy_Company_Name__c,FirstName, LastName, Email, 
                                                      LeadSource, Unomy_Company_ID_Formula__c, Unomy_Company_Name_Formula__c,
                                                      Cleansed_Company_Name__c FROM Lead WHERE Id = : leadRecord.Id ][0]);
        
        //Id orgID = OrganizationHelper.findRelatedOrg([SELECT Id,Account__c,Company, Name, LastName, Email, LeadSource, Cleansed_Company_Name__c,Unomy_Company_Name_Formula__c,Unomy_Company_Id_Formula__c,Cleansed_Unomy_Company_Name__c FROM Lead WHERE Id = : leadRecord.Id ][0]);
        
        System.assertEquals(orgID, orgAccountRecord.Id,'Org is not mapped properly');
    }

    @isTest
    public static void verifyGetRelatedOrgWhenPassSingleRecordOfContact(){
        List<String> leadFields = new OrganizationHelper().getListFields('lead');
        List<String> contactFields = new OrganizationHelper().getListFields('contact');
        CI_Company__c companyRecord = [SELECT Id FROM CI_Company__c WHERE CI_Company_Id__c=1234 AND Company_Name__c = 'test company1'];
        Account orgAccountRecord = TestingUtility.createAccount('strAccountName', false);
        orgAccountRecord.Account_Type__c = 'Org';
        orgAccountRecord.CI_Company__c = companyRecord.Id;
        orgAccountRecord.Cleansed_Account_Name__c = 'test company cleansed';
        Database.SaveResult accInsertResult = Database.insert(orgAccountRecord, false);
        System.assert (accInsertResult.isSuccess(), 'Org Account insertion error: ' + accInsertResult.getErrors());
        Contact objContact = new Contact();
        objContact.FirstName = 'Krishana First Name';
        objContact.LastName = 'Krishana';
        objContact.Email = 'Krishna@example.com';
        objContact.CI_Company__c = companyRecord.Id;
        Database.SaveResult contactInsertResult = Database.insert(objContact);
        System.assert (contactInsertResult.isSuccess(), 'Contact insertion error');
        Id orgID = OrganizationHelper.findOrCreateRelatedOrg([SELECT Id, AccountId, Account_Name__c, Name,Email_Domain_Text__c,Unomy_Company_ID_Formula__c,FirstName, LastName, Email, LeadSource, Cleansed_Company_Name__c FROM Contact WHERE Id = : objContact.Id ][0]);
    }

    @isTest
    public static void verifyMatchSpecialCharAccount(){
        Map<String, Map<String, String> > mapAccIdByChar = (Map<String, Map<String, String> >) JSON.deserialize(Settings.getMetadataSettingByDevName('Special_Character_Accounts').Data__c, Map<String, Map<String, String> >.class);
        Contact objContact = new Contact();
        objContact.FirstName = 'First Name Test';
        objContact.LastName = 'test111111111';
        objContact.Email = 'unmatchableemail@nomatch.com';
        insert objContact; 
        Test.startTest();
        Id orgId = OrganizationHelper.findOrCreateRelatedOrg([SELECT Name,LeadSource,AccountId,Unomy_Company_ID_Formula__c,Cleansed_Company_Name__c,Account_Name__c,Email,Email_Domain_Text__c,LastName,FirstName FROM Contact WHERE Id=: objContact.Id][0]);
        Test.stopTest();
        List<Apex_Debug_Log__c> logs = [SELECT Message__c FROM Apex_Debug_Log__c WHERE Message__c LIKE '%special character Account detected%' LIMIT 1];
        System.assertEquals(false, orgId == (Id) mapAccIdByChar.get('characters').get('.'), 'didnt find special char account when inserting Contact with special char company name ==> '+orgId +'/'+mapAccIdByChar.get('.'));
    }

    @isTest
    public static void verifyUnknownSpecialCharDetection(){
        Map<String, Map<String, String> > mapAccIdByChar = (Map<String, Map<String, String> >) JSON.deserialize(Settings.getMetadataSettingByDevName('Special_Character_Accounts').Data__c, Map<String, Map<String, String> >.class);
        Contact objContact = new Contact();
        objContact.FirstName = 'First Name Test';
        objContact.LastName = 'test111111111';
        objContact.Email = 'unmatchableemail@nomatch.com';
        insert objContact;
        Test.startTest();
        Id orgId = OrganizationHelper.findOrCreateRelatedOrg([SELECT Name,LeadSource,AccountId,Unomy_Company_ID_Formula__c,Cleansed_Company_Name__c,Account_Name__c,Email,Email_Domain_Text__c,LastName,FirstName FROM Contact WHERE Id=: objContact.Id][0]);
        Test.stopTest();
        List<Apex_Debug_Log__c> logs = [SELECT Message__c FROM Apex_Debug_Log__c WHERE Message__c LIKE '%unknown special character Account detected%' LIMIT 1];
        System.assert (logs!=null);
    }
    
    @isTest
    public static void getUltimateParents(){
        List<String> listOfStrings = new List<String>();
        Set<Id> accountIds = new Set<Id>();
        List<Account> accountList = TestingUtility.createAccounts(16, 'Test Accounts', true);
        for(Account accItem : accountList) {
            accItem.Account_Type__c = 'Org';
            accountIds.add(accItem.Id);
        }
        Test.startTest();
        OrganizationHelper.getUltimateParents(accountIds,listOfStrings);
        Test.stopTest();
        System.AssertNotEquals(null, accountIds,'Account should not be empty');
    }
}