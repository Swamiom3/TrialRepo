public with sharing class CaseUtilities {

    private static Set<Id> caseSalesRTIds;

    public Set<Id> getCaseSalesRecordTypeIds() {
        if (caseSalesRTIds != null) {
            return caseSalesRTIds;
        }
        caseSalesRTIds = new Set<Id>();
        Map<String, RecordTypeInfo> rtInfos = Case.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName();
        for (String rtDevName : GlobalConstants.CASE_SALES_RECORDTYPE_DEV_NAMES) {
            caseSalesRTIds.add(rtInfos.get(rtDevName).getRecordTypeId());
        }
        return caseSalesRTIds;
    }

    public List<Case> getServiceOnlyCases(List<Case> cases) {
        List<Case> filteredCases = new List<Case>();
        Set<Id> salesRTIds = getCaseSalesRecordTypeIds();
        for (Case caseToCheck : cases) {
            if (!salesRTIds.contains(caseToCheck.RecordTypeId)) {
                filteredCases.add(caseToCheck);
            }
        }
        return filteredCases;
    }

    public List<Case> getSalesOnlyCases(List<Case> cases) {
        List<Case> filteredCases = new List<Case>();
        Set<Id> salesRTIds = getCaseSalesRecordTypeIds();
        for (Case caseToCheck : cases) {
            if (salesRTIds.contains(caseToCheck.RecordTypeId)) {
                filteredCases.add(caseToCheck);
            }
        }
        return filteredCases;
    }
}