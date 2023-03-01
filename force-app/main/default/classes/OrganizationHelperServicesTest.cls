@isTest
public class OrganizationHelperServicesTest {
    private static String DOMAIN_NAME = 'WEWORKEXAMPLE.COM';

    @testSetup
    public static void initData(){
        WeWorkValidatorHelper.createTerritoryStructure();
        
        List<CI_Company__c> lstUnomy = new List<CI_Company__c>();
        lstUnomy.add(new CI_Company__c(CI_Company_Id__c = 1234, Company_Name__c = 'test company1'));
        lstUnomy.add(new CI_Company__c(CI_Company_Id__c = 12345, Company_Name__c = 'Test_Company'));
        TestingUtility.insertListWithAssert(lstUnomy);
        
        List<Account> lstAccounts = new List<Account>();
        Account orgAccount1 = TestingUtility.createAccount('Test Company', false);
        orgAccount1.Account_Type__c = 'Org';
        orgAccount1.CI_Company__c = lstUnomy[0].Id;
        orgAccount1.Phone = '111-111-1111';
        orgAccount1.Website = 'anaccountwebsite.co.uk';
        lstAccounts.add(orgAccount1);
        
        Account orgAccount2 = TestingUtility.createAccount('Test Contact Company', false);
        orgAccount2.Account_Type__c = 'Org';
        orgAccount2.Phone = '222-222-2222';
        orgAccount2.CI_Company__c = lstUnomy[1].Id;
        lstAccounts.add(orgAccount2);
        
        insert lstAccounts;
        
        List<Lead> lstLead = new List<Lead>();
        Lead objLead = new Lead();
        objLead.LastName = 'lastName';
        objLead.Email = 'email@enazigma.com';
        objLead.Phone = '1234567891';
        objLead.Company = 'Some unrelated company';
        objLead.Locations_Interested__c='Test Building Tour';
        objLead.CI_Company__c = lstUnomy[0].Id;
        objLead.LeadSource= 'Event';
        objLead.Lead_Source_Detail__c = 'Broker';
        objLead.Website = 'aleadwebsite.com';
        lstLead.add(objLead);
        
        Lead objLead2 = new Lead();
        objLead2.LastName = 'lastName2';
        objLead2.Email = 'email2@enazigma.com';
        objLead2.Phone = '1234567891';
        objLead2.Company = 'Test Company';
        objLead2.CI_Company__c = lstUnomy[0].Id;
        objLead2.Locations_Interested__c='Test Building Tour';
        objLead2.LeadSource= 'Event';
        objLead2.Lead_Source_Detail__c = 'Broker';
        objLead2.Website = 'anaccountwebsite.co.uk';
        lstLead.add(objLead2);
        
        insert lstLead;
        system.assert(objLead.Id != NULL, 'Lead Insertion Error on objLead');
        system.assert(objLead2.Id != NULL, 'Lead Insertion Error on objLead2');
        
        List<Contact> lstContacts = new List<Contact>();
        Contact objContact = new Contact();
        objContact.FirstName='Test1';
        objContact.LastName='Contact123';
        objContact.Email = 'test1.Contact123@example12.com';
        objContact.CI_Company__c = lstUnomy[0].Id;
        lstContacts.add(objContact);
        
        Contact objContact2 = new Contact();
        objContact2.FirstName='Test2';
        objContact2.LastName='Contact12';
        objContact2.Email = 'test2.contact12@example12.com';
        objContact2.Phone = '222-222-2222';
        lstContacts.add(objContact2);
        
        insert lstContacts;
        system.assert(objContact.Id != NULL, 'Lead Insertion Error on objContact');
        system.assert(objContact2.Id != NULL, 'Lead Insertion Error on objContact2');
    }
    @isTest
    public static void verifyLeadMatching(){
        List<Account> lstAccounts = [SELECT Id, Name, Website, Phone, Unomy_Company_ID_Formula__c, CI_Company__c, Cleansed_Account_Name__c, Cleansed_Unomy_Company_Name__c, Unomy_Company_Name_Formula__c, Account_Type__c, Unomy_Company_Phone_Formula__c, Unomy_Company_Website_Formula__c FROM Account];
        Map<String, Set<String>> mapMatchedAccounts = new Map<String, Set<String>>();
        Map<Id, Map<String, Set<String>>> mapSegmentedConfidence = new Map<Id, Map<String, Set<String>>>();
        for(Account a : lstAccounts){
            OrganizationHelperServices.setMatchingAccounts(a, mapMatchedAccounts, OrganizationHelperServices.getSearchingOrganizationCriteria().get('matchingCriteria'), true);
        }
        Boolean lowConfidenceMatchedAccount = false;
        Boolean highConfidenceMatchedAccount = false;
        Account testAccount = TestingUtility.createAccount(new Map<String, Object> 
                                                       {   'Name' => 'Test Contact Company 1',
                                                           'Account_Type__c' => 'Org',
                                                           'Interested_in_Number_of_Desks__c' => 10,
                                                           'Phone' => '222-222-2222'},
                                                       true);
      
        for(Lead l : (List<Lead>) Database.query('SELECT '+String.join(new OrganizationHelperServices().getListFields('Lead'), ',')+' FROM Lead')){
            for(Account a : lstAccounts){
                if( a.CI_Company__c == l.CI_Company__c && (a.Phone != l.Phone && a.Website != l.Website && a.Cleansed_Account_Name__c != l.Cleansed_Company_Name__c)){
                    // expecting a low-confidence match
                    lowConfidenceMatchedAccount = true;
                    OrganizationHelperServices.getLowConfidenceAccountInMap(new Map<Id, String>{TestAccount.Id => 'test'}, mapSegmentedConfidence, new List<Lead>{l}, lstAccounts);
                    OrganizationHelperServices.getLowConfidenceAccountInMap(new Map<Id, String>(), mapSegmentedConfidence, new List<Lead>{l}, lstAccounts);
                    System.assertEquals(mapSegmentedConfidence.containsKey(l.Id), true, 'failed to match Lead with ID ==> '+l.Id);
                    System.assertEquals(mapSegmentedConfidence.get(l.Id).containsKey('lowConfidenceAccountIds'), true, 'failed to find low confidence matches for Lead with ID ==> '+l.Id);
                    Boolean foundAccount = false;
                    for(Id matchedAccountId : mapSegmentedConfidence.get(l.Id).get('lowConfidenceAccountIds')){
                        if(matchedAccountId == a.Id) foundAccount = true;
                    }
                    System.assertEquals(true, foundAccount, 'didnt find account in low confidence match list for Lead ==> '+l.Id);
                }
                if( a.Website == l.Website && a.Cleansed_Account_Name__c == l.Cleansed_Company_Name__c){ // expecting high-confidence match
                    highConfidenceMatchedAccount = true;
                    Set<String> setMatchedAccountIds = OrganizationHelperServices.setMatchingAccounts(l, mapMatchedAccounts, OrganizationHelperServices.getSearchingOrganizationCriteria().get('leadMatchingCriteria'), false);
                    System.assertEquals(true, setMatchedAccountIds.contains(a.Id), 'missing account from high confidence match list for Lead ==> '+l.Id);
                }
            }
        }
        System.assertEquals(true, highConfidenceMatchedAccount, 'didnt find high confidence account matches');
    }

