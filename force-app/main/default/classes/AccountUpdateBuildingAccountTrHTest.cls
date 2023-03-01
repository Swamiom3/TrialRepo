/************************************************************************************************************************************
    Author      :   Rohit Nimase	
    Description :   This class is used to Map Legal Entity Name and Address from Billing Account to Building Account.				 	
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION		DATE				AUTHOR				ISSUE NO		DETAIL
    1           10 May 2022      	Rohit Nimase	    TWSPG-10451     Initial Developement 
**************************************************************************************************************************************/
@isTest
public class AccountUpdateBuildingAccountTrHTest {

    @testSetup
    static void setUpData(){
        Test.startTest();
        Profile adminProfile = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'];
        User testUserAdmin = new User(Alias = 'testU', Email='testUserAdmin@example.com', 
                                 EmailEncodingKey='UTF-8', LastName='User', LanguageLocaleKey='en_US', 
                                 LocaleSidKey='en_US', ProfileId = adminProfile.Id, IsActive = true,
                                 TimeZoneSidKey='America/Los_Angeles', UserName='testUseradmin@example.com.wework.service');
        insert testUserAdmin;
        
        list<PermissionSet> permissionsToBeAssigned = [SELECT Id, Label FROM PermissionSet WHERE Label = 'Account - Billing Account Legal Company Name Change' OR 
                                                      Label = 'Account - Billing Account Billing Address Change'];
        CustomPermission validationBypassUserCustPermission = [SELECT Id FROM CustomPermission WHERE DeveloperName = 'Validation_Bypass_User_Integration'];        
        PermissionSetAssignment psa1 = new PermissionSetAssignment(PermissionSetId = permissionsToBeAssigned[0].id , AssigneeId = testUserAdmin.Id);
        PermissionSetAssignment psa2 = new PermissionSetAssignment(PermissionSetId = permissionsToBeAssigned[1].id , AssigneeId = testUserAdmin.Id);
        List<PermissionSetAssignment> permissionSetinsertList = new List<PermissionSetAssignment>{psa1, psa2};
        insert permissionSetInsertList;
        Test.stopTest();
    }

    
    @isTest
    static void updateBuildingAccountsTest(){
        User testUserAdmin = [SELECT Id, Name FROM User WHERE Email = 'testUserAdmin@example.com'];
        
        System.runAs(testUserAdmin){
            Id billingAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Billing_Account').getRecordTypeId();
            
            Account billingAccount = new Account();
            billingAccount.Name = 'Test_Billing_Account';
            billingAccount.UUId__c = '454545';
            billingAccount.Legal_Name__c = 'Legal_test';
            billingAccount.BillingStreet = 'Baner1,Maharashtra';
            billingAccount.BillingCity = 'Pune';
            billingAccount.BillingCountry = 'India';
            billingAccount.BillingLatitude = 18.5596581;
            billingAccount.BillingLongitude = 73.7799374;
            billingAccount.BillingState = 'Maharashtra';
            billingAccount.RecordTypeId = billingAccountRecordTypeId;
            insert billingAccount;
            
            blng__LegalEntity__c legalEntity = new blng__LegalEntity__c();
            legalEntity.Name = 'Test Legal Entity 1';
            legalEntity.CurrencyIsoCode = 'CAD';
            insert legalEntity;
            
            List<Building__c> buildingsToInsert = new List<Building__c>();
            buildingsToInsert.add(UtilBuilding.createBuilding(null, 'test@test.com', null, true));
            buildingsToInsert[0].WeCode__c = 'ABC';
            buildingsToInsert[0].UUID__c = 'abcdefg';
            buildingsToInsert[0].Legal_Entity_Id__c = legalEntity.Id;
            buildingsToInsert[0].currencyIsoCode = 'CAD';
            upsert buildingsToInsert;
            
            Building_Account__c buildingAccount = new Building_Account__c();
            buildingAccount.Billing_Account_Id__c = billingAccount.Id;
            buildingAccount.Building_Id__c = buildingsToInsert[0].Id;
            insert buildingAccount;
            
            Building_Account__c buildingAccountInserted = [SELECT Id, Legal_Entity_Name__c, Billing_City__c, Billing_Street__c FROM Building_Account__c WHERE Id =: buildingAccount.Id ];
            
            Account billingAccountToUpdate = [SELECT Id, Legal_Name__c, BillingAddress FROM Account LIMIT 1];
            billingAccountToUpdate.Legal_Name__c = 'Legal_test2';
            billingAccountToUpdate.BillingStreet ='Baner2';
            billingAccountToUpdate.BillingCity = 'Mumbai';
            billingAccountToUpdate.BillingCountry = 'India';
            billingAccountToUpdate.BillingLatitude = 28.5596581;
            billingAccountToUpdate.BillingLongitude = 77.7799374;
            billingAccountToUpdate.BillingState = 'Maharashtra';
            update billingAccountToUpdate;
        }
        
        Building_Account__c buildingAccountUpdated = [SELECT Id, Legal_Entity_Name__c, Billing_City__c, Billing_Street__c FROM Building_Account__c LIMIT 1];
        System.assertEquals('Legal_test2', buildingAccountUpdated.Legal_Entity_Name__c, 'Legal company name not updated');
        System.assertEquals('Mumbai', buildingAccountUpdated.Billing_City__c, 'Billing City not updated');
    }
}