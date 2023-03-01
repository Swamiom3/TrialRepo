/**
* @author Gad Sharon    
* @date 19/11/18
* @description Util class for the Case object.
*/
@isTest
public class UtilCase {

    Private Static Map<String, Object> stMapFields = new Map<String, Object>();

    public static List <Case> createCases (Integer numberOfRecords, Boolean doInsert)
    {
        List<Map<String,Object>> ListOfMapFields = new List<Map<String,Object>>();

        for (Integer i = 0; i < numberOfRecords; i++)
        {
            Map <String, Object> mapCaseFields = new Map <String, Object>(StMapFields);
            ListOfMapFields.add(mapCaseFields);
        }

        return UtilGeneral.createTestRecords(Case.sObjectType, ListOfMapFields, doInsert); 
    }

    public static Case createCaseRelatedToOpp (Id oppId, Id ownerId, Id recordTypeId, boolean doInsert)
    {
        stMapFields.put('Opportunity__c', oppId);
        stMapFields.put('OwnerId', ownerId);
        if(recordTypeId != null)
            stMapFields.put('RecordTypeId', recordTypeId);
        
        return createCases(1, doInsert)[0];
    }

    public static Case createCaseReadyToBeClosed (Id AccountId, Id OppId, Id ownerId, Id caseTemplateId, Id RecordTypeId, string caseTemplateName, boolean doInsert)
    {
        stMapFields.put('AccountId', AccountId);
        stMapFields.put('Opportunity__c', oppId);
        if(ownerId != null){
            stMapFields.put('OwnerId', ownerId);
        }            
        stMapFields.put('RecordTypeId', recordTypeId);
        stMapFields.put('Status', 'New');
        stMapFields.put('Deal_RSF__c', 10);
        stMapFields.put('Deal_USF__c', 10);
        stMapFields.put('Actual_Guardrail_Margin__c', 10);
        
        return createCases(1, doInsert)[0];
    }

}