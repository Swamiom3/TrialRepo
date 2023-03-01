/************************************************************************************************************************************
Author      :   Tayo Chestnut 
Description :   This is Selector class for blng__Refund.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           20 Dec 2021         Tayo Chestnut        Initial Developement
**************************************************************************************************************************************/
public inherited sharing class RefundSelector extends SObjectSelector{

    private List<String> fields = new List<String>{'Id',
            'Sequential_Bank_Counter__c'
            };
            
    public RefundSelector() {
        super(blng__Refund__c.getSObjectType());
    }
    
    public List<blng__Refund__c > getCurrentRefundCounter(String memoDate){  
        List<Object> bindings = new List<Object>{memoDate};   
        String whereClause = ' Sequential_Bank_Counter__c != null and Batch_Date__c >=: memoDate ORDER BY Sequential_Bank_Counter__c DESC LIMIT 1';
        return (List<blng__Refund__c>) getSObjects(fields,whereClause, bindings);
    }
    
    public override Set<String> getDefaultFields(){
        return new Set<String>{'Id'};
    }
}