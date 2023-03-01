/************************************************************************************************************************************
    Author 		: 	Nikhil Mehta
    Description : 	This class matches incoming Leads / Contacts with existing Accounts.
    History		:
	----------------------------------------------------------------------------------------------------------------------------------
	VERSION		DATE				AUTHOR					DETAIL
	1	    October 2018	      Nikhil Mehta     	  Initial Development
**************************************************************************************************************************************/
public class OrganizationHelperServices {
    public static Map<Id, String> mapIsNumberOfFullTimeEmployeePresent = new Map<Id, String>();
    public List<String> getListFields(String sObjectName) {

        List<String> lstFields = new List<String>{'CI_Company__c', 'Email_Domain_Text__c', 'Unomy_Company_ID_Formula__c', 'Cleansed_Company_Name__c', 'Name', 'FirstName', 'LastName',  'Email', 'Phone', 'Unomy_Company_Phone_Formula__c', 'Unomy_Company_Website_Formula__c'};
			if(sObjectName.toLowerCase() == 'lead'){
                lstFields.addAll(new List<String>{'Company', 'Website', 'Account__c', 'Account__r.Account_Type__c', 'Cleansed_Unomy_Company_Name__c', 'Unomy_Company_Name_Formula__c'});
                return lstFields;
            }else if(sObjectName.toLowerCase() == 'contact'){
                lstFields.addAll(new List<String>{'AccountId', 'Account.Account_Type__c', 'Account_Name__c', 'LeadSource'});
                return lstFields;
            }
        return null;
    }

    /************************************************************************************************************************************
    Author 		: 	Nikhil Mehta
    Description : 	Service method called by external classes to match Lead/Contact.
    History		:
	----------------------------------------------------------------------------------------------------------------------------------
	VERSION		DATE				AUTHOR					DETAIL
	1			            	Nikhil Mehta     	Initial Development
    **************************************************************************************************************************************/
    public static Id findOrCreateOrgByNewCriteria(sObject objRecord) {
        Map<Id, Id> mapOrgByIds = findOrCreateOrgByNewCriteria(new List<sObject>{objRecord});
        return mapOrgByIds.get(String.valueOf(objRecord.get('Id')));
    }

