@isTest
public class ContractLineItemSelectorTest {
    @isTest
    static void getContractItemsPositive(){
        Product2 product = new Product2( Name = 'Physical Membership', IsActive = true, ProductCode= '1',Product_UUID__c = UUIDHandler.generateVersion4());
        insert product;
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product.Id,
            UnitPrice = 1020,
            IsActive = true
        );        
        insert pricebookEntry;
        
        Inventory__c addOninventory = new Inventory__c();
        addOninventory.Name = 'testAddonInv';
        addOninventory.List_Price__c = 100;
        addOninventory.Type__c = 'Office';
        addOninventory.UUID__c = '12345';
        insert addOninventory;
        
        ServiceContract serviceContract = new ServiceContract();
        serviceContract.Name ='Test';
        serviceContract.Pricebook2Id = standardPricebook.Id;
        insert serviceContract;
        
        ContractLineItem item = new ContractLineItem();
        item.ServiceContractId = serviceContract.Id;
        item.Inventory_Id__c = addOninventory.Id;
        item.Quantity =1;
        item.PricebookEntryId = pricebookEntry.Id;
        item.UnitPrice=100;
        insert item;
        ContractLineItemSelector contractItemSelector = new ContractLineItemSelector();
        List<ContractLineItem> contractItems=contractItemSelector.getContractItemsByServiceContractId(new Set<Id>{item.Id});
        System.assert(contractItems != null, 'Contract Items not retrieved');
    }
    @isTest
    static void getContractItemsNegative(){
        ContractLineItemSelector contractItemSelector = new ContractLineItemSelector();
        List<ContractLineItem> contractItems=contractItemSelector.getContractItemsByServiceContractId(new Set<Id>());
        System.assert(contractItems==null, 'Contract Items retrieved');
    }
}