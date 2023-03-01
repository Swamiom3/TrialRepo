/*************************************************************************************************************************************
    Author      :   Stepan Vardzal
    Description :   Test class for AccountTeamMemberValidationTrH
    History:        New test class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION         DATE            AUTHOR                      DETAIL							                            ISSUE
    1.0             03 Sept, 2021   Stepan Vardzal              Refactor triggers: AccountTeamMember                        ST-8430
**************************************************************************************************************************************/
@isTest
public class AccountTeamMemberValidationTrHTest {

    @isTest
    private static void testValidateAccountTeamMember() {
        List<AccountTeamMember> testListOldAccountTeamMembers = getFakeAccountTeamMembers(1,getFakeAccount().Id);
        testListOldAccountTeamMembers[0].Id = TestUtility.getFakeId(AccountTeamMember.SObjectType);
        
        List<AccountTeamMember> testListAccountTeamMember = testListOldAccountTeamMembers.deepClone(true, true, true);

        AccountTeamMemberValidationTrH handlerInstance = new AccountTeamMemberValidationTrH(testListAccountTeamMember, new Map<Id, AccountTeamMember>(testListOldAccountTeamMembers));
        handlerInstance.beforeUpdate();
        Profile notAllowedProfile = [SELECT Id FROM Profile WHERE Name = 'WeWork Sales User'];
        User userWithNotAllowedProfileId = TestingUtility.insertUserWithAssert(notAllowedProfile.Id, new Map<String, object> {'Email'=>'user16102019001@example.com'}, true);

        Test.startTest();
        System.runAs(userWithNotAllowedProfileId) {
            try{
                handlerInstance.validateAccountTeamMember(testListAccountTeamMember);
            } catch (Exception ex) {
                System.assertEquals(true, ex.getMessage().contains('You do not have permission to update Account Team Member. Please contact Growth Ops for further assistance.'), 'You do not have permission to update Account Team Member. Please contact Growth Ops for further assistance error should be thrown.');
            }
        }
        Test.stopTest();
    }

    @isTest
    private static void testValidateUniqueRole() {

        List<AccountTeamMember> testListOldAccountTeamMembers = getFakeAccountTeamMembers(2,getFakeAccount().Id);
        testListOldAccountTeamMembers[0].Id = TestUtility.getFakeId(AccountTeamMember.SObjectType);
        testListOldAccountTeamMembers[1].Id = TestUtility.getFakeId(AccountTeamMember.SObjectType);
        List<AccountTeamMember> testListNewAccountTeamMembers = testListOldAccountTeamMembers.deepClone(true, true, true);

        AccountTeamMemberValidationTrH handlerInstance = new AccountTeamMemberValidationTrH(testListNewAccountTeamMembers, new Map<Id, AccountTeamMember>(testListOldAccountTeamMembers));
        
        handlerInstance.accountTeamMemberSelector = (AccountTeamMemberSelector) MockService.createMock(
            AccountTeamMemberSelector.class,
                new Map<String, Object>{
                    'getAccountTeamMembers' => testListNewAccountTeamMembers });
        handlerInstance.registerDmlConsolidator(DmlConsolidatorPartialSuccess.getInstance());

        Test.startTest();
        try{
            handlerInstance.validateUniqueRole();
        } catch (Exception ex) {
            System.assertEquals(true, ex.getMessage().contains(Label.ATM_Nmd_Mlb_Role_Validation_Msessage), 'Only one active Account Manager role can exist under a particular Account at one time.');
        }
        Test.stopTest();  
    }

