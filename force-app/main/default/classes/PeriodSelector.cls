/*********************************************************************************************************
	Author        :  Krishna Somwanshi
	Description   :  Selector class for Period object
	Issue No.     :  ST-9152
	History       :
-----------------------------------------------------------------------------------------------------------
	VERSION        DATE            AUTHOR             DETAIL
	1          04/10/2021      Krishna Somwanshi    Initial development 
**********************************************************************************************************/
public inherited sharing class PeriodSelector extends SObjectSelector {
    
    private static final List<String> DEFAULT_FIELDS = new List<String>{'Id',
                                                                        'Name'};
    public PeriodSelector() {
        super(Period__c.getSObjectType());
    }
    
    public override Set<String> getDefaultFields(){
        return new Set<String>(DEFAULT_FIELDS);
    }
    
    public List<Period__c> getPeriodsByRecordTypeNameStartDateEndDate(Set<Date> startDates, Set<String> periodTypes, Set<Date> endDates){
        if (periodTypes == null || periodTypes.isEmpty()) {
            return new List<Period__c>();
        }
        List<String> fields = new List<String>{'Id',
                                               'Name',
                                               'Start_Date__c',
                                               'End_Date__c',
                                               'RecordType.Name'};
        String whereClause = '(RecordType.Name IN :periodTypes AND Start_Date__c IN :startDates AND End_Date__c IN :endDates)';
        return (List<Period__c>) getSObjects(fields, whereClause, new List<Object>{periodTypes, startDates, endDates});
    }
}