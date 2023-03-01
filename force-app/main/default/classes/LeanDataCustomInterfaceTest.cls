/********************************************************************************************************* 
    Name: LeanDataCustomInterface() 
    ====================================================== 
    ====================================================== 
    Purpose: Custom code that is called during the LeanData Routing process
    to support custom actions that aren't handled by LeanData Out of the Box
    ------- 
    ====================================================== 
    ====================================================== 
    History 
    ------- 
    VERSION AUTHOR DATE DETAIL FEATURES/CSR/TTP 
    1.0 - Kurt Jurgens 03/22/20019 INITIAL DEVELOPMENT
    2.0 - Vamsi        03/01/2022  To Increase Code Coverage
 *******************************************************************************************************/
@isTest
private class LeanDataCustomInterfaceTest {
    @TestSetup
    static void initData(){
        Test.startTest();
        Region__c objRegion = new Region__c(Name = 'Test Region', Region__c = 'Test Region');
        TestingUtility.insertWithAssert(objRegion, 'Region not inserted');
        
        Territory__c objTerritory = new Territory__c(Name = 'Test Territory', Territory__c =' Test Territory', RegionID__c = objRegion.Id);
        TestingUtility.insertWithAssert(objTerritory, 'Territory not inserted');
        
        Market__c objMarket = new Market__c(Name = 'Test Portfolio', Portfolio__c = 'Test Portfolio', TerritoryId__c = objTerritory.Id);
        TestingUtility.insertWithAssert(objMarket, 'Portfolio not inserted');
        
        Map<String, List<Object>> mapUservalues = new Map<String, List<Object>>();
        mapUservalues.put('Sales_Role__c', new List<Object>{Label.AccountTeamDirectorSalesFunctionForRenewalOpp});
        
        List<User> users = (List<User>)TestingUtility.getRecords(new Map<String,Object>{'doInsert' => 'true','objName' => 'User', 'numberOfRecords'=> '1','mapFieldValues'=>mapUservalues});
        System.assertEquals(1, users.size());
        
        List<Building__C> buildings = new List<Building__C>();
        buildings.addAll(TestingUtility.createBuildings(
            new Map<String,Object>{
                'Email__c' => 'teste@example.com',
                'Market__c' => objMarket.Id,
                'Director_Portfolio_Sales__c' => users[0].Id,
                'Associate_Director_Market_Sales__c'=>users[0].Id,
                'Associate_Director_Portfolio_Sales__c'=>users[0].Id,
                'Senior_Associate_Market_Sales__c'=>users[0].Id
            }, 1)
        );

        insert buildings;
        Test.stopTest();
    }
    
