@isTest
public class CaseEmailAlertOnReaCaseCreationTrHTest {
    private static final Id REA_CASE_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('REA').getRecordTypeId();
    @testSetup
    static void initData() {        
        Test.startTest();
        Group testGroup = new Group(Name = 'Test Group', Type = 'Queue');
        insert testGroup;
            
        QueuesObject queueObject = new QueueSObject(QueueId  = testGroup.Id, SobjectType = 'Case');
        insert queueObject;
        
        GroupMember member = new GroupMember();
        member.UserOrGroupId = UserInfo.getUserId();
        member.GroupId = testGroup.Id;
        insert member;
        Test.stopTest();
    }
    
    @isTest
    private static void verifySendEmailToValidCases() {
        TestingUtility.getTerritorystructure();
        Territory__c territory = [SELECT Id, Name FROM Territory__c LIMIT 1];
        territory.Name = 'Mid-Atlantic';
        TestingUtility.updateWithAssert(territory);
        
        BusinessHours hours = [SELECT ID FROM BusinessHours WHERE Name='India (Asia/Kolkata)'];
        Building__c building = [SELECT Id, Name, Market__c FROM Building__c WHERE Market__r.TerritoryID__c = :territory.Id LIMIT 1];
        building.Business_Hours_Id__c = hours.Id;
        update building;
        Account accountRecord = TestingUtility.createAccount('testAccount', false);
        TestingUtility.insertWithAssert(accountRecord);
        
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
            AccountId = accountRecord.Id,
            Opportunity__c = opportunity.Id,
            Status = 'New',
            Building_Nearest_Address__c = building.Id,
            RecordTypeId = REA_CASE_RECORD_TYPE_ID,
            BusinessHoursId = hours.Id
        ));
        cases.add(new Case(
            AccountId = accountRecord.Id,
            Opportunity__c = opportunity.Id,
            Status = 'New',
            Building_Nearest_Address__c = building.Id,
            RecordTypeId = REA_CASE_RECORD_TYPE_ID,
            OwnerId = [SELECT Id FROM Group WHERE Name = 'Test Group' LIMIT 1].Id,
            BusinessHoursId = hours.Id
        ));
        
        Test.startTest();
        TestingUtility.insertListWithAssert(cases);
        System.assert(Limits.getEmailInvocations() > 0, 'Email not sent');
        Test.stopTest();        
    }
}