/******************************************************************************************************************** 
Name              : UtilLead 
Description       : Lead Object Utility for testing and general functions .      
					

Revision History  :-
Created/Modified by                     Created/Modified Date       Requested by                  Technical Design Proposal
---------------------------------------------------------------------------------------------------------------------
1. Rashad Saeed (initial implementation)     27 Feb 2019            
---------------------------------------------------------------------------------------------------------------------
*********************************************************************************************************************/

@isTest
public class UtilLead {
    Private Static Map<String,Object> StMapFields = new Map<String,Object> ();
    public static List<Lead>GetNewleads(Integer NumberOfRecords,Boolean DoInsert)
    {
        List<Map<String,Object>> ListOfMapFields = new List<Map<String,Object>>();
        for (Integer i = 1, j = NumberOfRecords; i <= j; i++){
            Map<String,Object> LeadFieldsMap = new Map<String,Object>(StMapFields);
            LeadFieldsMap.put ('LastName','Test-');
            LeadFieldsMap.put ('FirstName',String.ValueOf (i));
            LeadFieldsMap.put ('Email','UtilTest'+String.ValueOf (i)+'@'+String.ValueOf (i)+'xqz.comm');
            ListOfMapFields.add(LeadFieldsMap);
        }
         return UtilGeneral.createTestRecords(Lead.sObjectType, ListOfMapFields, DoInsert);
    }
    
}