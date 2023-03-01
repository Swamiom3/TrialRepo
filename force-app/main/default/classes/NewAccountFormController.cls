/******************************************************************************************************************************
    Author      :  Nicholas Zozaya
    Description :  Utility class for newAccountForm_360 lwc (see in NewOrganization.cmp)
    History     :  --
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION                 DATE            ISSUE       AUTHOR                          DETAIL
    1                     18 Oct 2019      -          Nicholas Zozaya              Initial Developement
******************************************************************************************************************************/
public class NewAccountFormController {

    final static String QUERY_SELECT = 'SELECT ';
    final static String QUERY_WHERE =  ' FROM Account WHERE ';
    static List<Account> lstMatchedAccounts = new List<Account>();
    static List<Account> lstFuzzyMatchedAccounts = new List<Account>();

    /******************************************************************************************************************************
    Author      :  Nicholas Zozaya
    Description :  Executes exact search followed by fuzzy search, 
                   returns # of Accounts equal to Account_Search_Limit label
    History     :  --
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION                 DATE            ISSUE       AUTHOR                          DETAIL
    1                     18 Oct 2019      -          Nicholas Zozaya              Initial Developement1                     2 Sep 2019      -          Nicholas Zozaya              Initial Developement
    ******************************************************************************************************************************/
    @AuraEnabled
    public static List<Account> getAccountsByCriteria(String serializedSearchTerms, Map<String, Map<String, String>> mapFieldApiNameToSettings){				
        Map<String, String> mapSearchTerms = (Map<String, String>) JSON.deserialize(serializedSearchTerms, Map<String, String>.class);
        Integer accountSearchLimit = Integer.valueOf(Label.Account_Search_Limit);
        lstMatchedAccounts = getExactMatchAccounts(mapSearchTerms, mapFieldApiNameToSettings, accountSearchLimit); 
        accountSearchLimit = accountSearchLimit - lstMatchedAccounts.size();
        if(accountSearchLimit < 1){
            return lstMatchedAccounts;
        }
        lstMatchedAccounts.addAll(getFuzzyMatchAccounts(mapSearchTerms, mapFieldApiNameToSettings, accountSearchLimit));
        return lstMatchedAccounts;
    }

    private static List<Account> getExactMatchAccounts(Map<String, String> mapSearchTerms, Map<String, Map<String, String>> mapFieldApiNameToSettings, Integer accountSearchLimit){
        String exactQueryString = QUERY_SELECT + constructSelectStatement(mapFieldApiNameToSettings) + QUERY_WHERE;
        for(String key : mapSearchTerms.keyset()){ // construct query filter
            if(key.toLowerCase().contains('employees') || (key.toLowerCase() == 'website' && String.isBlank(mapSearchTerms.get(key)))){
                continue;
            }
            if((key.toLowerCase() == 'phone' && String.isBlank(mapSearchTerms.get(key)))){  //phone is no more required in the search form
                continue;
            }
            if((key.toLowerCase() == 'phone') || (key.toLowerCase() == 'website') || (key.toLowerCase().contains('email'))){  //search criteria will only contain name.
                continue;
            }
            if(key.toLowerCase() == 'website'){
				exactQueryString+= 'Name = \''+getParsedWebsite(mapSearchTerms.get(key))+'\' OR '; // exact match website domain to name
            }
            if(key.toLowerCase() == 'name'){
                exactQueryString += key+' LIKE \''+getCleansedName(mapSearchTerms.get(key))+'\' OR ';
        	}
            exactQueryString+=key+'= \''+mapSearchTerms.get(key)+'\' OR ';
        }
        exactQueryString = exactQueryString.substringBeforeLast('OR').trim() + ' LIMIT :accountSearchLimit';
        return (List<Account>) Database.query(exactQueryString);
    }

