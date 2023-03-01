/**
 * @description unit tests for the trac_Membership class
 * @name trac_MembershipTest
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-09-04
 */

@IsTest
private class trac_MembershipTest {
    static final TLTestFactory factory = new TLTestFactory();
    static final String personAccRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();

    @IsTest(SeeAllData=true)
    static void testSetAccountMembershipTypeVirtual() {
        Account acc = (Account) factory.createSObject(new Account(),true);
        Account personAcc = new Account(RecordTypeId=personAccRT, LastName='Test');
        insert personAcc;

        Product2 product = [SELECT Id, Name FROM Product2 WHERE Name IN :TLOrgConstants.PRODUCT_NAMES_VIRTUAL LIMIT 1];
        Asset membership = (Asset) factory.createSObject(new Asset(Member_Name__c=personAcc.Id,AccountId=acc.Id,Product2Id=product.Id),false);

        Test.startTest();
        insert membership;
        Test.stopTest();

        Account updatedAccount = [SELECT Id, Membership_Type__c FROM Account WHERE Id = :personAcc.Id];
        System.assertEquals(TLOrgConstants.MEMBERSHIP_TYPE_VIRTUAL, updatedAccount.Membership_Type__c, 'The membership type was not set on the account.');
    }

    @IsTest(SeeAllData=true)
    static void testSetAccountMembershipTypePhysical() {
        Account acc = (Account) factory.createSObject(new Account(),true);
        Account personAcc = new Account(RecordTypeId=personAccRT, LastName='Test');
        insert personAcc;

        Product2 product = [SELECT Id, Name FROM Product2 WHERE Name IN :TLOrgConstants.PRODUCT_NAMES_PHYSICAL LIMIT 1];
        Asset membership = (Asset) factory.createSObject(new Asset(Member_Name__c=personAcc.Id,AccountId=acc.Id,Product2Id=product.Id),false);

        Test.startTest();
        insert membership;
        Test.stopTest();

        Account updatedAccount = [SELECT Id, Membership_Type__c FROM Account WHERE Id = :personAcc.Id];
        System.assertEquals(TLOrgConstants.MEMBERSHIP_TYPE_PHYSICAL, updatedAccount.Membership_Type__c, 'The membership type was not set on the account.');
    }

    @IsTest(SeeAllData=true)
    static void testSetAccountMembershipTypeUpdateProduct() {
        Account acc = (Account) factory.createSObject(new Account(),true);
        Account personAcc = new Account(RecordTypeId=personAccRT, LastName='Test');
        insert personAcc;

        Product2 productPhysical = [SELECT Id, Name FROM Product2 WHERE Name IN :TLOrgConstants.PRODUCT_NAMES_PHYSICAL LIMIT 1];
        Asset membership = (Asset) factory.createSObject(new Asset(Member_Name__c=personAcc.Id,AccountId=acc.Id,Product2Id=productPhysical.Id),true);
        Product2 productVirtual = [SELECT Id, Name FROM Product2 WHERE Name IN :TLOrgConstants.PRODUCT_NAMES_VIRTUAL LIMIT 1];

        Test.startTest();
        update new Asset(Id=membership.Id,Product2Id=productVirtual.Id);
        Test.stopTest();

        Account updatedAccount = [SELECT Id, Membership_Type__c FROM Account WHERE Id = :personAcc.Id];
        System.assertEquals(TLOrgConstants.MEMBERSHIP_TYPE_VIRTUAL, updatedAccount.Membership_Type__c, 'The membership type was not set on the account.');
    }

    @IsTest(SeeAllData=true)
    static void testFindAccountMembershipStatusAssetDelete() {
        Account acc = (Account) factory.createSObject(new Account(),true);
        Account personAcc = new Account(RecordTypeId=personAccRT, LastName='Test');
        insert personAcc;
        Product2 productPhysical = [SELECT Id, Name FROM Product2 WHERE Name IN :TLOrgConstants.PRODUCT_NAMES_PHYSICAL LIMIT 1];
        Product2 productVirtual = [SELECT Id, Name FROM Product2 WHERE Name IN :TLOrgConstants.PRODUCT_NAMES_VIRTUAL LIMIT 1];
        Asset membership1 = (Asset) factory.createSObject(new Asset(Member_Name__c=personAcc.Id,AccountId=acc.Id,Product2Id=productPhysical.Id),true);
        Asset membership2 = (Asset) factory.createSObject(new Asset(Member_Name__c=personAcc.Id,AccountId=acc.Id,Product2Id=productVirtual.Id),true);

        Account updatedAccount = [SELECT Id, Membership_Type__c FROM Account WHERE Id = :personAcc.Id];
        System.assertEquals(TLOrgConstants.MEMBERSHIP_TYPE_VIRTUAL, updatedAccount.Membership_Type__c, 'The membership type was not set on the account.');

        Test.startTest();
        delete membership2;
        updatedAccount = [SELECT Id, Membership_Type__c FROM Account WHERE Id = :personAcc.Id];
        System.assert(updatedAccount.Membership_Type__c == TLOrgConstants.MEMBERSHIP_TYPE_PHYSICAL,'Membership type was not updated after membership was deleted');

        delete membership1;
        updatedAccount = [SELECT Id, Membership_Type__c FROM Account WHERE Id = :personAcc.Id];
        System.assert(updatedAccount.Membership_Type__c == null,'Membership type was not nullified after the only membership was deleted');
        Test.stopTest();
    }

    @IsTest(SeeAllData=true)
    static void testFindAccountMembershipStatusAssetReparent() {
        Account acc1 = (Account) factory.createSObject(new Account(),true);
        Account acc2 = (Account) factory.createSObject(new Account(),true);
        Account personAcc1 = new Account(RecordTypeId=personAccRT, LastName='Test');
        insert personAcc1;
        Account personAcc2 = new Account(RecordTypeId=personAccRT, LastName='Test');
        insert personAcc2;
        Product2 productPhysical = [SELECT Id, Name FROM Product2 WHERE Name IN :TLOrgConstants.PRODUCT_NAMES_PHYSICAL LIMIT 1];
        Asset membership = (Asset) factory.createSObject(new Asset(Member_Name__c=personAcc1.Id,AccountId=acc1.Id,Product2Id=productPhysical.Id),true);

        Account updatedAccount = [SELECT Id, Membership_Type__c FROM Account WHERE Id = :personAcc1.Id];
        System.assertEquals(TLOrgConstants.MEMBERSHIP_TYPE_PHYSICAL, updatedAccount.Membership_Type__c, 'The membership type was not set on the account.');

        Test.startTest();
        membership.AccountId = personAcc2.Id;
        update membership;
        Test.stopTest();

        updatedAccount = [SELECT Id, Membership_Type__c FROM Account WHERE Id = :personAcc2.Id];
        System.assert(updatedAccount.Membership_Type__c == null,'Membership type was not updated after membership was reparented');
    }
}