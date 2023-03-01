/*************************************************************************************************************************************
 Author      :   Silpa Putti
 Description :   This class is selector implementation of particular SObject (SBQQ__Quote__c)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               14/7/2021       Silpa Putti        Initial Deployment
 **************************************************************************************************************************************/
public inherited sharing class  QuoteSelector extends SObjectSelector {

    public QuoteSelector() {
        super(SBQQ__Quote__c.getSObjectType());
    }
    
    /****************************************************************************************************************************
     Author              : Silpa Putti
     Description         : This method is used to get default fields from Object
     Created Date        : 14/7/2021
     *****************************************************************************************************************************/
    public override Set<String> getDefaultFields(){
        return new Set<String>{'Id', 'Name'};
    }
    
    /****************************************************************************************************************************
     Author              : Silpa Putti
     Description         : This method is used to get quote record from quoteId
     Created Date        : 14/7/2021
     *****************************************************************************************************************************/
    public List<SBQQ__Quote__c> getQuoteById(string quoteId){
        if(quoteId == null){
            return null;
        }
        List<String> fields = new List<String>{'Id',
                'Name',
                'Building_Id__r.UUID__c',
            	'SBQQ__Opportunity2__r.StageName',
                'SBQQ__LineItemCount__c',
                'Billing_Account__c'};
        return (List<SBQQ__Quote__c>) getSObjectByField(fields, 'Id', quoteId, false);
    }
    
    /****************************************************************************************************************************
     Author              : Silpa Putti
     Description         : This method is used to get quote record with subscription type from quoteId
     Created Date        : 14/7/2021
     *****************************************************************************************************************************/
    public List<SBQQ__Quote__c> getQuoteByIdWithSubscriptionType(string quoteId){
        if(quoteId == null){
            return null;
        }
        List<String> fields = new List<String>{'Id',
                'Name',
                'Building_Id__r.UUID__c',
                'Building_Id__c',
                'SBQQ__PricebookId__c',
                'CurrencyIsoCode',
                'Subscription_Type__c',
                'SBQQ__LineItemCount__c',
                'Service_Retainer_Method__c'};
        return (List<SBQQ__Quote__c>) getSObjectByField(fields, 'Id', quoteId, false);
    }

    public List<SBQQ__Quote__c> getQuoteForDealDeskEmail(String quoteId){
        if(quoteId == null){
            return null;
        }
        List<String> fields = new List<String>{'Id',
                'Name',
                'Annual_Escalation_Rate__c',
                'Number_of_Modified_Products_with_Fees__c',
                'Early_Termination_Options__c',
                'Service_Retainer_Method__c',
                'Custom_Legal_Terms__c',
                'Default_Annual_Escalation_Rate__c',
                'Exempt_from_Late_Fees__c',
                'Modified_Credit_Allotment_Count__c',
                'Custom_CapEx_Count__c',
                'Early_Termination_Penalty_Count__c',
                'Number_of_Modified_Setup_Fees__c',
                'Late_Fee__c',
                'SBQQ__PaymentTerms__c',
                'Default_Late_Fee__c',
                'Quote_Expiration_Days__c',
                'Service_Retainer_Method_Pre_Approved__c',
                'Payment_Terms_Pre_Approved__c'
        };
        Set<String> quoteIds = new Set<String>{quoteId};
        List<Object> bindings = new List<Object>{quoteIds};
        return (List<SBQQ__Quote__c>) getSObjects(fields, '(Id IN :quoteIds)', bindings, 1);
    }

    public List<SBQQ__Quote__c> getPrimaryQuotesForOpportunities(List<Id> opportunityIds){
        if(opportunityIds == null || opportunityIds.isEmpty()){
            return null;
        }
        List<String> fields = new List<String>{
            'Id',
            'Contract_Public_URL__c',
            'SBQQ__Opportunity2__c'
        };
        String innerQuery = 'SELECT Id FROM Contract_Agreements__r';
        List<Object> bindings = new List<Object>{opportunityIds};
        String whereClause = 'SBQQ__Opportunity2__c IN :opportunityIds AND SBQQ__Primary__c = true';
        return (List<SBQQ__Quote__c>) getSObjectsWithChilds(fields,innerQuery, whereClause, bindings);
    }
    
    public List<AggregateResult> getModifiedTermsCount(String quoteId) {
        return [SELECT count(SBQQ__Type__c) totalTerms FROM SBQQ__QuoteTerm__c 
                WHERE SBQQ__Quote__c =: quoteId];
    }
    
    public List<AggregateResult> getDiscountLinesCount(String quoteId) {
        return [SELECT count(Id) totalLines FROM SBQQ__QuoteLine__c 
                WHERE SBQQ__Quote__c =: quoteId AND Out_of_Policy_Discount__c = true];
    }
    
    public List<AggregateResult> getNonStandardSRApprovalLinesCount(String quoteId) {
        return [SELECT count(Id) totalLines FROM SBQQ__QuoteLine__c 
                WHERE SBQQ__Quote__c =: quoteId AND Non_Standard_SR_Approval__c = true];
    }
    
    public List<AggregateResult> getNonStandardMoveOutApprovalLinesCount(String quoteId) {
        return [SELECT count(Id) totalLines FROM SBQQ__QuoteLine__c 
                WHERE SBQQ__Quote__c =: quoteId AND Non_Standard_Move_Out_Approval__c = true];
    }
}