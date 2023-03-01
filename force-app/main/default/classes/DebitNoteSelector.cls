/************************************************************************************************************************************
Author      :   Serge Kandukuri
Description :   This is Selector class for blng__DebitNote__c.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           08 Aug 2021         Serge Kandukuri         Initial Developement
**************************************************************************************************************************************/
public inherited sharing class DebitNoteSelector extends SObjectSelector{

    private List<String> fields = new List<String>{'Id',
            'Name',
            'Invoice_Id__r.Building_Short_Code__c',
            'Temp_Number__c'
            };
            
    public DebitNoteSelector() {
        super(blng__DebitNote__c.getSObjectType());
    }
    
    public List<blng__DebitNote__c > getLatestDebitNotes(Date startDate, Date endDate, Set<String> buildingCodes){  
        List<Object> bindings = new List<Object>{startDate,endDate,buildingCodes};   
        String whereClause = ' Temp_Number__c!=null and blng__DebitNoteDate__c >=: startDate ';
        whereClause += ' AND blng__DebitNoteDate__c <=: endDate and Invoice_Id__r.Building_Short_Code__c ';
        whereClause += ' IN: buildingCodes ORDER BY Temp_Number__c DESC';
        return (List<blng__DebitNote__c>) getSObjects(fields,whereClause, bindings);
    }
    
    public List<blng__DebitNote__c > getDebitNotesbyId(Set<Id> debitNotes){  
        List<Id> debitNoteList = new List<Id>();
        debitNoteList.addAll(debitNotes);
        return (List<blng__DebitNote__c>) getSObjectByIds(fields, debitNoteList);        
    }
    
    public List<blng__DebitNote__c > getLatestDebitNotes(Set<Id> invoideIdSet){  
        List<Object> bindings = new List<Object>{invoideIdSet};   
        String whereClause = ' Invoice_Id__c IN: invoideIdSet ORDER BY temp_Number__c DESC';
        return (List<blng__DebitNote__c>) getSObjects(fields,whereClause, bindings);
    }

    public override Set<String> getDefaultFields(){
        return new Set<String>{'Id', 'Name'};
    }
}