    /************************************************************************************************************************************
    Author 		: 	Nikhil Mehta
    Description : 	Dispatcher method to begin processing of Lead and matching Accounts.
    History		:
	----------------------------------------------------------------------------------------------------------------------------------
	VERSION		DATE				AUTHOR					DETAIL
	1			            	Nikhil Mehta     	Initial Development
    **************************************************************************************************************************************/
    public static Map<Id, Id> findOrCreateOrgByNewCriteria(List<sObject> lstRecords) {
        Map<Id, Map<String, Set<String>>> mapMatchingAccounts = findOrgByNewCriterias(lstRecords);
        Map<Id, Id> mapOrgByIds = new Map<Id, Id>();
        List<String> lstHighConfidenceAccountIds;
        Set<Id> setContactIds = new Set<Id>();
        for(Id sourceId : mapMatchingAccounts.keySet()){
            if(String.valueOf(sourceId).startsWith('003') && (mapMatchingAccounts.get(sourceId) == null || mapMatchingAccounts.get(sourceId).get('lowConfidenceAccountIds') != null)){
                setContactIds.add(sourceId);
            }else if(mapMatchingAccounts.get(sourceId) != null && mapMatchingAccounts.get(sourceId).get('highConfidenceAccountIds') != null){
                lstHighConfidenceAccountIds = new List<String>(mapMatchingAccounts.get(sourceId).get('highConfidenceAccountIds'));
                if(!lstHighConfidenceAccountIds.isEmpty()) mapOrgByIds.put(sourceId, lstHighConfidenceAccountIds[0]); // just grab first high-confidence ID to merge incoming Lead/Contact
            }
            if(!mapOrgByIds.containsKey(sourceId)){
                mapOrgByIds.put(sourceId, null);
            }
        }
        if(!setContactIds.isEmpty()){
            Map<Id, sObject> mapRecords = new Map<Id, sObject>(lstRecords);
            Map<String, Object> mapSetting = Settings.getMetadataSettingByDevNameAsMap('PartnerReferralLSandLSDforEntRecordType');
            Map<Id,sObject> mapFieldMappings = FieldMappingsHelper.getMappings(setContactIds, 'FieldMappings_ContactToAccount');
            Contact objContact;
            Integer thresholdLimit = Integer.valueOf(Label.Duplicate_Account_Creation_Threshold);
            for(Id sourceId : mapFieldMappings.keySet()){
                if(String.isBlank(String.valueOf(mapFieldMappings.get(sourceId).get('Primary_Member__c')))){
                    mapFieldMappings.get(sourceId).put('Primary_Member__c', sourceId);
                }
                if(PersonEndpointHelper.personContactId == sourceId){
                    mapFieldMappings.get(sourceId).put('Account_SubType__c', 'Broker');
                }
                mapIsNumberOfFullTimeEmployeePresent.put(sourceId, 'no');

                if(mapMatchingAccounts.get(sourceId) != null && mapMatchingAccounts.get(sourceId).get('lowConfidenceAccountIds') != null){
                    mapFieldMappings.get(sourceId).put('Potential_Match_Ids__c', String.join(new List<String>(mapMatchingAccounts.get(sourceId).get('lowConfidenceAccountIds')), ','));
                }

                if(String.isBlank(String.valueOf(mapFieldMappings.get(sourceId).get('Name')))){
                    for(sObject record : lstRecords){
                        if(record.get('Id') == sourceId){
                            objContact = (Contact)record;
                            if(objContact.Account_Name__c != null){
                                mapFieldMappings.get(sourceId).put('Name', objContact.Account_Name__c);

                            }else if(objContact.Name != null){
                                mapFieldMappings.get(sourceId).put('Name', objContact.Name);
                            }else if(objContact.FirstName != null && objContact.LastName != null){
                                mapFieldMappings.get(sourceId).put('Name', (objContact.FirstName+' '+objContact.LastName));
                            }else if(objContact.LastName != null){
                                mapFieldMappings.get(sourceId).put('Name', objContact.LastName);
                            }
                        }
                    }
                }
                mapFieldMappings.get(sourceId).put('Account_Type__c', 'Org');
                objContact = (Contact)mapRecords.get(sourceId);
            }
            List<Database.SaveResult> lstSaveResult = Database.insert(mapFieldMappings.values());
            for(Id sourceId : mapFieldMappings.keySet()){
                if(!String.isBlank(String.valueOf(mapFieldMappings.get(sourceId).get('Id')))){
                    if(mapIsNumberOfFullTimeEmployeePresent.containsKey(sourceId)){
                        mapIsNumberOfFullTimeEmployeePresent.put(String.valueOf(mapFieldMappings.get(sourceId).get('Id')), mapIsNumberOfFullTimeEmployeePresent.get(sourceId));
                    }
                    mapOrgByIds.put(String.valueOf(mapFieldMappings.get(sourceId).get('Primary_Member__c')), String.valueOf(mapFieldMappings.get(sourceId).get('Id')));
                }else{
                    mapOrgByIds.put(sourceId,null);
                }
            }
        }
        return mapOrgByIds;
    }


    public static Map<String, Set<String>> findOrgByNewCriterias(sObject objRecord){
        Map<Id, Map<String, Set<String>>> mapMatchingAccounts = findOrgByNewCriterias(new List<sObject>{objRecord});
        return mapMatchingAccounts.get(String.valueOf(objRecord.get('Id'))) != null ? mapMatchingAccounts.get(String.valueOf(objRecord.get('Id'))) : null;
    }

    /************************************************************************************************************************************
    Author 		: 	Nikhil Mehta
    Description : 	This method either (1) returns the Account related to the Lead/Contact, or begins matching processing if no related Account.
    History		:
	----------------------------------------------------------------------------------------------------------------------------------
	VERSION		DATE				AUTHOR					DETAIL
	1			            	Nikhil Mehta     	Initial Development
    **************************************************************************************************************************************/
    public static Map<Id, Map<String, Set<String>>> findOrgByNewCriterias(List<sObject> lstRecords){
        Map<Id, Map<String, Set<String>>> mapMatchingAccounts = new Map<Id, Map<String, Set<String>>>();
        Set<String> setAccountTypes = new Set<String>{'org', 'sales'};
        List<sObject> lstEntitiesWithNoOrg = new List<sObject>();
        for(sObject objRecord : lstRecords){
            mapMatchingAccounts.put(String.valueOf(objRecord.get('Id')), null);
            String strOrgField = String.valueOf(objRecord.get('Id')).toLowerCase().startsWith('00q')?'Account__c':'AccountId';
            if(String.isNotBlank(String.valueOf(objRecord.get(strOrgField))) && setAccountTypes.contains(String.valueOf(objRecord.getSObject(strOrgField =='Account__c'?'Account__r':'Account').get('Account_Type__c')).toLowerCase())){
                mapMatchingAccounts.put(String.valueOf(objRecord.get('Id')), new Map<String, Set<String>>{'highConfidenceAccountIds' => new Set<String>{String.valueOf(objRecord.get(strOrgField))}});
            }else{
                lstEntitiesWithNoOrg.add(objRecord);
            }
        }
        if(!lstEntitiesWithNoOrg.isEmpty()){
            return getOrgsByNewCriterias(lstEntitiesWithNoOrg, mapMatchingAccounts);
        }else{
            return mapMatchingAccounts;
        }
    }

