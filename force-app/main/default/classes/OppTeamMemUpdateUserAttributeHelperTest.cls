@isTest
public class OppTeamMemUpdateUserAttributeHelperTest {
    
    @TestSetup
    static void setData(){
        Account newAccount = new Account();
        newAccount.Name = 'Test Acc';
        insert newAccount;       
        
        Opportunity objOpportunity = new Opportunity();
        objOpportunity.Name = 'Test Opp';
        objOpportunity.Accountid = newAccount.id;
        objOpportunity.StageName = 'Prospecting';
        objOpportunity.CloseDate = System.today()+3;
        insert objOpportunity;
        
        OpportunityTeamMember newTeamMember = new OpportunityTeamMember (OpportunityId = objOpportunity.id,UserId = UserInfo.getUserId(),TeamMemberRole = NULL, User_Attribute__c = null);
        insert newTeamMember;
    }
    
    @isTest
    public static void initData(){          
        User_Attribute__c userAttributeToInsert = new User_Attribute__c();
        userAttributeToInsert.User_Name__c = 'test';
        userAttributeToInsert.User__c = UserInfo.getUserId();
        userAttributeToInsert.As_of_Date__c = system.today();
        userAttributeToInsert.End_Date__c = System.today();
        userAttributeToInsert.RecordTypeId = Schema.SObjectType.User_Attribute__c.getRecordTypeInfosByName().get('User History').getRecordTypeId();
        insert userAttributeToInsert;          
        
        Map<Id,List<User_Attribute__c>> mapUserAttribute = new Map<Id,List<User_Attribute__c>>();
        List<User_Attribute__c> listUserAttribute = new List<User_Attribute__c>();
        listUserAttribute = [SELECT ID, USER_NAME__C,USER__C,AS_OF_DATE__C, END_DATE__C FROM USER_ATTRIBUTE__C];
        List<User_Attribute__c> listUserAttribute1 = new List<User_Attribute__c>();
        listUserAttribute1 = [SELECT ID, USER_NAME__C,USER__C,AS_OF_DATE__C, END_DATE__C FROM USER_ATTRIBUTE__C WHERE USER__C !=NULL and RECORDTYPE.NAME LIKE 'User History'];
        mapUserAttribute.put(listUserAttribute1[0].id, listUserAttribute1);
        
        Test.startTest();          
        OppTeamMemberUpdateUserAttributeHelper attHelper = new OppTeamMemberUpdateUserAttributeHelper();
        attHelper.setUserIdToUserAttributes(userAttributeToInsert,mapUserAttribute);
        mapUserAttribute.put(UserInfo.getUserId(), listUserAttribute1);
        attHelper.setUserIdToUserAttributes(userAttributeToInsert,mapUserAttribute);
        attHelper.getUserAttribute(Date.today(),listUserAttribute);
        Id getId = attHelper.getUserAttribute(Date.today(),new List<User_Attribute__c>());        
        Test.stopTest();
        System.assertEquals(null, getId, 'Should get null value');
    }
    
    @isTest
    public static void updateUserAttribute(){         
        Test.startTest();
        OppTeamMemberUpdateUserAttributeHelper userAttributeHelper = new OppTeamMemberUpdateUserAttributeHelper();     
        userAttributeHelper.oppTeamRolesToUpdateUserAttribute = new List<String>{'account manager'};
        List<OpportunityTeamMember> oppTeamMembers = [SELECT Name, OpportunityId, UserId, TeamMemberRole, User_Attribute__c FROM OpportunityTeamMember WHERE UserId =: UserInfo.getUserId()];
        boolean isFromBatch = Boolean.valueOf('true');
        oppTeamMembers.get(0).TeamMemberRole = 'Account Manager';
        update oppTeamMembers.get(0);
        userAttributeHelper.updateUserAttribute(oppTeamMembers, True);
        userAttributeHelper.updateUserAttribute(oppTeamMembers, False);
        Test.stopTest();
        System.assertEquals(oppTeamMembers.get(0), OppTeamMemberUpdateUserAttributeHelper.userIdToTeamMembers.get(UserInfo.getUserId()).get(0), 'when the parameter is true/false the OpportunityTeamMember list should have same records');
        System.assertEquals(1,oppTeamMembers.size(),'Should get Opportunity Team Member records greater than 0');
    }
    
    @isTest
    public static void getUserIdToUserAttributesMapTest(){
        OppTeamMemberUpdateUserAttributeHelper attHelper = new OppTeamMemberUpdateUserAttributeHelper();
        OppTeamMemberUpdateUserAttributeHelper.userIdToTeamMembers = new Map<Id, List<OpportunityTeamMember>>{UserInfo.getUserId()=> new List<OpportunityTeamMember>{new OpportunityTeamMember()}};
        Test.startTest();
        Map<Id, List<User_Attribute__c>> userAttribute = attHelper.getUserIdToUserAttributesMap();
        Test.stopTest(); 
        System.assertEquals(new List<OpportunityTeamMember>{new OpportunityTeamMember()}, OppTeamMemberUpdateUserAttributeHelper.userIdToTeamMembers.get(UserInfo.getUserId()),'both should have a same list of OpportunityTeamMember records');
        System.assertEquals(new Map<Id, List<User_Attribute__c>>(), userAttribute, 'The map should be empty');
    }
    
    @isTest
    public static void storeValidTeamMembers(){ 
        
        Test.startTest();     
        OppTeamMemberUpdateUserAttributeHelper userAttributeHelper = new OppTeamMemberUpdateUserAttributeHelper();
		OpportunityTeamMember getTeamMember = [SELECT Id, OpportunityId, UserId, User_Attribute__c, TeamMemberRole FROM OpportunityTeamMember WHERE UserId=:UserInfo.getUserId() LIMIT 1];
                
        boolean isFromBatch = Boolean.valueOf('true');
        userAttributeHelper.storeValidTeamMembers(getTeamMember, isFromBatch);
        getTeamMember.TeamMemberRole = 'Account Manager';
        update getTeamMember;
        
        userAttributeHelper.oppTeamRolesToUpdateUserAttribute = new List<String>{'account manager'};
        userAttributeHelper.storeValidTeamMembers(getTeamMember, isFromBatch);
        
        Test.stopTest();   
        System.assertEquals(OppTeamMemberUpdateUserAttributeHelper.userIdToTeamMembers.containskey(getTeamMember.UserId), true, 'The userIdToTeamMembers variable in the main class should get updated');
        System.assertEquals(OppTeamMemberUpdateUserAttributeHelper.userIdToTeamMembers.get(getTeamMember.UserId).get(0).TeamMemberRole, 'Account Manager', 'The userIdToTeamMembers variable should have a TeamMemberRole as Account Manager');   
        System.assertEquals(OppTeamMemberUpdateUserAttributeHelper.userIdToTeamMembers.keyset(),new set<Id>{UserInfo.getUserId()}, 'Both should have same set of userIds');
    }
}