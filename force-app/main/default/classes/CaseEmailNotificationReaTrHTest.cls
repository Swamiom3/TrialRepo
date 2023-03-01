@isTest
public class CaseEmailNotificationReaTrHTest {
    private static final Id reaRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('REA').getRecordTypeId();

    @testSetup
    static void initData() {
        TestingUtility.getTerritorystructure();
    }

    @isTest
    private static void verifySendEmailToValidCases() {
        Territory__c territory = [SELECT Id, Name FROM Territory__c LIMIT 1];
        territory.Name = 'Mid-Atlantic';
        TestingUtility.updateWithAssert(territory);
		
        BusinessHours hours = [SELECT ID FROM BusinessHours WHERE Name='India (Asia/Kolkata)'];
        Building__c building = [SELECT Id, Name, Market__c FROM Building__c WHERE Market__r.TerritoryID__c = :territory.Id LIMIT 1];
        building.Business_Hours_Id__c = hours.Id;
        update building;
        
        Account accountRecord = TestingUtility.createAccount('testAccount', false);
        TestingUtility.insertWithAssert(accountRecord);
        
        Account salesAccount = TestingUtility.createAccount(new Map<String,Object> {
            'Name' => 'Sales Account',
            'ParentId' => accountRecord.Id,
            'Account_Type__c' => 'Sales',
            'Nickname__c' => 'TestSalesAcc'},
            false
        );
        TestingUtility.insertWithAssert(salesAccount);

        Profile weworkSystemAdmin = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        Map<String,Object> userRecordMap1 = new Map<String,Object>();
        userRecordMap1.put('LastName','Last Name 1');
        userRecordMap1.put('Username','testweworkuser11@example.com');
        userRecordMap1.put('Email','testweworkuser1@example.com');
        userRecordMap1.put('CommunitynickName','test111'+system.now());
        user testUser1 = TestingUtility.insertUserWithAssert(weworkSystemAdmin.Id, userRecordMap1, true);
        
        User loggedInUser = UserUtility.getUserById(UserInfo.getUserId());
        List<AccountTeamMember> accountTeamMember = new List<AccountTeamMember>();

        accountTeamMember.add(TestingUtility.getAccountTeamMember(accountRecord.Id, loggedInUser, 'Real Estate Advisory', null, null));
        
        accountTeamMember.add(TestingUtility.getAccountTeamMember(accountRecord.Id, testUser1, 'Real Estate Advisory', null, null));
        TestingUtility.insertListWithAssert(accountTeamMember);
            
        Map<String,  List<Object>> fieldValues = new Map<String, List<Object>> {
            'AccountId' => new List<Object>{accountRecord.Id},
            'StageName' => new List<Object>{'Selling'},
            'CloseDate' => new List<Object>{System.today().addDays(5)},
            'Amount' => new List<Object>{150},
            'Building__c' => new List<Object>{building.Id}
        };
        Map<String, Object> opportunityData = new Map<String, Object> {
            'objName' => 'opportunity',
            'doInsert' => false,
            'numberOfRecords' => 1,
            'mapFieldValues' => fieldValues
        };
        Opportunity opportunity = (Opportunity) TestingUtility.getRecords(opportunityData)[0];
        TestingUtility.insertWithAssert(opportunity);

        List<Case> cases = new List<Case>();
        cases.add(new Case(
            AccountId = salesAccount.Id,
            Opportunity__c = opportunity.Id,
            Status = 'New',
            Building_Nearest_Address__c = building.Id,
            RecordTypeId = reaRecordTypeId,
            BusinessHoursId = hours.Id
        ));
        cases.add(new Case(
            AccountId = accountRecord.Id,
            Opportunity__c = opportunity.Id,
            Status = 'New',
            Building_Nearest_Address__c = building.Id,
            RecordTypeId = reaRecordTypeId,
            BusinessHoursId = hours.Id
        ));

        Test.startTest();
        TestingUtility.insertListWithAssert(cases);
        System.assertEquals(1, Limits.getEmailInvocations(), 'Email not sent');
        Test.stopTest();        
    }
}