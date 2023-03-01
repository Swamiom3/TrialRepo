/************************************************************************************************************************************
Author      :  Salesforce
Description :  BatchUpdateOrderItemsDataMigration batch apex test class
Issue No    :  TWSPG-10733

-------------------------------------------------------------------------------------------------------------------------------------
VERSION      DATE           AUTHOR              DETAIL
   1      9-MAY-2022      Salesforce       Initial Developement
**************************************************************************************************************************************/
@isTest
private with sharing class BatchUpdateOrderItemsDataMigrationTest {
    
    @testSetup
    static void createTestData() {
        Test.startTest();
        
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueOf(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        String randomIntString = String.valueOf(Crypto.getRandomInteger());

        Profile profile = [SELECT Id, Name FROM Profile WHERE (UserType = 'Standard' AND Name = 'System Administrator') LIMIT 1];
        PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'Billing_Associate' LIMIT 1];

        User testUser = new User(
            UserName = 'test@' + orgId + dateString + randomIntString + '.org',
            Email = 'test@' + orgId + dateString + randomIntString + '.org',
            FirstName = 'Mulesoft',
            LastName = 'Data Migration User',
            Alias = 'Mulesoft',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US',
            ProfileId = profile.Id,
            UserPermissionsKnowledgeUser = true,
            Salesforce_Scheduler_User__c = true
        );        
        insert testUser;        

        PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment();
        permissionSetAssignment.AssigneeId = testUser.Id;
        permissionSetAssignment.PermissionSetId = permissionSet.Id;
        insert permissionSetAssignment;
        
        System.runAs(testUser){
            Date startDate = System.today().AddDays(1);
            Date endDate = System.today().AddDays(15);
            
            Account testAccount = new Account();
            testAccount.Name = 'Test_Account';
            testAccount.UUId__c = '454545';
            insert testAccount;
            
            blng__LegalEntity__c legalEntity = new blng__LegalEntity__c();
            legalEntity.Name = 'Test Legal Entity';
            legalEntity.CurrencyIsoCode = 'CAD';
            insert legalEntity;
            
            List<Building__c> buildingsToInsert = new List<Building__c>();
            buildingsToInsert.add(UtilBuilding.createBuilding(null, 'test@test.com', null, true));
            buildingsToInsert.get(0).WeCode__c = 'ABC';
            buildingsToInsert.get(0).UUID__c = 'abcdefg';
            buildingsToInsert.get(0).Legal_Entity_Id__c = legalEntity.Id;
            buildingsToInsert.get(0).currencyIsoCode = 'CAD';
            upsert buildingsToInsert;
            
            Building_Account__c buildingAccount = new Building_Account__c();
            buildingAccount.Billing_Account_Id__c = testAccount.Id;
            buildingAccount.Building_Id__c = buildingsToInsert.get(0).Id;
            insert buildingAccount;
            
            Pricebook2 priceBook = new Pricebook2();
            priceBook.IsActive = true;
            priceBook.Name = 'Test Price Book';
            priceBook.CurrencyISOCode = 'CAD';
            insert priceBook;
            
            blng__BillingRule__c billingRule = new blng__BillingRule__c();
            billingRule.Name = 'Test Billing Rule';
            billingRule.blng__InitialBillingTrigger__c = 'Order Product Activation Date';
            billingRule.blng__PartialPeriodTreatment__c = 'Separate';
            billingRule.blng__PeriodTreatmentForBTDO__c = 'Exclude Billing Day of Month';
            billingRule.blng__GenerateInvoices__c = 'Yes';
            insert billingRule;
            
            blng__RevenueRecognitionRule__c revRecRule = new blng__RevenueRecognitionRule__c();
            revRecRule.blng__Active__c = true;
            revRecRule.Name = 'TestRevRec';
            revRecRule.blng__CreateRevenueSchedule__c = 'No';
            insert revRecRule;
            
            blng__TaxRule__c taxRule = new blng__TaxRule__c();
            taxRule.blng__Active__c = true;
            taxRule.Name = 'Test Tax Rule';
            taxRule.blng__TaxableYesNo__c = 'No';
            insert taxRule;
            
            Product2 product = new Product2();
            product.Name = 'Physical Membrership';
            product.ProductCode = CPQConstants.PRODUCTCODE_COMMIT;
            product.Family = 'Workspace';
            product.SBQQ__ChargeType__c = 'Recurring';
            product.SBQQ__BillingFrequency__c = 'Monthly';
            product.SBQQ__BillingType__c = 'Advance';
            product.blng__BillingRule__c = billingRule.Id;
            product.blng__RevenueRecognitionRule__c = revRecRule.Id;
            product.blng__TaxRule__c = taxRule.Id;
            product.Product_UUID__c = UUIDHandler.generateVersion4();
            insert product;
            
            Order orderToCreate = new Order();
            orderToCreate.Building_Account_Id__c = buildingAccount.Id;
            orderToCreate.blng__BillingDayOfMonth__c = '1';
            orderToCreate.AccountId = testAccount.Id;
            orderToCreate.Building_Id__c = buildingsToInsert.get(0).Id;
            orderToCreate.Status = 'Draft';
            orderToCreate.Pricebook2Id = priceBook.Id;
            orderToCreate.EffectiveDate = startDate;
            orderToCreate.CurrencyISOCode = 'CAD';
            insert orderToCreate;
            
            PricebookEntry standardPriceEntry = new PricebookEntry();
            standardPriceEntry.Product2Id = product.Id;
            standardPriceEntry.IsActive = true;
            standardPriceEntry.UnitPrice = 30;
            standardPriceEntry.Pricebook2Id = test.getStandardPricebookId();
            standardPriceEntry.CurrencyISOCode = 'CAD';
            insert standardPriceEntry;
            
            PricebookEntry customPriceEntry = new PricebookEntry();
            customPriceEntry.IsActive = true;
            customPriceEntry.UnitPrice = 30;
            customPriceEntry.Product2Id = product.Id;
            customPriceEntry.Pricebook2Id = priceBook.Id;
            customPriceEntry.CurrencyISOCode = 'CAD';
            insert customPriceEntry;
            
            OrderItem item = new OrderItem();
            item.OrderId = orderToCreate.Id;
            item.Building_Account_Id__c = buildingAccount.Id;
            item.Product2Id = product.Id;
            item.SBQQ__ChargeType__c = 'Recurring';
            item.PricebookEntryId = customPriceEntry.Id;
            item.UnitPrice = 30;
            item.blng__BillableUnitPrice__c = 30;
            item.SBQQ__Activated__c = false;
            item.SBQQ__SubscriptionTerm__c = 1;
            item.Quantity = 1;
            item.ServiceDate = startDate;
            item.EndDate = endDate;
            item.SBQQ__BillingFrequency__c = 'Monthly';
            item.SBQQ__BillingType__c = 'Advance';
            item.SBQQ__ProrateMultiplier__c = 1;
            insert item;
        }
        
        Test.stopTest();
    }

    @isTest
    static void testBatchUpdateOrderItemsDataMigrationExecute(){
        BatchUpdateOrderItemsDataMigration batchUpdateOrderItems = new BatchUpdateOrderItemsDataMigration();
        Id batchJobId;
        Test.startTest();
        batchJobId = Database.executeBatch(batchUpdateOrderItems, 10);
        Test.stopTest();
        AsyncApexJob resultApexJob = [SELECT Id, Status FROM AsyncApexJob WHERE Id =: batchJobId];
        System.assertEquals('Completed', resultApexJob.Status, 'BatchUpdateOrderItemsDataMigration apex job is completed');
        OrderItem resultOrderItems = [SELECT Id, Building_Account_Id__c, Order.Building_Account_Id__c, SBQQ__BillingType__c, Product2.SBQQ__BillingType__c,
               						      SBQQ__BillingFrequency__c, Product2.SBQQ__BillingFrequency__c, SBQQ__ChargeType__c, Product2.SBQQ__ChargeType__c
                					  FROM OrderItem WHERE CreatedBy.Name = 'Mulesoft Data Migration User' LIMIT 1];
        System.assertEquals(resultOrderItems.Building_Account_Id__c, resultOrderItems.Order.Building_Account_Id__c, 'Updated OrderItem Building_Account_Id__c field successfully');
        System.assertEquals(resultOrderItems.SBQQ__BillingType__c, resultOrderItems.Product2.SBQQ__BillingType__c, 'Updated OrderItem SBQQ__BillingType__c field successfully');
        System.assertEquals(resultOrderItems.SBQQ__BillingFrequency__c, resultOrderItems.Product2.SBQQ__BillingFrequency__c, 'Updated OrderItem SBQQ__BillingFrequency__c field successfully');
        System.assertEquals(resultOrderItems.SBQQ__ChargeType__c, resultOrderItems.Product2.SBQQ__ChargeType__c, 'Updated OrderItem SBQQ__ChargeType__c field successfully');
    }
}