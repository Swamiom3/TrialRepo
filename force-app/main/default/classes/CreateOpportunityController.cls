/************************************************************************************************************************************
    Author      :   Priyanka Ambre
    Description :   This class contain all aura methods related to CreateOpportunity.
   ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
       1        16 July 2018        Priyanka Ambre          Initial Developement
 **************************************************************************************************************************************/
global without sharing class CreateOpportunityController {
    public class CreateOpportunityControllerException extends Exception {}
    public static Boolean isInvoker = false;
    public static Savepoint sp {get; set;}
    @TestVisible
    private static UserSelector userSelector = new UserSelector();
    static {
        isInvoker = ApexDebugLog.registerRootInvoker(ApexDebugLog.InvokerType.AURA, 'CreateOpportunityController' + 'getsObjectPrefix', ApexDebugLog.InvokerType.AURA);
    }

    /************************************************************************************************************************************
       Author         : Priyanka Ambre
       Description    : This method takes record Id and returns you record detail.
       Created Date   : 16 July 2018
       Issue No.      :
     **************************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getCreateOpportunityData(String recordId, List<Id> reservationIds){
        RelatedRecordDetail objRelatedRecordDetail = new RelatedRecordDetail();
        DatabaseResult recordTypeInfo = LightningComponentController.getRecordTypeInfos(new List<String> {'Account', 'Contact', 'Opportunity'});
        objRelatedRecordDetail.recordTypeInfo = (Map<String, Map<String, Id> >)recordTypeInfo.data;
        objRelatedRecordDetail.isValidForCreateOpp = true;
        objRelatedRecordDetail.userInfo = userSelector.getUsersWithAdditionalFieldsById(UserInfo.getUserId())[0];
        objRelatedRecordDetail.userCurrency = UserInfo.getDefaultCurrency();
        List<String> productCodes = new List<String>();
        List<OpportunityProductCode__mdt> oppProductCodes = (List<OpportunityProductCode__mdt>) Settings.getFieldsFromMDT('OpportunityProductCode__mdt', '', new Set<String>{'ProductCode__c'});
        if (oppProductCodes != null) {
            for (OpportunityProductCode__mdt oppProductCode : oppProductCodes) {
                productCodes.add(oppProductCode.ProductCode__c);
            }
        }
        objRelatedRecordDetail.mapDataForProductCode = new Map<String, String>();
        for(PricebookEntry entry : [SELECT Id, Name, CurrencyIsoCode, UnitPrice, ProductCode FROM PricebookEntry WHERE ProductCode IN :productCodes AND CurrencyISOCode = 'USD']) {
            objRelatedRecordDetail.mapDataForProductCode.put(setPriceBookEntryName(entry.Name), String.valueOf(GlobalConstants.DEFAULT_OPP_SALES_PRICE));
        }
        objRelatedRecordDetail.mapConversionRate = new Map<String, Decimal>();
        for(CurrencyType objCurrencyType : [SELECT ISOCode, ConversionRate FROM CurrencyType WHERE IsActive = TRUE]) {
            objRelatedRecordDetail.mapConversionRate.put(objCurrencyType.ISOCode, objCurrencyType.ConversionRate);
        }
        
        
        objRelatedRecordDetail.opportunityQualifySetting = SalesConsoleSettings.get('EnterpriseOpportunityQualifySetting');


        MetadataSetting__mdt objReservationSelectorSetting = Settings.getMetadataSetting('ReservationSelectorSetting');
        Map<String,Object> mapData = (Map<String,Object>)JSON.deserializeUntyped(objReservationSelectorSetting.Data__c);
        objRelatedRecordDetail.reservationSelectorSetting = objReservationSelectorSetting;
        Map<String, Boolean> mapFeatureFlagStatus = new Map<String, Boolean> {'showReservationSelector' => FeatureManagement.checkPermission('Reservation_Selector_Feature')};

        Boolean newGeoField = Settings.getMetadataSetting('create_opportunity_new_geography_field').Data__c == 'true' ? true : false;
        mapFeatureFlagStatus.put('new_geography_field', newGeoField);

        objRelatedRecordDetail.featureFlagStatus = mapFeatureFlagStatus;
        
        Boolean showReservationSelector = mapFeatureFlagStatus.get('showReservationSelector');
        Id ultimateParentRecordId;

        List<SObject> lstRelatedRecords = new List<SObject>();
        Id relatedRecordId;
        String sObjectName;
        if(String.isNotBlank(recordId)) {
            relatedRecordId = Id.valueOf(recordId);
            sObjectName = relatedRecordId.getSObjectType().getDescribe().getName();
            Set<String> setAccountTypes = new Set<String> {'Sales', 'Org'};
            switch on sObjectName {
                when 'Account' {
                    lstRelatedRecords = [SELECT Id, Name, Number_of_Full_Time_Employees__c, ParentId, Primary_Member__c, Primary_Member__r.Name, Primary_Member__r.Email, Lead_Source__c, Description, Interested_in_Number_of_Desks__c, Parent_Org_Id__c, Account_Type__c, RecordType.Name, OwnerId, Owner.Name FROM Account WHERE Id =: recordId LIMIT 1];
                    if(lstRelatedRecords.size() > 0) {
                        Account accRec = (Account)lstRelatedRecords.get(0);
                        if(accRec != null && setAccountTypes.contains(accRec.Account_Type__c)) {
                            ultimateParentRecordId = accRec.Id;
                        }
                    }
                }

                when 'Contact' {
                    lstRelatedRecords = [SELECT Id, Name, Email, AccountId, Account.Name, Account_Name__c, Account.Number_of_Full_Time_Employees__c, Account.Parent_Org_Id__c, Account.Account_Type__c, Account.ParentId, LeadSource, Location__c, Lead_Source_Detail__c, Description, Unomy_Company_Id_Formula__c, Cleansed_Company_Name__c, Email_Domain_Text__c, Phone, OwnerId, Owner.Name, CI_Company__c FROM Contact WHERE Id =: recordId LIMIT 1];
                    if(lstRelatedRecords.size() > 0 ) {
                        List<Contact> lstContact = (List<Contact>) lstRelatedRecords;
                        if(lstContact.get(0).AccountId != null && setAccountTypes.contains(lstContact.get(0).Account.Account_Type__c)) {
                            ultimateParentRecordId = lstContact.get(0).AccountId;
                        }else {
                            Map<String, Set<String> > mapMatchingAccounts = OrganizationHelperServices.findOrgByNewCriterias(lstContact[0]);
                            if(mapMatchingAccounts != null && mapMatchingAccounts.get('highConfidenceAccountIds') != null && !mapMatchingAccounts.get('highConfidenceAccountIds').isEmpty()) {
                                ultimateParentRecordId = new List<String>(mapMatchingAccounts.get('highConfidenceAccountIds'))[0];
                            }
                        }
                    }
                }
                
                when else {

                }
            }
        }
        if(lstRelatedRecords.size() > 0) {
            objRelatedRecordDetail.relatedRecord = lstRelatedRecords[0];
            String relatedObjectName = relatedRecordId.getSObjectType().getDescribe().getName().toLowerCase();
            if(relatedObjectName.contains('__c')) {
                relatedObjectName =  relatedObjectName.substringBefore('__c');
                relatedObjectName =  relatedObjectName.replace('_', ' ');
            }
            objRelatedRecordDetail.relatedObjectName = relatedObjectName;
            if(ultimateParentRecordId != null) {
                objRelatedRecordDetail.ultimateParentAccountRecord = [SELECT Id, Name, Primary_Member__c FROM Account WHERE Id =: ultimateParentRecordId LIMIT 1];
            }
        }
        DatabaseResult result = new DatabaseResult(JSON.serialize(objRelatedRecordDetail));
        return result;
    }

    /************************************************************************************************************************************
       Author         : Priyanka Ambre
       Description    : Wrapper class used for getCreateOpportunityData.
       Created Date   : 16 July 2018
     **************************************************************************************************************************************/
    global class RelatedRecordDetail {
        @AuraEnabled
        public User userInfo {get; set;}
        @AuraEnabled
        public SObject relatedRecord {get; set;}
        @AuraEnabled
        public String relatedObjectName {get; set;}
        @AuraEnabled
        public Account ultimateParentAccountRecord {get; set;}
        @AuraEnabled
        public Boolean isValidForCreateOpp {get; set;}
        @AuraEnabled
        public Object opportunityQualifySetting {get; set;}
        @AuraEnabled
        public Map<String, Map<String, Id> > recordTypeInfo {get; set;}
        @AuraEnabled
        public DatabaseResult relatedBillingAccounts {get; set;}
        @AuraEnabled
        public MetadataSetting__mdt reservationSelectorSetting {get; set;}
        @AuraEnabled
        public Map<String, Boolean> featureFlagStatus {get; set;}
        @AuraEnabled
        public Map<String, String> mapDataForProductCode {get; set;}
        @AuraEnabled
        public Map<String, Decimal> mapConversionRate {get; set;}
        @AuraEnabled
        public String userCurrency {get; set;}
    }

    /***************************************************************************************************************************
       Author              : Priyanka Ambre
       Description         : This method is used to create Enterprise Opportunity.
       Created Date        : 16 July 2018
       Issue No			: ST-2486
       LastModifiedBy      : Roshan KanKrayane
       LastModifiedDate	: 20 May 2020
       Issue				: ST-6189
     *****************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult createEnterpriseOpportunity(Opportunity oppRec,List<Id> lstReservationsIds, String OppCurrencyISOCode){
        
        Opportunity objOpportunity = OpportunityHelper.createOpportunity(oppRec);
        if(String.isNotBlank(OppCurrencyISOCode)) {
            objOpportunity.CurrencyISOCode = OppCurrencyISOCode;
        }
        System.debug('Type__c DEBUG  ' + objOpportunity.Type__c);	
        System.debug('Type__c DEBUG  ' + objOpportunity);
        insert objOpportunity;

        DatabaseResult result = new DatabaseResult(true, objOpportunity, 'Opportunity created successfully.');
        return result;
    }
    
    @AuraEnabled
    public static List<DependentPicklistController.PicklistEntryWrapper> getPicklistValues(String fieldApiname){
        List<DependentPicklistController.PicklistEntryWrapper> optionlist = new List<DependentPicklistController.PicklistEntryWrapper>();
        Map<String, Schema.SObjectField> fieldMap = Opportunity.sObjectType.getDescribe().fields.getMap();
        List<Schema.PicklistEntry> picklistValues = fieldMap.get(fieldApiname).getDescribe().getPickListValues();
        for (Schema.PicklistEntry pv : picklistValues) {
            optionlist.add(new DependentPicklistController.PicklistEntryWrapper(pv.getLabel(), pv.getValue()));
        }
        return optionlist;
    }

    @TestVisible
    private static String setPriceBookEntryName(String inputName){
        if (String.isBlank(inputName)) {
            return null;
        }
        if (GlobalConstants.ALL_ACCESS_ALL.contains(inputName)) {
            return inputName;
        }else if (inputName == 'Design & Build') {
            return GlobalConstants.PX_WE;
        }else if (inputName == 'Workplace') {
            return GlobalConstants.WORKPLACE;
        } else {
            return GlobalConstants.WEWORK;
        }
    }
}