    /************************************************************************************************************************************
    Author 		: 	Nikhil Mehta
    Description : 	Get all potential matched Accounts, group them by matchable values, then compare them to incoming Lead/Contact values.
    History		:
	----------------------------------------------------------------------------------------------------------------------------------
	VERSION		DATE				AUTHOR					DETAIL
	1			            	Nikhil Mehta     	Initial Development
    **************************************************************************************************************************************/
    public static Map<Id, Map<String, Set<String>>> getOrgsByNewCriterias(List<sObject> lstRecords, Map<Id, Map<String, Set<String>>> mapMatchingAccounts) {
        List<String> lstBypassNames = (List<String>) JSON.deserialize(Settings.getMetadataSettingByDevName('Organization_Helper_Bypass_Names').Data__c, List<String>.class);
        Set<Id> setCICompanyIds = new Set<Id>();
        Set<String> setUnomyCompanyNames = new Set<String>();
        Set<String> setCompanyNames = new Set<String>();
        Set<String> setCleansedCompanyNames = new Set<String>();
        Set<String> setWebsites = new Set<String>();
        Set<String> setPhoneNumbers = new Set<String>();
        Set<String> setEmailDomains = new Set<String>();
        Set<String> setPublicDomains = OrganizationHelper.getPublicDomains();
        for(sObject objRecord : lstRecords){
            if(String.isNotBlank(String.valueOf(objRecord.get('CI_Company__c')))){
                setCICompanyIds.add(String.valueOf(objRecord.get('CI_Company__c')));
            }
            // edited by Nick 10/30/2019 to stop matching on [NOT PROVIDED] name
            if(objRecord.getSObjectType() == Lead.SObjectType && String.isNotBlank(String.valueOf(objRecord.get('Cleansed_Unomy_Company_Name__c'))) && !lstBypassNames.contains(String.valueOf(objRecord.get('Cleansed_Unomy_Company_Name__c'))) && !OrganizationHelper.checkStringForOnlySpecialCharacter(String.valueOf(objRecord.get('Cleansed_Unomy_Company_Name__c')))){
                setUnomyCompanyNames.add(String.valueOf(objRecord.get('Cleansed_Unomy_Company_Name__c')));
            }
            if(objRecord.getSObjectType() == Lead.SObjectType && String.isNotBlank(String.valueOf(objRecord.get('Unomy_Company_Name_Formula__c'))) && !lstBypassNames.contains(String.valueOf(objRecord.get('Unomy_Company_Name_Formula__c'))) && !OrganizationHelper.checkStringForOnlySpecialCharacter(String.valueOf(objRecord.get('Unomy_Company_Name_Formula__c')))){
                setCompanyNames.add(String.valueOf(objRecord.get('Unomy_Company_Name_Formula__c')));
                setUnomyCompanyNames.add(String.valueOf(objRecord.get('Unomy_Company_Name_Formula__c')));
            }
            // edited by Nick 10/30/2019 to stop matching on [NOT PROVIDED] name
            if(String.isNotBlank(String.valueOf(objRecord.get('Cleansed_Company_Name__c'))) && !lstBypassNames.contains(String.valueOf(objRecord.get('Cleansed_Company_Name__c'))) && !OrganizationHelper.checkStringForOnlySpecialCharacter(String.valueOf(objRecord.get('Cleansed_Company_Name__c')))){
                setCleansedCompanyNames.add(String.valueOf(objRecord.get('Cleansed_Company_Name__c')));
            }
			else if(String.valueOf(objRecord.get('Id')).toLowerCase().startsWith('00q') && String.isNotBlank(String.valueOf(objRecord.get('Company'))) && !lstBypassNames.contains(String.valueOf(objRecord.get('Company'))) && !OrganizationHelper.checkStringForOnlySpecialCharacter(String.valueOf(objRecord.get('Company')))){
                setCompanyNames.add(String.valueOf(objRecord.get('Company')));
            }
            // edited by Nick 10/30/2019 to stop matching on [NOT PROVIDED] name
            if(String.isNotBlank(String.valueOf(objRecord.get('Name'))) && !lstBypassNames.contains(String.valueOf(objRecord.get('Name'))) && !OrganizationHelper.checkStringForOnlySpecialCharacter(String.valueOf(objRecord.get('Name')))){
                setCompanyNames.add(String.valueOf(objRecord.get('Name')));
            }
            if(String.valueOf(objRecord.get('Id')).toLowerCase().startsWith('00q') && String.isNotBlank(String.valueOf(objRecord.get('Website')))){
                setWebsites.add(String.valueOf(objRecord.get('Website')));
            }
            if(String.isNotBlank(String.valueOf(objRecord.get('Phone')))){
                setPhoneNumbers.add(String.valueOf(objRecord.get('Phone')));
            }
        }
        List<Account> lstAccounts = new List<Account>();

        lstAccounts.addAll([SELECT Id, Name, Website, Phone, Unomy_Company_ID_Formula__c, CI_Company__c, Cleansed_Account_Name__c,
                            Cleansed_Unomy_Company_Name__c, Unomy_Company_Name_Formula__c, Account_Type__c,
                            Unomy_Company_Phone_Formula__c, Unomy_Company_Website_Formula__c FROM Account WHERE Account_Type__c IN ('Org','Sales') AND
                            (CI_Company__c IN : setCICompanyIds OR Name IN :setCompanyNames OR Cleansed_Account_Name__c IN :setUnomyCompanyNames
                             OR Cleansed_Account_Name__c IN :setCleansedCompanyNames)]);
        Set<Id> setAccountIds = new Set<Id>();
        Set<String> setNewEmailDomains = new Set<String>();
        for(Account objAccount : lstAccounts){
            setAccountIds.add(objAccount.Id);
        }
        Map<Id,Id> mapUltimateParents = OrganizationHelper.getUltimateParents(setAccountIds);
        Map<Id, Set<Id>> mapOrgsByCICompanyIds = new Map<Id, Set<Id>>();
        Map<String, Map<String, Set<Id>>> mapHighConfidenceAccounts = new Map<String, Map<String, Set<Id>>>();
        List<String> lstStrings;
        Map<String, Set<String>> mapMatchingCriterias = getSearchingOrganizationCriteria();
        Map<String, Set<String>> mapMatchingCriteriaWithAccountIds = new Map<String, Set<String>>();
        for(Account objAccount : lstAccounts){
            setMatchingAccounts(objAccount, mapMatchingCriteriaWithAccountIds, mapMatchingCriterias.get('matchingCriteria'), true);
        }
        Set<String> setHighConfidenceAccountIds;
        Map<Id, String> mapLowConfidenceRecordsWithEmailDomain = new Map<Id, String>();
        String key;
        List<sObject> lstLowConfidenceCheck = new List<sObject>();
        for(sObject objRecord : lstRecords){
            if( String.isNotBlank(String.valueOf(objRecord.get('Id'))) ){
                key = OrganizationHelper.getSobjectName(objRecord) + 'MatchingCriteria';
                if( mapMatchingCriterias.containsKey(key) ){
                    setHighConfidenceAccountIds = setMatchingAccounts(objRecord, mapMatchingCriteriaWithAccountIds, mapMatchingCriterias.get(key), false);
                }
            }
            if( setHighConfidenceAccountIds != null ){
                mapMatchingAccounts.put(String.valueOf(objRecord.get('Id')), new Map<String, Set<String>>{'highConfidenceAccountIds' => setHighConfidenceAccountIds});
                continue;
            }else if(  String.isNotBlank(String.valueOf(objRecord.get('Email'))) && !OrganizationHelper.checkStringForOnlySpecialCharacter(String.valueOf(objRecord.get('Email'))) ){
                String strDomain = String.valueOf(objRecord.get('Email')).split('@')[1];
                if(!setPublicDomains.contains(strDomain)){
                    mapLowConfidenceRecordsWithEmailDomain.put(String.valueOf(objRecord.get('Id')), strDomain.toLowerCase());
                }
            }
            if( !mapMatchingAccounts.containsKey(String.valueOf(objRecord.get('Id'))) ){
                // mapMatchingAccounts.put(String.valueOf(objRecord.get('Id')), null);
                lstLowConfidenceCheck.add(objRecord);
            }
        }
        if( !lstLowConfidenceCheck.isEmpty() ){
            getLowConfidenceAccountInMap(mapLowConfidenceRecordsWithEmailDomain, mapMatchingAccounts, lstLowConfidenceCheck, lstAccounts);
        }
        return mapMatchingAccounts;
    }

