/************************************************************************************************************************************
Author      :   Serge Kandukuri
Description :   This is Selector class for blng__Invoice__c.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           05 Aug 2021         Serge Kandukuri         Initial Developement
**************************************************************************************************************************************/
public inherited sharing class InvoiceSelector extends SObjectSelector{

    private List<String> fields = new List<String>{'Id',
            'Name',
            'temp_Number__c',
            'Invoice_Type__c',
            'Building_Short_Code__c'};
            
    public InvoiceSelector() {
        super(blng__Invoice__c.getSObjectType());
    }
    
    public List<blng__Invoice__c > getSRInvoices(Date startDate, Date endDate, Set<String> buildingCodes){  
        List<Object> bindings = new List<Object>{startDate,endDate,buildingCodes};      
        String whereClause = ' temp_Number__c != null AND blng__InvoiceDate__c>=:startDate ';
        whereClause += ' AND blng__InvoiceDate__c<=:endDate AND Building_Short_Code__c IN:buildingCodes ';
        whereClause += ' ORDER BY temp_Number__c DESC ';
        return (List<blng__Invoice__c>) getSObjects(fields, whereClause, bindings);
    }
    
    public List<blng__Invoice__c > getLatestNonSRInvoices(Date startDate, Date endDate, Set<String> buildingCodes){  
        String serviceRetainer = InvoiceConstants.SERVICE_RETAINER;
        List<Object> bindings = new List<Object>{serviceRetainer,startDate,endDate,buildingCodes};      
        String whereClause = ' Invoice_Type__c !=: serviceRetainer AND temp_Number__c != null ';
        whereClause += ' AND blng__InvoiceDate__c>=:startDate AND blng__InvoiceDate__c<=:endDate ';
        whereClause += ' AND Building_Short_Code__c IN:buildingCodes ORDER BY temp_Number__c DESC ';
        return (List<blng__Invoice__c>) getSObjects(fields, whereClause, bindings);
    }
    
    public List<blng__Invoice__c > getLatestSRInvoices(Date startDate, Date endDate, Set<String> buildingCodes){  
        String serviceRetainer = InvoiceConstants.SERVICE_RETAINER;
        List<Object> bindings = new List<Object>{serviceRetainer,startDate,endDate,buildingCodes};   
        String whereClause = ' Invoice_Type__c =: serviceRetainer AND temp_Number__c != null AND ';
        whereClause += ' blng__InvoiceDate__c>=:startDate AND blng__InvoiceDate__c<=:endDate AND ';
        whereClause += ' Building_Short_Code__c IN:buildingCodes ORDER BY temp_Number__c DESC ';
        return (List<blng__Invoice__c>) getSObjects(fields,whereClause, bindings);
    }
    
    public List<blng__Invoice__c> getInvoicesById(set<Id> invoiceIds){  
        List<Object> bindings = new List<Object>{invoiceIds};   
        String whereClause = ' Id IN: invoiceIds AND temp_Number__c != null ORDER BY temp_Number__c DESC ';
        return (List<blng__Invoice__c>) getSObjects(fields,whereClause, bindings);
    }
    
    public override Set<String> getDefaultFields(){
        return new Set<String>{'Id', 'Name'};
    }
}