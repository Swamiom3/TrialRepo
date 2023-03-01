/********************************************************************************************************************************
    Author 		: @hemanshu.shah@enzigma.com
    Description : This class should contain all test methods related to Settings 
    History		: --

-----------------------------------------------------------------------------------------------------------------------------------
	VERSION							DATE						AUTHOR 							DETAIL
  	1							    24,Apr 2016				    hemanshu shah 			        Initial Developement
***********************************************************************************************************************************/
@isTest
public class SettingsTest {
    
    static{ 
        Profile weworkSystemAdmin = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        Map<String,Object> userRecordMap1 = new Map<String,Object>();
        userRecordMap1.put('LastName','Last Name 1');
        userRecordMap1.put('Username','testweworkuser11@example.com');
        userRecordMap1.put('Email','testweworkuser1@example.com');
        userRecordMap1.put('CommunitynickName','test111'+system.now());
        user testUser1 = TestingUtility.insertUserWithAssert(weworkSystemAdmin.Id, userRecordMap1, true);
    }
    
    public static Settings.FieldMappings getTestMappings(){
        Settings.FieldMappings settingsMapping = new Settings.FieldMappings();
        settingsMapping.version = 1;
        settingsMapping.mappings = new Map<String, Settings.MappedField>();
        settingsMapping.mappings.put('Description', new Settings.MappedField('Description'));
        settingsMapping.mappings.put('Lead_Source__c', new Settings.MappedField('WeWork.com', true));
        return settingsMapping;
    }
    
	/***************************************************************************************************************************
       Author 				: Hemanshu Shah
       Description 			: Tehst Method for Settings increase code coverage
       Created Date			: 24,Apr 2016
	   Last Modified By 	: Prashant Mane
	   Last Modified Date   : 02 Feb,2018
	******************************************************************************************************************************/
    @isTest
    public static void testSettingsforIncreaseCodeCoverage(){
        user testUser1=[Select Id,Name,UserName,Email From User Where UserName='testweworkuser11@example.com'];
        User getUserById=Settings.getUserById(testUser1.Id);
        system.assert(getUserById !=null);
        User getUserByEmail=Settings.getUserByEmail('testweworkuser1@example.com');
        system.assert(getUserByEmail !=null);
        getUserByEmail=Settings.getUserByEmail('testweworkuser_123@example.com');
        system.assertEquals(null, getUserByEmail);
        User getUserByName= Settings.getUserByName('Last Name 1');
        system.assert(getUserByName !=null);
        getUserByName= Settings.getUserByName('Last Name_123');
        system.assertEquals(null, getUserByName);
        Boolean getUserActive=Settings.getUserActive(testUser1.Id);
        system.assertEquals(true, getUserActive);
        List<User> lstAllUsers=Settings.getAllUsers();
        
        MySettings settingsMy = new MySettings();
        settingsMy.count = 10;
        settingsMy.timestamp = Date.today();
        settingsMy.name = 'Test';

        Building__c objBuilding = new Building__c(
            City__c = 'Test',
            Name = 'NYC-Penn Station',          
            uuid__c = 'abc123');
        insert objBuilding;
        Building__c getBuildingById= Settings.getBuildingById(objBuilding.Id);
        system.assert(getBuildingById !=null);
        Building__c getBuildingByUUID=Settings.getBuildingByUUID('abc123');
        system.assert(getBuildingByUUID !=null);
        List<Building__c> lstBuildings=Settings.getAllBuildings();
        System.assertEquals(1, lstBuildings.size());
        lstBuildings = Settings.getBuildingsByIds(new Set<Id>{objBuilding.Id});
        System.assertEquals(1, lstBuildings.size());
        System.assert(String.isNotBlank(Settings.getApiUserId()));
        System.assert(String.isBlank(Settings.getValidationRuleRestrictionSalesforceId(null)));
    }
    
	/*************************************************************************************************
       Author 				: Hemanshu Shah
       Description 			: test Settings Caching
       Created Date			: 24,Apr 2016
	   Last Modified By 	: Prashant Mane
	   Last Modified Date   : 02 Feb,2018
	****************************************************************************************************/
    @isTest
    public static void testSettingsCaching(){
        String strName = 'FieldMappings_LeadToContact';
        Settings.FieldMappings fieldMappings = getTestMappings();
        
        Integer iQueriesSoFar = Limits.getQueries();
        Sales_Console_Setting__mdt setting = Settings.get(strName);
        System.assert(setting != null);
        System.assert(iQueriesSoFar + 2 == Limits.getQueries());
        
        setting = Settings.get(strName);
        System.assert(setting != null);
        System.assert(iQueriesSoFar + 2 == Limits.getQueries());
        
        Settings.FieldMappings mappings = Settings.getFieldMappings('LeadToContact');
        System.assert(mappings != null);
        Settings.MappedField mappedField = mappings.mappings.get('Description');
        System.assert(mappedField.fieldname == 'Description');
        
        iQueriesSoFar = Limits.getQueries();
        Settings.LoadFieldMappings();
        System.assert(iQueriesSoFar + 1 == Limits.getQueries());
        mappings = Settings.getFieldMappings('LeadToContact');
        System.assert(mappings != null);
        mappedField = mappings.mappings.get('Description');
        System.assert(mappedField.fieldname == 'Description');
        System.assert(iQueriesSoFar + 1 == Limits.getQueries());
    }
    
