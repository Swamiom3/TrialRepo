@isTest
public class CreateOpportunityControllerTests {
    public static List<Lead> lstLeads = new List<Lead>();
    public static List<Account> lstAccounts = new List<Account>();
    public static List<Contact> lstContacts = new List<Contact>();
    public static List<Building__c> lstBuildings = new List<Building__c>();
    public static List<User> lstUser = new List<User>();
    public static List<Journey__c> lstJourneys = new List<Journey__c>();
    public static Account orgAccRec;

    @TestSetup
    static void initData(){
        Test.startTest();
        OperatingHours objOpHour = new OperatingHours(Name = 'EDT: Standard 9AM - 5PM Weekday');
        insert objOpHour;
        Account orgAccRec;
        Profile objProfile1 = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        Profile objProfile2 = [SELECT Id FROM Profile WHERE Name = 'WeWork System Administrator'];
        User objUser1 = new User(Alias = 'testU', Email = 'testUserName1@example.com',
                                 EmailEncodingKey = 'UTF-8', LastName = 'User', LanguageLocaleKey = 'en_US',
                                 LocaleSidKey = 'en_US', ProfileId = objProfile1.Id, IsActive = true,
                                 TimeZoneSidKey = 'America/Los_Angeles', UserName = 'testUserName1@example.com',CommunityNickname = TestingUtility.createUserCommunityName());
        lstUser.add(objUser1);

        User objUser2 = new User(Alias = 'testU1',Email = 'testUser1LeadOwner@example.com',
                                 EmailEncodingKey = 'UTF-8', LastName = 'User', LanguageLocaleKey = 'en_US',
                                 LocaleSidKey = 'en_US', ProfileId = objProfile2.Id, IsActive = true,
                                 TimeZoneSidKey = 'America/Los_Angeles', UserName = 'testUser1LeadOwner@example.com',CommunityNickname = TestingUtility.createUserCommunityName());
        lstUser.add(objUser2);
        TestingUtility.insertListWithAssert(lstUser);

        //Groups
        List<Group>  lstGroup = new List<Group>();
        Group testGroup = new Group(Name = 'New_Org_Request_Recipient_Queue', type = 'Queue');
        lstGroup.add(testGroup);
        TestingUtility.insertListWithAssert(lstGroup);
        System.runAs(new User(Id = UserInfo.getUserId())){
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SobjectType = 'Case');
            insert testQueue;
            GroupMember member = new GroupMember();
            member.UserOrGroupId = lstUser[1].Id;
            member.GroupId = testGroup.Id;
            insert member;

        }
        //Buildings
        lstBuildings.add(new Building__c(Name = 'Building1', UUID__c = '15318_1', Email__c = 'Building1@example.com'));
        TestingUtility.insertListWithAssert(lstBuildings);
        //Accounts with Unomy
        List<Account> lstAccounts = (List<Account>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Account', 'numberOfRecords' => 6});
       
        orgAccRec = lstAccounts[0];
        Account orgAccRec2;
        Account objBill1; 
        Account objBill2;
        Account objAcc1;
        Account objAcc2;
        orgAccRec2 = lstAccounts[1];
        objBill1 = lstAccounts[2];
        objBill2 = lstAccounts[3];
        
        for (Integer index = 0 ; index < lstAccounts.size() ; index++){
            lstAccounts[index].Number_of_Full_Time_Employees__c = 1000;
            if(index < 4){
                lstAccounts[index].Account_Type__c = 'Org';
            }else if(index == 4){
                lstAccounts[index].ParentId = orgAccRec.Id;
                lstAccounts[index].UUID__c = 'ABC123-62481';
                lstAccounts[index].Nickname__c = 'strAcc';
                lstAccounts[index].Account_Type__c = 'Sales';
            }else if(index == 5){
                lstAccounts[index].ParentId = orgAccRec2.Id;
                lstAccounts[index].UUID__c = 'ABC123-62483';
                lstAccounts[index].Nickname__c = 'strAcc2';
                lstAccounts[index].Account_Type__c = 'Sales';
            }
        }
        
        TestingUtility.updateListWithAssert(lstAccounts);
        objAcc1 = lstAccounts[4];
        objAcc2 = lstAccounts[5];
        
        //Insert Test Leads
        List<Lead> lstLeads = (List<Lead>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Lead', 'numberOfRecords' => 3, 'doInsert' => false});
        TestingUtility.insertListWithAssert(lstLeads);

        List<Contact> lstContacts = (List<Contact>)TestingUtility.getRecords(new Map<String, Object>{'objName' => 'Contact', 'doInsert' => false, 'numberOfRecords' => 6});
        for( Integer index = 0 ; index < lstContacts.size() ; index++ ){
            lstContacts[index].Status__c = 'active';
            if(index == 0){
                lstContacts[index].AccountId = orgAccRec.Id;
            }else if(index == 1){
                lstContacts[index].AccountId = objAcc1.Id;
            }else if(index == 2){
                lstContacts[index].AccountId = objBill1.Id;
            }else if(index == 3){
                lstContacts[index].AccountId = NULL;
            }else if(index == 4){
                lstContacts[index].AccountId = objAcc2.Id;
                lstContacts[index].email = 'john.con5@example.com';
            }else if(index == 5){
                lstContacts[index].AccountId = objBill2.Id;
                lstContacts[index].email = 'john.con6@example.com';
            }
        }
        TestingUtility.insertListWithAssert(lstContacts);
           String strCreateAccountDat = String.valueOf(CreateOpportunityController.getCreateOpportunityData(lstAccounts[0].Id, null).data);
           String strCreateContactData = String.valueOf(CreateOpportunityController.getCreateOpportunityData(lstContacts[0].Id, null).data);
        Test.stopTest();

        Map<String, List<Object>> mapField = new Map<String, List<Object>>();
        Map<String, Object> mapData = new Map<String, Object>();
    }

    /************************************************************************************************************************************
        Author          : Dipak Pawar
        Description     : This method tests the getRelatedRecordDetails() function.
        Created Date    : 23 June 2018
    **************************************************************************************************************************************
        Author          : Gad Sharon
        Date Changed    : 1 Sep 2019
        Description     : Changed the function to check only accounts to avoid 101 SOQL limit issue.
    **************************************************************************************************************************************/
     public static void getRelatedRecordDetailsAccounts(Map<String, Account> mapAccounts, List<Id> lstReservationIds){

        String strCreateOpportunityData = String.valueOf(CreateOpportunityController.getCreateOpportunityData(mapAccounts.get('orgAcc').Id, null).data);
        Map<String, object> mapOfCreateOpportunityData = (Map<String, object>)JSON.deserializeUntyped(strCreateOpportunityData);
        Map<String, object> mapOfUltimateParentAccountRecord = (Map<String, object>)mapOfCreateOpportunityData.get('ultimateParentAccountRecord');
        System.assertEquals(mapAccounts.get('orgAcc').Id, mapOfUltimateParentAccountRecord.get('Id'));
        
        strCreateOpportunityData = String.valueOf(CreateOpportunityController.getCreateOpportunityData(mapAccounts.get('orgAcc').Id, lstReservationIds).data);
        mapOfCreateOpportunityData = (Map<String, object>)JSON.deserializeUntyped(strCreateOpportunityData);
        mapOfUltimateParentAccountRecord = (Map<String, object>)mapOfCreateOpportunityData.get('ultimateParentAccountRecord');
        System.assertEquals(mapAccounts.get('salesAcc1').Id, mapOfUltimateParentAccountRecord.get('Id'));

        strCreateOpportunityData = String.valueOf(CreateOpportunityController.getCreateOpportunityData(mapAccounts.get('salesAcc').Id, null).data);
        mapOfCreateOpportunityData = (Map<String, object>)JSON.deserializeUntyped(strCreateOpportunityData);
        mapOfUltimateParentAccountRecord = (Map<String, object>)mapOfCreateOpportunityData.get('ultimateParentAccountRecord');
        System.assertEquals(mapAccounts.get('salesAcc').Id, mapOfUltimateParentAccountRecord.get('Id'));
        
        strCreateOpportunityData = String.valueOf(CreateOpportunityController.getCreateOpportunityData(mapAccounts.get('billAcc').Id, null).data);
        mapOfCreateOpportunityData = (Map<String, object>)JSON.deserializeUntyped(strCreateOpportunityData);
        mapOfUltimateParentAccountRecord = (Map<String, object>)mapOfCreateOpportunityData.get('ultimateParentAccountRecord');
        System.assertEquals(mapAccounts.get('billAcc').Id, mapOfUltimateParentAccountRecord.get('Id'));

        strCreateOpportunityData = String.valueOf(CreateOpportunityController.getCreateOpportunityData(mapAccounts.get('billAcc1').Id, null).data);
        mapOfCreateOpportunityData = (Map<String, object>)JSON.deserializeUntyped(strCreateOpportunityData);
        mapOfUltimateParentAccountRecord = (Map<String, object>)mapOfCreateOpportunityData.get('ultimateParentAccountRecord');
        System.assertEquals(mapAccounts.get('billAcc1').Id, mapOfUltimateParentAccountRecord.get('Id'));
    }
    
    /************************************************************************************************************************************
        Author          : Dipak Pawar
        Description     : This method tests the getRelatedRecordDetails() function.
        Created Date    : 23 June 2018
    **************************************************************************************************************************************
        Author          : Gad Sharon
        Date Changed    : 1 Sep 2019
        Description     : Changed the function to check only contacts to avoid 101 SOQL limit issue.
    **************************************************************************************************************************************/
    public static void getRelatedRecordDetailsContacts(Map<String, Account> mapAccounts, Map<String, Contact> mapContacts){

        String strCreateOpportunityData = String.valueOf(CreateOpportunityController.getCreateOpportunityData(mapContacts.get('objOrgCon').Id, null).data);
        Map<String, object> mapOfCreateOpportunityData = (Map<String, object>)JSON.deserializeUntyped(strCreateOpportunityData);
        Map<String, object> mapOfUltimateParentAccountRecord = (Map<String, object>)mapOfCreateOpportunityData.get('ultimateParentAccountRecord');
        System.assertEquals(mapAccounts.get('orgAcc').Id, mapOfUltimateParentAccountRecord.get('Id'));

        strCreateOpportunityData = String.valueOf(CreateOpportunityController.getCreateOpportunityData(mapContacts.get('objSalesCon').Id, null).data);
        mapOfCreateOpportunityData = (Map<String, object>)JSON.deserializeUntyped(strCreateOpportunityData);
        mapOfUltimateParentAccountRecord = (Map<String, object>)mapOfCreateOpportunityData.get('ultimateParentAccountRecord');
        System.assertEquals(mapAccounts.get('salesAcc').Id, mapOfUltimateParentAccountRecord.get('Id'));

        strCreateOpportunityData = String.valueOf(CreateOpportunityController.getCreateOpportunityData(mapContacts.get('objBillCon').Id, null).data);
        mapOfCreateOpportunityData = (Map<String, object>)JSON.deserializeUntyped(strCreateOpportunityData);
        mapOfUltimateParentAccountRecord = (Map<String, object>)mapOfCreateOpportunityData.get('ultimateParentAccountRecord');
        System.assertEquals(mapAccounts.get('billAcc').Id, mapOfUltimateParentAccountRecord.get('Id'));

        if(mapContacts.get('objConNoAcc') != null){
          strCreateOpportunityData =  String.valueOf(CreateOpportunityController.getCreateOpportunityData(mapContacts.get('objConNoAcc').Id, null).data);
        }
        
        strCreateOpportunityData = String.valueOf(CreateOpportunityController.getCreateOpportunityData(mapContacts.get('objBillCon1').Id, null).data);
        mapOfCreateOpportunityData = (Map<String, object>)JSON.deserializeUntyped(strCreateOpportunityData);
        mapOfUltimateParentAccountRecord = (Map<String, object>)mapOfCreateOpportunityData.get('ultimateParentAccountRecord');
        System.assertEquals(mapAccounts.get('billAcc1').Id, mapOfUltimateParentAccountRecord.get('Id'));
    }
    
    /************************************************************************************************************************************
        Author          : Dipak Pawar
        Description     : This method tests the getRelatedRecordDetails() function.
        Created Date    : 23 June 2018
    **************************************************************************************************************************************
        Author          : Gad Sharon
        Date Changed    : 1 Sep 2019
        Description     : Changed the function to check only journeys to avoid 101 SOQL limit issue.
    **************************************************************************************************************************************/
    public static void getRelatedRecordDetailsJourneys(Map<String, Account> mapAccounts, Map<String, Journey__c> mapJourneys){
        
        String strCreateOpportunityData = String.valueOf(CreateOpportunityController.getCreateOpportunityData(mapJourneys.get('objOrgJourney').Id, null).data);
        Map<String, object> mapOfCreateOpportunityData = (Map<String, object>)JSON.deserializeUntyped(strCreateOpportunityData);
        Map<String, object> mapOfUltimateParentAccountRecord = (Map<String, object>)mapOfCreateOpportunityData.get('ultimateParentAccountRecord');
        System.assertEquals(mapAccounts.get('orgAcc').Id, mapOfUltimateParentAccountRecord.get('Id'));

        strCreateOpportunityData = String.valueOf(CreateOpportunityController.getCreateOpportunityData(mapJourneys.get('objSalesJourney').Id, null).data);
        mapOfCreateOpportunityData = (Map<String, object>)JSON.deserializeUntyped(strCreateOpportunityData);
        mapOfUltimateParentAccountRecord = (Map<String, object>)mapOfCreateOpportunityData.get('ultimateParentAccountRecord');
        System.assertEquals(mapAccounts.get('salesAcc').Id, mapOfUltimateParentAccountRecord.get('Id'));

        strCreateOpportunityData = String.valueOf(CreateOpportunityController.getCreateOpportunityData(mapJourneys.get('objBillJourney').Id, null).data);
        mapOfCreateOpportunityData = (Map<String, object>)JSON.deserializeUntyped(strCreateOpportunityData);
        mapOfUltimateParentAccountRecord = (Map<String, object>)mapOfCreateOpportunityData.get('ultimateParentAccountRecord');
        System.assertEquals(mapAccounts.get('billAcc').Id, mapOfUltimateParentAccountRecord.get('Id'));

        strCreateOpportunityData = String.valueOf(CreateOpportunityController.getCreateOpportunityData(mapJourneys.get('objOrgJourneyLead').Id, null).data);
        mapOfCreateOpportunityData = (Map<String, object>)JSON.deserializeUntyped(strCreateOpportunityData);
        mapOfUltimateParentAccountRecord = (Map<String, object>)mapOfCreateOpportunityData.get('ultimateParentAccountRecord');
        System.assertEquals(NULL, mapOfUltimateParentAccountRecord);

        strCreateOpportunityData = String.valueOf(CreateOpportunityController.getCreateOpportunityData(mapJourneys.get('objConJourney').Id, null).data);
        mapOfCreateOpportunityData = (Map<String, object>)JSON.deserializeUntyped(strCreateOpportunityData);
        mapOfUltimateParentAccountRecord = (Map<String, object>)mapOfCreateOpportunityData.get('ultimateParentAccountRecord');
        System.assertEquals(NULL, mapOfUltimateParentAccountRecord);

        strCreateOpportunityData = String.valueOf(CreateOpportunityController.getCreateOpportunityData(mapJourneys.get('objOrgJourneyLead2').Id, null).data);
        mapOfCreateOpportunityData = (Map<String, object>)JSON.deserializeUntyped(strCreateOpportunityData);
        mapOfUltimateParentAccountRecord = (Map<String, object>)mapOfCreateOpportunityData.get('ultimateParentAccountRecord');
        System.assertEquals(NULL, mapOfUltimateParentAccountRecord);
    }
   
   /************************************************************************************************************************************
        Author          : Dipak Pawar
        Description     : This method tests the getRelatedRecordDetails() function.
        Created Date    : 23 June 2018
   **************************************************************************************************************************************/
    public static testMethod void getRelatedRecordDetailsForLead(){
        test.startTest();
        Lead objOrgLead;
        Lead objOrgLead1;
        Lead objOrgLead2;

        for(Lead objLead :[SELECT LastName, FirstName, Email, Company, LeadSource FROM Lead]){
            if(objLead.Email == 'john.smith1@example.com'){
                objOrgLead=objLead;
            }else if(objLead.Email == 'john.smith2@example.com'){
                objOrgLead1=objLead;
            } else if(objLead.Email == 'john.smith3@example.com'){
                objOrgLead2=objLead;
            }
        }

        System.assert(objOrgLead.Id != null);
        String strCreateOpportunityData = String.valueOf(CreateOpportunityController.getCreateOpportunityData(objOrgLead.Id, null).data);
        System.assertNotEquals(NULL, strCreateOpportunityData);

        System.assert(objOrgLead1.Id != null);
        strCreateOpportunityData = String.valueOf(CreateOpportunityController.getCreateOpportunityData(objOrgLead1.Id, null).data);
        System.assertNotEquals(NULL, strCreateOpportunityData);

        System.assert(objOrgLead2.Id != null);
        strCreateOpportunityData = String.valueOf(CreateOpportunityController.getCreateOpportunityData(objOrgLead2.Id, null).data);
        System.assertNotEquals(NULL, strCreateOpportunityData);
        test.stopTest();
    }  

    /************************************************************************************************************************************
        Author              :   Priyanka Ambre
        Description         :   This test method is used to verify CreateOpportunity() when we pass Opportunity Record to the Method .
        Created Date        :   23 July 2018
        Issue No            :   ST-2486
    ***************************************************************************************************************************************/
    
    static testMethod void verifyCreateEnterpriseOpportunity(){
        List<Id> lstReservationIds = new List<Id>();
        List<Id> listOfIds = new List<Id>();

        List<Building__c> lstBuildings = [SELECT Id, Name FROM Building__c];

        Contact objOrgCon = [SELECT LastName, FirstName, UUID__c, AccountId, Email FROM Contact WHERE Email = 'john1.Contact@example.com' LIMIT 1];

        Opportunity objOppRec = new Opportunity(
            Do_Not_Create_Opportunity_Role__c = true,
            AccountId = objOrgCon.AccountId,
            LeadSource = 'WeWork.com',
            StageName = 'Qualifying',
            Decision_Maker__c = null,
            Primary_Member__c = objOrgCon.Id,
            Interested_in_Number_of_Desks__c = 0,
            Building__c = lstBuildings[0].Id,
            CloseDate = system.today().addDays(5)

        );
        Test.startTest();
        DatabaseResult result = CreateOpportunityController.createEnterpriseOpportunity(objOppRec,lstReservationIds,'USD');
        Opportunity objOppResponse =  (Opportunity)result.data;
        System.assertNotEquals(null, objOppResponse.Id);
        System.assertEquals(lstBuildings[0].Id, objOppResponse.Building__c);
        Test.stopTest();
    }
    
    
    public static testMethod void getPicklistValuesTest(){
        List<DependentPicklistController.PicklistEntryWrapper> optionlist = CreateOpportunityController.getPicklistValues('StageName');
        System.assertEquals(10, optionlist.size(), 'Stage name picklist should have 10 values');
    }
    
    public static testMethod void setPriceBookEntryNameTest(){
        String priceBookName = CreateOpportunityController.setPriceBookEntryName('Design & Build');
        System.assertEquals('PxWe', priceBookName);
    }
    
}