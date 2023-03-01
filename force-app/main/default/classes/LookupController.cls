/*************************************************************************************************************************************
 Author      :   Salesforce
 Description :   This class is used to search the records in the lookup component
 Issue No    :   TWSPG-4402
 History     :
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR                 ISSUE NO         DETAIL
 1               14 Oct 2021     Salesforce             TWSPG-4402     Initial Deployment
 **************************************************************************************************************************************/
public with sharing class LookupController {
    @AuraEnabled(cacheable=true)
    public static List<sObject> search(String searchTerm, String myObject, String filter) {
        List<String> filters = new List<String>();
        String myQuery = 'SELECT Id, Name FROM ' + myObject + ' ';
        if (String.isNotBlank(filter)) {
            filters.add(filter);
        }
        if (String.isNotBlank(searchTerm)) {
            filters.add('Name Like  \'%' + String.escapeSingleQuotes(searchTerm) + '%\'');
        }
        if (!filters.isEmpty()) {
            myQuery += 'WHERE ' + String.join(filters, ' AND ') + ' ';
        }
        myQuery += 'ORDER BY Name ASC LIMIT 5';
        return Database.query(myQuery);
    }
}