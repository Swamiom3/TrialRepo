@isTest
public class FieldMappingsHelperTest {  
    @testSetup
    public static void initData(){
        Test.startTest();
        Map<String, List<Object>> mapUservalues=   new Map<String, List<Object>>();
        mapUservalues.put('Sales_Role__c', new List<Object>{'Other', 'Inbound'});
        List<User> lstUsers = (List<User>)TestingUtility.getRecords(new map<String,object>{
            'doInsert' => 'true',
                'objName' => 'User',
                'numberOfRecords'=> '2',
                'mapFieldValues'=>mapUservalues});
        Test.stopTest();
        List<User> lstUsers1 = [SELECT Id, Sales_Role__c From User WHERE Sales_Role__c != NULL LIMIT 2];
        System.assertEquals(2, lstUsers.size());
    }
   /****************************************************************************************************************************
        Author 				: Chandra teja
        Description  		: This test method used to validate all the mapping methods.  
        Created Date		: 24 March 2020
        Last Modified By 	: 
        Last Modified Date  : 
   *****************************************************************************************************************************/
    @isTest
    public static void verifyAllMappings(){
        Test.startTest();
        List<User> lstUsers = [SELECT Id, Sales_Role__c From User WHERE Sales_Role__c != NULL ORDER BY CreatedDate DESC LIMIT 2];   
        Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'Wework System Administrator'];  
        List<id> lstUserIds = new List<id>();
        Set<Id> setUserIds = new Set<Id>();
        for(User obj : lstUsers)
        {
            lstUserIds.add(obj.id);
        }
        setUserIds.addAll(lstUserIds);
        verifyMappingWhenBothObjectPresent(lstUsers);
        verifyMappingWhenSourceIDPresent(lstUsers[0], objProfile.Id);
        verifyMappingWhenListOfSourceObjectPresent(lstUserIds, objProfile.Id);
        verifyMappingWhenSetOfSourceObjectPresent(setUserIds, objProfile.Id);
        verifyMappingWhenSourceandDestinationPresent(lstUsers[0], objProfile.Id);
        Test.stopTest();        
    }  
     /****************************************************************************************************************************
        Author 				: Chandra teja
        Description  		: This test method used to create dynamic mapping When both object Present means already inserted .  
        Created Date		: 26 March 2020
        Last Modified By 	:  
        Last Modified Date  : 
   *****************************************************************************************************************************/
    public static void verifyMappingWhenBothObjectPresent(List<User>  lstUsers){
        sObject mappedObj = FieldMappingsHelper.getMappings(lstUsers[0].id , lstUsers[1].Id ,'FieldMappings_UserToUser');
        UPSERT mappedObj;        
        List<User> lstUpdatedUsers = [SELECT  Sales_Role__c, DelegatedApproverId FROM User WHERE Id IN :lstUsers];       
        System.assertEquals(lstUpdatedUsers[0].Sales_Role__c , lstUpdatedUsers[1].Sales_Role__c);
        if(lstUsers[0].Id == lstUpdatedUsers[0].Id){
            System.assertEquals(lstUpdatedUsers[0].Id , lstUpdatedUsers[1].DelegatedApproverId);
        }else{
            System.assertEquals(lstUpdatedUsers[1].Id , lstUpdatedUsers[0].DelegatedApproverId);
        }
    }
    
    /****************************************************************************************************************************
        Author 				: Chandra teja
        Description  		: This test method used to verify Mapping When Source Object id is passed as argument for mapping and 
							  new destination object is created at the time of mapping.
        Created Date		: 24 March 2020
        Last Modified By 	: 
        Last Modified Date  : 
   *****************************************************************************************************************************/
    public static void verifyMappingWhenSourceIDPresent(User objUser, Id profileId){         
        sObject mappedObj = FieldMappingsHelper.getMappings(objUser.id,'FieldMappings_UserToUser');
        mapRequiredFields(mappedObj, profileId);
        UPSERT mappedObj;
        User updatedUser = [SELECT  Sales_Role__c FROM User WHERE DelegatedApproverId = :objUser.Id LIMIT 1];       
        System.assertEquals(objUser.Sales_Role__c , updatedUser.Sales_Role__c);
    }
   	/****************************************************************************************************************************
        Author 				: Chandra teja
        Description  		: This test method used to create dynamic mapping When list of Source Object id pass as argument.
        Created Date		: 26 March 2020
        Last Modified By 	: 
        Last Modified Date  : 
   *****************************************************************************************************************************/
    public static void verifyMappingWhenListOfSourceObjectPresent(List<id> lstUserIds, Id profileId){
        Map<Id,sObject> mappedObject = FieldMappingsHelper.getMappings(lstUserIds,'FieldMappings_UserToUser');
        for(sObject objSObject: mappedObject.values()){
            mapRequiredFields(objSObject, profileId);
        }
        INSERT mappedObject.values();
        Map<Id, User> mapUsers= new Map<Id, User>([SELECT Id, Sales_Role__c, DelegatedApproverId FROM USER WHERE Id IN: lstUserIds OR DelegatedApproverId IN: lstUserIds]);
        for(User objUser: mapUsers.values()){
            if(objUser.DelegatedApproverId != NULL){
                System.assertEquals(mapUsers.get(objUser.DelegatedApproverId).Sales_Role__c, objUser.Sales_Role__c);
            }    
        }
    }
    
   /****************************************************************************************************************************
        Author 				: Chandra teja
        Description  		: This test method used to create dynamic mapping When Set of Source Object id pass as argument.
        Created Date		: 26 March 2020
        Last Modified By 	: 
        Last Modified Date  : 
   *****************************************************************************************************************************/
    public static void verifyMappingWhenSetOfSourceObjectPresent(Set<Id> setUserIds, Id profileId){
        Map<Id,sObject> mappedObject = FieldMappingsHelper.getMappings(setUserIds,'FieldMappings_UserToUser');
        for(sObject objSObject: mappedObject.values()){
            mapRequiredFields(objSObject, profileId);
        }
        INSERT mappedObject.values();       
        Map<Id, User> mapUsers= new Map<Id, User>([SELECT Id, Sales_Role__c, DelegatedApproverId FROM USER WHERE Id IN: setUserIds OR DelegatedApproverId IN: setUserIds]);
        for(User objUser: mapUsers.values()){
            if(objUser.DelegatedApproverId != NULL){
                System.assertEquals(mapUsers.get(objUser.DelegatedApproverId).Sales_Role__c, objUser.Sales_Role__c);
            }    
        } 
    }    
   /****************************************************************************************************************************
        Author 				: Chandra teja
        Description  		: This test method used to create dynamic mapping When Source Object id pass as argument and Destination object.
        Created Date		: 26 March 2020
        Last Modified By 	: 
        Last Modified Date  : 
   *****************************************************************************************************************************/
    public static void verifyMappingWhenSourceandDestinationPresent(User objUser, Id profileId){
        User objNewUser = new User();
        objNewUser.Sales_Pod__c = 'ARG_001';
        sObject mappedObject = FieldMappingsHelper.getMappings(objUser.id,objNewUser,'FieldMappings_UserToUser');     
        mapRequiredFields(mappedObject, profileId);
        INSERT mappedObject;
        User updatedUser = [SELECT  Sales_Role__c FROM User WHERE DelegatedApproverId = :objUser.Id LIMIT 1];       
        System.assertEquals(objUser.Sales_Role__c , updatedUser.Sales_Role__c);  
    } 
       /****************************************************************************************************************************
        Author 				: Chandra teja
        Description  		: This test method used to map required fields on user record.
        Created Date		: 27 March 2020
        Last Modified By 	: 
        Last Modified Date  : 
   *****************************************************************************************************************************/
    public static void mapRequiredFields(sObject userRecordMap, Id profileId){
        userRecordMap.put('alias','te');
        userRecordMap.put('LastName','testLastName');
        userRecordMap.put('Username',TestingUtility.createStringValue()+'standarduser@test.com');
        userRecordMap.put('Email', 'testUserEmail' +TestingUtility.createStringValue() + '@test.com' );
        userRecordMap.put('ProfileId',profileId);
        userRecordMap.put('EmailEncodingKey','ISO-8859-1');
        userRecordMap.put('LanguageLocaleKey','en_US');
        userRecordMap.put('LocaleSidKey','en_US');
        userRecordMap.put('TimeZoneSidKey','America/Los_Angeles');
    }
}