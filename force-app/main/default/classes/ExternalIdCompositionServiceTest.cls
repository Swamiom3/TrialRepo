/*************************************************************************************************************************************
 Author      :   Oleg Krasko
 Description :   It covers ExternalIdCompositionService
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               02/10/2022      Oleg Krasko         Initial Deployment
 **************************************************************************************************************************************/
@isTest
private class ExternalIdCompositionServiceTest{
    @isTest
    static void testExternalIdCompositionService_positive(){
        Account account = new Account(
            Phone = '1231212',
            BillingCity = 'Test Billing City',
            BillingState = 'Test Billing State',
            BillingCountry = 'Test Billing Country'
        );
        Account anohtherAccount = account.clone();
        anohtherAccount.BillingCity = 'Different Billing City';
        Account accountAlgorithmName = account.clone();
        Account accountEncodingMethod = account.clone();
        List<Account> accounts = new List<Account>{account, anohtherAccount, accountAlgorithmName, accountEncodingMethod};
        
        Test.startTest();
        new ExternalIdCompositionService(
            new List<Account>{account, anohtherAccount}, 
            new Set<String>{'Phone', 'BillingCity', 'BillingState', 'BillingCountry'},
            'Name'
        ).assignExternalID();
        new ExternalIdCompositionService(
            new List<Account>{accountAlgorithmName}, 
            new Set<String>{'Phone', 'BillingCity', 'BillingState', 'BillingCountry'},
            'Name',
            ExternalIdCompositionService.AlgorithmName.MD5
        ).assignExternalID();
        new ExternalIdCompositionService(
            new List<Account>{accountEncodingMethod}, 
            new Set<String>{'Phone', 'BillingCity', 'BillingState', 'BillingCountry'},
            'Name',
            ExternalIdCompositionService.AlgorithmName.MD5,
            ExternalIdCompositionService.EncodingMethod.CONVERT_TO_HEX
        ).assignExternalID();
        Test.stopTest();

        for (Account acc : accounts) {
            System.assert(acc.Name != null, 'Name field should be populated');
        }
        
    }

    @isTest
    static void testMultipleInserts_positive(){
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        olis.add(new OpportunityLineItem());
        olis.add(new OpportunityLineItem(Quantity=10));

        Test.startTest();
        new ExternalIdCompositionService(
            olis,
            new Set<String>{'Name'},
            'Description'
        ).assignExternalID();
        Test.stopTest();

        for (OpportunityLineItem oli : olis) {
            System.assertNotEquals(null, oli.Description, 'Description field should be populated');
        }
        System.assertNotEquals(olis[0].Description, olis[1].Description, 'Description field should be unique');
    }

    @isTest
    static void testExternalIdCompositionService_negative(){
        List<Account> accounts = new List<Account>();
        accounts.add(new Account());
        accounts.add(new Account(Phone='12312323'));
        Account account = new Account(Phone='12312323', Name = 'test name');

        Test.startTest();
        new ExternalIdCompositionService(
            new List<Account>{accounts[0]},
            new Set<String>{'Phone'},
            'Name'
        ).assignExternalID();
        new ExternalIdCompositionService(
            new List<Account>{accounts[1]}, 
            new Set<String>(),
            'Name'
        ).assignExternalID();
        new ExternalIdCompositionService(
            new List<Account>{accounts[1]}, 
            null,
            'Name'
        ).assignExternalID();
        new ExternalIdCompositionService(
            new List<Account>{accounts[1]}, 
            new Set<String>{'Phone'},
            null
        ).assignExternalID();
        new ExternalIdCompositionService(
            new List<Account>{accounts[1]},
            new Set<String>{'Phone'},
            'Test'
        ).assignExternalID();
        new ExternalIdCompositionService(
            new List<Account>{account},
            new Set<String>{'Phone'},
            'Name'
        ).assignExternalID();
        new ExternalIdCompositionService(
            new List<Account>(),
            new Set<String>{'Phone'},
            'Name'
        ).assignExternalID();
        new ExternalIdCompositionService(
            null,
            new Set<String>{'Phone'},
            'Name'
        ).assignExternalID();
        Test.stopTest();


        System.assert(accounts[0].Name != null, 'Name field should not be blank');
        System.assert(accounts[1].Name == null, 'Name field should not be blank for emty list of fields');
        System.assertEquals('test name', account.Name, 'Name field should remain the same');
    }
}