    static testMethod void testGetLeadOwnerIdFromChosenAccount(){         
        List<Account> accounts = TestingUtility.createAccounts(1,'Test-Account', false);
        accounts[0].Named_Account_Segment__c = 'Global Account';
        accounts[0].Account_Manager_Lookup__c = UserInfo.getUserId();
        TestingUtility.insertListWithAssert(accounts);
        
        Opportunity primary = TestingUtility.createOpportunity(accounts[0].Id, true);
        Opportunity opportunityRecord = [
            SELECT Id, Name, AccountId, OwnerId, Account_Manager_Email__c, Account.OwnerId, Account.Owner.isActive, IsClosed
            FROM Opportunity 
            WHERE Id =: primary.Id
        ];

        Account acc = [SELECT Id FROM Account Where Id = :opportunityRecord.AccountId];
        Database.update(acc);

        Opportunity updatedOpportunityRecord = [
            SELECT Id, Name , AccountId, Account.Owner.IsActive, OwnerId, IsClosed
            FROM Opportunity 
            WHERE Id =: primary.Id
        ];

        Map<String, SObject> chosenSObjects = new Map<String, SObject>();
        LeanDataCustomInterface testInterface = new LeanDataCustomInterface();
        
        String strResult = testInterface.customRoutingRule((SObject)opportunityRecord, chosenSObjects, 'Update Account Owner');
        System.assert(strResult.equalsIgnoreCase('next node'));
        
        strResult =  testInterface.customRoutingRule((SObject)opportunityRecord, chosenSObjects, 'Add Opportunity Team Member');
        System.assert(strResult.equalsIgnoreCase('False'));
        
        strResult =  testInterface.customRoutingRule((SObject)updatedOpportunityRecord, chosenSObjects, 'Add Opportunity Team Member');
        System.assert(strResult.equalsIgnoreCase('False'));

        strResult =  testInterface.customRoutingRule((SObject)updatedOpportunityRecord, chosenSObjects, 'assign account to susie');
        System.assert(strResult.equalsIgnoreCase('Next Node'));
        
        strResult =  testInterface.customRoutingRule((SObject)new Opportunity() , chosenSObjects, 'Add Opportunity Team Member');
        System.assert(strResult.equalsIgnoreCase('False'));
        
        
        List<User> lstAccDirectorUsers = [SELECT Id FROM USER WHERE isActive = true AND Sales_Role__c = :Label.AccountTeamDirectorSalesFunctionForRenewalOpp];

        Database.insert(new AccountTeamMember(
            TeamMemberRole = Settings.getTeamRoleConfigSettings('LeanDataassigntoaccountteamdirector'),
            AccountId = acc.Id,
            UserId = lstAccDirectorUsers[0].Id
        ));

        strResult =  testInterface.customRoutingRule((SObject)updatedOpportunityRecord, chosenSObjects, 'Add Opportunity Team Member');


        strResult =  testInterface.customRoutingRule((SObject)opportunityRecord, chosenSObjects, 'Invalid Param');
        System.assert(strResult.equalsIgnoreCase('Next Node'));

        List<Building__C> lstBuilding = [SELECT Id FROM Building__c];
        opportunityRecord.Building__c = lstBuilding[0].Id;
        update opportunityRecord;

        strResult =  testInterface.customRoutingRule((SObject)opportunityRecord, chosenSObjects, 'Capture Opportunity Old Owner');
        System.assert(strResult.equalsIgnoreCase('Next Node'));

        List<User> lstUsers = new List<User>([SELECT Id FROM User WHERE IsActive = TRUE AND ProfileId = :UserInfo.getProfileId() AND Id <> :opportunityRecord.OwnerId LIMIT 1]);
        opportunityRecord.OwnerId = lstUsers[0].Id;

        strResult =  testInterface.customRoutingRule((SObject)opportunityRecord, chosenSObjects, 'Request Co-Owner MLB');
        System.assert(strResult.equalsIgnoreCase('Next Node'));

        strResult =  testInterface.customRoutingRule((SObject)opportunityRecord, chosenSObjects, 'Request Co-Owner ENT');
        System.assert(strResult.equalsIgnoreCase('Next Node'));

        opportunityRecord = [
            SELECT Id, Name, Account.OwnerId, Account.Owner.IsActive, Account.Named_Account_Segment__c,
                AccountId, OwnerId,Building__r.Associate_Director_Market_Sales__r.Id,Building__r.Associate_Director_Portfolio_Sales__r.Id,
                Building__r.Senior_Associate_Market_Sales__r.Id,Building__r.Director_Portfolio_Sales__r.Id, isClosed
            FROM Opportunity
            WHERE Id =: primary.Id
        ];

        strResult =  testInterface.customRoutingRule((SObject)opportunityRecord, chosenSObjects, 'co-owner for small portfolio manger');
        System.assert(strResult.equalsIgnoreCase('Next Node'));

        strResult =  testInterface.customRoutingRule((SObject)opportunityRecord, chosenSObjects, 'co-owner for large portfolio salesperson');
        System.assert(strResult.equalsIgnoreCase('Next Node'));

        strResult =  testInterface.customRoutingRule((SObject)opportunityRecord, chosenSObjects, 'co-owner for small portfolio salesperson');
        System.assert(strResult.equalsIgnoreCase('Next Node'));

        strResult =  testInterface.customRoutingRule((SObject)opportunityRecord, chosenSObjects, 'co-owner for large portfolio director');
        System.assert(strResult.equalsIgnoreCase('Next Node'));

        strResult =  testInterface.customRoutingRule((SObject)opportunityRecord, chosenSObjects, 'assign to account team director');
        System.assert(strResult.equalsIgnoreCase('True'));
        
        strResult =  testInterface.customRoutingRule((SObject)opportunityRecord, chosenSObjects, 'sales inquiry task assignment');

        delete [SELECT Id FROM OpportunityTeamMember WHERE OpportunityId =: opportunityRecord.Id];
        strResult =  testInterface.customRoutingRule((SObject)opportunityRecord, chosenSObjects, 'usa canada add opportunity team member');

        Map<String, OpportunityTeamMember> opportunityTeamMembers = new Map<String, OpportunityTeamMember>();
        for (OpportunityTeamMember item : [SELECT Id, TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId =: opportunityRecord.Id]) {
            opportunityTeamMembers.put(item.TeamMemberRole.toLowerCase(), item);
        }

        System.assertEquals(2, opportunityTeamMembers.size(), 'size of OpportunityTeamMember created records doesn\'t equal to 2');
        System.assert(opportunityTeamMembers.containsKey('account sales'), 'created OpportunityTeamMember record doesn\'t contain Account Sales team role');
        System.assert(strResult.equalsIgnoreCase('Next Node'));

        Database.insert(new Task(
            WhatId = primary.Id,
            WhoId = primary.Primary_Member__c,
            Building__c = lstBuilding[0].Id,
            Type = 'Sales Inquiry',
            Status = 'Not Started'
        ));

        opportunityRecord = [
            SELECT Id, AccountId, Account_Manager_Email__c,
                Account.OwnerId, Account.Owner.IsActive, Account.Named_Account_Segment__c, OwnerId, isClosed
            FROM Opportunity
            WHERE Id =: primary.Id
        ];

    }
    
