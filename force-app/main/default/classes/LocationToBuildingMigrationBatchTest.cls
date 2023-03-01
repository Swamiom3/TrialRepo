@isTest
class LocationToBuildingMigrationBatchTest {
    @TestSetup
    static void makeData(){
        Building__c building = new Building__c(
            Name = 'Test Building Name',
            UUID__c = 'Test UUID'
        );
        Location__c location = new Location__c(
            Name = 'Test  Location Name',
            Location_UUID__c = 'Test UUID'
        );
        Task task = new Task(
            Status = 'Open',
            Building_del__r = new Location__c(Location_UUID__c = 'Test UUID')
        );
        Event event = new Event(
            DurationInMinutes = 5,
            ActivityDateTime = System.now(),
            Building_del__r = new Location__c(Location_UUID__c = 'Test UUID')
        );
        insert new List<SObject>{location, building, task, event};
    }

    @isTest static void testLocationToBuildingMigrationBatchBoth(){
        Test.startTest();
        Database.executeBatch(new LocationToBuildingMigrationBatch(
            LocationToBuildingMigrationBatch.ActivityType.BOTH
        ));
        Test.stopTest();

        System.assert([SELECT Building__c FROM Task].Building__c != null, 'Building should be populated');
        System.assert([SELECT Building__c FROM Event].Building__c != null, 'Building should be populated');
    }

    @isTest static void testLocationToBuildingMigrationBatchTask(){
        Test.startTest();
        Database.executeBatch(new LocationToBuildingMigrationBatch(
            LocationToBuildingMigrationBatch.ActivityType.TASK
        ));
        Test.stopTest();

        System.assert([SELECT Building__c FROM Task].Building__c != null, 'Building should be populated');
    }

    @isTest static void testLocationToBuildingMigrationBatchEvent(){
        Test.startTest();
        Database.executeBatch(new LocationToBuildingMigrationBatch(
            LocationToBuildingMigrationBatch.ActivityType.EVENT
        ));
        Test.stopTest();

        System.assert([SELECT Building__c FROM Event].Building__c != null, 'Building should be populated');
    }

    @isTest static void testLocationToBuildingMigrationBatch_negative(){
        String errorMessage = '';
        Test.startTest();
        try {
            Database.executeBatch(new LocationToBuildingMigrationBatch(null));
        } catch (Exception ex) {
            errorMessage = ex.getMessage();
        }
        Test.stopTest();

        System.assertEquals(
            new LocationToBuildingMigrationBatch(LocationToBuildingMigrationBatch.ActivityType.EVENT).ERROR_MESSAGE , errorMessage, 
                                                                                'Error Message should match');
        System.assert([SELECT Building__c FROM Task].Building__c == null, 'Building should be NOT populated');
        System.assert([SELECT Building__c FROM Event].Building__c == null, 'Building should be NOT populated');
    }

}