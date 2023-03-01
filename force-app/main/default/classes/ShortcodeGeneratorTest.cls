/************************************************************************************************************************************
    Author       :  Shubham Nandwana   
    @Description :  Test class for ShortcodeGenerator class
    Issue No     :  TWSPG-711
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO        DETAIL
    1           20 August 2021      Shubham Nandwana    TWSPG-711       Initial Developement              
**************************************************************************************************************************************/
@isTest
private class ShortcodeGeneratorTest {

    static ShortcodeGenerator shortcodeGeneratorInstance;

    @isTest
    static void getValidatedCodeTest(){
        ShortcodeGenerator shortcodeGenerator=new ShortcodeGenerator();       
        String uuid='7f1ed9c0-7b81-0139-7a63-1288dc637d31';
        shortcodeGenerator=new ShortcodeGenerator();
        System.assertEquals('5YH052', shortcodeGenerator.getMessageShortCode(uuid),'Short code is not generated properly');
        uuid='abe2b3c0-609e-0138-b280-4632030c73bf';
        System.assertEquals('JSMRMP', shortcodeGenerator.getMessageShortCode(uuid),'Short code is not generated properly');
    }
    
    @isTest
    static void verifyUniqueCode_test_positive(){
        Id billRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();
        TestingUtility.createAccount(new Map<String,Object>{'Name' => 'Account-1', 
            'RecordTypeId' => billRecTypeId,
            'Account_Type__c' => 'Org',
            'Member_Short_Code__c' => '5YH052'}, true);
        
        TestingUtility.createAccount(new Map<String,Object>{'Name' => 'Account-2', 
            'RecordTypeId' => billRecTypeId,
            'Account_Type__c' => 'Org',
            'uuid__c' => '7f1ed9c0-7b81-0139-7a63-1288dc637d31'}, true);
        List<Account> accounts = [SELECT Id, Member_Short_Code__c FROM Account WHERE Name = 'Account-2'];
        System.assertEquals('355S0H', accounts.get(0).Member_Short_Code__c, 'Short code is not generated correctly with different seed');
    }
    
    @isTest
    static void verifyUniqueCode_test_negative(){
        Id billRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();
        TestingUtility.createAccount(new Map<String,Object>{'Name' => 'Account-2', 
            'RecordTypeId' => billRecTypeId,
            'Account_Type__c' => 'Org'
            }, true);
        List<Account> accounts = [SELECT Id, Member_Short_Code__c FROM Account WHERE Name = 'Account-2'];
        System.assertEquals(null, accounts.get(0).Member_Short_Code__c, 'Short code should be generated when UUID is null');
    }
	
    private static ShortcodeGenerator getShortcodeGeneratorInstance(){
        if(shortcodeGeneratorInstance != null)
            return shortcodeGeneratorInstance;
        shortcodeGeneratorInstance = new ShortcodeGenerator();
        return shortcodeGeneratorInstance;
    }
}