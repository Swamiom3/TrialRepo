/*----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Name:            Opportunity.cls
Description:    Opportunity Object Utility for testing and general functions .        
Date            Author          Summary of Changes 
7-OCT-2018     Rashad Saeed  Initial Implementation 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
@isTest
public class UtilOpportunity {
    Private Static Map <String,Id>activeRecordTypes = UtilRecordType.GetSobjectActiveRecordTypes('Opportunity');    
    Private Static Map<String,Object> stMapFields = new Map<String,Object> ();
   
    public static List<Opportunity> getNewOpportunity(Integer numberOfRecords, Account acc, Boolean doInsert) {
        List<Map<String,Object>> ListOfMapFields = new List<Map<String,Object>>();
        for (Integer i = 1, j = numberOfRecords; i <= j; i++) {
            Map<String,Object> OppFieldsMap = new Map<String,Object>(stMapFields);
            OppFieldsMap.put ('AccountId',acc.id);
            OppFieldsMap.put ('StageName','New');
            String OppName = acc.Name+'_'+i;
            OppFieldsMap.Put ('Name',OppName);
            OppFieldsMap.Put ('CloseDate',System.today().addDays(5));
            OppFieldsMap.Put ('LeadSource','WeWork.com');
            ListOfMapFields.add(OppFieldsMap);
        }
        return UtilGeneral.createTestRecords(Opportunity.sObjectType, ListOfMapFields, doInsert); 
    }


    public static List<Opportunity> getNewOpportunityWithFieldMapping(Integer numberOfRecords, Account acc, Map<String, Object> mapFields, Boolean doInsert) {
        stMapFields = mapFields;
        return getNewOpportunity(numberOfRecords, acc, doInsert); 
    }  

    public static List <Opportunity> getOppByRecordType (Integer numberOfRecords, String recordTypeName, Account acc, Boolean doInsert) {
        recordTypeName = recordTypeName.toLowerCase();
        if (activeRecordTypes.containsKey(recordTypeName)) {
            stMapFields.put('RecordTypeId', activeRecordTypes.get(recordTypeName));
        }
        else {
            return null;
        }
        return getNewOpportunity (numberOfRecords, acc, doInsert);
    }

}