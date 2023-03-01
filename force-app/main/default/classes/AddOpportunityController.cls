/************************************************************************************************************************************
    Author      :   Priyanka Ambre
    Description :   This class contain all aura methods related to AddOpportunity.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           30 Oct 2018         Priyanka Ambre      	Initial Developement
	2           31 Oct 2018         Krishana Tupe         	Code Optimization
**************************************************************************************************************************************/
global without sharing class AddOpportunityController {    
    public static Boolean isInvoker = false;
    @TestVisible
    private static final BuildingSelector buildingSelector = new BuildingSelector();
    public static Savepoint sp;
    static {
        isInvoker = ApexDebugLog.registerRootInvoker(ApexDebugLog.InvokerType.AURA, 'AddOpportunityController' + 'getsObjectPrefix', ApexDebugLog.InvokerType.AURA);        
    }
    
 /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is used to get Opportunity related detail data like account name, contact name and lead name. 
  *****************************************************************************************************************************/   
    @AuraEnabled
    public static DatabaseResult getAddOpportunityData(Id journeyId){        
        try{
            if(String.isBlank(journeyId)){
                throw new AddOpportunityControllerException('Please provide journey Id');  
            }
            AddOpportunityData objAddOpportunityData = new AddOpportunityData();
            objAddOpportunityData.journeyRecord = [SELECT Id, Name, Primary_Lead__c, Primary_Lead__r.Account__c, Primary_Contact__r.Name, Primary_Contact__r.Account.Name, Status__c, Primary_Lead__r.Name, Primary_Lead__r.Email, Primary_Lead__r.Company, OwnerId, Owner.Name FROM Journey__C WHERE Id =: journeyId];
            objAddOpportunityData.settingData = Settings.getMetadataSettingByDevName('SendPaperworkSetting').Data__c; 
            objAddOpportunityData.excludedProfiles = SalesConsoleSettings.get('AccountSelectorSettings').Data__c;        
            objAddOpportunityData.systemDate = system.today();
            objAddOpportunityData.currentUserProfile = UserUtility.getUserById(UserInfo.getUserId()).Profile.Name;
            return new DatabaseResult(JSON.serialize(objAddOpportunityData)); 
        }catch(Exception pEx){ 
            ApexDebugLog.logException(pEx,'journeyId==>'+journeyId, 'AddOpportunityController', 'getAddOpportunityData'); 
            return (new DatabaseResult(pEx));
        }    
    }   
     
 /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : This method is used to get Opportunity related detail data like account name, contact name and lead name.
        Created Date        : -
        Last Modified By    : Ashish Mishra
        Last Modified Date  : 31,May 2018
  *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getJourneyOpportunityData(Map<String, String> mapOpportunityData){
        try{
            if(mapOpportunityData == null){
                throw new AddOpportunityControllerException('Parameter should not be blank');     
            }
            JourneyOpportunityData journeyOpportunityData = new JourneyOpportunityData();
            if(mapOpportunityData.get('journeyId') != NULL){
                journeyOpportunityData.journey = [SELECT Id, Building_Interested_In__c, Primary_Contact__r.AccountId, Primary_Contact__c,Primary_Lead__c FROM Journey__c WHERE Id =: Id.valueOf(mapOpportunityData.get('journeyId'))]; 
            } 
            if(mapOpportunityData.get('accountId') != NULL){               
                List<Account> lstAccount = [SELECT Id, OwnerId, RecordType.Name, Number_of_Full_Time_Employees__c, Company_Size__c, Unomy_Company_Size_Formula__c, Interested_in_Number_of_Desks__c FROM Account WHERE Id =: Id.valueOf(mapOpportunityData.get('accountId'))];         
                if(lstAccount != NULL && !lstAccount.isEmpty()){
                    journeyOpportunityData.account = lstAccount[0];
                }                
            }
            if(mapOpportunityData.get('contactId') != NULL){              
                journeyOpportunityData.contact = [SELECT Id, Location__c, Location_Interested__c FROM Contact WHERE Id =: Id.valueOf(mapOpportunityData.get('contactId'))];
            }
            if(mapOpportunityData.containsKey('leadId')){                
                journeyOpportunityData.lead = [SELECT Id, Number_of_Full_Time_Employees__c,Unomy_Company_Size_Formula__c,Interested_in_Number_of_Desks__c  FROM Lead WHERE Id =: Id.valueOf(mapOpportunityData.get('leadId'))];
            }
            journeyOpportunityData.opportunityRecordTypes = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
            journeyOpportunityData.accountRecordTypes = Schema.SObjectType.Account.getRecordTypeInfosByName();
            journeyOpportunityData.mapBuildings = new Map<Id, Building__c>(buildingSelector.getBuildingsWithoutFilters());
            return new DatabaseResult(JSON.serialize(journeyOpportunityData) ); 
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,'', 'AddOpportunityController', 'getJourneyOpportunityData');   
            return (new DatabaseResult(pEx));
        }  
    }
    
 /****************************************************************************************************************************
        Author              : Priyanka Ambre
        Description         : This method is used to get required query data.
        Created Date        : 30 Oct 2018        
   *****************************************************************************************************************************/ 
    @AuraEnabled
    public static DatabaseResult getQueryData(String queryLable, Id journeyId, Id contactId, Id accountId){           
        try{
            sp = Database.setSavepoint();    
            if(String.isBlank(queryLable)){
                throw new AddOpportunityControllerException('Please provide queryLable');  
            }
            String query;
            switch on queryLable {
                when 'getJourneyRelatedOpportunities' {
                    query = 'SELECT Id, RecordType.Name, Name, Type__c, Account.Name, Billing_Account__c, Billing_Account__r.UUID__c, Primary_Member__r.Name, Building__r.Name, Building__r.UUID__c, StageName, CloseDate, Encoded_ID__c, Actual_Start_Date__c, Quantity__c, Deal_Type__c FROM Opportunity WHERE Primary_Member__c =: contactId OR Journey__c =: journeyId';
                }
                when 'getAccountRecord' {
                    query = 'SELECT Id, Name, Parent_Org_Id__c,Account_Type__c FROM Account WHERE Id =: accountId';
                }
            }            
            if(String.isNotBlank(query)){
                return new DatabaseResult(Database.query(query));                
            }
            return null;            
        }catch(Exception pEx){                   
            LightningComponentController.rollbackTransaction(sp);
            ApexDebugLog.logException(pEx, queryLable + ' ' + journeyId + ' ' + accountId, 'AddOpportunityController', 'getQueryData');
            return (new DatabaseResult(pEx));             
        }
    }
    
 /****************************************************************************************************************************
    Author              : Krishana Tupe
    Description         : This method is used to insert new Opportunity from AddOpportunity component.
    Created Date        : 01 Nov 2018    
*****************************************************************************************************************************/    
    @AuraEnabled  
    global static DatabaseResult insertAddOpportunity(Map<String,Object> mapOpportunityData, Map<String,Object> mapRevstarResult){ 
        try{          
            sp = Database.setSavepoint();
            if(mapOpportunityData == null){
                throw new AddOpportunityControllerException('Parameter should not be blank');     
            }
            Opportunity objOpportunity = new Opportunity();
            if(String.isNotBlank((String)mapOpportunityData.get('Journey__c'))){
                objOpportunity = (Opportunity)FieldMappingsHelper.getMappings((String)mapOpportunityData.get('Journey__c'), objOpportunity, 'FieldMappings_JourneyToOpportunity');        
            }else{
                objOpportunity = (Opportunity)FieldMappingsHelper.getMappings((String)mapOpportunityData.get('Primary_Member__c'), objOpportunity, 'FieldMappings_ContactToOpportunity');
            }
            if(mapOpportunityData.get('CloseDate') != null){
                String closedate = (String)mapOpportunityData.get('CloseDate');
                objOpportunity.CloseDate = Date.valueOf(closedate);
                objOpportunity.Opportunity_Creation_Source__c = 'From Add Opportunity';
            }else{
                objOpportunity.CloseDate = System.today();                
            }   
            
            for(String field : mapOpportunityData.keySet()){  
                if(!field.equalsIgnoreCase('CloseDate') && mapOpportunityData.get(field) != NULL){
                    objOpportunity.put(field, mapOpportunityData.get(field)); 
                }           
            }
            objOpportunity.StageName = 'Qualifying';
            objOpportunity.OwnerId = userInfo.getUserId();
            
           // objOpportunity.Uom__c = CalculateUnitsService.DESKS; 
            objOpportunity.Original_Quantity__c = objOpportunity.Interested_in_Number_of_Desks__c;
            if(String.isEmpty(objOpportunity.Type__c)){
                objOpportunity.Sales_Price__c = 0;
                objOpportunity.CurrencyIsoCode = 'USD';
            }else if(objOpportunity.Type__c == GlobalConstants.ALL_ACCESS){
                objOpportunity.Sales_Price__c = 299;
                objOpportunity.CurrencyIsoCode = 'USD';
            }else{
                if(mapRevstarResult?.get('RevStar_Price') == null){
                    objOpportunity.Sales_Price__c = 500;
                    objOpportunity.CurrencyIsoCode = 'USD';
                }else{
                    objOpportunity.CurrencyIsoCode = String.valueOf(mapRevstarResult.get('Currency'));
                    objOpportunity.Sales_Price__c = Decimal.valueOf(String.valueOf(mapRevstarResult?.get('RevStar_Price')));
                }
            }
            
            if(objOpportunity.Desired_Term_Length_in_months__c == null){
                objOpportunity.Desired_Term_Length_in_months__c = 1;
            }
            UtilSObject.trimTooLongPicklist(objOpportunity, GlobalConstants.OPPORTUNITY_MULTIPICKLIST_FIELDS);
            return new DatabaseResult(JSON.serialize(Database.insert(objOpportunity)));
        }catch(Exception pEx){
            LightningComponentController.rollbackTransaction(sp);
            ApexDebugLog.logException(pEx,mapOpportunityData != null ? JSON.serialize(mapOpportunityData) : '', 'AddOpportunityController', 'insertAddOpportunity');  
            return (new DatabaseResult(pEx));
        }
    }
    
 /****************************************************************************************************************************
    Author              : Shubham Nandwana
    Description         : This method is used to get open opportunities for an account.
    Created Date        : 09 September 2021    
*****************************************************************************************************************************/ 
    @AuraEnabled
    global static DatabaseResult getOpenOpportunitiesForAccount(String accountId){
        Sales_Console_Setting__mdt openOpportunityStages = SalesConsoleSettings.get('OpenOpportunityStages');
        Set<String> setOppStageNotToBypass;
        if(openOpportunityStages?.Data__c == null){
            setOppStageNotToBypass = new Set<String>{'qualifying','selling','negotiating'};
        }else{
            setOppStageNotToBypass = (Set<String>) JSON.deserialize(openOpportunityStages.Data__c.toLowerCase(), Set<String>.Class);       
        }
        return new DatabaseResult([SELECT Id, RecordType.Name, Name, Type__c, Account.Name, Billing_Account__c, Billing_Account__r.UUID__c, Primary_Member__r.Name, 
                        Building__r.Name, Building__r.UUID__c, StageName, CloseDate, Encoded_ID__c, Actual_Start_Date__c, Quantity__c, Deal_Type__c
                        FROM Opportunity WHERE StageName IN: setOppStageNotToBypass AND AccountId =: accountId]);
    }
    
    /************************************************************************************************************************************
        Author              : Rohit Nimase
        Description         : This method checks is opportunity is valid for SendPaperWork functionality.
        Created Date        : 23 July 2018 
        Issue No            : CSI-1571
    **************************************************************************************************************************************/	
    /*@AuraEnabled
    public static DatabaseResult isValidOppforSendPaperwork(Id oppId){        
        //return new DatabaseResult(SendPaperWorkController.isValidOppforSendPaperwork(oppId));
    }*/
    
 /****************************************************************************************************************************
        Author              : Milanjeet
        Description         : Added from Ajay instance for Add Opportunity Functionality
        Created Date        : 9:33 PM 08/16/2017
        Issue               : ST-1262,1270
  *****************************************************************************************************************************/
    global class AddOpportunityData{
        @AuraEnabled
        public Journey__c journeyRecord {get;set;}
        @AuraEnabled
        public String settingData {get;set;}
        @AuraEnabled
        public String excludedProfiles {get;set;}
        @AuraEnabled
        public String currentUserProfile {get;set;}
        @AuraEnabled
        public Date systemDate {get;set;}
    }

 /****************************************************************************************************************************
        Author              : Ajaysinh Chauhan
        Description         : Class for Journey Opportunity Data.             
  ****************************************************************************************************************************/ 
    global class JourneyOpportunityData{
        @AuraEnabled
        public Account account {get;set;}
        @AuraEnabled
        public Contact contact {get;set;}
        @AuraEnabled
        public Journey__c journey {get;set;}
        @AuraEnabled
        public Lead lead {get;set;}
        @AuraEnabled
        public Map<Id, Building__c> mapBuildings {get;set;}
        @AuraEnabled
        public Map<String, Object> opportunityRecordTypes {get;set;}
        @AuraEnabled
        public Map<String, Object> accountRecordTypes {get;set;}
    }   
    
 /****************************************************************************************************************************
        Author              : Krishana Tupe
        Description         : This class is used for handle the custom exception of AddOpportunity class.
		CreatedDate 		: 31 Oct 2018
  ****************************************************************************************************************************/ 
    public class AddOpportunityControllerException extends Exception{}    
}