    @isTest
    private static void testvalidateAgainstExistingRecords() {

        List<AccountTeamMember> testListOldAccountTeamMembers = getFakeAccountTeamMembers(2,getFakeAccount().Id);
        testListOldAccountTeamMembers[0].Id = TestUtility.getFakeId(AccountTeamMember.SObjectType);
        testListOldAccountTeamMembers[1].Id = TestUtility.getFakeId(AccountTeamMember.SObjectType);
        List<AccountTeamMember> testListNewAccountTeamMembers = testListOldAccountTeamMembers.deepClone(true, true, true);

        AccountTeamMemberValidationTrH handlerInstance = new AccountTeamMemberValidationTrH(testListNewAccountTeamMembers, new Map<Id, AccountTeamMember>(testListOldAccountTeamMembers));

        handlerInstance.accountTeamMemberSelector = (AccountTeamMemberSelector) MockService.createMock(
            AccountTeamMemberSelector.class,
                new Map<String, Object>{
                    'getAccountTeamMembers' => testListNewAccountTeamMembers });
        handlerInstance.registerDmlConsolidator(DmlConsolidatorPartialSuccess.getInstance());

        Test.startTest();
        try{
            handlerInstance.validateAgainstExistingRecords();
        } catch (Exception ex) {
            System.assertEquals(true, ex.getMessage().contains(Label.ATM_Nmd_Mlb_Role_Validation_Msessage), 'Only one active Account Manager role can exist under a particular Account at one time.');
        }
        Test.stopTest();
    }

    @isTest
    private static void validateAccountManagerTeamMemberTest() {
        List<AccountTeamMember> testListOldAccountTeamMembers = getFakeAccountTeamMembers(1,getFakeAccount().Id);
        testListOldAccountTeamMembers[0].Id = TestUtility.getFakeId(AccountTeamMember.SObjectType);
        
        List<AccountTeamMember> testListAccountTeamMember = testListOldAccountTeamMembers.deepClone(true, true, true);
        testListOldAccountTeamMembers[0].TeamMemberRole = 'Partnerships';

        AccountTeamMemberValidationTrH handlerInstance = new AccountTeamMemberValidationTrH(testListAccountTeamMember, new Map<Id, AccountTeamMember>(testListOldAccountTeamMembers));
        handlerInstance.beforeUpdate();
        
        Test.startTest();
        try{
            handlerInstance.validateAccountManagerTeamMember(testListAccountTeamMember);
        } catch (Exception ex) {
            System.assertEquals(true, ex.getMessage().contains(Label.AccountManagerTeamMemberValidation), 'During role change in account manager team member error should be thrown');
    
        }
        Test.stopTest();
    }

    @isTest
    private static void beforeInsertTest() {
        List<AccountTeamMember> testListOldAccountTeamMembers = getFakeAccountTeamMembers(2,getFakeAccount().Id);
        testListOldAccountTeamMembers[0].Id = TestUtility.getFakeId(AccountTeamMember.SObjectType);
        testListOldAccountTeamMembers[1].Id = TestUtility.getFakeId(AccountTeamMember.SObjectType);
        List<AccountTeamMember> testListNewAccountTeamMembers = testListOldAccountTeamMembers.deepClone(true, true, true);

        AccountTeamMemberValidationTrH handlerInstance = new AccountTeamMemberValidationTrH(testListNewAccountTeamMembers, new Map<Id, AccountTeamMember>(testListOldAccountTeamMembers));
        
        handlerInstance.accountTeamMemberSelector = (AccountTeamMemberSelector) MockService.createMock(
            AccountTeamMemberSelector.class,
                new Map<String, Object>{
                    'getAccountTeamMembers' => testListNewAccountTeamMembers });
        handlerInstance.registerDmlConsolidator(DmlConsolidatorPartialSuccess.getInstance());
        handlerInstance.beforeInsert();

        Test.startTest();
        try{
            handlerInstance.beforeInsert();
        } catch (Exception ex) {
            System.assertEquals(true, ex.getMessage().contains(Label.ATM_Nmd_Mlb_Role_Validation_Msessage), 'Only one active Account Manager role can exist under a particular Account at one time.');
        }
        Test.stopTest();
    }
    
