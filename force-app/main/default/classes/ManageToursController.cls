/************************************************************************************************************************************
    Author      :   Samadhan Kadam
    Description :   This class contain all aura methods related to Manage Tour.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           30 Oct 2018         Samadhan Kadam      	Initial Developement
	2           10 Jan 2019         Prashant Mane			Seperate functionality from lightning component controller.
**************************************************************************************************************************************/
global without sharing class ManageToursController {
    public static Boolean isInvoker = false;
    public static Savepoint sp {get;set;}
    @TestVisible
    private static JourneySelector journeySelector = new JourneySelector();
    public static ManageTourWrapper objManageTourWrapper = new ManageTourWrapper();
    static {
        isInvoker = ApexDebugLog.registerRootInvoker(ApexDebugLog.InvokerType.AURA, 'ManageToursController' + 'getsObjectPrefix', ApexDebugLog.InvokerType.AURA);
    }
	/************************************************************************************************************************************
		Author              : 	Samadhan Kadam
		Description         : 	This method is used to validate the opportunity before redirect user to Books Tour page.
		Created Date        : 	18/07/2018
		Issue No.           : 	ST-2608
	*************************************************************************************************************************************/
    webservice static string isValidOpportunityForManageTour(Id oppId) {
        Opportunity  objOpp = [Select Id,Name,StageName,Contract_Stage__c from Opportunity where Id = : oppId];
        ValidResultWithOpportunity validResult = new ValidResultWithOpportunity();
        If(objOpp != null && objOpp.StageName == 'Closed Won' || objOpp.StageName == 'Closed Lost' || objOpp.StageName == 'Merged'){
            validResult.isValid = false;
            validResult.errorMsg  = 'Cannot Book Tours for Opportunity with stage Closed Won, Closed Lost or Merged';
        }else if(objOpp != null &&  objOpp.StageName == 'Closing' && (objOpp.Contract_Stage__c == 'Contract Sent' || objOpp.Contract_Stage__c == 'Contract Signed')){
            validResult.isValid = false;
            validResult.errorMsg  = 'Cannot Book Tours on Closing Opportunity with Contract Stage as Sent or Signed';
        }else{
            validResult.isValid = true;
        }
        return JSON.serialize(validResult);
    }

    /************************************************************************************************************************************
		Author              : 	Samadhan Kadam
		Description         : 	This method is used to validate the opportunity before redirect user to Books Tour page.
		Created Date        : 	18/07/2018
		Issue No.           : 	ST-2608
	*************************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult isValidOpportunityForManageTourLightning(Id oppId) {
        try{
            return new DatabaseResult(isValidOpportunityForManageTour(oppId));
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,'oppId==>'+oppId, 'ManageToursController', 'isValidOpportunityForManageTourLightning');
            return (new DatabaseResult(pEx));
        }
    }
	/************************************************************************************************************************************
		Author              : 	Prashant Mane
		Description         : 	This method is used to validate the Account before redirect user to Books Tour page.
		Created Date        : 	27/07/2018
		Issue No.           : 	CSI-827
	*************************************************************************************************************************************/
    webservice static String isValidAccountForManageTour(Id accountId) {
        Account acc = new AccountSelector().getAccountWithContacts(new Set<Id>{accountId})?.get(0);
        ValidResultWithOpportunity validResult = new ValidResultWithOpportunity();
        if(acc != null && acc.contacts.size() < 1 ){
            validResult.isValid = false;
            validResult.errorMsg  = 'You cannot book a tour due to Contact not found under '+acc.Name+'';
        }else{
            validResult.isValid = true;
        }
        return JSON.serialize(validResult);
    }

    /************************************************************************************************************************************
		Author              : 	Samadhan Kadam
		Description         : 	This method is used to validate the Account before redirect user to Books Tour page.
		Created Date        : 	27/07/2018
		Issue No.           : 	CSI-827
	*************************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult isValidAccountForManageTourLightning(Id accountId) {
        try{
            return new DatabaseResult(isValidAccountForManageTour(accountId));
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,'accountId==>'+accountId, 'ManageToursController', 'isValidOpportunityForManageTourLightning');
            return (new DatabaseResult(pEx));
        }
    }

    /************************************************************************************************************************************
		Author              : 	Samadhan Kadam
		Description         : 	This method is used to validate the Account before redirect user to Books Tour page.
		Created Date        : 	01/10/2019
		Issue No.           : 	CSI-1571
	*************************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getDataForManageTours(Map<String, String> mapData){
        String buildingId = mapData.get('buildingId');
        String entityType = mapData.get('entityType');
        String accountId = mapData.get('accountId');
        Boolean isOnload = String.isNotBlank(mapData.get('isOnload')) ? Boolean.valueOf(mapData.get('isOnload')) : true;
        try{
            if(mapData.get('Id') != NULL){
                objManageTourWrapper.entityData = fetchsObjectData(mapData);
                if(!objManageTourWrapper.entityData.isEmpty()){
                    if(mapData.get('entityType') == 'journey' && objManageTourWrapper.entityData[0].get('Primary_Contact__c') != null){
                        mapData.put('Primary_Member__c', (String)objManageTourWrapper.entityData[0].get('Primary_Contact__c'));
                    } else if(mapData.get('entityType') == 'contact' && objManageTourWrapper.entityData[0].get('AccountId') != null){
                        accountId = (String)objManageTourWrapper.entityData[0].get('AccountId');
                    } else if(mapData.get('entityType') == 'account' && objManageTourWrapper.entityData[0].get('Primary_Member__c') != null){
                        mapData.put('Primary_Member__c', (String)objManageTourWrapper.entityData[0].get('Primary_Member__c'));
                    }
                }
            }
            DatabaseResult info =  LightningComponentController.getUserInfo();
            objManageTourWrapper.userInfo =  info.data;
            return new DatabaseResult(JSON.serialize(objManageTourWrapper));
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,'mapData==>'+JSON.serializePretty(mapData), 'ManageToursController', 'getDataForManageTours');
            return (new DatabaseResult(pEx));
        }
    }

    public static List<sObject> fetchsObjectData(Map<String, String> entity){
        String query;
        Id sObjectId = entity.get('Id');
        String objectName = sObjectId.getSObjectType().getDescribe().getName().toLowerCase();
        switch on objectName {
            when 'lead' {
                query = 'SELECT Id, Name, Company, Email, Account__c, Building_Interested_In__c, Unomy_Company_Size_Formula__c, Phone, Number_of_Full_Time_Employees__c, Interested_in_Number_of_Desks__c, Referrer_Name__c, Referrer_Email__c FROM Lead WHERE Id=: sObjectId';
            }
            when 'contact' {
                query = 'SELECT Id, AccountId, Name, Email, Phone, Account.Number_of_Full_Time_Employees__c, Account.Interested_in_Number_of_Desks__c, Referrer_Name__c, Referrer_Email__c, Location__c FROM Contact WHERE Id=: sObjectId';
            }
            when 'journey__c' {
                query = journeySelector.getJourneysWithMoreAdditionalFieldsByIds();
            }
        }
        return Database.query(query);
    }

    public class ValidResultWithOpportunity{
        public Boolean isValid {get;set;}
        public string errorMsg {get;set;}
    }

    public class ManageTourWrapper{
        public Building__c building {get;set;}
        public Object userInfo {get;set;}
        public Contact currentUser {get;set;}
        public List<String> allowNMDOverrideInBuildingProfiles {get;set;}
        public List<Opportunity> relatedOpportunities {get;set;}
        public List<Contact> relatedContacts {get;set;}
        public DatabaseResult relatedTourData {get;set;}
        public List<sObject> entityData{get;set;}
    }
    public class ManageToursControllerException extends Exception{}
}