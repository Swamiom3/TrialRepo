/*************************************************************************************************************************************
 Author      :   Arun
 Description :   Helper class for CPQRenewalQuoteClone
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               03/07/2021       Arun        Initial Deployment
 **************************************************************************************************************************************/
public with sharing class CPQRenewalQuoteCloneHelper {
    public Map<String, String> getParentLines(List<SBQQ__QuoteLine__c> clonedQuoteLines){
        Map<String, String> parentQuoteLines = new Map<String, String>();
        for(SBQQ__QuoteLine__c quoteLine : clonedQuoteLines){
            if(quoteLine.SBQQ__ProductName__c.startsWith(CPQConstants.COMMITMENT)){
                parentQuoteLines.put(quoteLine.Inventory_Id__c, quoteLine.Id);
            }else if(quoteLine.SBQQ__ProductName__c.startsWith(CPQConstants.ALL_ACCESS)){
                parentQuoteLines.put(quoteLine.SBQQ__ProductName__c, quoteLine.Id);
            }
        }
        return parentQuoteLines;
    }
    
    public void updateRequiredByOnChildLines(List<SBQQ__QuoteLine__c> clonedQuoteLines, Map<String, String> parentQuoteLines){
        clonedQuoteLines.sort();
        List<SBQQ__QuoteLine__c> childQuoteLines = new List<SBQQ__QuoteLine__c>();
        String allAccessprodName;
        for(SBQQ__QuoteLine__c quoteLine : clonedQuoteLines){
            if(quoteLine.SBQQ__ProductName__c.startsWith(CPQConstants.ALL_ACCESS)){
                allAccessprodName = quoteLine.SBQQ__ProductName__c;
            }
            if((!quoteLine.SBQQ__ProductName__c.startsWith(CPQConstants.COMMITMENT) 
                && !quoteLine.SBQQ__ProductName__c.startsWith(CPQConstants.ALL_ACCESS))){ 
                if(quoteLine.Inventory_Id__c != null && parentQuoteLines.containsKey(quoteLine.Inventory_Id__c)){
                    quoteLine.SBQQ__RequiredBy__c = parentQuoteLines.get(quoteLine.Inventory_Id__c); 
                }else if(quoteLine.Inventory_Id__c == null && parentQuoteLines.containsKey(allAccessprodName)){
                    quoteLine.SBQQ__RequiredBy__c = parentQuoteLines.get(allAccessprodName); 
                }
                childQuoteLines.add(quoteLine);         
            }
        }
        update childQuoteLines;
    }
    
    public Boolean checkSelectedBundleLines(Set<String> selectedBundleLines, SBQQ__QuoteLine__c quoteLine) {
        return !selectedBundleLines.contains(quoteLine.Id) 
        && !selectedBundleLines.contains(quoteLine.SBQQ__RequiredBy__c);
    }
    
    public Boolean isPhysicalAccessMoveInDate(SBQQ__QuoteLine__c quoteLine, String action) {
        return isPhysicalOrAllAccessProd(quoteLine) 
        && action == CPQConstants.CHANGE_MOVEIN_DATE_ACTION && quoteLine.New_Move_in_Date__c != null;
    }
    
    public Boolean isPhysicalAccessAmend(SBQQ__QuoteLine__c quoteLine, String action) {
        return isPhysicalOrAllAccessProd(quoteLine) 
        && action == CPQConstants.AMEND_TERM && quoteLine.New_End_Date__c != null;
    }
    
    private Boolean isPhysicalOrAllAccessProd(SBQQ__QuoteLine__c quoteLine) {
        return quoteLine.SBQQ__ProductName__c.startsWith(CPQConstants.COMMITMENT) 
        || quoteLine.SBQQ__ProductName__c.startsWith(CPQConstants.ALL_ACCESS);
    }
    
    public Boolean isMonthProdAmendAction(SBQQ__QuoteLine__c quoteLine, String action) {
        return action == CPQConstants.AMEND_TERM 
        && quoteLine.SBQQ__ProductName__c.startsWith('Month');
    }
    
    public Boolean isMonthProdMoveInAction(SBQQ__QuoteLine__c quoteLine, String action) {
        return quoteLine.SBQQ__ProductName__c.startsWith('Month') 
        && action == CPQConstants.CHANGE_MOVEIN_DATE_ACTION;
    }
    
    public Boolean verifyMonthProdActionDate(SBQQ__QuoteLine__c quoteLine, SBQQ__QuoteLine__c quoteLineClone, String action, Date actionDate) {        
        return !quoteLine.SBQQ__ProductName__c.startsWith('Month') || !quoteLine.Quote_Line_Billing_Status__c;
    }
    
    public void processQuoteLine(SBQQ__QuoteLine__c quoteLine, SBQQ__QuoteLine__c quoteLineClone, String action, Date newMoveInDate, Date newEndDate) {
        if(isWorkspaceAndMoveInAction(quoteLine, action)){
            quoteLineClone.SBQQ__StartDate__c = newMoveInDate;
            quoteLineClone.SBQQ__EndDate__c = newEndDate;
            quoteLineClone.Segment_End_Date__c = newEndDate;
        } else if(isWorkspaceAndAmendAction(quoteLine, action)){
            quoteLineClone.Segment_End_Date__c = quoteLineClone.SBQQ__EndDate__c = newEndDate;
        } else if(action != CPQConstants.CHANGE_MOVEIN_DATE_ACTION && action != CPQConstants.AMEND_TERM){   
            quoteLineClone.SBQQSC__UpgradedContractLine__c = null;
        }
    }
    
    private Boolean isWorkspaceAndMoveInAction(SBQQ__QuoteLine__c quoteLine, String action) {
        return isWorkspaceProd(quoteLine) 
        && action == CPQConstants.CHANGE_MOVEIN_DATE_ACTION;
    }
    
    private Boolean isWorkspaceAndAmendAction(SBQQ__QuoteLine__c quoteLine, String action) {
        return isWorkspaceProd(quoteLine) 
        && action == CPQConstants.AMEND_TERM;
    }
    
    private Boolean isWorkspaceProd(SBQQ__QuoteLine__c quoteLine) {
        return quoteLine.SBQQ__ProductName__c.startsWith('Setup Fee')
                || quoteLine.SBQQ__ProductName__c.startsWith('Service Retainer')
                || quoteLine.SBQQ__ProductName__c.startsWith('Late Fee')
                || quoteLine.SBQQ__ProductName__c.startsWith('Conference Room Credit')
                || quoteLine.SBQQ__ProductName__c.startsWith('Color Printing Credit')
                || quoteLine.SBQQ__ProductName__c.startsWith('Black & White Printing Credit');
    }
}