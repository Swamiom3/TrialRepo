/************************************************************************************************************************************
Author      :   Serge Kandukuri
Description :   This is Selector class for blng__CreditNote__c.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           08 Aug 2021         Serge Kandukuri         Initial Developement
**************************************************************************************************************************************/
public inherited sharing class CreditNoteSelector extends SObjectSelector{

    private List<String> fields = new List<String>{'Id',
            'Name',
            'blng__RelatedInvoice__r.Building_Short_Code__c',
            'Temp_Number__c',
            'blng__RelatedInvoice__c',
            'Credit_Note_Temp_Number__c'
            };
            
    public CreditNoteSelector() {
        super(blng__CreditNote__c.getSObjectType());
    }
    
    public List<blng__CreditNote__c > getLatestCreditNotes(Date startDate, Date endDate, Set<String> buildingCodes){  
        List<Object> bindings = new List<Object>{startDate,endDate,buildingCodes};   
        String whereClause = ' Temp_Number__c != null and blng__CreditNoteDate__c >=: startDate AND blng__CreditNoteDate__c <=: endDate and blng__RelatedInvoice__r.Building_Short_Code__c IN: buildingCodes ORDER BY Temp_Number__c DESC ';
        return (List<blng__CreditNote__c>) getSObjects(fields,whereClause, bindings);
    }
    
    public List<blng__CreditNote__c > getCreditNotesbyId(Set<Id> creditNotes){  
        List<Object> bindings = new List<Object>{creditNotes};   
        String whereClause = ' id IN:creditNotes';
        return (List<blng__CreditNote__c>) getSObjects(fields,whereClause, bindings);
    }
    
    public override Set<String> getDefaultFields(){
        return new Set<String>{'Id', 'Name'};
    }
}