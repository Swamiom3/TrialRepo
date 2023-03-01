/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class is create/modify the Service Resources based on Building Players.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                DETAIL
1           14 September 2021   Salesforce            Initial Developement
**************************************************************************************************************************************/
@isTest
public class BuildingPlayersToServiceResourceTrHTest {
    
    static List<User> testUsers;
    
    @testsetup
    static void setup(){
        testUsers = getTestUsers();
        BuildingPlayersToServiceResourceTrH buildPlayerToSer = new BuildingPlayersToServiceResourceTrH();
        List<ServiceResource> serviceResources = new List<ServiceResource>(); 
        for(User usr : testUsers){
            ServiceResource serviceResourceRecord = new ServiceResource();
            serviceResourceRecord.RelatedRecordId = usr.Id;
            serviceResourceRecord.Name = usr.Username;
            serviceResourceRecord.ResourceType = buildPlayerToSer.RESOURCE_TYPE_TECHNICIAN;
            serviceResourceRecord.isActive = true;
            serviceResources.add(serviceResourceRecord);
        }
        insert serviceResources;
        Building__c testBuilding = new Building__c(Name = 'Test Building', No_Longer_in_Use__c=false,
                                                   Address__c='123 Mission St', City__c='california',
                                                   Country__c='USA', Postal_Code__c='90168', State__c='california',
                                                   Time_Zone__c='America/New_York');
        TestingUtility.insertWithAssert(testBuilding, 'Building not inserted');
        WorkType workType = new WorkType();
        workType.Name = 'Test workType';
        workType.Building_Id__c = testBuilding.Id;
        workType.Tour_Format__c = 'Virtual';
        workType.Block_Same_Day_Touring__c = true;
        workType.EstimatedDuration = 10.0;
        insert workType;
        
        testBuilding.Is_Tourable__c = true;
        update testBuilding;
    }
    
    @isTest
    private static void upsertServiceResourcesTest_test_positive () {
        Test.startTest();
        testUsers = getTestUsers();
        List<ServiceResource> serviceResources = insertServiceResourceRecords(testUsers);
        List<Building__c> buildings = [SELECT Id, Leasing_Manager_Id__c 
                                       FROM Building__c];
        buildings.get(0).Leasing_Manager_Id__c = testUsers.get(1).Id;
        buildings.get(0).Leasing_Director_Id__c = testUsers.get(0).Id;
        update buildings.get(0);
        List<ServiceTerritory> serviceTerritories = [SELECT Id, Name FROM ServiceTerritory];
        List<ServiceTerritoryMember> serviceTerritoryMembers = [SELECT Id FROM ServiceTerritoryMember];
        Test.stopTest();
        System.assertEquals(1, serviceTerritories.size(), 'Service Territory records are not created correctly');
        System.assertEquals(2, serviceTerritoryMembers.size(), 'Service Territory Member records are not created correctly');
    }
    
    static private List<ServiceResource> insertServiceResourceRecords(List<User> testUsers){
        List<ServiceResource> servResources = new List<ServiceResource>();
        for(User usr : testUsers){
            ServiceResource serviceResource = new ServiceResource();
            serviceResource.Name = usr.Username;
            serviceResource.RelatedRecordId = usr.Id;
            serviceResource.IsActive = true;
            servResources.add(serviceResource);
        }
        insert servResources;
        return servResources;
    }
    
    @isTest
    private static void upsertServiceResourcesTest_test_negative () {
        Test.startTest();
        try{
            testUsers = getTestUsers();
            List<Building__c> buildings = [SELECT Id, Leasing_Manager_Id__c 
                                           FROM Building__c];
            buildings.get(0).Leasing_Manager_Id__c = testUsers.get(1).Id;
            buildings.get(0).Leasing_Director_Id__c = testUsers.get(0).Id;
            update buildings.get(0);
        }catch(Exception ex){
            System.assertEquals('System.DmlException', ex.getTypeName(), 'Error is not returned correctly');
            System.assert(ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'), 'Custom error is not returned');
        }
        Test.stopTest();
    }
    
    private static List<User> getTestUsers() {
        if(testUsers != null ){
            return testUsers;
        }else {
            testUsers = new List<User>();
        }
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueOf(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        String randomIntString = String.valueOf(Crypto.getRandomInteger());
        Profile p = [Select Id, Name FROM Profile where (UserType = 'Standard' AND PermissionsCustomizeApplication = true)][0];
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs (thisUser) {
            for(Integer i = 0; i < 2 ; i++){
                User u = new User(
                    UserName = 'test@' + orgId + dateString + randomIntString + i + '.org',
                    Email = 'test@' + orgId + dateString + randomIntString + i + '.org',
                    FirstName = 'FirstName'+i,
                    LastName = 'test'+ i,
                    Alias = 'test'+ i,
                    TimeZoneSidKey = 'America/Los_Angeles',
                    LocaleSidKey = 'en_US',
                    EmailEncodingKey = 'ISO-8859-1',
                    LanguageLocaleKey = 'en_US',
                    ProfileId = p.Id,
                    UserPermissionsKnowledgeUser = true,
                    Salesforce_Scheduler_User__c = true
                );
                testUsers.add(u);
            }
            insert testUsers;
        }
        return testUsers;
    }
}