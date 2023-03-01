/*************************************************************************************************************************************
 Author      :   Swapnil Mahale
 Description :   This class is used to find related organizations.
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               21 May, 2019    Swapnil Mahale      Initial Deployment
 2               16 Feb, 2021    Alex Vashchenko     Refactor, Ultimate Parents optimalization
 3               19 Mar, 2021    Pawel Biszczak      Refactor
 **************************************************************************************************************************************/
public without sharing class OrganizationHelper {
    public static Boolean isFromParentAccountBatch = false;
    private static Map<String, Map<String, String> > mapSpecialCharSettings = (Map<String, Map<String, String> >) JSON.deserialize(Settings.getMetadataSettingByDevName('Special_Character_Accounts').Data__c, Map<String, Map<String, String> >.class);
    private static final String FUNCTIONAL_ACCOUNTS_NAMES = 'Functional_Accounts_Names';
    private static final String ACCOUNTS_NAMES_BY_DOMAINS = 'Accounts_Names_By_Domains';
    private static final Set<String> ACCOUNT_TYPES = new Set<String> {GlobalConstants.ACCOUNT_TYPE_ORG,GlobalConstants.ACCOUNT_TYPE_SALES};


    public List<String> getListFields(String sObjectName){
        List<String> fields = new List<String> {'Email_Domain_Text__c', 'Unomy_Company_ID_Formula__c', 'Cleansed_Unomy_Company_Name__c', 'Unomy_Company_Name_Formula__c', 'Cleansed_Company_Name__c', 'Name', 'Email'};
        if(sObjectName.toLowerCase() == 'lead') {
            fields.addAll(new List<String> {'Company'});
            return fields;
        }else if(sObjectName.toLowerCase() == 'contact') {
            fields.addAll(new List<String> {'Account_Name__c'});
            return fields;
        }
        return null;
    }

    public static Id findRelatedOrg(SObject record){
        Map<Id,Id> orgByIds = findRelatedOrg(new List<SObject> {record});
        return orgByIds.get(String.valueOf(record.get('Id')));
    }

    public static Id findOrCreateRelatedOrg(SObject record){
        Map<Id,Id> orgByIds = findOrCreateRelatedOrg(new List<SObject> {record});
        return orgByIds.get(String.valueOf(record.get('Id')));
    }

    public static Map<Id,Id> findRelatedOrg(List<SObject> records){
        return findOrgs(records);
    }

    public static Map<Id,Id> findOrCreateRelatedOrg(List<SObject> records){
        Map<Id,Id> orgByIds = findOrgs(records);
        Set<Id> contactIds = new Set<Id>();
        for(Id sourceId : orgByIds.keySet()) {
            if(isContact(sourceId) && orgByIds.get(sourceId) == null) {
                contactIds.add(sourceId);
            }
        }
        if(contactIds.isEmpty()) {
            isFromParentAccountBatch = false;
            return orgByIds;
        }
        Map<Id, SObject> recordsByIds = new Map<Id, SObject>(records);
        Map<String, Object> referralSourcesSetting = Settings.getMetadataSettingByDevNameAsMap('PartnerReferralLSandLSDforEntRecordType');
        Map<Id, SObject> destinationFieldsBySourceIds = FieldMappingsHelper.getMappings(contactIds, 'FieldMappings_ContactToAccount');
        Id bilingAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();

        for(Id sourceId : destinationFieldsBySourceIds.keySet()) {
            if(isFieldBlank(destinationFieldsBySourceIds.get(sourceId), 'Primary_Member__c')) {
                destinationFieldsBySourceIds.get(sourceId).put('Primary_Member__c', sourceId);
            }
            if(PersonEndpointHelper.personContactId == sourceId) {
                destinationFieldsBySourceIds.get(sourceId).put('Account_SubType__c', 'Broker');
            }
            if(isFieldBlank(destinationFieldsBySourceIds.get(sourceId), 'Name')) {
                if(recordsByIds.get(sourceId) == null) {
                    continue;
                }
                Contact contactRecord = (Contact) recordsByIds.get(sourceId);
                if (contactRecord.Account_Name__c != null) {
                    destinationFieldsBySourceIds.get(sourceId).put('Name', contactRecord.Account_Name__c);

                } else if (contactRecord.Name != null) {
                    destinationFieldsBySourceIds.get(sourceId).put('Name', contactRecord.Name);
                } else if (contactRecord.FirstName != null && contactRecord.LastName != null) {
                    destinationFieldsBySourceIds.get(sourceId).put('Name', contactRecord.FirstName + ' ' + contactRecord.LastName);
                } else if (contactRecord.LastName != null) {
                    destinationFieldsBySourceIds.get(sourceId).put('Name', contactRecord.LastName);
                }
            }
            destinationFieldsBySourceIds.get(sourceId).put('Account_Type__c', GlobalConstants.ACCOUNT_TYPE_ORG);
            Contact objContact = (Contact) recordsByIds.get(sourceId);
            if( objContact != null
                && String.isNotBlank(objContact.LeadSource) && String.isNotBlank(objContact.Lead_Source_Detail__c)
                && !referralSourcesSetting.isEmpty()
                && ((List<Object>)referralSourcesSetting.get('leadsource')).contains(objContact.LeadSource.toLowerCase())
                && ((List<Object>)referralSourcesSetting.get('leadsourcedetail')).contains(objContact.Lead_Source_Detail__c.toLowerCase())) {
                destinationFieldsBySourceIds.get(sourceId).put('RecordTypeId', bilingAccountRecordTypeId);
            }
            if(isFromParentAccountBatch) {
                destinationFieldsBySourceIds.get(sourceId).put('Account_Creation_Source__c', 'Batch - BatchToFindParentAccount');
            }
        }

        Database.insert(destinationFieldsBySourceIds.values(), !isFromParentAccountBatch);
        for(Id sourceId : destinationFieldsBySourceIds.keySet()) {
            if(isFieldNotBlank(destinationFieldsBySourceIds.get(sourceId), 'Id')) {
                orgByIds.put(getStringValue(destinationFieldsBySourceIds.get(sourceId),'Primary_Member__c'), getStringValue(destinationFieldsBySourceIds.get(sourceId),'Id'));
            } else {
                orgByIds.put(sourceId, null);
            }
        }
        isFromParentAccountBatch = false;
        return orgByIds;
    }

    public static Map<Id,Id> findOrgs(List<SObject> records){
        Map<Id,Id> result = new Map<Id,Id>();
        List<SObject> entitiesWithNoOrg = new List<SObject>();
        for(SObject record : records) {
            if(record == null) {
                continue;
            }
            String orgFieldName = isLead(record) ? 'Account__c' : 'AccountId';
            if (record.get(orgFieldName) == null) {
                entitiesWithNoOrg.add(record);
                continue;
            }
            
            result.put(getStringValue(record,'Id'), getStringValue(record,orgFieldName));
        }

        if(!entitiesWithNoOrg.isEmpty()) {
            return getOrgsByAllCriteria(entitiesWithNoOrg,result);
        }
        return result;
    }

    public static Map<Id,Id> getOrgsByAllCriteria(List<SObject> records, Map<Id,Id> orgIds){
        CompaniesInfo companiesRecord = getCompaniesNamesIdsAndEmailsInfo(records);
        List<SObject> relatedRecords = getrelatedRecordsFromCompanies(companiesRecord);
        Set<Id> accountIds =  getAccountIdsForUniqueDomains(relatedRecords);
        Map<Id,Id> ultimateParents = getUltimateParents(accountIds);
        OrgsByParametersInfo orgsInfoRecord = getOrgsByParameters(relatedRecords, ultimateParents);
        return getOrgsIds(records, orgsInfoRecord, orgIds);
    }

    private static CompaniesInfo getCompaniesNamesIdsAndEmailsInfo(List<SObject> records) {
        CompaniesInfo companies = new CompaniesInfo();

        for(SObject record : records) {
            if(!isContact(record) && isFieldNotBlank(record, 'Unomy_Company_Id_Formula__c')) {
                companies.unomyCompanyIds.add(Integer.valueOf(record.get('Unomy_Company_Id_Formula__c')));
            }else if(!isContact(record) && isContainsSpecialCharacters(record, 'Cleansed_Unomy_Company_Name__c')) {
                companies.unomyCompanyNames.add(getStringValue(record, 'Cleansed_Unomy_Company_Name__c'));
            }else if(!isContact(record) && isContainsSpecialCharacters(record, 'Unomy_Company_Name_Formula__c')) {
                companies.companyNames.add(getStringValue(record, 'Unomy_Company_Name_Formula__c'));
                companies.unomyCompanyNames.add(getStringValue(record, 'Unomy_Company_Name_Formula__c'));
            }
            if(isContainsSpecialCharacters(record, 'Cleansed_Company_Name__c')) {
                companies.cleansedCompanyNames.add(getStringValue(record, 'Cleansed_Company_Name__c'));
            }else if(isContact(record) && isContainsSpecialCharacters(record, 'Company__c')) {
                companies.companyNames.add(getStringValue(record, 'Company__c'));
            }else if(isLead(record) && isContainsSpecialCharacters(record, 'Company')) {
                companies.companyNames.add(getStringValue(record, 'Company'));
            }
            if(isContact(record) && isContainsSpecialCharacters(record, 'Account_Name__c')) {
                companies.companyNames.add(getStringValue(record, 'Account_Name__c'));
            }
            if(isFieldNotBlank(record, 'Name')) {
                companies.companyNames.add(getStringValue(record, 'Name'));
            }
            if(isFieldNotBlank(record, 'Email')) {
                String strDomain = getStringValue(record, 'Email').split('@')[1];
                if(!companies.publicDomains.contains(strDomain)) {
                    companies.emailDomains.add(strDomain);
                }
            }
        }

        return companies;
    }

    private static List<SObject> getrelatedRecordsFromCompanies(CompaniesInfo companies) {
        Set<Id> functionalAccountsIds = getFunctionalAccountsIds();
        List<SObject> relatedRecords = new List<SObject>();
        Id billingAccountRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(GlobalConstants.ACCOUNT_BILLING_ACCOUNT_RECORD_TYPE_DEV_NAME).getRecordTypeId();
        relatedRecords.addAll([SELECT Id, Name, Unomy_Company_ID_Formula__c, CI_Company__c,
                                   Cleansed_Account_Name__c, Cleansed_Unomy_Company_Name__c,
                                   Unomy_Company_Name_Formula__c, Account_Type__c
                               FROM Account
                               WHERE RecordTypeId != :billingAccountRecTypeId
                                   AND Id NOT IN :functionalAccountsIds
                                   AND (CI_Company__c IN: [SELECT Id
                                                           FROM CI_Company__c
                                                           WHERE CI_Company_ID__c IN: companies.unomyCompanyIds]
                                        OR Name IN: companies.companyNames
                                        OR Cleansed_Account_Name__c IN: companies.unomyCompanyNames
                                        OR Cleansed_Account_Name__c IN: companies.cleansedCompanyNames
                                        OR Cleansed_Unomy_Company_Name__c IN: companies.unomyCompanyNames
                                        OR Cleansed_Unomy_Company_Name__c IN: companies.cleansedCompanyNames)
        ]);
        if(companies.emailDomains.isEmpty()) {
            return relatedRecords;
        }
        Set<String> accountsNames = getAccountsNamesForDomains(companies.emailDomains);
        for(AggregateResult contactWithMatchingDomain : [SELECT AccountId, Email_Domain_Text__c
                                                         FROM Contact
                                                         WHERE AccountId NOT IN :functionalAccountsIds
                                                             AND ((Email_Domain_Text__c IN :companies.emailDomains) OR (Account.Name IN :accountsNames))
                                                         GROUP BY AccountId, Email_Domain_Text__c LIMIT 2000]) {
            relatedRecords.add(new Contact(AccountId = (Id)contactWithMatchingDomain.get('AccountId'),
                                           Email_Domain_Text__c = (String)contactWithMatchingDomain.get('Email_Domain_Text__c')));
        }
        return relatedRecords;
    }

    private static Set<Id> getAccountIdsForUniqueDomains(List<SObject> relatedRecords) {
        Set<Id> accountIds = new Set<Id>();
        Set<String> newEmailDomains = new Set<String>();
        for(SObject record : relatedRecords) {
            if(isAccount(record)) {
                accountIds.add(getStringValue(record,'Id'));
            }else if(isFieldNotNull(record, 'Id')
                     && (isLead(record) && isFieldNotNull(record, 'Account__c')) || (isContact(record) && isFieldNotNull(record, 'AccountId'))) {
                if(!newEmailDomains.contains(getStringValue(record,'Email_Domain_Text__c'))) {
                    String accountId = isLead(record) ? getStringValue(record,'Account__c') : getStringValue(record,'AccountId');
                    accountIds.add(accountId);
                    newEmailDomains.add(getStringValue(record,'Email_Domain_Text__c'));
                }
            }
        }
        return accountIds;
    }

    private static OrgsByParametersInfo getOrgsByParameters(List<SObject> relatedRecords, Map<Id,Id> ultimateParents) {
        OrgsByParametersInfo orgsByParameters = new OrgsByParametersInfo();

        for(SObject record : relatedRecords) {
            if(isAccount(record)) {
                Id ultimateParentId = ultimateParents.get(getStringValue(record, 'Id'));
                if(isFieldNotNull(record, 'Unomy_Company_ID_Formula__c')) {
                    orgsByParameters.orgsByUnomyId.put(Decimal.valueOf(getStringValue(record, 'Unomy_Company_ID_Formula__c')), ultimateParentId);
                }
                if(isFieldNotNull(record, 'Cleansed_Unomy_Company_Name__c')) {
                    orgsByParameters.orgsByUnomyName.put(getStringValueLowerCase(record, 'Cleansed_Unomy_Company_Name__c'), ultimateParentId);
                }
                if(isFieldNotNull(record, 'Unomy_Company_Name_Formula__c')) {
                    orgsByParameters.orgsByUnomyName.put(getStringValueLowerCase(record, 'Unomy_Company_Name_Formula__c'), ultimateParentId);
                }
                if(isFieldNotNull(record, 'Cleansed_Account_Name__c')) {
                    orgsByParameters.orgsByName.put(getStringValueLowerCase(record, 'Cleansed_Account_Name__c'), ultimateParentId);
                }
                if(isFieldNotNull(record, 'Name')) {
                    orgsByParameters.orgsByName.put(getStringValueLowerCase(record, 'Name'), ultimateParentId);
                }
            }
            else if(isFieldNotNull(record, 'Id')
                        && (isLead(record) && isFieldNotNull(record, 'Account__c'))
                        || (isContact(record) && isFieldNotNull(record, 'AccountId'))
                    &&(isFieldNotNull(record, 'Email_Domain_Text__c')
                        && !orgsByParameters.orgsByDomain.containsKey(getStringValueLowerCase(record, 'Email_Domain_Text__c')))) {

               String accountIdFieldName = isLead(record) ? getStringValue(record, 'Account__c') : getStringValue(record, 'AccountId');
               orgsByParameters.orgsByDomain.put(getStringValueLowerCase(record, 'Email_Domain_Text__c'), ultimateParents.get(accountIdFieldName));
            }

        }
        return orgsByParameters;
    }

    private static Map<Id,Id> getOrgsIds(List<SObject> records, OrgsByParametersInfo orgsByParameters, Map<Id, Id> orgIds) {
        Map<String, Id> mapAccountIdBySpecialChar = new Map<String, Id>(); // account Id being used to track instance of special character key value
        String specialChar;
        Map<Decimal,Id> orgsByUnomyId = orgsByParameters.orgsByUnomyId;
        Map<String,Id> orgsByUnomyName = orgsByParameters.orgsByUnomyName;
        Map<String,Id> orgsByName = orgsByParameters.orgsByName;
        Map<String,Id> orgsByDomain = orgsByParameters.orgsByDomain;

        for(SObject record : records) {
            Boolean isContact = isContact(record);
            String recordId = getStringValue(record, 'Id');
            if(isContainsDecimalFieldValue(record, 'Unomy_Company_ID_Formula__c', orgsByUnomyId)) {
                orgIds.put(recordId, orgsByUnomyId.get(Decimal.valueOf(getStringValue(record,'Unomy_Company_ID_Formula__c'))));
            }else if(!isContact && isContainsStringFieldValueLowerCase(record, 'Cleansed_Unomy_Company_Name__c', orgsByUnomyName)) {
                orgIds.put(recordId, orgsByUnomyName.get(getStringValueLowerCase(record,'Cleansed_Unomy_Company_Name__c')));
            }else if(!isContact && isContainsStringFieldValueLowerCase(record, 'Cleansed_Unomy_Company_Name__c', orgsByName)) {
                orgIds.put(recordId, orgsByName.get(getStringValueLowerCase(record,'Cleansed_Unomy_Company_Name__c')));
            }else if(isContainsStringFieldValueLowerCase(record, 'Cleansed_Company_Name__c', orgsByUnomyName)) {
                orgIds.put(recordId, orgsByUnomyName.get(getStringValueLowerCase(record,'Cleansed_Company_Name__c')));
            }else if(isContainsStringFieldValue(record, 'Cleansed_Company_Name__c', orgsByName)) {
                orgIds.put(recordId, orgsByName.get(getStringValueLowerCase(record, 'Cleansed_Company_Name__c')));
            }else if(!isContact && isContainsStringFieldValueLowerCase(record, 'Unomy_Company_Name_Formula__c', orgsByUnomyName)) {
                orgIds.put(recordId, orgsByUnomyName.get(getStringValueLowerCase(record,'Unomy_Company_Name_Formula__c')));
            }else if(!isContact && isContainsStringFieldValueLowerCase(record, 'Unomy_Company_Name_Formula__c', orgsByName)) {
                orgIds.put(recordId, orgsByName.get(getStringValueLowerCase(record,'Unomy_Company_Name_Formula__c')));
            }else if(isFieldNotNull(record, 'Id') && isContact && isContainsStringFieldValueLowerCase(record, 'Account_Name__c', orgsByName)) {
                orgIds.put(recordId, orgsByName.get(getStringValueLowerCase(record,'Account_Name__c')));
            }else if(isFieldNotNull(record, 'Id') && !isContact && isContainsStringFieldValueLowerCase(record, 'Company', orgsByName)) {
                orgIds.put(recordId, orgsByName.get(getStringValueLowerCase(record,'Company')));
            }else if(isContainsStringFieldValueLowerCase(record, 'Email_Domain_Text__c', orgsByDomain)) {
                orgIds.put(recordId, orgsByDomain.get(getStringValueLowerCase(record,'Email_Domain_Text__c')));
            }else if(isFieldNotNull(record, 'Id') && !isContact && isContainsStringFieldValueLowerCase(record, 'Name', orgsByName)) {
                orgIds.put(recordId, orgsByName.get(getStringValueLowerCase(record,'Name')));
            }else if( !(mapAccountIdBySpecialChar = getSpecialCharEntry(record, mapAccountIdBySpecialChar)).isEmpty() ) { // check for special char if no matches
                orgIds.put(recordId, mapAccountIdBySpecialChar.values()[0]);
                ApexDebugLog.logException(new OrganizationHelperException('special character Account detected ==> '+new List<String>(mapAccountIdBySpecialChar.keyset())[0]), recordId, 'OrganizationHelper', 'getOrgsByAllCriteria_nopush');
            }else if( (specialChar = getUnknownSpecialCharacter(record)) != null ) { // unknown special char account detected
                orgIds.put(recordId, null);
                ApexDebugLog.logException(new OrganizationHelperException('unknown special character Account detected in one of the following fields ==> '+specialChar), recordId, 'OrganizationHelper', 'getOrgsByAllCriteria');
            }else{
                orgIds.put(recordId, null);
            }
        }
        return orgIds;
    }

    public static Set<String> getAccountsNamesForDomains(Set<String> domains) {
        Map<String, String> accountsNamesByDomains;
        MetadataSetting__mdt metadataRecord = Settings.getMetadataSettingByDevName(ACCOUNTS_NAMES_BY_DOMAINS);
        if (String.isBlank(metadataRecord?.Data__c)) {
            return new Set<String>();
        }
        accountsNamesByDomains = (Map<String, String>) (JSON.deserialize(metadataRecord.Data__c, Map<String, String>.class));
        if(accountsNamesByDomains.isEmpty()){
            return new Set<String>();
        }
        Set<String> accountsNames = new Set<String>();
        Set<String> foundDomains = new Set<String>();
        for (String domainName : accountsNamesByDomains.keySet()) {
            if(domains.contains(domainName)) {
                accountsNames.add(accountsNamesByDomains.get(domainName));
                foundDomains.add(domainName);
            }
        }
        domains.removeAll(foundDomains);
        return accountsNames;
    }

    private static Set<Id> getFunctionalAccountsIds() {
        Set<String> functionalAccountsNames;
        MetadataSetting__mdt metadataRecord = Settings.getMetadataSettingByDevName(FUNCTIONAL_ACCOUNTS_NAMES);
        if (String.isBlank(metadataRecord?.Data__c)) {
            return new Set<Id>();
        }
        Set<Id> accountsIds;
        functionalAccountsNames =  (Set<String>) (JSON.deserialize(metadataRecord.Data__c, Set<String>.class));
        accountsIds = new Map<Id, Account> ([SELECT Id
                                             FROM Account
                                             WHERE Name IN :functionalAccountsNames
                                                OR Parent.Name IN :functionalAccountsNames]).keySet();
        return accountsIds;
    }

    private class CompaniesInfo {
        public Set<Integer> unomyCompanyIds = new Set<Integer>();
        public Set<String> unomyCompanyNames = new Set<String>();
        public Set<String> companyNames = new Set<String>();
        public Set<String> cleansedCompanyNames = new Set<String>();
        public Set<String> emailDomains = new Set<String>();
        public Set<String> publicDomains;

        public CompaniesInfo() {
            publicDomains = getPublicDomains();
        }
    }

    private class OrgsByParametersInfo {
        public Map<Decimal,Id> orgsByUnomyId = new Map<Decimal,Id>();
        public Map<String,Id> orgsByUnomyName = new Map<String,Id>();
        public Map<String,Id> orgsByName = new Map<String,Id>();
        public Map<String,Id> orgsByDomain = new Map<String,Id>();
    }

    public static Boolean isContainsDecimalFieldValue(SObject record, String fieldName, Map<Decimal, Id> collection) {
        return isFieldNotNull(record, fieldName) && collection.containsKey(Decimal.valueOf(getStringValue(record, fieldName)));
    }

    public static Boolean isContainsStringFieldValue(SObject record, String fieldName, Map<String, Id> collection) {
        return isFieldNotNull(record, fieldName) && collection.containsKey(getStringValue(record, fieldName));
    }

    public static Boolean isContainsStringFieldValueLowerCase(SObject record, String fieldName, Map<String, Id> collection) {
        return isFieldNotNull(record, fieldName) && collection.containsKey(getStringValueLowerCase(record, fieldName));
    }

    public static Boolean isFieldBlank(SObject record, String fieldName) {
        return String.isBlank(String.valueOf(record.get(fieldName)));
    }

    public static Boolean isFieldNotBlank(SObject record, String fieldName) {
        return String.isNotBlank(String.valueOf(record.get(fieldName)));
    }

    public static Boolean isFieldNull(SObject record, String fieldName) {
        return (record.get(fieldName) == null);
    }

    public static Boolean isFieldNotNull(SObject record, String fieldName) {
        return (record.get(fieldName) != null);
    }

    private static Boolean isFieldEqualIgnoreCase(SObject record, String fieldName, String value) {
        return String.valueOf(record.get(fieldName)) == value;
    }

    public static String getStringValue(SObject record, String fieldName) {
        return String.valueOf(record.get(fieldName));
    }

    public static String getStringValueLowerCase(SObject record, String fieldName) {
        return getStringValue(record, fieldName).toLowerCase();
    }

    public static Boolean isCampaign(SObject record) {
        return isObjectTypeEqual(record, Schema.Campaign.SObjectType);
    }

    public static Boolean isCampaign(Id recordId) {
        return isObjectTypeEqual(recordId, Schema.Campaign.SObjectType);
    }

    public static Boolean isUser(SObject record) {
        return isObjectTypeEqual(record, Schema.User.SObjectType);
    }

    public static Boolean isUser(Id recordId) {
        return isObjectTypeEqual(recordId, Schema.User.SObjectType);
    }

    public static Boolean isContact(SObject record) {
        return isObjectTypeEqual(record, Schema.Contact.SObjectType);
    }

    public static Boolean isContact(Id recordId) {
        return isObjectTypeEqual(recordId, Schema.Contact.SObjectType);
    }

    public static Boolean isJourney(SObject record) {
        return isObjectTypeEqual(record, Schema.Journey__c.SObjectType);
    }

    public static Boolean isJourney(Id recordId) {
        return isObjectTypeEqual(recordId, Schema.Journey__c.SObjectType);
    }

    public static Boolean isLead(SObject record) {
        return isObjectTypeEqual(record, Schema.Lead.SObjectType);
    }

    public static Boolean isLead(Id recordId) {
        return isObjectTypeEqual(recordId, Schema.Lead.SObjectType);
    }

    public static Boolean isAccount(SObject record) {
        return isObjectTypeEqual(record, Schema.Account.SObjectType);
    }

    public static Boolean isAccount(Id recordId) {
        return isObjectTypeEqual(recordId, Schema.Account.SObjectType);
    }

    public static Boolean isGroup(Id recordId) {
        return isObjectTypeEqual(recordId, Schema.Group.SObjectType);
    }

    private static Boolean isObjectTypeEqual(SObject record, SObjectType objectType) {
        return record.getSObjectType() === objectType;
    }

    private static Boolean isObjectTypeEqual(Id recordId, SObjectType objectType) {
        return recordId.getSobjectType() === objectType;
    }

    private static Boolean isContainsSpecialCharacters(SObject record, String fieldName) {
        return isFieldNotBlank(record, fieldName) && !checkStringForOnlySpecialCharacter(String.valueOf(record.get(fieldName)));
    }

    /*
     * Author: Nicholas Zozaya
     * Description: check specified fields in record for known special characters
     * Issue: ST-5687
     */
    private static Map<String, Id> getSpecialCharEntry(SObject record, Map<String, Id> mapAccountIdBySpecialChar) {
        mapAccountIdBySpecialChar.clear();
        Map<String, String> mapFieldSets = mapSpecialCharSettings.get('fields');
        for (String field : isContact(record) ? mapFieldSets.get('contact').split(',') : mapFieldSets.get('lead').split(',')) {
            if (mapSpecialCharSettings.get('characters').containsKey((String) record.get(field))) {
                mapAccountIdBySpecialChar.put((String) record.get(field), (Id) mapSpecialCharSettings.get('characters').get((String) record.get(field)));
            }
        }
        return mapAccountIdBySpecialChar;
    }

    /*
     * Author: Nicholas Zozaya
     * Description: check specified fields in record for unknown special characters
     * Issue: ST-5687
     */
    private static String getUnknownSpecialCharacter(SObject record){
        String specialChar;
        Map<String, String> mapFieldSets = mapSpecialCharSettings.get('fields');
        for(String field : isContact(record) ? mapFieldSets.get('contact').split(',') : mapFieldSets.get('lead').split(',')) {
            specialChar = checkStringForOnlySpecialCharacter((String) record.get(field)) ? (String) record.get(field) : null;
            if(specialChar != null)
                break;
        }
        return specialChar;
    }

    public static String getSobjectName(SObject record){
        return String.valueOf(record.getSObjectType()).toLowerCase();
    }

    public static Set<String> getPublicDomains(){
        Sales_Console_Setting__mdt objPublicDomainSetting = SalesConsoleSettings.get('PublicDomainSettings');
        Set<String> publicDomains = (Set<String>)JSON.deserialize(objPublicDomainSetting.Data__c, Set<String>.class);
        return publicDomains;
    }

    private static CleansedWrapper cleansedSettingSpecialCharacters;
    private static void getAccountCleansingSetting(){
        cleansedSettingSpecialCharacters = (CleansedWrapper)JSON.deserialize(SalesConsoleSettings.get('AccountCleansingSetting').Data__c.toLowerCase(), CleansedWrapper.class);
    }

    public static Boolean checkStringForOnlySpecialCharacter(String inputString){
        Boolean stringHasSpecialCharsOnly = false;
        if(String.isNotBlank(inputString)) {
            if(cleansedSettingSpecialCharacters == null) {
                getAccountCleansingSetting();
            }
            if(cleansedSettingSpecialCharacters != null && String.isNotBlank(cleansedSettingSpecialCharacters.specialCharactersForOrgFinder)) {
                String specialCharacters = '[' + cleansedSettingSpecialCharacters.specialCharactersForOrgFinder + ']+';
                Pattern specialCharPattern = Pattern.compile(specialCharacters);
                Matcher objMatcher = specialCharPattern.matcher(inputString);
                stringHasSpecialCharsOnly = objMatcher.matches();
            }
        }
        return stringHasSpecialCharsOnly;
    }

    public static Map<Id,Id> getUltimateParents(Set<Id> accountIds){
        Set<Id> accountIdsPool = new Set<Id>(accountIds);
        Map<Id,Id> ultimateAccountParents = new Map<Id,Id>();
        Boolean reachedRoot = false;
        while(!reachedRoot) {
            if(accountIdsPool.isEmpty()) {
                reachedRoot = true;
                continue;
            }
            for(Account accountItem : getAccountParents(accountIdsPool)) {
                Account parentAccount = null;
                if(accountItem.Parent == null) { // has no parent
                    parentAccount = accountItem;
                } else if(accountItem.Parent.Parent == null) { // has one parent
                    parentAccount = accountItem.Parent;
                } else if(accountItem.Parent.Parent.Parent == null) {
                    parentAccount = accountItem.Parent.Parent;
                } else if(accountItem.Parent.Parent.Parent.Parent == null) {
                    parentAccount = accountItem.Parent.Parent.Parent;
                } else if(accountItem.Parent.Parent.Parent.Parent.Parent == null) {
                    parentAccount = accountItem.Parent.Parent.Parent.Parent;
                } else if(accountItem.Parent.Parent.Parent.Parent.Parent != null) { // has parents, we do not know how deep
                    Account lastFoundParentAcc = accountItem.Parent.Parent.Parent.Parent.Parent;
                    ultimateAccountParents.put(accountItem.Id,lastFoundParentAcc.Id);
                    accountIdsPool.add(lastFoundParentAcc.Id);
                    accountIdsPool.remove(accountItem.Id);
                    continue;
                }
                ultimateAccountParents.put(accountItem.Id, filterOrgParent(parentAccount));
                accountIdsPool.remove(accountItem.Id);
            }
        }
        return ultimateAccountParents;
    }

    // To reduce heap size and performance was decided to keep two methods
    public static Map<Id,Account> getUltimateParents(Set<Id> accountIds, List<String> accountFields){
        String query = buildAccountParentsQuery(accountFields);
        Set<Id> accountIdsPool = new Set<Id>(accountIds);
        Map<Id,Account> mapUltimateAccounts = new Map<Id,Account>();
        Boolean reachedRoot = false;
        while(!reachedRoot) {
            if(accountIdsPool.isEmpty()) {
                reachedRoot = true;
                continue;
            }
            for(Account accRec : (List<Account>)Database.query(query)) {
                Account objAccount = null;
                Account objParentAccount = null;
                if(accRec.Parent == null) {
                    objAccount = accRec;
                }else if(accRec.Parent.Parent == null) {
                    objAccount = accRec.Parent;
                }else if(accRec.Parent.Parent.Parent == null) {
                    objAccount = accRec.Parent.Parent;
                }else if(accRec.Parent.Parent.Parent.Parent == null) {
                    objAccount = accRec.Parent.Parent.Parent;
                }else if(accRec.Parent.Parent.Parent.Parent.Parent == null) {
                    objAccount = accRec.Parent.Parent.Parent.Parent;
                }else if(accRec.Parent.Parent.Parent.Parent.Parent != null) {
                    objParentAccount = accRec.Parent.Parent.Parent.Parent.Parent;
                    accountIdsPool.add(objParentAccount.Id);
                }
                if(objAccount?.Account_Type__c == GlobalConstants.ACCOUNT_TYPE_ORG) {
                    mapUltimateAccounts.put(accRec.Id,objAccount);
                }
                accountIdsPool.remove(accRec.Id);
            }
        }
        return mapUltimateAccounts;
    }

    public static String getCleansedName(String name){
        if(String.isBlank(name)) {
            return null;
        }
        CleansedWrapper cleansedSetting = (CleansedWrapper)JSON.deserialize(SalesConsoleSettings.get('AccountCleansingSetting').Data__c, CleansedWrapper.class);
        String cleansedName = name.toLowerCase();
        for(String specialChar:cleansedSetting.specialCharacters.split('|')) {
            cleansedName = cleansedName.replace(specialChar,'');
        }
        while(true) {
            Boolean isStartsWith = false;
            for(String startsWith : cleansedSetting.starts_with) {
                startsWith = startsWith.toLowerCase();
                cleansedName = cleansedName.trim();
                if(cleansedName.startsWith(startsWith+' ')) {
                    cleansedName = cleansedName.replace(startsWith,'');
                    isStartsWith = true;
                }
            }
            if(!isStartsWith) {
                break;
            }
        }
        while(true) {
            Boolean isEndsWith = false;
            for(String endsWith:cleansedSetting.ends_with) {
                endsWith = endsWith.toLowerCase();
                cleansedName = cleansedName.trim();
                if(cleansedName.endsWith(' '+endsWith)) {
                    cleansedName = cleansedName.replace(endsWith,'');
                    isEndsWith = true;
                }
            }
            if(!isEndsWith) {
                break;
            }
        }
        cleansedName = cleansedName.replaceAll(' ', '');
        return cleansedName;
    }

    private static Id filterOrgParent(Account parent) {
        return (parent.Account_Type__c == GlobalConstants.ACCOUNT_TYPE_ORG) ? parent.Id : null;
    }

    private static List<Account> getAccountParents(Set<Id> accountIds) {
        return new List<Account>([SELECT Id,
                                         Account_Type__c,
                                         Parent.Id,
                                         Parent.Account_Type__c,
                                         Parent.Parent.Id,
                                         Parent.Parent.Account_Type__c,
                                         Parent.Parent.Parent.Id,
                                         Parent.Parent.Parent.Account_Type__c,
                                         Parent.Parent.Parent.Parent.Id,
                                         Parent.Parent.Parent.Parent.Account_Type__c,
                                         Parent.Parent.Parent.Parent.Parent.Id,
                                         Parent.Parent.Parent.Parent.Parent.Account_Type__c
                                  FROM Account
                                  WHERE Id IN: accountIds]);
    }

    private static String buildAccountParentsQuery(List<String> accountFields) {
        List<String> extendedAccountFields = new List<String>(accountFields);
        extendedAccountFields.add('Id');
        extendedAccountFields.add('Account_Type__c');

        List<String> parentFields = new List<String>();
        for(Integer i=0; i < 5; i++) {
            String field='';
            for(Integer j=i; j >= 0; j--) {
                field += 'Parent.';
            }
            for(String fieldName :extendedAccountFields) {
                parentFields.add(field+fieldName);
            }
        }
        String query = 'SELECT '+
                String.join(extendedAccountFields, ',') +
                ', ' + String.join(parentFields, ',') +
                ' FROM Account WHERE Id IN: accountIds';
        return query;
    }

    class CleansedWrapper {
        Set<String> starts_with {get; set;}
        Set<String> ends_with {get; set;}
        String specialCharacters {get; set;}
        String specialCharactersForOrgFinder {get; set;}
    }
    public class OrganizationHelperException extends Exception {}
}