	/*************************************************************************************************
       Author 				: Hemanshu Shah
       Description 			: test method for Load Settings
       Created Date			: 24,Apr 2016
	   Last Modified By 	: Prashant Mane
	   Last Modified Date   : 02 Feb,2018
	****************************************************************************************************/
    @isTest
    public static void testLoadSettings(){
        String strName = 'FieldMappings_LeadToContact';
        Settings.FieldMappings fieldMappings = getTestMappings();
        
       /* Database.UpsertResult result = Settings.saveFieldMappings('LeadToContact', fieldMappings);
        System.assert(result.getId() != null);*/
        
        Settings.LoadSettings(new List<String>{strName});
        integer iQueriesSoFar = Limits.getQueries();
        
        Sales_Console_Setting__mdt setting = Settings.get(strName);
        System.assert( setting != null);
        System.assert( iQueriesSoFar == Limits.getQueries());
        
        Settings.LoadFieldMappings();
        iQueriesSoFar = Limits.getQueries();
        
        setting = Settings.get(strName);
        System.assert( setting != null);
        System.assert( iQueriesSoFar == Limits.getQueries());
    }
    
    public class MySettings {
        Integer count;
        Date timestamp;
        String name;
    }
    
    /*****************************************************************************************************************************************
        Author              :   Pragalbha Mahajan
        Description         :   This method is used to test fetchEmailTemplates method
        Created Date        :   01 October 2018
        Issue No            :   ST-2696
    ******************************************************************************************************************************************/
    @isTest
    public static void testFetchEmailTemplates(){
        User objUser = [SELECT Id, Name, Email FROM User WHERE Email =: 'testweworkuser1@example.com'];
        system.runAs(objUser){
            EmailTemplate objEmailTemplate = new EmailTemplate (developerName = 'test', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'test'); 
            TestingUtility.insertWithAssert(objEmailTemplate);
            system.assertNotEquals(null, objEmailTemplate.Id);                       
            EmailTemplate objEmailTemplateByName = Settings.getEmailTemplateByDeveloperName('test');
            Integer countSOQLLimit = Limits.getQueries();
            system.assertNotEquals(null, objEmailTemplateByName);
            objEmailTemplateByName = Settings.getEmailTemplateByDeveloperName('test');//2 times calling to test here no SOQL is fired again for same email template
            system.assertEquals(countSOQLLimit, Limits.getQueries());
            system.assertNotEquals(null, objEmailTemplateByName);
            EmailTemplate objEmailTemplateByName1 = Settings.getEmailTemplateByDeveloperName('tst');
            system.assertEquals(null, objEmailTemplateByName1);
        }
    } 
    
  /************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method is usde to check is record value changed.
        Created Date  		:   12 December 2018		
  **************************************************************************************************************************************/ 
    @isTest
    public static void verifyIsChange(){     
        System.assertEquals(true, Settings.isChanged('Test', null));
        System.assertEquals(true, Settings.isChanged(null, 'test'));
        System.assertEquals(true, Settings.isChanged('null', 'test'));
        System.assertEquals(true, Settings.isChanged('test', 'null'));
        System.assertEquals(false, Settings.isChanged(null, null));
        System.assertEquals(false, Settings.isChanged('Test', 'Test'));
        System.assertEquals(false, Settings.isChanged('Test', 'test'));
        set<String> setValues = Settings.splitStringToSet('test1,test2',',');
        System.assertEquals(2, setValues.size());
        Settings.getAllProducts();
    }
    
    /************************************************************************************************************************************
        Author              :   Chandra Teja
        Description         :   This method is usde to verify getMetadataSettingByDevNameAsMap method in settings class.
        Created Date  		:   21 August 2019		
  **************************************************************************************************************************************/ 
    @isTest
    public static void verifyGetMetadataSettingByDevNameAsMap(){     
       Settings.getMetadataSettingByDevNameAsMap('PartnerReferralLSandLSDforEntRecordType');// For first call to method
       Map<String, Object> mapSettings =Settings.getMetadataSettingByDevNameAsMap('PartnerReferralLSandLSDforEntRecordType');// for second call to use the static map
        for(String objKey: mapSettings.keySet()){
            System.assert(mapSettings.get(objKey) != NULL);
        }
    }
    