    @isTest
    public static void verifyContactMatching(){
        List<Account> lstAccounts = [SELECT Id, Name, Website, Phone, Unomy_Company_ID_Formula__c, CI_Company__c, Cleansed_Account_Name__c, Cleansed_Unomy_Company_Name__c, Unomy_Company_Name_Formula__c, Account_Type__c, Unomy_Company_Phone_Formula__c, Unomy_Company_Website_Formula__c FROM Account];
        Map<String, Set<String>> mapMatchedAccounts = new Map<String, Set<String>>();
        Map<Id, Map<String, Set<String>>> mapSegmentedConfidence = new Map<Id, Map<String, Set<String>>>();
        for(Account a : lstAccounts){
            OrganizationHelperServices.setMatchingAccounts(a, mapMatchedAccounts, OrganizationHelperServices.getSearchingOrganizationCriteria().get('matchingCriteria'), true);
        }
        Boolean lowConfidenceMatchedAccount = false;
        Boolean highConfidenceMatchedAccount = false;
        for(Contact c : [SELECT CI_Company__c,Phone,Cleansed_Company_Name__c,Name,
                         Unomy_Company_Website_Formula__c,Unomy_Company_Phone_Formula__c FROM Contact]){
        
            for(Account a : lstAccounts){
                if(a.CI_Company__c == c.CI_Company__c && (a.Phone != c.Phone && a.Cleansed_Account_Name__c != c.Cleansed_Company_Name__c) ){
                    lowConfidenceMatchedAccount = true;
                    OrganizationHelperServices.getLowConfidenceAccountInMap(new Map<Id, String>(), mapSegmentedConfidence, new List<Contact>{c}, lstAccounts);
                    System.assertEquals(mapSegmentedConfidence.containsKey(c.Id), true, 'failed to match Contact with ID ==> '+c.Id);
                    System.assertEquals(mapSegmentedConfidence.get(c.Id).containsKey('lowConfidenceAccountIds'), true, 'failed to find low confidence matches for Contact with ID ==> '+c.Id);
                    Boolean foundAccount = false;
                    for(Id matchedAccountId : mapSegmentedConfidence.get(c.Id).get('lowConfidenceAccountIds')){
                        if(matchedAccountId == a.Id) foundAccount = true;
                    }
                    System.assertEquals(true, foundAccount, 'didnt find account in low confidence match list for Contact ==> '+c.Id);
                }
                if( a.Phone == c.Phone && a.Cleansed_Account_Name__c == c.Cleansed_Company_Name__c){ // expecting high-confidence match
                    highConfidenceMatchedAccount = true;
                    Set<String> setMatchedAccountIds = OrganizationHelperServices.setMatchingAccounts(c, mapMatchedAccounts, OrganizationHelperServices.getSearchingOrganizationCriteria().get('contactMatchingCriteria'), false);
                    System.assertEquals(true, setMatchedAccountIds.contains(a.Id), 'missing account from high confidence match list for Contact ==> '+c.Id);
                }
            }
        }
        System.assertEquals(true, lowConfidenceMatchedAccount, 'didnt find low confidence account matches');
    }