    @isTest
    public static void verifyLeadCustomNodeUpdation(){
        
        List<Account> accounts = TestingUtility.createAccounts(1,'Test-Account', false);
        accounts[0].Named_Account_Segment__c = 'Global Account';
        accounts[0].Account_Manager_Lookup__c = UserInfo.getUserId();
        TestingUtility.insertListWithAssert(accounts);
        
        Opportunity primary = TestingUtility.createOpportunity(accounts[0].Id, true);
        Opportunity opportunityRecord = [
            SELECT Id, Name, AccountId, OwnerId, Account_Manager_Email__c, Account.OwnerId, Account.Owner.isActive, IsClosed
            FROM Opportunity 
            WHERE Id =: primary.Id
        ];     
        
        
        List<Building__C> lstBuilding = [SELECT Id FROM Building__c];
        opportunityRecord.Building__c = lstBuilding[0].Id;
        update opportunityRecord;
        List<Task> tasksList = new List<Task>();
         Task tsk = (new Task(
            WhatId = primary.Id,
            WhoId = primary.Primary_Member__c,
            Building__c = lstBuilding[0].Id,
            Type = 'Sales Inquiry'
        ));
        tasksList.add(tsk);
        
        
        Geography__c objGeography1 = new Geography__c(
            Name = 'Sangamner123, Maharashtra',
            City__c = 'Sangamner2456',
            Country__c = 'Indi2456politicala',
            District__c = 'Ahmednagar2456',
            Formatted_Address__c = 'Sangamner2476, Maharashtra 422605, India', 
            Geocode__Latitude__s = 85.5771397 ,
            Geocode__Longitude__s = 95.2079648,
            JSON__c = new GeographyHandlerTest().getJSONForGeography('Sangamner2456', 'Sangamner2456', 'Maharashtra2456', 'Indi2456politicala'),
            Location_Type__c = 'APPROXIMATE', 
            Place_ID__c = 'ChIJy2456M--wjs2456_-5cSkaI', 
            State__c = 'Maharashtra2456',
            CurrencyIsoCode = 'USD',
            Nearest_Building__c = lstBuilding[0].Id,
            Country_Code__c = 'USD'
        );
        TestingUtility.insertWithAssert(objGeography1);       
        
        Lead objLead = new Lead(
            LastName = 'Doe1', 
            FirstName = 'John1', 
            Company = 'infoway', 
            Email = 'johnDoe007_01@example.com', 
            LeadSource='weWork.com', 
            Generate_Journey__c = true,
            Country_Code__c = 'USD', 
            Lead_Source_Detail__c='Book A Tour Availability', 
            Building_Interested_In__c = lstBuilding[0].Id, 
            Interested_in_Number_of_Desks__c = 2
        );
        TestingUtility.insertWithAssert(objLead);

        SObject objLead1 = [
            SELECT Id, Country_Code__c, Country_Code_Geography__c, Territory_Name__c, Routing_Qualification_Result__c 
            FROM Lead 
            WHERE Id = :objLead.Id 
                AND IsConverted = FALSE
        ];
        Map<String, SObject> chosenSObjects = new Map<String, SObject>();

        String strResult = new LeanDataCustomInterface().customRoutingRule((SObject)objLead1, chosenSObjects, 'get geography as per country code');       
        System.assert(strResult.equalsIgnoreCase('Next Node'));
        System.assertEquals('USD' ,objLead1.get('Country_Code__c'));
        System.assertEquals(objGeography1.Id ,objLead1.get('Country_Code_Geography__c'));
        System.assertEquals('Test Territory' ,objLead1.get('Territory_Name__c'));
        
        User getUser = [SELECT Id,email FROM User WHERE Profile.Name = 'System Administrator' AND isActive = TRUE AND Id != :UserInfo.getUserId() LIMIT 1];
        Map<Id, User> users = new Map<Id, User>();
        users.put(getUser.id,getUser);
        objLead1.put('OwnerId', getUser.Id);
        List<Journey__c> lstJournyes = [SELECT Id, OwnerId FROM Journey__c WHERE Primary_Lead__c = :(Id)objLead1.get('Id')];
        System.assert(lstJournyes.size()  == 1,'Should always get one Journey record');
        System.assert(lstJournyes[0].OwnerId  != getUser.Id);
        
        strResult = new LeanDataCustomInterface().customRoutingRule((SObject)objLead1, chosenSObjects, 'update related journeys');  
        System.assert(strResult.equalsIgnoreCase('Next Node'));
        strResult = new LeanDataCustomInterface().customRoutingRule((SObject)objLead1, chosenSObjects, 'fire lead assignment rule');  
        System.assert(strResult.equalsIgnoreCase('Next Node'));
        
        strResult = new LeanDataCustomInterface().customRoutingRule((SObject)objLead1, chosenSObjects, 'get lead owner by assignment rule');  
        System.assert(strResult.equalsIgnoreCase('Next Node'));
        
        strResult = new LeanDataCustomInterface().customRoutingRule((SObject)objLead1, chosenSObjects, 'update related journeys without mql');  
        System.assert(strResult.equalsIgnoreCase('Next Node'));
        
        lstJournyes = [SELECT Id, OwnerId FROM Journey__c WHERE Primary_Lead__c = :(Id)objLead1.get('Id')];
        System.assert(lstJournyes.size() == 1);        
        User u = [select id,name,email from user where id=: UserInfo.getUserId()];
        LeanDataCustomInterface leanInt = new LeanDataCustomInterface();
        leanInt.handleSalesInquiryTask(primary, users, getUser.Id);
        try{
            leanInt.sendSalesInquiryEmail(tasksList, primary,u, u.Id);
            System.assert(false);
        }catch(Exception e){
            System.assertEquals('System.EmailException', e.getTypeName(), 'Should send email failed as some of the required fields where missing');
        }
    }  
}