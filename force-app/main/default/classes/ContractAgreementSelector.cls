/*************************************************************************************************************************************
 Author      :   Arun
 Description :   This class is selector implementation of particular SObject (APXT_Redlining__Contract_Agreement__c)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               11/11/2021       Arun        Initial Deployment
 **************************************************************************************************************************************/
public inherited sharing class ContractAgreementSelector extends SObjectSelector {
	public ContractAgreementSelector() {
        super(APXT_Redlining__Contract_Agreement__c.getSObjectType());
    }
    
    /****************************************************************************************************************************
     Author              : Arun
     Description         : This method is used to get default fields from Object
     Created Date        : 11/11/2021
     *****************************************************************************************************************************/
    public override Set<String> getDefaultFields(){
        return new Set<String>{'Id', 'Name'};
    }
    
    /****************************************************************************************************************************
     Author              : Arun
     Description         : This method is used to get APXT_Redlining__Contract_Agreement__c based on Ids
     Created Date        : 11/11/2021
     *****************************************************************************************************************************/
    public List<APXT_Redlining__Contract_Agreement__c> getAgreementsWithWhereClause(List<Id> recIds, String status, String whereClause) {
        if(recIds == null || recIds.isEmpty()){
            return null;
        }
        List<String> fields = new List<String>{'Id', 'Quote_Id__c'};
        List<Object> bindings = new List<Object>{recIds, status};
        return (List<APXT_Redlining__Contract_Agreement__c>) getSObjects(fields, whereClause, bindings);
    }
}