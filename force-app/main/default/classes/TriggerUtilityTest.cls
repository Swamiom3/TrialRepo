@isTest
private class TriggerUtilityTest {
    @isTest
    static void isFieldValueChangedTest_positive(){
        Account accountRecord = new Account(Name = 'Acme');
        Account changedAccountRecord = new Account(Name ='NotAcme');
        System.assertEquals(true, TriggerUtility.isFieldValueChanged(changedAccountRecord, accountRecord, 'Name'), 'Field changed, so it should return true');
    }

    @isTest
    static void isFieldValueChangedTest_negative(){
        Account accountRecord = new Account(Name = 'Acme');
        Account changedAccountRecord = accountRecord.clone();
        System.assertEquals(false, TriggerUtility.isFieldValueChanged(changedAccountRecord, accountRecord, 'Name'), 'Field didn\'t change so it should return false');
    }

    @isTest static void isFieldsValueChangedOrNullTest(){
        Account accountRecord = new Account();
        Account changedAccountRecord = new Account();
        System.assertEquals(true, TriggerUtility.isFieldsValueChangedOrNull(accountRecord, changedAccountRecord, new Set<String>{'Name'}), 'Field equals null, so it should return true');
        System.assertEquals(false, TriggerUtility.isFieldsValueNotNullAndChanged(accountRecord, changedAccountRecord, new Set<String>{'Name'}), 'Field equals null, so it should return false');
    }

    @isTest static void addSobjectValuesToMapTest(){
        Id accountId = TestUtility.getFakeId(Account.getSObjectType());
        Account account = new Account(Id = accountId);
        Account anotherAccount = new Account(Id = accountId);
        Account oneMoreAccount = new Account();
        Map<Id, List<Account>> accountMap = new Map<Id,List<Account>>();
        TriggerUtility.addSobjectValuesToMap('Id', accountMap, account);
        TriggerUtility.addSobjectValuesToMap('Id', accountMap, anotherAccount);
        TriggerUtility.addSobjectValuesToMap('Id', accountMap, oneMoreAccount);
        System.assertEquals(1, accountMap.size(), 'Map should contain 1 entry');
        System.assertEquals(2, accountMap.get(accountId).size(), 'List should contain 2 entries');
    }
}