    private static List<Account> getFuzzyMatchAccounts(Map<String, String> mapSearchTerms, Map<String, Map<String, String>> mapFieldApiNameToSettings, Integer accountSearchLimit){
        String fuzzyQueryFullName;
        String fuzzyQueryString = QUERY_SELECT + constructSelectStatement(mapFieldApiNameToSettings) + QUERY_WHERE + '(';
        for(String key : mapSearchTerms.keyset()){ // construct query filter
            if(key.toLowerCase().contains('employees') || (key.toLowerCase() == 'website' && String.isBlank(mapSearchTerms.get(key)))){ // don't search fte or blank website
                continue;
            }
            if((key.toLowerCase() == 'phone' && String.isBlank(mapSearchTerms.get(key)))){  //phone is no more required in the search form
                continue;
            }
            if((key.toLowerCase() == 'phone') || (key.toLowerCase() == 'website') || (key.toLowerCase().contains('email'))){  //search criteria will only contain name.
                continue;
            }
            if(key.toLowerCase() == 'name'){
                if(mapSearchTerms.get(key).contains(' ')){ // if Name contains space, use both split and full Name as search terms
                    fuzzyQueryFullName = fuzzyQueryString;
                }
                String name = mapSearchTerms.get(key).contains(' ') ? mapSearchTerms.get(key).substringBefore(' ') : mapSearchTerms.get(key);
                if(String.isNotBlank(fuzzyQueryFullName)) fuzzyQueryFullName += key+' LIKE \''+mapSearchTerms.get(key)+'%\' OR ';
                fuzzyQueryString += key+' LIKE \''+getCleansedName(name)+'%\' OR ';
                continue;
            }
            if(key.toLowerCase() == 'website'){
                if(String.isNotBlank(fuzzyQueryFullName)) fuzzyQueryFullName += 'Website LIKE \'%.'+getParsedWebsite(mapSearchTerms.get(key))+'.%\' OR ';
                fuzzyQueryString += 'Website LIKE \'%.'+getParsedWebsite(mapSearchTerms.get(key))+'.%\' OR ';
                continue;
            }
            fuzzyQueryString += key+'= \''+mapSearchTerms.get(key)+'\' OR ';
            if(String.isNotBlank(fuzzyQueryFullName)) fuzzyQueryFullName += key+'= \''+mapSearchTerms.get(key)+'\' OR ';
        }
        if(String.isNotBlank(fuzzyQueryFullName)){ 
            // if space in Name, get full name results before split name results
            fuzzyQueryFullName = fuzzyQueryFullName.substringBeforeLast('OR').trim() + ') AND Id NOT IN :lstMatchedAccounts LIMIT :accountSearchLimit';
            lstFuzzyMatchedAccounts.addAll((List<Account>) Database.query(fuzzyQueryFullName));
            if(!lstFuzzyMatchedAccounts.isEmpty()) accountSearchLimit -= lstFuzzyMatchedAccounts.size();
        }
        // add split name results
        fuzzyQueryString = fuzzyQueryString.substringBeforeLast('OR').trim() + ') AND Id NOT IN: lstMatchedAccounts AND Id NOT IN: lstFuzzyMatchedAccounts LIMIT :accountSearchLimit';
        lstFuzzyMatchedAccounts.addAll((List<Account>) Database.query(fuzzyQueryString));
        return lstFuzzyMatchedAccounts;
    }

    @testVisible
    private static String getParsedWebsite(String website){ // get text before '.' after 'www.' has been removed
        if(website.toLowerCase().contains('www.')){
            website = website.substringAfter('.');
        }
        if(website.contains('.')){ 
            website = website.substringBefore('.');
        }
        return website;
    }
    
    @testVisible
    private static String getCleansedName(String name){
        if(name.toLowerCase().containsAny(',.-/|?*&')){
            for(String nameSegment : name.splitByCharacterTypeCamelCase()){
                if(nameSegment.length() > 2){ // handle up to 2 consecutive special chars
					name = nameSegment;
                    continue;
                }
            }
        }
        return name;
    }

    public static String constructSelectStatement(Map<String, Map<String, String>> mapFieldApiNameToSettings){
        List<String> fieldsToQuery = new List<String>();
        if(!mapFieldApiNameToSettings.isEmpty()) fieldsToQuery = new List<String>(mapFieldApiNameToSettings.keyset());
        String selectStatement = '';
        for(Integer i = 0; i < fieldsToQuery.size(); i++){
            if(mapFieldApiNameToSettings.get(fieldsToQuery[i]) != null && mapFieldApiNameToSettings.get(fieldsToQuery[i]).get('link') != '')
                selectStatement += mapFieldApiNameToSettings.get(fieldsToQuery[i]).get('link').remove('"')+',';
            selectStatement += (i == (fieldsToQuery.size() - 1)) ? fieldsToQuery[i] : fieldsToQuery[i]+',';
        }
        return selectStatement;
    }
    
}