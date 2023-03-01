public class OverrideNewOpportunityExtension {
    public String billingAccountId { get; set; }
    
    public OverrideNewOpportunityExtension(ApexPages.StandardController controller){
        Map<String, String> mapUrlParams = (Map<String, String>)(ApexPages.currentPage().getParameters());
        String strBillingAccId = mapUrlParams.containsKey('recordId') ? mapUrlParams.get('recordId') : mapUrlParams.containsKey('CF00N0G00000DLYMg_lkid') ? mapUrlParams.get('CF00N0G00000DLYMg_lkid') : NULL;
        if(strBillingAccId != NULL && strBillingAccId != 'undefined' &&String.valueOf(Id.valueOf(strBillingAccId).getSObjectType()).equals('Account'))
            billingAccountId = strBillingAccId.replace('"', '');
    }
}