    /************************************************************************************************************************************
        Author              :   Ashish Sharma
        Description         :   This method is usde to verify updateDataFromRelatedObject method in settings class.
        Created Date  		:   4 April 2020		
  	**************************************************************************************************************************************/
    @isTest
    public static void verifyGetParentFieldValue() {
        TestingUtility.getTerritorystructure();
        Building__c objBuilding = [SELECT Id, Name FROM Building__c LIMIT 1];
        User objUser = Settings.getUserByEmail('testweworkuser1@example.com');
        objBuilding.Associate_Director_Market_Sales__c = objUser.Id;
        TestingUtility.updateWithAssert(objBuilding);
        Settings.lstBuildings = NULL;
        BuildingUtility.buildings = null;
        objBuilding = Settings.getBuildingById(objBuilding.Id);
        //One level relationship
        Object value = Settings.getParentFieldValue(objBuilding, 'Associate_Director_Market_Sales__r.Name');
        System.assert(value == objUser.Name);
        //no level
        value = Settings.getParentFieldValue(objBuilding, 'Associate_Director_Market_Sales__c');
        System.assert(value == objUser.Id);
        //source null
        value = Settings.getParentFieldValue(NULL, 'Associate_Director_Market_Sales__r.Name');
        System.assert(value == NULL);
    }

    @isTest
    public static void shouldReloadUsers() {
        Map<Id, User> usersByIdsMap;

        Test.startTest();
        Integer iQueriesSoFar = Limits.getQueries();
        Settings.refreshUsers();
        System.assert(iQueriesSoFar + 2 == Limits.getQueries());
        usersByIdsMap = UserUtility.idToUser;
        Test.stopTest();

        System.assert(!usersByIdsMap.isEmpty(), 'List of users should not be empty');
    }

    @isTest
    public static void shouldCheckSystemUser() {
        Test.startTest();
        System.assert(Settings.isSystemAdministrator, 'System User should be Admin');
        System.assert(!Settings.isMuleSoftUser, 'System User should be not MuleSoft User');
        Test.stopTest();
    }

    @isTest
    public static void shouldGetTeamRoleForLeanData() {
        String teamMemberRole;
        Test.startTest();
        teamMemberRole = Settings.getTeamRoleConfigSettings('LeanDatacreateOppTeam');
        Test.stopTest();

        System.assert(String.isNotBlank(teamMemberRole), 'Should get role for lean data');
    }

    @isTest
    public static void shouldNotGetTeamRoleForFakeData() {
        String teamMemberRole;

        Test.startTest();
        teamMemberRole = Settings.getTeamRoleConfigSettings('FakeTeamRoleSettings');
        Test.stopTest();

        System.assert(String.isBlank(teamMemberRole), 'Should get no role for fake data');
    }

    @isTest
    public static void shouldFetchQueues() {
        List<Group> queues;

        Test.startTest();
        Settings.fetchQueues();
        queues = Settings.lstQueues;
        Test.stopTest();

        System.assert(!queues.isEmpty(), 'Should retrieve some records');
    }

    @isTest
    public static void shouldNotGetQueueForFakeName() {
        Group fakeQueue;

        Test.startTest();
        fakeQueue = Settings.getQueueByName('Some_test_fake_queue_name');
        Test.stopTest();

        System.assertEquals(fakeQueue, null, 'Queue should be not retrieved for fake name');
    }

    @isTest
    public static void shouldNotGetQueueForFakeId() {
        Group fakeQueue;
        Id fakeAnotherObjectId = Account.SObjectType.getDescribe().getKeyPrefix() + '0'.repeat(12);

        Test.startTest();
        fakeQueue = Settings.getQueueById(fakeAnotherObjectId);
        Test.stopTest();

        System.assertEquals(fakeQueue, null, 'Queue should be not retrieved for fake Id');
    }

        
    @isTest
    public static void getFlowToTriggersSettingsTest(){
        Test.startTest();
        Boolean updateOpportunityUpdatedFromClosedWonUPDATE = Settings.getFlowToTriggersSettings('updateOpportunityUpdatedFromClosedWon__UPDATE', 'Opportunity');
        Boolean dummy = Settings.getFlowToTriggersSettings('dummy', 'dummy');
        Test.stopTest();
        System.assertEquals(true, updateOpportunityUpdatedFromClosedWonUPDATE, 'updateOpportunityUpdatedFromClosedWon__UPDATE should be true');
        System.assertEquals(false, dummy, 'Config should not be found');
    }
}