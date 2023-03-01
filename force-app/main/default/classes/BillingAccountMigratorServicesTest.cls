/************************************************************************************************************************************
    Author      : Urvi Tanna
    Description : This class contains Unit Tests methods of BillingAccountMigratorServices
    History     :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE            AUTHOR             DETAIL
    1           23 July 2019    Urvi Tanna         Initial Developement
    2           09 Nov  2021    Tejasvi Gujjula    Code Coverage Fix
    3           8 Dec, 2021     Pawel Biszczak     Fix test coverage
**************************************************************************************************************************************/
@isTest
public without sharing class BillingAccountMigratorServicesTest {

    private static final Id billingAccountRT = Schema.SObjectType.Account
                                                    .getRecordTypeInfosByDeveloperName()
                                                    .get(GlobalConstants.ACCOUNT_BILLING_ACCOUNT_RECORD_TYPE_DEV_NAME)
                                                    .getRecordTypeId();

    @TestSetup
    static void initData(){
        TestingUtility.getRecords(new Map<String, Object>{'objName' => 'User',
                                                          'numberOfRecords' => 2});

        Test.startTest();
        TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Lead',
                                                          'numberOfRecords' => 2});
        TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Contact',
                                                          'numberOfRecords' => 4,
                                                          'doInsert' => true});
        TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Account',
                                                          'numberOfRecords' => 6});
        TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Building__c',
                                                          'numberOfRecords' => 1});
        Test.stopTest();


        List<Account> billingAccounts = (List<Account>) TestingUtility.getRecords(
                new Map<String, Object>{
                        'objName' => 'billing_account__c',
                        'numberOfRecords' => 1
                });

        List<Opportunity> opportunities = (List<Opportunity>) TestingUtility.getRecords(
                new Map<String, Object>{
                        'objName' => 'Opportunity',
                        'numberOfRecords' => 1,
                        'doInsert' => false,
                        'mapFieldValues' =>
                                new Map<String, List<Object>>{
                                        'Contract_Stage__c' =>
                                                new List<Object>{
                                                        'Contract Sent'
                                                },
                                        'Billing_Account__c' =>
                                                new List<Object>{
                                                        billingAccounts[0].Id
                                                }
                                }
                });
        opportunities.addAll((List<Opportunity>) TestingUtility.getRecords(
                new Map<String, Object>{
                        'objName' => 'Opportunity',
                        'numberOfRecords' => 1,
                        'doInsert' => false,
                        'mapFieldValues' => new Map<String, List<Object>>{
                                'Contract_Stage__c' =>
                                        new List<Object>{
                                                'Contract Sent'
                                        }
                        }
                }));
        insert opportunities;
    }


    @isTest
    public static void migrateBillingAccountsTest(){
        Id billingAccountId = [ SELECT Id 
                                FROM Account
                                WHERE RecordTypeId =: billingAccountRT
                                LIMIT 1 ].Id;
        Opportunity opportunityRecord = [ SELECT AccountId 
                                          FROM Opportunity
                                          WHERE Billing_Account__c =: billingAccountId][0];
        List<Account> accounts = [ SELECT Id 
                                   FROM Account
                                   WHERE Id !=: opportunityRecord.AccountId
                                   LIMIT 2 ];
        Id firstAccountId = accounts[1].Id;

        Test.startTest();
        LightningComponentController.migrateBillingAccounts(firstAccountId, new List<Id>{ billingAccountId });
        Test.stopTest();
        
        Account resultBillingAccount = [ SELECT Id, ParentId 
                                         FROM Account
                                         WHERE Id = :billingAccountId ][0];
        System.assertEquals(firstAccountId, resultBillingAccount.ParentId, 'The Parent account of selected billing account should be updated to new account');
        
        List<Opportunity> opportunitiesAfterBillingAccountChange = [ SELECT AccountId
                                                                     FROM Opportunity
                                                                     WHERE Billing_Account__c = :resultBillingAccount.Id ];
        for(Opportunity resultOpp : opportunitiesAfterBillingAccountChange) {
            System.assertEquals(firstAccountId,resultOpp.AccountId, 'The Parent account of selected billing account related opportunities should be updated to new account');
        }
    }

    @isTest
    public static void billingAccountMigratorQueryTests(){
        List<String> fieldsApiNames = new List<String>{'Name', 'Parent.Name', 'Owner.Name', 'Account_Type__c'};
        Map<String, String> labelReplacementsMap = new Map<String, String>{'Parent.Name'=>'Parent Name', 'Owner.Name'=>'Owner Name'};
        Map<String, String> linkedFieldsMap = new Map<String, String>{'Name'=>'Id', 'Parent.Name'=>'ParentId', 'Owner.Name'=>'Owner.Id'};
        Map<String, Map<String,String>> fieldsToLabelsAndLinks = BillingAccountMigratorServices.getFieldLabels('Account', fieldsApiNames, labelReplacementsMap, linkedFieldsMap);
        for(String key : fieldsToLabelsAndLinks.keySet()){
            System.assertEquals(true, fieldsApiNames.contains(key), 'returned header label object contains api names not provided in the fieldApiNames param');
            if(labelReplacementsMap.get(key) != null) {
                System.assertEquals(true, fieldsToLabelsAndLinks.get(key).get('label') == labelReplacementsMap.get(key), 'returned header label object has inconsistent label replacement values\nlabel in param: ' + labelReplacementsMap.get(key) + '\nlabel returned: ' + fieldsToLabelsAndLinks.get(key).get('label'));
            }
            if(linkedFieldsMap.get(key) != null) {
                System.assertEquals(true, fieldsToLabelsAndLinks.get(key).get('link') == linkedFieldsMap.get(key), 'returned header label object has inconsistent link values\nlabel in param: ' + linkedFieldsMap.get(key) + '\nlink field returned: ' + fieldsToLabelsAndLinks.get(key).get('link'));
            }
        }
        List<Account> accounts = [SELECT Id, Name, ParentId, Owner.Id, Owner.Name, Account_Type__c FROM Account LIMIT 3];
        
        accounts[0].Name = 'Billing Account Migrator Test';
        accounts[0].ParentId = accounts[1].Id;
        accounts[0].Account_Type__c = 'Org';
        accounts[1].Account_Type__c = 'Sales';
        accounts[1].Nickname__c = 'Test Sales Account';
        accounts[1].ParentId = accounts[2].Id;
        accounts[2].Account_Type__c = 'Org';
        
        Test.startTest();
        update accounts;
        Test.stopTest();

        for(Account acc : (List<Account>) LightningComponentController.getRelatedRecords(new Map<String, String>{'Id'=>accounts[0].Id}, fieldsToLabelsAndLinks, 'Account')){
            System.assertEquals(acc.Name, accounts[0].Name, 'returned account name is different than account intended');
            System.assertEquals(acc.ParentId, accounts[0].ParentId, 'returned account parentId is different than account intended');
            System.assertEquals(acc.Owner.Id, accounts[0].Owner.Id, 'returned owner id is different than account intended');
        }
        for(Account acc : (List<Account>) LightningComponentController.getTransferAccounts('Billing Account Migrator', new List<String>{'Org'}, fieldsToLabelsAndLinks)){
            System.assertEquals(acc.Name, accounts[0].Name, 'returned account name is different than account intended');
            System.assertEquals(acc.ParentId, accounts[0].ParentId, 'returned account parentId is different than account intended');
            System.assertEquals(acc.Owner.Id, accounts[0].Owner.Id, 'returned owner id is different than account intended');
            System.assertEquals(acc.Account_Type__c, 'Org', 'returned account type is inconsistent with account type filter');
        }
    }
}