/**
 * @description Class to act as a query selector for basic case queries
 * @author Daniel Labonte, Traction on Demand
 * @date 2020-02-28
 */

public with sharing class trac_CaseSelector {
    /**
     * @description Method to retrieve case records
     * @param caseIds Set of case ids
     * @param fields Set of fields (set to avoid duplicates and add Id without duplicate field)
     * @return Map of matched case records
     */
    public Map<Id,Case> getCasesFromIdSet(Set<Id> caseIds, Set<String> fields) {
        fields.add('Id');
        String query = 'SELECT ' + String.join(new List<String>(fields),',') + ' FROM Case WHERE Id IN :caseIds';
        return new Map<Id,Case>((List<Case>) Database.query(query));
    }
}