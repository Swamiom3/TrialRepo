/************************************************************************************************************************************
Author      :  Salesforce
Description :  Test Class to cover BatchUpdateContractLinetemsDataMigration
Issue No    :  TWSPG-10771

-------------------------------------------------------------------------------------------------------------------------------------
VERSION		DATE      		AUTHOR            	DETAIL
	1       9-MAY-2022      Salesforce          Initial Developement
**************************************************************************************************************************************/
@isTest
public class BatchUpdateContractLinetemsTest {
    @TestSetup
    static void initData(){
        Test.startTest();

        Date startDate = Date.newInstance(2021, 12, 1);
        Date endDate = Date.newInstance(2021, 12, 31);
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueOf(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        String randomIntString = String.valueOf(Crypto.getRandomInteger());

        Profile p = [SELECT Id, Name FROM Profile WHERE (UserType = 'Standard' AND Name = 'System Administrator')][0];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Billing_Associate'];

        User user = new User(
            UserName = 'test@' + orgId + dateString + randomIntString + '.org',
            Email = 'test@' + orgId + dateString + randomIntString + '.org',
            FirstName = 'Mulesoft',
            LastName = 'Data Migration User',
            Alias = 'Mulesoft',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            UserPermissionsKnowledgeUser = true,
            Salesforce_Scheduler_User__c = true
        );        
    
        insert user;        

        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = user.Id;
        psa.PermissionSetId = ps.Id;
        insert psa;

        System.runAs(user){
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
    
            Pricebook2 priceBook = new Pricebook2();
            priceBook.IsActive = true;
            priceBook.Name = 'Test Price Book';
            priceBook.CurrencyISOCode = 'CAD';
            insert priceBook;

            Product2 product = new Product2();
            product.Name = 'Physical Membrership';
            product.ProductCode = CPQConstants.PRODUCTCODE_COMMIT;
            product.Family = 'Workspace';
            product.blng__BillingRule__c = billingRule.Id;
            product.blng__RevenueRecognitionRule__c = revRecRule.Id;
            product.blng__TaxRule__c = taxRule.Id;
            product.Product_UUID__c = UUIDHandler.generateVersion4();
            insert product;
    
            Product2 productConferenceRoom = new Product2();
            productConferenceRoom.Name = 'Conference Room Credit';
            productConferenceRoom.ProductCode = CPQConstants.PRODUCTCODE_COMMIT;
            productConferenceRoom.blng__BillingRule__c = billingRule.Id;
            productConferenceRoom.blng__RevenueRecognitionRule__c = revRecRule.Id;
            productConferenceRoom.blng__TaxRule__c = taxRule.Id;
            productConferenceRoom.Product_UUID__c = UUIDHandler.generateVersion4();
            insert productConferenceRoom;
    
            PricebookEntry standardPriceEntryCredit = new PricebookEntry();
            standardPriceEntryCredit.Product2Id = productConferenceRoom.Id;
            standardPriceEntryCredit.IsActive = true;
            standardPriceEntryCredit.UnitPrice = 100;
            standardPriceEntryCredit.Pricebook2Id = Test.getStandardPricebookId();
            standardPriceEntryCredit.CurrencyISOCode = 'CAD';
            standardPriceEntryCredit.UseStandardPrice = false;
            insert standardPriceEntryCredit;
            
            Order orderToCreate = new Order();
            orderToCreate.Building_Account_Id__c = buildingAccount.Id;
            orderToCreate.blng__BillingDayOfMonth__c = '1';
            orderToCreate.AccountId = testAccount.Id;
            orderToCreate.Building_Id__c = buildingsToInsert.get(0).Id;
            orderToCreate.Status = 'Draft';
            orderToCreate.Pricebook2Id = Test.getStandardPricebookId();
            orderToCreate.EffectiveDate = startDate;
            orderToCreate.CurrencyISOCode = 'CAD';    
            insert orderToCreate;
       
            OrderItem item = new OrderItem();
            item.OrderId = orderToCreate.Id;
            item.Building_Account_Id__c = buildingAccount.Id;
            item.Product2Id = product.Id;
            item.SBQQ__ChargeType__c = 'Recurring';
            item.PricebookEntryId = standardPriceEntryCredit.Id;
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
    
            List<blng__Invoice__c> invs = new List<blng__Invoice__c>();
            invs.add(new blng__Invoice__c(blng__Account__c = testAccount.Id,
                                        Building_Account_Id__c = buildingAccount.Id,
                                        blng__InvoiceStatus__c = 'Draft',
                                        Invoice_Type__c = 'Standard',
                                        CurrencyISOCode = 'CAD',
                                        blng__InvoiceDate__c = System.today(),
                                        Building_Id__c = buildingsToInsert.get(0).Id,
                                        blng__Order__c = orderToCreate.Id,
                                        blng__DueDate__c = System.today().addDays(-5)));
            Database.insert(invs);
    
            blng__InvoiceLine__c invoiceLineToAdd = new blng__InvoiceLine__c();
            invoiceLineToAdd.blng__Invoice__c = invs.get(0).Id;
            invoiceLineToAdd.blng__Product__c = product.Id;
            invoiceLineToAdd.blng__OrderProduct__c = item.Id;
            invoiceLineToAdd.blng__Quantity__c = 1;
            invoiceLineToAdd.blng__Subtotal__c = 30;
            invoiceLineToAdd.blng__TotalAmount__c = 30;
            invoiceLineToAdd.blng__TaxRule__c = taxRule.Id;
            invoiceLineToAdd.blng__BillingRule__c = billingRule.Id;
            invoiceLineToAdd.blng__ChargeType__c = 'Recurring';
            invoiceLineToAdd.CurrencyIsoCode = 'CAD';
            invoiceLineToAdd.blng__StartDate__c = System.today();
            invoiceLineToAdd.Building_Account_Id__c = buildingAccount.Id;
            invoiceLineToAdd.blng__LegalEntityReference__c = legalEntity.Id;
    
            insert invoiceLineToAdd;
    
            blng__Payment__c paymentToTest = new blng__Payment__c();
            paymentToTest.blng__Account__c = testAccount.Id;
            paymentToTest.blng__Amount__c = 100;
            paymentToTest.blng__PaymentDate__c = System.today();
            paymentToTest.blng__Status__c = 'Posted';
            paymentToTest.blng__Invoice__c = invs.get(0).Id;
            paymentToTest.CurrencyISOCode = 'CAD';
            insert paymentToTest;
    
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                Building_Id__c = buildingsToInsert.get(0).Id,
                Billing_Account__c = testAccount.Id,
                SBQQ__PricebookId__c = test.getStandardPricebookId(),
                SBQQ__Account__c = testAccount.Id,
                CurrencyIsoCode = 'CAD'
            );
            insert quote;
            
            SBQQ__QuoteLine__c quoteLine1 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Product__c = productConferenceRoom.Id,
                Building_Id__c = buildingsToInsert.get(0).Id,
                SBQQ__StartDate__c = System.today(),
                Commitment_Term__c = '1',
                SBQQ__Number__c = 1
            );
            insert quoteLine1;
    
            ServiceContract serviceContract = new ServiceContract(
                Name = 'Test Service Contract',
                AccountId = testAccount.Id,
                SBQQSC__Quote__c = quote.Id,
                SBQQSC__Order__c = orderToCreate.Id,
                StartDate = System.Now().date(),
                EndDate = System.Now().date() + 10,
                Pricebook2Id = Test.getStandardPricebookId(),
                SBQQSC__PreserveBundleStructureUponRenewals__c = true,
                CurrencyIsoCode = 'CAD'
            );
            insert serviceContract;
            
            ContractLineItem contractLineItem = new ContractLineItem(
                UnitPrice = 0,
                Quantity = 1,
                SBQQSC__Account__c = testAccount.Id,
                Allotment__c = 100,
                StartDate = System.Now().date(),
                EndDate = System.Now().date() + 10,
                ServiceContractId = serviceContract.Id,                
                SBQQSC__QuoteLine__c = quoteLine1.Id,
                PricebookEntryId = standardPriceEntryCredit.Id,
                SBQQSC__Product__c = productConferenceRoom.Id
            );
            insert contractLineItem;        
        }

        Test.stopTest();
    }
    @isTest
    static void runBatchTest(){               
        Test.startTest();
        BatchUpdateContractLinetemsDataMigration batchJob= new BatchUpdateContractLinetemsDataMigration();
        Id jobid= Database.executeBatch(batchJob,5);        
        Test.stopTest();        

        //List<ContractLineItem> contractItems = [SELECT Id, SBQQSC__ChargeType__c FROM ContractLineItem WHERE SBQQSC__ChargeType__c = 'Recurring' AND LastModifiedDate = TODAY];  
        //system.assertEquals(1, contractItems.size());  
    }
}