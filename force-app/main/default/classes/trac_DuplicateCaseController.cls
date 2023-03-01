/**
* Controller class for duplicate support request component .
* @author Shubham Jain, Traction on Demand
* @date 2019-09-15
*/

public with sharing class trac_DuplicateCaseController {
    public static DescribeSObjectResult describeCaseSObject = Schema.getGlobalDescribe().get('Case').getDescribe();

    /**
     * @description gets fields from the duplicate case table fieldset
     * @return list of fieldset members
     */
    @AuraEnabled
    public static List<Map<String,String>> getFields() {
        Schema.FieldSet fieldSetObj = describeCaseSObject.FieldSets.getMap().get('Duplicate_Case_Table_Columns');
        List<Map<String,String>> myMap = new List<Map<String, String>>();
        for(FieldSetMember fsm : fieldSetObj.getFields()) {
            myMap.add(new Map<String,String>{
                            'label'       => fsm.getLabel(),
                            'fieldPath'   => fsm.getFieldPath(),
                            'type'        => String.valueOf(fsm.getType()),
                            'debRequired' => String.valueOf(fsm.getDbRequired()),
                            'required'    => String.valueOf(fsm.getRequired())
            });
        }
        return myMap;
    }


    /**
     * @description retrieves case datafor cases that match the current case based
     *              on the duplicate rules in the custom setting Duplicate_Case_Setting__c
     * @param recordId case record id to find duplicates
     * @param fields fields to compare for duplicates
     * @return list of cases
     */
    @AuraEnabled
    public static List<Case> getDuplicateCases(String recordId, List<String> fields) {
        Duplicate_Case_Setting__c settings = Duplicate_Case_Setting__c.getInstance();

        List<String> matchFieldList = settings.Fields_to_Match__c.split('(\\r\\n|;|,)');

        //TODO make this cleaner
        Set<String> fieldSet = new Set<String>();
        fieldSet.add('Id');
        fieldSet.addAll(fields);
        fieldSet.addAll(matchFieldList);
        List<String> myFields = new List<String>();
        myFields.addAll(fieldSet);

        String query = 'SELECT '+ String.join(myFields,',') +' FROM Case WHERE Id = \'' + recordId + '\'';
        Case myCase = Database.query(query);

        String query2 = 'SELECT '+ String.join(fields,',') +' ' +
                'FROM Case ' +
                'WHERE CreatedDate = LAST_N_DAYS:'+Integer.valueOf(settings.Match_Number_Days_Old__c)+' ' +
                'AND Id != \'' + recordId + '\' ';

        Map<String,SObjectField> fieldMap = describeCaseSObject.fields.getMap();

        for(String field : matchFieldList) {
            String value;
            String x = myCase.get(field) != null ? '\'' : '';
            String f = String.valueOf(fieldMap.get(field).getDescribe().getSoapType());
            if(f == 'ID' || f == 'String') {
                value = x + myCase.get(field) + x;
            }
            //TODO Time and Date (datetime works)
            else if(f == 'DateTime' || f == 'Date' || f == 'Time') {
                value = Datetime.valueOf(myCase.get(field)).formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            }
            else if(f != 'base64binary') {
                value = String.valueOf(myCase.get(field));
            }
            else {
                break;
            }
            query2 += 'AND ' + field + ' = ' + value + ' ';
        }

        List<Case> duplicateCases = new List<Case>();
        System.debug(query2);
        for(Case cs : Database.query(query2)) {
            if(cs.Subject == myCase.Subject || (cs.Subject != null && myCase.Subject != null && similarity(myCase.Subject,cs.Subject) > settings.Subject_Match__c/100)) {
                duplicateCases.add(cs);
            }
        }

        return duplicateCases;
    }


    /**
     * @description rates the similarity between 2 strings
     * @param s1 first string to compare
     * @param s2 second string to compare
     * @return similarity between 0 (no similarity) and 1 (exact same string)
     */
    public static Double similarity(String s1, String s2) {
        s1 = prepareString(s1);
        s2 = prepareString(s2);
        String longer = s1, shorter = s2;
        if (s1.length() < s2.length()) {
            longer = s2; shorter = s1;
        }
        Integer longerLength = longer.length();
        if (longerLength == 0) return 1.0;
        return (longerLength - editDistance(longer, shorter)) / (Double) longerLength;
    }


    /**
     * @description cleanses the string from punctuation and sorts the words alphabetically
     * @param input string to be prepared
     * @return clean string
     */
    public static String prepareString(String input) {
        input = input.replaceAll('(&#124;)|[^A-Za-z0-9\\s]','');
        List<String> words = input.split('\\s');
        for (Integer i = 0; i < words.size(); i++) {
            if(words[i].length() <= 2) {
                words.remove(i);
                i--;
            }
        }
        words.sort();
        return String.join(words,' ').toLowerCase();
    }


    /**
     * @description Levenshtein Edit Distance algorithm to compare 2 strings
     * @param s1 first string to compare
     * @param s2 second string to compare
     * @return number of character changes between the 2 strings
     */
    public static Integer editDistance(String s1, String s2) {
        List<Integer> costs = new Integer[s2.length() + 1];
        for (Integer i = 0; i <= s1.length(); i++) {
            Integer lastValue = i;
            for (Integer j = 0; j <= s2.length(); j++) {
                if (i == 0)
                    costs[j] = j;
                else {
                    if (j > 0) {
                        Integer newValue = costs[j - 1];
                        if (s1.charAt(i - 1) != s2.charAt(j - 1)) {
                            newValue = Math.min(Math.min(newValue, lastValue), costs[j]) + 1;
                        }
                        costs[j - 1] = lastValue;
                        lastValue = newValue;
                    }
                }
            }
            if (i > 0) {
                costs[s2.length()] = lastValue;
            }
        }
        return costs[s2.length()];
    }

}