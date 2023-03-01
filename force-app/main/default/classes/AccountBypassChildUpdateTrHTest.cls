@isTest
public class AccountBypassChildUpdateTrHTest {
    private static final Map<String, RecordTypeInfo> ALLOWED_ACC_REC_TYPES_BY_NAME = Schema.SObjectType.Account.getRecordTypeInfosByName();
    private static final String WEWORK_STD_USER_PROFILE = 'WeWork Sales User';
    private static final Map<String, RecordTypeInfo> ALLOWED_OPP_REC_TYPES_BY_NAME = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
    private static final Map<String, RecordTypeInfo> ALLOWED_CON_REC_TYPES_BY_NAME = Schema.SObjectType.Contact.getRecordTypeInfosByName();
    private final static Set<String> RESTRICTED_HOLD_APPROVAL_STATUS = new Set<String> {'Released', 'Expired'};
        
        @testSetup 
        private static void setupTestData(){
            User growthOpsUser = UtilUser.createUser([SELECT Id FROM Profile WHERE Name = :WEWORK_STD_USER_PROFILE].Id, true);
            System.assert(growthOpsUser != null, 'Growth ops User should be present');
            List<Account> parentOrgAccounts = new List<Account>();
            parentOrgAccounts.add(TestingUtility.createAccount(new Map<String,Object>{'Name' => 'Parent Account 1', 'UUID__c' => 'parent-UUID-001', 'Account_Type__c' => 'Org'}, false));
            parentOrgAccounts.add(TestingUtility.createAccount(new Map<String,Object>{'Name' => 'Parent Account 2', 'UUID__c' => 'parent-UUID-002', 'Account_Type__c' => 'Org'}, false));
            insert parentOrgAccounts;
            List<Building__c> buildings =  (List<Building__c>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Building__c', 'numberOfRecords' => 2});
            List<sObject> childAccContactRecords = new List<sObject>();
            childAccContactRecords.add(TestingUtility.createAccount(new Map<String, Object>{'Name' => 'childAccount1',
                'ParentId' => parentOrgAccounts[0].Id, 
                'Account_Type__c' => 'Sales',
                'Nickname__c' => 'SalesAcc1'}, false));
            childAccContactRecords.add(TestingUtility.createAccount(new Map<String, Object>{'Name' => 'childAccount2', 
                'ParentId' => parentOrgAccounts[1].Id,
                'Account_Type__c' => 'Sales',
                'Nickname__c' => 'SalesAcc2'}, false));
            childAccContactRecords.add(TestingUtility.createContact(new Map<String, Object>{
                'UUID__c' => 'cont-01-uuid',
                'Firstname' => 'John1',
                'LastName' => 'Smith1',
                'Email' => 'john.smith1@example.com', 
                'AccountId' => parentOrgAccounts[0].Id
            },false));
            childAccContactRecords.add(TestingUtility.createContact(new Map<String, Object>{
                'UUID__c' => 'cont-02-uuid',
                'Firstname' => 'John2',
                'LastName' => 'Smith2', 
                'Email' => 'john.smith2@example.com', 
                'AccountId' => parentOrgAccounts[0].Id
            },false));
            childAccContactRecords.add(TestingUtility.createContact(new Map<String, Object>{
                'UUID__c' => 'cont-03-uuid',
                'Firstname' => 'John3',
                'LastName' => 'Smith3',
                'Email' => 'john.smith3@example.com', 
                'AccountId' => parentOrgAccounts[0].Id
            },false));
            childAccContactRecords.add(TestingUtility.createContact(new Map<String, Object>{
                'UUID__c' => 'cont-04-uuid',
                'Firstname' => 'John4',
                'LastName' => 'Smith4',
                'Email' => 'john.smith4@example.com',
                'AccountId' => parentOrgAccounts[0].Id
            },false));
            childAccContactRecords.add(TestingUtility.createContact(new Map<String, Object>{
                'UUID__c' => 'cont-05-uuid',
                'FirstName' => 'BrokerContact First Name',
                'LastName' => 'BrokerContact', 
                'Email' => 'testbrokercontact@example.com',
                'AccountId' => parentOrgAccounts[1].Id, 
                'Type__c' => 'Broker'
            }, false));
            insert childAccContactRecords;
            List<Opportunity> childOppRecords = new List<Opportunity>();
            childOppRecords.add(TestingUtility.createOpportunity(new Map<String,Object>{'name' => 'Test Opportunity 0', 
                'Primary_Member__c' => childAccContactRecords[2].Id, 
                'AccountID' => parentOrgAccounts[0].Id, 
                'StageName' => 'Selling', 
                'CloseDate' => System.today()}, false));
            childOppRecords.add(TestingUtility.createOpportunity(new Map<String,Object>{'name' => 'Test Opportunity 1',
                'Primary_Member__c' => childAccContactRecords[3].Id, 
                'AccountID' => parentOrgAccounts[0].Id, 
                'StageName' => 'Selling', 
                'CloseDate' => System.today()}, false));
            childOppRecords.add(TestingUtility.createOpportunity(new Map<String,Object>{'name' => 'Test Opportunity 2', 
                'Primary_Member__c' => childAccContactRecords[2].Id,
                'StageName' => 'Selling',
                'AccountId'=> parentOrgAccounts[1].Id}, false));
            insert childOppRecords;
            List<OpportunityTeamMember> oppTeamMembersToInsert = new List<OpportunityTeamMember>();
            for(Opportunity oppRec : childOppRecords){
                oppTeamMembersToInsert.add(new OpportunityTeamMember(OpportunityId = oppRec.Id, userId = UserInfo.getUserId(), TeamMemberRole = 'Opp: Originating Rep'));
                oppTeamMembersToInsert.add(new OpportunityTeamMember(OpportunityId = oppRec.Id, userId = growthOpsUser.Id, TeamMemberRole = 'Opp: Originating Rep'));
            }
            insert oppTeamMembersToInsert;
        }
    
    @isTest
    private static void verifyAccountChildRecordsUpdateOnOwnerChange(){
        User growthOpsUser = [SELECT Id FROM User WHERE Profile.Name = :WEWORK_STD_USER_PROFILE AND isActive = true LIMIT 1];
        Set<String> parentAccUUIDs = new Set<String>{'parent-UUID-001', 'parent-UUID-002'};
        Id accBillingAccountTypeId = ALLOWED_ACC_REC_TYPES_BY_NAME.get('Billing Account').getRecordTypeId();
        Id accBuinessAccountRecTypeId = ALLOWED_ACC_REC_TYPES_BY_NAME.get('Business Account').getRecordTypeId();
        List<Account> accountsToUpdateRecTypeOwner = new List<Account>();
        Test.startTest();        
        List<Account> accounts = getAccountsWithChildRecords(parentAccUUIDs);
        for(Account accRec : accounts){ 
            verifyAssertionBeforeUpdate(accRec, accBuinessAccountRecTypeId);
            accountsToUpdateRecTypeOwner.add(new Account(Id = accRec.Id, RecordTypeId = accBuinessAccountRecTypeId, OwnerId = growthOpsUser.Id));
        }
        MetadataDrivenTriggerHandler.clearLoopCount('AccountStoreOpportunityTeamMembersTrH');        
        if(!accountsToUpdateRecTypeOwner.isEmpty()){
            update accountsToUpdateRecTypeOwner;
        }
        Test.stopTest();
        accounts = getAccountsWithChildRecords(parentAccUUIDs);
        Id oppMidMarketRecTypeId = ALLOWED_OPP_REC_TYPES_BY_NAME.get('New Business').getRecordTypeId();
        Id conMidMarketRecTypeId = ALLOWED_CON_REC_TYPES_BY_NAME.get('Contact').getRecordTypeId();
        for(Account accRec : accounts){            
            System.assert(accRec.RecordTypeId == accBuinessAccountRecTypeId, 'Account recordType should be Business Account');
            System.assert(accRec.OwnerId == growthOpsUser.Id);
            verifyChildrecordsCount(accRec);
            for(Contact conRec : accRec.Contacts){    
                System.assert(conRec.RecordTypeId == conMidMarketRecTypeId, 'Contact recordType should be Contact');
            }
            for(Opportunity oppRec : accRec.Opportunities){
                System.assert(oppRec.RecordTypeId == oppMidMarketRecTypeId, 'Opportunity recordType should be New Business');             
            } 
        } 
        System.assertEquals(1,AccountSendEmailToAccountOwnersTrH.emailSentCount, 'Opportunity owner change an email should be sent');
    }
    
    private static void verifyChildrecordsCount(Account accRec){
        if(accRec.UUID__c == 'parent-UUID-001'){
            System.assert(accRec.Contacts.size() == 4, '4 Contacts should be present');
            System.assert(accRec.Opportunities.size() == 2, '2 Opportunities should be present');              
        }else if(accRec.UUID__c == 'parent-UUID-002'){
            System.assert(accRec.Contacts.size() == 1, '1 contacts should be created');
            System.assert(accRec.Opportunities.size() == 1, '1 Opportunities should be created');             
        }
        System.assert(accRec.ChildAccounts.size() == 1, '1 Child Accounts should be present');
    }
    
    private static void verifyAssertionBeforeUpdate(Account masterAccount, Id accRecTypeId){
        System.assert(masterAccount.RecordTypeId == accRecTypeId, 'Account recordType should be same Billing Account');
        verifyChildrecordsCount(masterAccount);
        for(Contact conRec : masterAccount.Contacts){              
            System.assert(conRec.OwnerId == masterAccount.OwnerId, 'Account and Contact OwnerId should be same');
        }
        for(Account childAcc : masterAccount.ChildAccounts){                  
            System.assert(childAcc.OwnerId == masterAccount.OwnerId, 'Account and Child Account OwnerId should be same');
            System.assert(childAcc.RecordTypeId == accRecTypeId, 'Account recordType should be same Consumer');
        }
        for(Opportunity oppRec : masterAccount.Opportunities){                 
            System.assert(oppRec.OwnerId == masterAccount.OwnerId, 'Account and Opportunity OwnerId should be same');  
        }  
    }
    
    private static List<Account> getAccountsWithChildRecords(Set<String> parentAccUUIDs){
        return [SELECT Id, Name, OwnerId, RecordTypeId, UUID__c, Processing_Stage__c, Account_Owner_RecordType_For_Batch__c, Primary_Member__c, 
                (SELECT Id, Name, OwnerId, RecordTypeId FROM Contacts),
                (SELECT Id, OwnerId, RecordTypeId FROM Opportunities),
                (SELECT Id, OwnerId, RecordTypeId FROM ChildAccounts) FROM Account WHERE UUID__c IN :parentAccUUIDs ORDER BY CreatedDate DESC]; 
        
    }
      
    @isTest
    private static void verifyAccUpdateHierarchyOppNameOnMerge(){
        Test.startTest();
        List<Account> accounts = [SELECT Id, Name, Account_Type__c, Nickname__c FROM Account];
        Database.MergeResult orgAccountresult = Database.merge(accounts[0],accounts[1]);
        System.assert(orgAccountresult.isSuccess());
        Database.MergeResult salesAccountResult = Database.merge(accounts[2],accounts[3]);
        System.assert(salesAccountResult.isSuccess());
        Test.stopTest();
    }
    
}