    @isTest
    public static void shouldAddDomainInLowerCase(){
        String fakeAccountId = String.valueOf(TestUtility.getFakeId(Account.SObjectType));
        Map<String, Set<String>> emailDomainWithAccountIdsMap = new  Map<String, Set<String>>();
        Set<String> emailDomains;

        Test.startTest();
        OrganizationHelperServices.setEmailDomainMatchAccounts(DOMAIN_NAME, fakeAccountId, emailDomainWithAccountIdsMap);
        Test.stopTest();

        System.assertNotEquals(emailDomainWithAccountIdsMap.get(DOMAIN_NAME.toLowerCase()), null, 'Set should be properly retrieved');
        emailDomains = emailDomainWithAccountIdsMap.get(DOMAIN_NAME.toLowerCase());
        System.assert(emailDomains.contains(fakeAccountId), 'Set should contain Account Id');
    }

    @isTest
    public static void shouldTestOrgFind(){
        Contact contactRecord = getContactByWeb(getTourPayload());
        insert contactRecord;

        Test.startTest();
        contactRecord.AccountId = OrganizationHelperServices.findOrCreateOrgByNewCriteria(contactRecord);
        Test.stopTest();

        System.assertNotEquals(contactRecord.AccountId, null, 'Should contain Account Id');
    }

    private static RESTAPITourModelsV2.Input getTourPayload(){
        String jsonTourPayload = '{"first_name":"John","last_name":"Smith","email":"john.smith1@example.com","phone":"1234567890","lead_source":"Event","lead_source_detail":"Book A Tour Form","utm_campaign_id":"","utm_campaign":"San Francisco - Modifier","utm_content":"utm contents","utm_medium":"cpc","utm_source":"ads-google","utm_term":"virtual +office +san +francisco","company_name":"John Smith","company_size":"2-5 desks","company_industry":"Education","quick_quote_location":"New York City","notes":"Our Notes for","referral_code":"JetBlue","promo_code":"JetBlue","buildings_interested_uuids":["bdf78b97-f8c9-4062-923d-ed32e251d2ad"],"product_interests":["Office Space"],"product_line":"WeWork","locale":"US","country_code":"US","tour_date":"2018-06-07","tour_time":"08:00AM","tour_uuid":"fdb15bdf-19e2-4abe-bd40-7b7fa9816fb5","tour_building_uuid":"bdf78b97-f8c9-4062-923d-ed32e251d2ad","tour_notes":"Currently at Manhattan, Relocate","contact_uuid":"dsp18593-3239-45cc-b690-5bccc15a27c3","original_tour":"","original_tour_uuid":"","sf_journey_uuid":"","booked_by_contact_id":"0033D00000Ou6FA","tour_completed_by":"","t_and_cs_consent":"False","marketing_consent":"False","affiliates_consent":"False","referral_fail_reason":"No Show","booked_by_sales_lead":true}';
        RESTAPITourModelsV2.Input tourPayload = (RESTAPITourModelsV2.Input)JSON.deserialize(jsonTourPayload, RESTAPITourModelsV2.Input.class);
        return tourPayload;
    }

    private static Contact getContactByWeb(RESTAPITourModelsV2.Input tourPayload) {
        return new Contact(
                FirstName = tourPayload.first_name,
                LastName = tourPayload.last_name,
                Convert_Lead__c = false,
                Phone = tourPayload.phone,
                Email = tourPayload.email,
                Locale__c = tourPayload.locale,
                Product_Interests__c = tourPayload.product_interests != null ? String.join(tourPayload.product_interests, ';') : null,
                Country_Code__c = tourPayload.country_code,
                Product_Line__c = tourPayload.product_line,
                UUID__c = tourPayload.contact_uuid,
                Marketing_Consent__c = ((tourPayload.marketing_consent != null && tourPayload.marketing_consent == 'true') ? true : false),
                Ts_and_Cs_Consent__c = ((tourPayload.t_and_cs_consent != null && tourPayload.t_and_cs_consent == 'true') ? true : false)
        );
    }
}