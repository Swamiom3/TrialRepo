/*********************************************************************************************************
	Author        :  Vipul Chaudahari
	Description   :  Test class for JourneyGenerateUUIDTrH
	Issue No.     :  ST-8958
-----------------------------------------------------------------------------------------------------------
	VERSION        DATE             AUTHOR             DETAIL
	1          09-Sept-2021     Vipul Chaudhari     Trigger Refactor
**********************************************************************************************************/
@isTest
public class JourneyGenerateUUIDTrHTest {
    @isTest
    public static void testInsertedJourneyUUID(){
        List<Journey__c> testJourneys = getInsertedJourneys(2);
        List<Journey__c> mokedJourneys = new List<Journey__c>{
            new Journey__c(Id = testJourneys[0].Id),
            new Journey__c(Id = testJourneys[1].Id)
        };
        Test.startTest();
        JourneyGenerateUUIDTrH generateUUID = new JourneyGenerateUUIDTrH();
        generateUUID.newJourneys = mokedJourneys;
        generateUUID.beforeInsert();
        Test.stopTest();
        System.assertNotEquals(mokedJourneys[0].UUID__c, null, 'UUID Ca');
    }
    public static List<Journey__c> getInsertedJourneys(Integer size){
        List<Journey__c> testJourneys = new List<Journey__c>();
        for(Integer i = 0; i<size; i++){
            testJourneys.add(new Journey__c(
                Id = TestUtility.getFakeId(Journey__c.getSObjectType()), 
                Name = 'Demo',
                NMD_Next_Contact_Date__c = System.date.Today().addDays(1),
                Primary_Contact__c = getContacts().Id
            ));
        }
        return testJourneys;
    }
    public static Contact getContacts(){
        return new Contact(
            FirstName = 'Test',
            LastName = 'TestLastName',
            Email = 'test@example.com',
            Id = TestUtility.getFakeId(Contact.getSObjectType())
        );
    }
}