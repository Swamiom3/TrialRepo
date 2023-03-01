@isTest
public with sharing class OpportunityNamingTrHTest {
    @testSetup
    static void initData(){
        OperatingHours objOpHour = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday');
        insert objOpHour;
        List<Account> accountsToCreate = TestingUtility.createAccounts( 1, 'WeWork', false);
        accountsToCreate[0].RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
                                           .get('Business Account')
                                           .getRecordTypeId();
        TestingUtility.insertListWithAssert(accountsToCreate);

        List<Contact> contactsToCreate = new List<Contact>();
        contactsToCreate.add(TestingUtility.createContact(new Map<String, Object> {'FirstName' => 'Paul',
                                                                                   'LastName' => 'enterpriseBoss',
                                                                                   'Email' => 'paul@enterpriseBoss.com',
                                                                                   'AccountId' => accountsToCreate[0].Id,
                                                                                   'UUID__c' => 'xxx123'},
                                                          false));
        TestingUtility.insertListWithAssert(contactsToCreate);
        List<Geography__c> geographies = new List<Geography__c>();
        Map<String, Object> geographyValues= new Map<String, Object> {'Name' => 'Baner1,Maharashtra',
                                                                      'City__c' => 'Baner1,Maharashtra',
                                                                      'Country__c' => 'Netherlands',
                                                                      'District__c' => 'Pune',
                                                                      'Formatted_Address__c' => 'Baner, Pune, Maharashtra, India',
                                                                      'Geocode__Latitude__s' => 18.5596581,
                                                                      'Geocode__Longitude__s' => 73.7799374,
                                                                      'JSON__c' => '{"address_components":[{"long_name":"Baner","short_name":"Baner","types":["","sublocality","sublocality_level_1"]},{"long_name":"Pune","short_name":"Pune","types":["locality","political"]},{"long_name":"Pune","short_name":"Pune","types":["administrative_area_level_2","political"]},{"long_name":"Maharashtra","short_name":"MH","types":["administrative_area_level_1","political"]},{"long_name":"India","short_name":"IN","types":["country","political"]}],"formatted_address":"Baner, Pune, Maharashtra, India","geometry":{"bounds":{"northeast":{"lat":18.5756111,"lng":73.8043045},"southwest":{"lat":18.544332,"lng":73.76332800000002}},"location":{"lat":18.5596581,"lng":73.7799374},"location_type":"APPROXIMATE","viewport":{"northeast":{"lat":18.5756111,"lng":73.8043045},"southwest":{"lat":18.544332,"lng":73.76332800000002}}},"place_id":"ChIJy9Nd8M--wjsRfat_-5cSkaE","types":["political","sublocality","sublocality_level_1"]}',
                                                                      'Location_Type__c' => 'APPROXIMATE',
                                                                      'Place_ID__c' => 'ChIJy9Nd8M--wjsRfat_-5cSkaEvhj',
                                                                      'State__c' => 'Maharashtra'};
        geographies.add((Geography__c)TestingUtility.createTestRecords(Geography__c.sObjectType, geographyValues, false));

        geographyValues.put('Name', 'Sangamner, Maharashtra');
        geographyValues.put('City__c', 'Sangamner, Maharashtra');
        geographyValues.put('Country__c', 'Indi2politicala');
        geographyValues.put('District__c', 'Ahmednagar');
        geographyValues.put('Formatted_Address__c', 'Sangamner, Maharashtra 422605, India');
        geographyValues.put('Geocode__Latitude__s', 19.5771387);
        geographyValues.put('Geocode__Longitude__s', 74.2079648);
        geographyValues.put('JSON__c', '{"address_components":[{"long_name":"Sangamner","short_name":"Sangamner","types":["locality","political"]},{"long_name":"Ahmednagar","short_name":"Ahmednagar","types":["administrative_area_level_2","political"]},{"long_name":"Maharashtra","short_name":"MH","types":["administrative_area_level_1","political"]},{"long_name":"India","short_name":"IN","types":["country","political"]},{"long_name":"422605","short_name":"422605","types":["postal_code"]}],"formatted_address":"Sangamner, Maharashtra 422605, India","geometry":{"bounds":{"northeast":{"lat":19.5954532,"lng":74.2273235},"southwest":{"lat":19.5567976,"lng":74.1888714}},"location":{"lat":19.5771387,"lng":74.2079648},"location_type":"APPROXIMATE","viewport":{"northeast":{"lat":19.5954532,"lng":74.2273235},"southwest":{"lat":19.5567976,"lng":74.1888714}}},"partial_match":true,"place_id":"ChIJeavrqdAB3TsRiL6oagFS3UY","types":["locality","political"]}');
        geographyValues.put('Place_ID__c', 'ChIJy9Nd8M--wjsRfat_-5cSkaEnjbhjg');
        geographyValues.put('State__c', 'Maharashtra');
        geographies.add((Geography__c)TestingUtility.createTestRecords(Geography__c.sObjectType, geographyValues, false));

        geographyValues.put('Name', 'Melbourne VIC, Victoria');
        geographyValues.put('City__c', 'Victoria');
        geographyValues.put('Country__c', 'Australia');
        geographyValues.put('District__c', 'Ahmednagar');
        geographyValues.put('Formatted_Address__c', 'Melbourne VIC, Australia');
        geographyValues.put('Geocode__Latitude__s', 19.5771387);
        geographyValues.put('Geocode__Longitude__s', 74.2079648);
        geographyValues.put('JSON__c', '{"address_components":[{"long_name":"Melbourne","short_name":"Melbourne","types":["colloquial_area","locality","political"]},{"long_name":"Victoria","short_name":"VIC","types":["administrative_area_level_1","political"]},{"long_name":"Australia","short_name":"AU","types":["country","political"]}],"formatted_address":"Melbourne VIC, Australia","geometry":{"bounds":{"northeast":{"lat":-37.5112737,"lng":145.5125288},"southwest":{"lat":-38.4338593,"lng":144.5937418}},"location":{"lat":-37.8136276,"lng":144.9630576},"location_type":"APPROXIMATE","viewport":{"northeast":{"lat":-37.5112737,"lng":145.5125288},"southwest":{"lat":-38.4338593,"lng":144.5937418}}},"place_id":"ChIJ90260rVG1moRkM2MIXVWBAQ","types":["colloquial_area","locality","political"]}');
        geographyValues.put('Place_ID__c', 'ChIJ90260rVG1moRkM2MIXVWBAQ');
        geographyValues.put('State__c', 'Victoria');
        geographies.add((Geography__c)TestingUtility.createTestRecords(Geography__c.sObjectType, geographyValues, false));

        TestingUtility.insertListWithAssert(geographies);
        List<Building__c> buildings = new List<Building__c>();
        Map<String, Object> mapBuildingValues = new Map<String, Object> {'City__c' => 'Pune',
                                                                         'Country__c' => 'Netherlands',
                                                                         'Name' => 'AMS-Metropool',
                                                                         'CurrencyIsoCode' => 'USD',
                                                                         'Geography__c' => geographies[0].Id,
                                                                         'UUID__c' => '11111',
                                                                         'Time_Zone__c' => 'America/New_York'};
        buildings.add(TestingUtility.createBuilding(mapBuildingValues, false));

        mapBuildingValues.put('City__c', 'Sangamner');
        mapBuildingValues.put('Country__c', 'Indi2politicala');
        mapBuildingValues.put('State__c', 'TS');
        mapBuildingValues.put('Name', 'BKN-Brooklyn Heights');
        mapBuildingValues.put('Geography__c', geographies[1].Id);
        mapBuildingValues.put('UUID__c', '22222');
        buildings.add(TestingUtility.createBuilding(mapBuildingValues, false));

        mapBuildingValues.put('City__c', 'Victoria');
        mapBuildingValues.put('Country__c', 'Australia');
        mapBuildingValues.put('State__c', 'TS');
        mapBuildingValues.put('Name', 'BL-Sony Center');
        mapBuildingValues.put('Geography__c', geographies[2].Id);
        mapBuildingValues.put('UUID__c', '33333');
        buildings.add(TestingUtility.createBuilding(mapBuildingValues, false));

        mapBuildingValues.put('City__c', 'Nashik');
        mapBuildingValues.put('Country__c', 'India');
        mapBuildingValues.put('State__c', 'TS');
        mapBuildingValues.put('Name', 'BL-Tower');
        mapBuildingValues.put('Geography__c', geographies[2].Id);
        mapBuildingValues.remove('UUID__c');
        buildings.add(TestingUtility.createBuilding(mapBuildingValues, false));
        TestingUtility.insertListWithAssert(buildings);
    }

    @IsTest
    public static void testWeWorkType() {
        Opportunity opportunityToCreate = new Opportunity();
        Contact contactForOpportunity = [SELECT Id, AccountId FROM Contact Limit 1];
        Building__c building = [SELECT Id, Name FROM Building__c LIMIT 1];
        opportunityToCreate = TestingUtility.createOpportunity(new Map<String, Object> {'Name' => 'Enterprise Opportunity1',
                                                                                        'Primary_Member__c' => contactForOpportunity.Id,
                                                                                        'AccountId' => contactForOpportunity.AccountId,
                                                                                        'Building__c' => building.Id,
                                                                                        'Type__c' => GlobalConstants.WEWORK,
                                                                                        'closeDate' => System.today(),
                                                                                        'Contract_Stage__c' => 'Contract Sent'},
                                                               false);

        Test.startTest();
        insert opportunityToCreate;
        Opportunity recordToTest = [SELECT Name FROM Opportunity WHERE Id =: opportunityToCreate.Id];
        System.assert (recordToTest.Name.contains(building.Name), 'Opportunity name should have building name');
        Opportunity opportunityToUpdate = recordToTest;
        opportunityToUpdate.Building__c = null;
        update opportunityToUpdate;
        Opportunity updatedRecordToTest = [SELECT Name FROM Opportunity WHERE Id =: opportunityToUpdate.Id];
        System.assert (!updatedRecordToTest.Name.contains(building.Name), 'Opportunity name should not have building name');
        Test.stopTest();
    }

    @IsTest
    public static void testWeWorkTypeWithGeography() {
        Opportunity opportunityToCreate = new Opportunity();
        Contact contactForOpportunity = [SELECT Id, AccountId FROM Contact Limit 1];
        Geography__c geography = [SELECT Id, City__c FROM Geography__c LIMIT 1];
        opportunityToCreate = TestingUtility.createOpportunity(new Map<String, Object> {'Name' => 'Enterprise Opportunity1',
                                                                                        'Primary_Member__c' => contactForOpportunity.Id,
                                                                                        'AccountId' => contactForOpportunity.AccountId,
                                                                                        'Geography__c' => geography.Id,
                                                                                        'Type__c' => GlobalConstants.WEWORK,
                                                                                        'closeDate' => System.today(),
                                                                                        'Contract_Stage__c' => 'Contract Sent'},
                                                               false);

        Test.startTest();
        insert opportunityToCreate;
        Opportunity recordToTest = [SELECT Name FROM Opportunity WHERE Id =: opportunityToCreate.Id];
        System.assert (recordToTest.Name.contains(geography.City__c), 'Opportunity name should have geography name');
        Test.stopTest();
    }

    @IsTest
    public static void testPxWeType() {
        Opportunity opportunityToCreate = new Opportunity();
        Contact contactForOpportunity = [SELECT Id, AccountId FROM Contact Limit 1];
        Geography__c geography = [SELECT Id, City__c FROM Geography__c LIMIT 1];
        opportunityToCreate = TestingUtility.createOpportunity(new Map<String, Object> {'Name' => 'Enterprise Opportunity1',
                                                                                        'Primary_Member__c' => contactForOpportunity.Id,
                                                                                        'AccountId' => contactForOpportunity.AccountId,
                                                                                        'Geography__c' => geography.Id,
                                                                                        'Type__c' => GlobalConstants.PX_WE,
                                                                                        'closeDate' => System.today(),
                                                                                        'Contract_Stage__c' => 'Contract Sent'},
                                                               false);

        Test.startTest();

        insert opportunityToCreate;
        Opportunity recordToTest = [SELECT Name FROM Opportunity WHERE Id =: opportunityToCreate.Id];
        System.assert (recordToTest.Name.contains(geography.City__c), 'Opportunity name should have city');
        Test.stopTest();
    }

    @IsTest
    public static void testEmptyType() {
        Opportunity opportunityToCreate = new Opportunity();
        Contact contactForOpportunity = [SELECT Id, AccountId FROM Contact Limit 1];
        Building__c building = [SELECT Id, Name FROM Building__c LIMIT 1];
        opportunityToCreate = TestingUtility.createOpportunity(new Map<String, Object> {'Name' => 'Enterprise Opportunity1',
                                                                                        'Primary_Member__c' => contactForOpportunity.Id,
                                                                                        'AccountId' => contactForOpportunity.AccountId,
                                                                                        'Building__c' => building.Id,
                                                                                        'Type__c' => null,
                                                                                        'closeDate' => System.today(),
                                                                                        'Contract_Stage__c' => 'Contract Sent'},
                                                               false);

        Test.startTest();

        insert opportunityToCreate;
        Opportunity recordToTest = [SELECT Name FROM Opportunity WHERE Id =: opportunityToCreate.Id];
        System.assert (recordToTest.Name.contains(building.Name), 'Opportunity name should have building name');
        Test.stopTest();
    }

    @IsTest
    public static void testAccessType() {
        Opportunity opportunityToCreate = new Opportunity();
        Contact contactForOpportunity = [SELECT Id, AccountId FROM Contact Limit 1];
        Geography__c geography = [SELECT Id, City__c FROM Geography__c LIMIT 1];
        opportunityToCreate = TestingUtility.createOpportunity(new Map<String, Object> {'Name' => 'Enterprise Opportunity1',
                                                                                        'Primary_Member__c' => contactForOpportunity.Id,
                                                                                        'AccountId' => contactForOpportunity.AccountId,
                                                                                        'Geography__c' => geography.Id,
                                                                                        'Type__c' => GlobalConstants.ALL_ACCESS,
                                                                                        'closeDate' => System.today(),
                                                                                        'Contract_Stage__c' => 'Contract Sent'},
                                                               false);

        Test.startTest();

        insert opportunityToCreate;
        Opportunity recordToTest = [SELECT Name FROM Opportunity WHERE Id =: opportunityToCreate.Id];
        System.assert (recordToTest.Name.contains(geography.City__c), 'Opportunity name should have city');
        Test.stopTest();
    }

    @isTest
    public static void testEmptyAccount(){
        
        Opportunity opportunityToCreate = TestingUtility.createOpportunity(
            new Map<String, Object> {
                'Name' => 'Enterprise Opportunity1',
                'Type__c' => GlobalConstants.WEWORK,
                'Requirement_Quantity__c' => 10,
                'CloseDate' => System.today(),
                'Contract_Stage__c' => 'Contract Sent',
                'StageName' => 'Closed Won'
            }, 
            false
        );

        Test.startTest();
            insert opportunityToCreate;
        Test.stopTest();

        Opportunity recordToTest = [
            SELECT Name, Opportunity_Account_Name__c, CloseDate 
            FROM Opportunity 
            WHERE Id =: opportunityToCreate.Id
        ];
        System.assertEquals(DateFormatter.monthDayYear(recordToTest.CloseDate), recordToTest.Name, 'Wrong Opportunity name for empty account');    
	}
}