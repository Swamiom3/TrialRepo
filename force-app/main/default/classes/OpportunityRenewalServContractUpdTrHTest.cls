@isTest
private with sharing class OpportunityRenewalServContractUpdTrHTest {

    @testSetup
    static void createTestData() {
        
        Id billingAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Billing_Account').getRecordTypeId();
    	List<Account> accounts = new List<Account>();
        Account billingAccount = TestingUtility.createAccount('testAcc1', false);
        billingAccount.RecordTypeId = billingAccountRecordTypeId;
        accounts.add(billingAccount);
        Account businessAccount = TestingUtility.createAccount('testAcc2', false);
        accounts.add(businessAccount);
        insert accounts;

        Building__c building = new Building__c(
            Name = 'testbuild-001',
            Building_ID__c = 'test234',
            Time_Zone__c ='America/Denver',
            CurrencyIsoCode = 'CAD'
         );
        insert building;
        
        Inventory__c inventory = new Inventory__c(
            Building__c = building.Id,
            Name = 'testinv',
            List_Price__c = 100, 
            Type__c = 'Office',
            UUID__c = 'gfty789hgfd'
        );
        insert inventory;
        
		List<Contact> lstContact = (List<Contact>)TestingUtility.getRecords(new map<String,object>{'doInsert' => false,'objName' => 'Contact','numberOfRecords'=> '1',
            																		    'lstEmails'=>new List<String>{'testContact1@test1.com'}});
        lstContact[0].AccountId = businessAccount.Id;
        insert lstContact;
        
        List<Product2> products = new List<Product2>();
        for(integer i= 0;i<1;i++){
            Product2 product1 = new Product2();
            product1.Name = 'Month '+i;
            product1.IsActive = true;
            product1.ProductCode= string.valueof(i);
            product1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
            product1.Product_UUID__c = 'TestUUID' + i;
            products.add(product1); 
        }
        insert products;
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            currencyIsoCode = 'CAD'
        );
        update standardPricebook;
        
        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = products.get(0).Id,
            UnitPrice = 1,
            IsActive = true
        );
        insert pricebookEntry;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            Building_Id__c = building.Id,
            SBQQ__PricebookId__c = standardPricebook.Id,
            SBQQ__Account__c = businessAccount.Id,
            CurrencyIsoCode = 'CAD',
            Subscription_Type__c = 'Commitment Term',
            Billing_Account__c = billingAccount.Id,
            SBQQ__PrimaryContact__c = lstContact[0].Id
        );
        insert quote;
        
        SBQQ__QuoteLine__c quoteLine1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = products.get(0).Id,
            Building_Id__c = building.Id,
            Inventory_Id__c = inventory.Id,
            SBQQ__StartDate__c = System.today(),
            Commitment_Term__c = '1',
            SBQQ__Number__c = 1
        );
        insert quoteLine1;
        
        ServiceContract serviceContract = new ServiceContract(
            Name = 'Test Service Contract',
            AccountId = billingAccount.Id,
            SBQQSC__Quote__c = quote.Id,
            StartDate = System.Now().date() - 1,
            EndDate = System.Now().date() + 10,
            Pricebook2Id = standardPricebook.Id,
            SBQQSC__PreserveBundleStructureUponRenewals__c = true,
            Building_Id__c = building.Id,
            Capacity__c = 100,
            Term = 1
        );
        insert serviceContract;
        
        ContractLineItem contractLineItem = new ContractLineItem(
            UnitPrice = 1,
            Quantity = 1,
            SBQQSC__Account__c = billingAccount.Id,
            StartDate = System.Now().date() - 1,
            EndDate = System.Now().date() + 10,
            ServiceContractId = serviceContract.Id,
            SBQQSC__QuoteLine__c = quoteLine1.Id,
            PricebookEntryId = pricebookEntry.Id,
            Move_Out_Notice_Length__c = 1
        );
        insert contractLineItem;
    }

    @isTest
    static void testPositiveRenewalOpportunityUpdate(){
        Id userApiId = Id.valueOf(Settings.getValidationRuleRestrictionSalesforceId('Susie_Romero_API_User'));
        Id opptyRenewalRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Renewal').getRecordTypeId();
        Account accountRec = [SELECT Id,Name FROM Account WHERE Name = 'testAcc2' LIMIT 1];
        SBQQ__Quote__c quoteRec = [SELECT Id,Billing_Account__c,Building_Id__c FROM SBQQ__Quote__c LIMIT 1];
        ServiceContract serviceContractRec = [SELECT Id,Building_Id__c, Term, Capacity__c
                                               FROM ServiceContract LIMIT 1];

        Test.startTest();
        Map<String, Object> opportunityRecordsFieldMappings = new Map<String, Object>{'Interested_in_Number_of_Desks__c' => 2,'Type__c' => 'Wework','CloseDate' => system.now()+10};
        List<Opportunity> opportunityRecords = UtilOpportunity.getNewOpportunityWithFieldMapping(1, accountRec, opportunityRecordsFieldMappings, false);
        Opportunity createRenewalOpportunity = opportunityRecords.get(0);
        createRenewalOpportunity.SBQQSC__RenewedServiceContract__c = serviceContractRec.Id;
        insert createRenewalOpportunity;
        Test.stopTest();
        ServiceContract updatedServiceContractRec = [SELECT Id, Building_Id__c, SBQQSC__Quote__r.Billing_Account__c,Notice_Date__c,
                                                          Term, Capacity__c, SBQQSC__Quote__r.SBQQ__PrimaryContact__c
                                                      FROM ServiceContract LIMIT 1];
        Opportunity updatedRenewalOpportunityRec = [SELECT Id,Sales_Price__c, Interested_in_Number_of_Desks__c, Desired_Term_Length_in_months__c, Notice_Date__c, CloseDate, CreatedById, 
                                                        RecordTypeId, Billing_Account__c, Primary_Member__c, Building__c
                                                    FROM Opportunity
                                                    WHERE SBQQSC__RenewedServiceContract__c =: updatedServiceContractRec.Id LIMIT 1];
        System.assertEquals(updatedServiceContractRec.Building_Id__c, updatedRenewalOpportunityRec.Building__c, 'Building should be assigned correctly');
        System.assertEquals(updatedServiceContractRec.SBQQSC__Quote__r.Billing_Account__c, updatedRenewalOpportunityRec.Billing_Account__c, 'Billing Account should be assigned correctly');
        System.assertEquals(updatedServiceContractRec.Notice_Date__c, updatedRenewalOpportunityRec.CloseDate, 'CloseDate should be equal to Notice Date');
        System.assertEquals(updatedServiceContractRec.Capacity__c, updatedRenewalOpportunityRec.Interested_in_Number_of_Desks__c, 'Quantity Interested In should be assigned correctly');
        System.assertEquals(updatedServiceContractRec.Term, updatedRenewalOpportunityRec.Desired_Term_Length_in_months__c, 'Term should be assigned correctly');
        System.assertEquals(updatedServiceContractRec.SBQQSC__Quote__r.SBQQ__PrimaryContact__c, updatedRenewalOpportunityRec.Primary_Member__c, 'Primary Contact should be assigned correctly');
        System.assertEquals(userApiId, updatedRenewalOpportunityRec.CreatedById, 'Created By User should be assigned correctly');
        System.assertEquals(opptyRenewalRecTypeId, updatedRenewalOpportunityRec.RecordTypeId, 'Record Type Renewal should be assigned correctly');
    }

    @isTest
    static void testNegativeRenewalOpportunityUpdate(){
        Id userApiId = Id.valueOf(Settings.getValidationRuleRestrictionSalesforceId('Susie_Romero_API_User'));
        Id opptyRenewalRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Renewal').getRecordTypeId();
        Account accountRec = [SELECT Id,Name FROM Account WHERE Name = 'testAcc2' LIMIT 1];
        SBQQ__Quote__c quoteRec = [SELECT Id,Billing_Account__c,Building_Id__c FROM SBQQ__Quote__c LIMIT 1];
        ServiceContract serviceContractRec = [SELECT Id,Building_Id__c, Term, Capacity__c
                                               FROM ServiceContract LIMIT 1];

        Test.startTest();
        Map<String, Object> opportunityRecordsFieldMappings = new Map<String, Object>{'Interested_in_Number_of_Desks__c' => 2,'Type__c' => 'Wework','CloseDate' => system.now()+10};
        List<Opportunity> opportunityRecords = UtilOpportunity.getNewOpportunityWithFieldMapping(1, accountRec, opportunityRecordsFieldMappings, false);
        Opportunity createRenewalOpportunity = opportunityRecords.get(0);
        insert createRenewalOpportunity;
        Test.stopTest();
        ServiceContract updatedServiceContractRec = [SELECT Id, Building_Id__c, SBQQSC__Quote__r.Billing_Account__c,Notice_Date__c,
                                                          Term, Capacity__c, SBQQSC__Quote__r.SBQQ__PrimaryContact__c
                                                      FROM ServiceContract LIMIT 1];
        Opportunity updatedRenewalOpportunityRec = [SELECT Id,Sales_Price__c, Interested_in_Number_of_Desks__c, Desired_Term_Length_in_months__c, Notice_Date__c, CloseDate, CreatedById, 
                                                        RecordTypeId, Billing_Account__c, Primary_Member__c, Building__c
                                                    FROM Opportunity
                                                    WHERE Type__c = 'Wework' LIMIT 1];
        System.assertNotEquals(updatedServiceContractRec.Building_Id__c, updatedRenewalOpportunityRec.Building__c, 'Building should not be assigned');
        System.assertNotEquals(updatedServiceContractRec.SBQQSC__Quote__r.Billing_Account__c, updatedRenewalOpportunityRec.Billing_Account__c, 'Billing Account should not be assigned');
        System.assertNotEquals(updatedServiceContractRec.Notice_Date__c, updatedRenewalOpportunityRec.CloseDate, 'CloseDate should not be equal to Notice Date');
        System.assertNotEquals(updatedServiceContractRec.Capacity__c, updatedRenewalOpportunityRec.Interested_in_Number_of_Desks__c, 'Quantity Interested In should not be assigned');
        System.assertNotEquals(updatedServiceContractRec.Term, updatedRenewalOpportunityRec.Desired_Term_Length_in_months__c, 'Term should not be assigned');
        System.assertNotEquals(updatedServiceContractRec.SBQQSC__Quote__r.SBQQ__PrimaryContact__c, updatedRenewalOpportunityRec.Primary_Member__c, 'Primary Contact should not be assigned');
        System.assertNotEquals(userApiId, updatedRenewalOpportunityRec.CreatedById, 'Created By User should not be assigned');
        System.assertNotEquals(opptyRenewalRecTypeId, updatedRenewalOpportunityRec.RecordTypeId, 'Record Type Renewal should not be assigned');
    }
}