    /************************************************************************************************************************************
    Author 		: 	Nikhil Mehta
    Description : 	If isPut is TRUE, create a map of {match_value} to Set of Account Ids
                    If isPut is FALSE, return Accounts which match the given record's values
    History		:
	----------------------------------------------------------------------------------------------------------------------------------
	VERSION		DATE				AUTHOR					DETAIL
	1			            	Nikhil Mehta     	Initial Development
    2         3 Jan 2020        Nicholas Zozaya     Add confidence level awareness
    **************************************************************************************************************************************/
    public static set<String> setMatchingAccounts(sObject record, Map<String, Set<String>> matchingAccounts, Set<String> setOrgMatchingCriteria, Boolean isPut){
        String keyValue;
        Set<String> setLowConfidenceId = new Set<String>();
        String confidenceLevel = '';
        for(String key : setOrgMatchingCriteria){
            if( key.toLowerCase().contains('confidence') ){
                    confidenceLevel = key.toLowerCase().remove('confidence');
                    continue;
            }
            keyValue = '';
            for(String fieldName : key.split('-')){
                if( String.isBlank(String.valueOf(record.get(fieldName))) ){
                    keyValue = '';
                    break;
                }
                keyValue = keyValue + (String.isBlank(keyValue) ? '' : '-') + String.valueOf(record.get(fieldName)).toLowerCase();
            }
            if(String.isNotBlank(keyValue)){
                if( !isPut && matchingAccounts.containsKey(keyValue) && !matchingAccounts.get(keyValue).isEmpty() ){
                    if( confidenceLevel == 'low' ){
                        setLowConfidenceId.addAll(matchingAccounts.get(keyValue));
                    }
                    if( confidenceLevel == 'high' ){
                        return matchingAccounts.get(keyValue);
                    }
                }
                if( isPut ){
                    if( !matchingAccounts.containsKey(keyValue) ){
                        matchingAccounts.put(keyValue, new Set<String>());
                    }
                    matchingAccounts.get(keyValue).add(String.valueOf(record.get('Id')));
                }
            }
        }
        if( !setLowConfidenceId.isEmpty() ) return setLowConfidenceId;
        return null;
    }