    @isTest
    private static void beforeDeleteTest() {
        List<AccountTeamMember> testListOldAccountTeamMembers = getFakeAccountTeamMembers(2,getFakeAccount().Id);
        testListOldAccountTeamMembers[0].Id = TestUtility.getFakeId(AccountTeamMember.SObjectType);
        testListOldAccountTeamMembers[1].Id = TestUtility.getFakeId(AccountTeamMember.SObjectType);
        List<AccountTeamMember> testListNewAccountTeamMembers = testListOldAccountTeamMembers.deepClone(true, true, true);

        AccountTeamMemberValidationTrH handlerInstance = new AccountTeamMemberValidationTrH(testListNewAccountTeamMembers, new Map<Id, AccountTeamMember>(testListOldAccountTeamMembers));
        
        handlerInstance.accountTeamMemberSelector = (AccountTeamMemberSelector) MockService.createMock(
            AccountTeamMemberSelector.class,
                new Map<String, Object>{
                    'getAccountTeamMembers' => testListNewAccountTeamMembers });
        handlerInstance.registerDmlConsolidator(DmlConsolidatorPartialSuccess.getInstance());
        handlerInstance.beforeDelete();

        Test.startTest();
        try{
            handlerInstance.beforeInsert();
        } catch (Exception ex) {
            System.assertEquals(true, ex.getMessage().contains(Label.ATM_Nmd_Mlb_Role_Validation_Msessage), 'Only one active Account Manager role can exist under a particular Account at one time.');
        }
        Test.stopTest();
    }
    @isTest
    private static void afterDeleteTest() {
        List<AccountTeamMember> testListOldAccountTeamMembers = getFakeAccountTeamMembers(2,getFakeAccount().Id);
        testListOldAccountTeamMembers[0].Id = TestUtility.getFakeId(AccountTeamMember.SObjectType);
        testListOldAccountTeamMembers[1].Id = TestUtility.getFakeId(AccountTeamMember.SObjectType);
        List<AccountTeamMember> testListNewAccountTeamMembers = testListOldAccountTeamMembers.deepClone(true, true, true);

        AccountTeamMemberValidationTrH handlerInstance = new AccountTeamMemberValidationTrH(testListNewAccountTeamMembers, new Map<Id, AccountTeamMember>(testListOldAccountTeamMembers));
        
        handlerInstance.accountTeamMemberSelector = (AccountTeamMemberSelector) MockService.createMock(
            AccountTeamMemberSelector.class,
                new Map<String, Object>{
                    'getAccountTeamMembers' => testListNewAccountTeamMembers });
        handlerInstance.registerDmlConsolidator(DmlConsolidatorPartialSuccess.getInstance());
        handlerInstance.afterDelete();

        Test.startTest();
        try{
            handlerInstance.beforeInsert();
        } catch (Exception ex) {
            System.assertEquals(true, ex.getMessage().contains(Label.ATM_Nmd_Mlb_Role_Validation_Msessage), 'Only one active Account Manager role can exist under a particular Account at one time.');
        }
        Test.stopTest();
    } 

    static Account getFakeAccount() {
        Account fakeAccount = new Account();
        fakeAccount.Id = TestUtility.getFakeId(Account.SObjectType);
        return fakeAccount;
    }

    static List<AccountTeamMember> getFakeAccountTeamMembers(Integer numberOfRecords, Id AccountId) {
        List<AccountTeamMember> fakeAccountTeamMembers = new List<AccountTeamMember>();
        for (Integer i = 0; i < numberOfRecords; i++) {
            AccountTeamMember fakeAccountTeamMember = new AccountTeamMember();
            fakeAccountTeamMember.AccountId = AccountId;
            fakeAccountTeamMember.TeamMemberRole = 'Account Manager';
            fakeAccountTeamMember.Start_Date__c = Date.today();
            fakeAccountTeamMember.UserId = UserInfo.getUserId();
            fakeAccountTeamMember.AccountAccessLevel = 'Read';
            fakeAccountTeamMember.CaseAccessLevel = 'Read';
            fakeAccountTeamMember.ContactAccessLevel = 'Read';
            fakeAccountTeamMember.OpportunityAccessLevel = 'Read';

            fakeAccountTeamMembers.add(fakeAccountTeamMember);
        }
        return fakeAccountTeamMembers;
    }
}