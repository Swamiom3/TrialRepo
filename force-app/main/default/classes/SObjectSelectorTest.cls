/************************************************************************************************************************************
Author      :   Vamsi
Description :   This class provides sufficient test coverage for SObjectSelector class
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           25 Nov 2021         Vamsi             Initial Developement
**************************************************************************************************************************************/
@isTest
public class SObjectSelectorTest extends SObjectSelector{
    
    public SObjectSelectorTest(Schema.SObjectType sObjectType){
        super(sObjectType);
    }
  
    @isTest
    static void addRequiredFiltersTest(){
        Schema.SObjectType SchemaAccount = Account.sObjectType;
        SObjectSelector testObjSelector = new SObjectSelectorTest(SchemaAccount);
        
        String filetr = testObjSelector.addRequiredFilters(true);
        System.assertEquals('', filetr, 'Required Filter Should be empty');
        
        List<String> fields = new List<String>();
        Map<String,Schema.SObjectField> fieldMap = Account.SObjectType.getDescribe().fields.getMap();
        for(String field : fieldMap.keyset()){
            if(field != Account.Tier__c.getDescribe().getLabel()){
              fields.add(fieldMap.get(field).getDescribe().getName());
            }
        }
        List<Id> ids = new List<Id>();
        List<SObject> objectWithEmptyIds = testObjSelector.getSObjectByIds(fields, ids);
        Account account = new Account();
        account.Name = 'TestAccount';
        insert account;
        ids.add(account.Id);
        List<SObject> objectWithListIds = testObjSelector.getSObjectByIds(new List<String>{'Name','Id'}, ids);

        List<SObject> objectWithSingleId = testObjSelector.getSObjectByIds(new List<String>{'Name','Id'}, account.Id);
        
        List<String> objects = new List<String>{'TestAccount'};
        List<String> objnames = new List<String>();
        List<SObject> objectWithListOfName = testObjSelector.getSObjectByName(fields,objects,true);
        List<SObject> objectWithEmptyListOfName = testObjSelector.getSObjectByName(fields,objnames,true);
        
        List<SObject> objectWithoutFilters = testObjSelector.getSObjectsWithoutFilters(fields);
        
        List<SObject> listOfSObjectByNames = testObjSelector.getSObjectByName(fields,objects.get(0),true);
        List<SObject> listOfSObjectWithoutNames = testObjSelector.getSObjectByName(fields,'',false);
        
        List<SObject> objectWithWhereClause = testObjSelector.getSObjects(fields,'');
        
        List<SObject> filterByIds = testObjSelector.getSObjects(fields,'Id',account.Id,false,1);
        
        List<Object> bind = new List<Object>();
        bind.add(account.Name);
        bind.add(account.Id);
        testObjSelector.getSObjects(fields,'Name =:test AND Id =:test',bind,'Name');
        
        testObjSelector.getSObjects(fields,'Name =:test AND Id =:test',bind,1);
        
        List<SObject> bindingList = testObjSelector.getSObjects(fields,'Name =:test AND Id =:test',bind);
        
        testObjSelector.getSObjects('Name =:test AND Id =:test',bind);
        
        String StringField = 'SELECT Name,Id FROM Account WHERE Name = TestAccount';
        Integer allRecords = [SELECT Id FROM Account].size();
        
        List<Object> innerBinding = new List<Object>();
        innerBinding.add('Territory Co-Prime');
        List<Object> allBinding = new List<Object>();
        allBinding.add('Territory Co-Prime');
        allBinding.add(account.Id);
        List<String> newFields = new List<String>{ 'Id', 'Co_Prime_Region__c', 'Co_Prime__c'};
        List<SObject> listOfSObjectsWithChilds = testObjSelector.getSObjectsWithChilds(newFields, 'SELECT Id, Region__c FROM AccountTeamMembers', 'TeamMemberRole =:teamMemberRoles', 'Id =:accountIds', innerBinding, allBinding);
        
        String listOfObjectWithMultipleBindings = testObjSelector.normalizeWhereClauseForOuterQueryMultipleBindings('Id IN :accountIds',allBinding.size(),innerBinding.size());
        
        System.assertEquals(allRecords, objectWithoutFilters.size(), 'Should get all Accounts');
        System.assertEquals(allRecords, objectWithWhereClause.size(), 'Should get all Accounts');
        System.assertEquals(null, objectWithEmptyIds, 'There shouldn\'t be any records');
        System.assertEquals([SELECT Name,Id FROM Account WHERE Id IN : ids], objectWithListIds, 'Should get 1 or More Records');
        System.assertEquals([SELECT Name,Id FROM Account WHERE Id =: account.Id LIMIT 1], objectWithSingleId, 'Should get 1 Record');
        System.assertEquals([SELECT Name FROM Account WHERE Name = 'TestAccount'].size(), objectWithListOfName.size(), 'Should get atleast 1 Record');
        System.assertEquals(null, objectWithEmptyListOfName, 'List should be Empty');
        System.assertEquals(true, bindingList.size()>0, 'List should contain atleast 1 Record');
        System.assertEquals([SELECT Name FROM Account WHERE Name = 'TestAccount'].size(), listOfSObjectByNames.size(), 'List must have atleast 1 Record');
        System.assertEquals(null, listOfSObjectWithoutNames, 'List should be empty');
        System.assertEquals(account.Id, filterByIds.get(0).Id, 'Record isn\'t available in the List');
        System.assertEquals([SELECT Id, Co_Prime_Region__c, Co_Prime__c, (SELECT Id, Region__c FROM AccountTeamMembers WHERE TeamMemberRole IN ('Territory Co-Prime','Regional Co-Prime')) FROM Account].size(),listOfSObjectsWithChilds.size(),'List should contain atleast 1 Record');
        System.assertEquals((' WHERE Id IN  :binding1').length(),listOfObjectWithMultipleBindings.length(),'OuterWhere clause should be same');
    }
    
    public override Set<String> getDefaultFields(){
        Set<String> defaultFields = new Set<String>{'Name','Id'}; 
        return defaultFields;
    }
}