    /************************************************************************************************************************************
    Author 		: 	Nikhil Mehta
    Description : 	Put Accounts whose email domain or low-confidence field values match same fields in incoming Lead/Contact
    History		:
	----------------------------------------------------------------------------------------------------------------------------------
	VERSION		DATE				AUTHOR					DETAIL
	1			            	 Nikhil Mehta     	  Initial Development
    2          3 Jan 2020       Nicholas Zozaya       Add low-confidence criteria Accounts to map
    **************************************************************************************************************************************/
    public static void getLowConfidenceAccountInMap(Map<Id, String> mapLowConfidenceRecordsWithEmailDomain, Map<Id, Map<String, Set<String>>> mapMatchingAccounts, List<sObject> lstRecords, List<Account> lstAccounts) {
        Set<String> setEmailDomains;
        List<sObject> lstLeadContacts = new List<sObject>();
        Map<String, Set<String>> mapEmailDomainWithAccountIds = new Map<String, Set<String>>();
        String strEmailDomain;
        if(!mapLowConfidenceRecordsWithEmailDomain.isEmpty()){
            setEmailDomains = new Set<String>(mapLowConfidenceRecordsWithEmailDomain.values());
            Set<Id> setAccountIds = new Set<Id>();
            for(AggregateResult objLeadAggResult : [SELECT Account__c, Email_Domain_Text__c FROM Lead WHERE Account__r.Account_Type__c IN ('Org','Sales') AND Email_Domain_Text__c IN :setEmailDomains AND isConverted = FALSE GROUP BY Account__c, Email_Domain_Text__c LIMIT 2000]){
                setEmailDomainMatchAccounts(String.valueOf(objLeadAggResult.get('Email_Domain_Text__c')), String.valueOf(objLeadAggResult.get('Account__c')), mapEmailDomainWithAccountIds);
                setAccountIds.add(String.valueOf(objLeadAggResult.get('Account__c')));
            }
            for(AggregateResult objContactAggResult : [SELECT AccountId, Email_Domain_Text__c FROM Contact WHERE Account.Account_Type__c IN ('Org','Sales') AND Email_Domain_Text__c IN :setEmailDomains GROUP BY AccountId, Email_Domain_Text__c LIMIT 2000]){
                setEmailDomainMatchAccounts(String.valueOf(objContactAggResult.get('Email_Domain_Text__c')), String.valueOf(objContactAggResult.get('AccountId')), mapEmailDomainWithAccountIds);
                setAccountIds.add(String.valueOf(objContactAggResult.get('AccountId')));
            }
            Map<Id, Id> mapUltimateParents = OrganizationHelper.getUltimateParents(setAccountIds);
            Set<String> setAllAccountIds;
            for(Id recordId : mapLowConfidenceRecordsWithEmailDomain.keySet()){
                if(mapEmailDomainWithAccountIds.containsKey(mapLowConfidenceRecordsWithEmailDomain.get(recordId))){
                    setAllAccountIds = new Set<String>(mapEmailDomainWithAccountIds.get(mapLowConfidenceRecordsWithEmailDomain.get(recordId)));
                    for(String accountId : mapEmailDomainWithAccountIds.get(mapLowConfidenceRecordsWithEmailDomain.get(recordId))){
                        if(mapUltimateParents.containsKey(accountId)){
                            setAllAccountIds.add(mapUltimateParents.get(accountId));
                        }
                    }
                    mapMatchingAccounts.put(String.valueOf(recordId), new Map<String, Set<String>>{'lowConfidenceAccountIds' => setAllAccountIds});
                }
            }
        }
        Map<String, Set<String>> matchingCriteria = getSearchingOrganizationCriteria();
        Set<String> setLowConfidenceCriteria = matchingCriteria.get(String.valueOf(lstRecords[0].Id).toLowerCase().startsWith('00q') ? 'lowConfidenceLeadMatchingCriteria' : 'lowConfidenceContactMatchingCriteria');
        String keyValue;
        Map<String, Set<String>> mapLowConfidenceAccValueToIds = new Map<String, Set<String>>();
        if(!lstAccounts.isEmpty()){
            for(sObject account : lstAccounts){
                setMatchingAccounts(account, mapLowConfidenceAccValueToIds, matchingCriteria.get('matchingCriteria'), true);
            }
        }
        if(!lstRecords.isEmpty()){
            for(sObject record : lstRecords){
                Set<String> setMatchedAccounts = setMatchingAccounts(record, mapLowConfidenceAccValueToIds, setLowConfidenceCriteria, false);
                if( setMatchedAccounts != null && !setMatchedAccounts.isEmpty() ){
                    mapMatchingAccounts.put(String.valueOf(record.Id), new Map<String, Set<String>>{'lowConfidenceAccountIds' => setMatchedAccounts});
                }
            }
        }
    }

    public static void setEmailDomainMatchAccounts(String strEmailDomain, String accountId, Map<String, Set<String>> mapEmailDomainWithAccountIds) {
        strEmailDomain = strEmailDomain.toLowerCase();
        if(!mapEmailDomainWithAccountIds.containsKey(strEmailDomain)){
            mapEmailDomainWithAccountIds.put(strEmailDomain, new Set<String>());
        }
        mapEmailDomainWithAccountIds.get(strEmailDomain).add(accountId);
    }

    public static Map<String, Set<String>> getSearchingOrganizationCriteria(){
        MetadataSetting__mdt orgSearchingCriteria = Settings.getMetadataSetting('Searching_Organization_Criteria');
        Map<String, Set<String>> mapSearchOrgCriteria;
        if(orgSearchingCriteria != null){
            mapSearchOrgCriteria = (Map<String, Set<String>>) JSON.deserialize(orgSearchingCriteria.Data__c, Map<String, Set<String>>.class);
        }
        return mapSearchOrgCriteria;
    }
}