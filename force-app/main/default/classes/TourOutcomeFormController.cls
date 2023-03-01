global without sharing class TourOutcomeFormController {

    @TestVisible
    private static BuildingSelector buildSelector = new BuildingSelector();

    public static Boolean isInvoker = false;
    static {
        isInvoker = ApexDebugLog.registerRootInvoker(ApexDebugLog.InvokerType.AURA, 'TourOutcomeFormController' + 'getsObjectPrefix', ApexDebugLog.InvokerType.AURA);        	
    }

    global class FormData {
        public Object tourRecord {get;set;}
        public Object setting {get;set;}
        public Contact tourCompletedBy {get;set;}
        public Date currentDate {get;set;}
        public List<Building__c> buildings {get;set;}
        public String sessionId {get;set;}
        public String loggedInUser {get;set;}
    }
    
    @AuraEnabled
    public static DatabaseResult getFormData(Map<String, Object> parameters) {
        try{
            FormData objFormData = new FormData();
            Sales_Console_Setting__mdt settingRecord = Settings.get('TourOutcomeForm');
            TourOutcomeFormSettings setting = new TourOutcomeFormSettings();
            String label = (String) parameters.get('label');
            setting = (TourOutcomeFormSettings)JSON.deserialize(settingRecord.Data__c, TourOutcomeFormSettings.class); 
            object queryResult = getQueryResultForLabel(label, parameters).data;
            if(queryResult != null){
                objFormData.tourRecord = queryResult;
            }            
            objFormData.setting = setting;
            String userEmail = UserInfo.getUserEmail();
            List<Contact> contactRecord = new List<Contact>([SELECT Id, Name, Email, UUID__c FROM Contact WHERE Email =: userEmail]);
            if(contactRecord.size() > 0){
                objFormData.tourCompletedBy = contactRecord[0];
            }else{
                userEmail = 'joinus@wework.com';
                contactRecord = new List<Contact>([SELECT Id, Name, Email, UUID__c FROM Contact WHERE Email =: userEmail]);
                if(contactRecord.size() > 0){
                    objFormData.tourCompletedBy = contactRecord[0];
                } else {
                    objFormData.tourCompletedBy = new Contact();
                }
            }
            objFormData.currentDate = System.today();            
            Map<String, Building__c> mapBuildings = new Map<String, Building__c>();
            objFormData.buildings = buildSelector.getBuildingsWithLocationNoCityAndNotNullUuid();            
            objFormData.sessionId = UserInfo.getSessionId();
            objFormData.loggedInUser = UserInfo.getUserId();
            return new DatabaseResult(JSON.serialize(objFormData));            
        }catch(Exception ex){
            ApexDebugLog.logException(ex, JSON.serialize(parameters), 'TourOutcomeFormController', 'getFormData');            
            return (new DatabaseResult(ex)); 
        }
    }

    @AuraEnabled
    public static List<Contact> searchContacts(String searchQuery, Id accountId) {
        try {
            List<List<SObject>> searchResult = [FIND :searchQuery RETURNING Contact (Id, Name, Email WHERE AccountId = :accountId LIMIT 25)];
            return (List<Contact>) searchResult[0];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Contact> searchReferrerContacts(String searchQuery) {
        try {
            List<List<SObject>> searchResult = [FIND :searchQuery RETURNING Contact (Id, Name, Email WHERE Type__c IN ('Broker','Employee','Member') LIMIT 25)];
            return (List<Contact>) searchResult[0];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /************************************************************************************************************************************
        Author          : Samadhan Kadam
        Description     : We have moved all the client side queries to server side using this method
        Created Date    : 30 November 2018 
        Issue No        : ST-3011
    **************************************************************************************************************************************/
     @AuraEnabled
    public static DatabaseResult getQueryResultForLabel(String label, Map<String, Object> filters){
        String query;
        Switch on label{
            WHEN 'TourDetails'{
                query = 'SELECT Id, AppointmentNumber, Description, ContactId, Opportunity_Id__r.AccountId, Opportunity_Id__r.Referrer__c, Opportunity_Id__r.Referrer__r.Name, Opportunity_Id__r.Referrer__r.Email, Opportunity_Id__r.Actual_Start_Date__c, Contact.Email, Contact.AccountId, Contact.Account.Number_of_Full_Time_Employees__c, Contact.Account.Name, Contact.Account.BillingCountry, Contact.Account.BillingState, Contact.Account.BillingCity, Contact.Account.BillingStreet, Contact.Name, Building_Id__r.Name, Building_Id__r.uuid__c, Building_Id__r.Tour_Spacing__c, Opportunity_Id__c, OwnerId, Tour_Outcome__c, Status, Product_Interests__c, Target_Move_In_Date__c, Urgency__c, Desired_Budget__c, Is_Decision_Maker__c, Tour_Outcome_Notes__c, Objections__c, No_Follow_Up__c, Lease_Expiration__c, FORMAT(SchedStartTime), FORMAT(SchedEndTime), CreatedById, CreatedBy.Name, Interested_in_Number_of_Desks__c FROM ServiceAppointment';
                query += ' WHERE ' + checkForUUIDorSFID(String.valueof(filters.get('IdOrUUID')));
            }
        }
        return String.isNotBlank(query) ? LightningComponentController.getQueryData(query) : new DatabaseResult(false, null, 'Something went wrong, please contact your system administrator');
    }
    
    public static string checkForUUIDorSFID(String parameter){
        String queryParameter = '';
        try{
            Id.valueOf(parameter);
            queryParameter += 'Id = \''+parameter+'\'';
        }catch(Exception ex){
            queryParameter += 'UUID__c = \''+parameter+'\'';
        }
        return queryParameter;
    }
    
    //Method to get contact by current user email
    @AuraEnabled
    public static string getUserContactInfo(){
        return JSON.serialize([Select Id, Name, Email From Contact Where Email=:UserInfo.getUserEmail()]);
    }
    global class TourOutcomeFormSettings{
        public Set<String> RestrictedProfiles {get;set;}
        public ReservableAvailabilityAPI reservableAvailabilityAPI {get;set;}
        public CreateTourOutcomes createTourOutcomes {get;set;}
        public NoShow noShow {get;set;}
        public Reasons reasons {get;set;}
        public HowHeards howHeards {get;set;}
        public Urgencies urgencies {get;set;}
        public ReservableTourBuildingAvailabilitiesAPI reservableTourBuildingAvailabilitiesAPI {get;set;}
        public ReservableRescheduleAPI reservableRescheduleAPI {get;set;}
    }
    global class ReservableAvailabilityAPI {
        public String url {get;set;}
        public Headers headers {get;set;}
    }    
    global class Headers {
        public String Authorization {get;set;}
    }
    global class CreateTourOutcomes {
        public String url {get;set;}
        public Headers headers {get;set;}
    }
    global class NoShow {
        public String url {get;set;}
        public Headers headers {get;set;}
    }
    global class Reasons {
        public String url {get;set;}
        public Headers headers {get;set;}
    }
    global class HowHeards {
        public String url {get;set;}
        public Headers headers {get;set;}
    }
    global class Urgencies {
        public String url {get;set;}
        public Headers headers {get;set;}
    }
    global class ReservableTourBuildingAvailabilitiesAPI {
        public String url {get;set;}
        public Headers headers {get;set;}
    }
    global class ReservableRescheduleAPI {
        public String url {get;set;}
        public Headers headers {get;set;}
    }    
}