/************************************************************************************************************************************
Author      :   Serge Kandukuri
Description :   Invocable Class for Debit Note AutoNumbering.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           6 Dec 2021          Serge Kandukuri         Initial Developement
************************************************************************************************************************************/
public with sharing class BillingCustomNumbering {
    public static Map<String,Integer> standardDebitNoteToTempNumber = new Map<String,Integer>();
    public static Map<String,Integer> serviceRetainerDebitNoteToTempNumber = new Map<String,Integer>();
    public static Map<String,Integer> standardInvoiceToTempNumber = new Map<String,Integer>();
    
    static Set<Id> sObjectIds = new Set<Id>();
    static Set<Id> invoiceIds = new Set<Id>();
    
    static Integer currentYear = System.today().year();
    public static Map<String,Integer> buildingCodeToTempNumber = new Map<String,Integer>();
    public static Map<String,Integer> buildingCodeToTempNumberInvoice = new Map<String,Integer>();
    
    public static DebitNoteSelector dNoteSelector = new DebitNoteSelector();
    
    public static Date startDate = Date.newInstance(currentYear,1,1);
    public static Date endDate =  Date.newInstance(currentYear, 12, 31);
    
    @InvocableMethod(label='Custom Numbering' description='Updates Numbering for Objects' category='Custom Number')
    public static List<String> setNumbering(List<List<sObject>> sObjectToUpdate) {
        
        List<String> returnStrings = new List<String>();
        
        List<sObject> finalsObjectList = new List<sObject>();
        for(List<sObject> dn: sObjectToUpdate){
            finalsObjectList.addAll(dn);
        }        
        
        List<blng__DebitNote__c> finalDebitNoteList = new List<blng__DebitNote__c>();
        List<blng__CreditNote__c> finalCreditNoteList = new List<blng__CreditNote__c>();
        List<blng__Invoice__c> finalInvoiceList = new List<blng__Invoice__c>();
        for(sObject so: finalsObjectList){
            returnStrings.add(so.Id);
            sObjectIds.add(so.Id);
            try{
                    switch on (so.getSObjectType().getDescribe().getName()){
                        when ('blng__DebitNote__c'){
                            finalDebitNoteList.add((blng__DebitNote__c)so);
                            if(so.get('Invoice_Id__c') != null){
                                invoiceIds.add((Id)so.get('Invoice_Id__c'));
                            }
                        }
                        when ('blng__CreditNote__c'){
                            finalCreditNoteList.add((blng__CreditNote__c)so);
                        }
                        when ('blng__Invoice__c'){
                            finalInvoiceList.add((blng__Invoice__c)so);
                        }
                    }
                } 
            catch(Exception ex){
                ApexDebugLog.logException(ex,ex.getStackTraceString(), 'BillingCustomNumbering', 'populateBuildingAndBillingAccount');
            }              
        }        
        if(!finalDebitNoteList.isEmpty()){
            handleDebitNoteNumbering(invoiceIds,buildingCodeToTempNumber,startDate,endDate,finalDebitNoteList);
        }
        else if(!finalCreditNoteList.isEmpty()){
            handleCreditNoteNumbering(invoiceIds,buildingCodeToTempNumber,startDate,endDate,finalCreditNoteList);
        }        
        else if(!finalInvoiceList.isEmpty()){
            handleInvoiceCustomNumbering(finalInvoiceList,startDate,endDate);
        }
        return returnStrings;
    }    
    public static void handleCreditNoteNumbering(Set<ID> invoiceIds,Map<String,Integer> buildingCodeToTempNumber,Date startDate,Date endDate,List<blng__CreditNote__c> finalCreditNoteList  ){
        Map<String,Integer> invoiceToTempNumber = new Map<String,Integer>();
        Map<String,String> creditNoteToBuildingCode = new Map<String,String>();
        CreditNoteSelector cNoteSelector = new CreditNoteSelector();
        for(blng__CreditNote__c cn : cNoteSelector.getCreditNotesbyId(sObjectIds)){
            buildingCodeToTempNumber.put(cn.blng__RelatedInvoice__r.Building_Short_Code__c,0);
            invoiceToTempNumber.put(cn.blng__RelatedInvoice__c, 0);
            creditNoteToBuildingCode.put(cn.Id,cn.blng__RelatedInvoice__r.Building_Short_Code__c);
        }
        
        for(blng__CreditNote__c biNon : cNoteSelector.getLatestCreditNotes(startDate,endDate,buildingCodeToTempNumber.keySet())){
            if(buildingCodeToTempNumber.get(biNon.blng__RelatedInvoice__r.Building_Short_Code__c) == 0){
                buildingCodeToTempNumber.put(biNon.blng__RelatedInvoice__r.Building_Short_Code__c,Integer.valueOf(biNon.Temp_Number__c));
            }
            if(invoiceToTempNumber.get(biNon.blng__RelatedInvoice__c) == 0 && biNon.Credit_Note_Temp_Number__c != null){
                invoiceToTempNumber.put(biNon.blng__RelatedInvoice__c, Integer.valueOf(biNon.Credit_Note_Temp_Number__c));
            }
        }
        for(blng__CreditNote__c cn : finalCreditNoteList){
            String buildingCode = creditNoteToBuildingCode.get(cn.Id);
            cn.Temp_Number__c = buildingCodeToTempNumber.get(buildingCode) + 1;
            buildingCodeToTempNumber.put(buildingCode, Integer.valueOf(cn.temp_Number__c) + 1);
            
            if(invoiceToTempNumber.containsKey(cn.blng__RelatedInvoice__c)){
                Integer runningCreditNumber = invoiceToTempNumber.get(cn.blng__RelatedInvoice__c) + 1;
                cn.Credit_Note_Temp_Number__c = runningCreditNumber;
                invoiceToTempNumber.put(cn.blng__RelatedInvoice__c, runningCreditNumber);
            }else{
                cn.Credit_Note_Temp_Number__c = 1;
                invoiceToTempNumber.put(cn.blng__RelatedInvoice__c, 1);
            }
            
        }
        
        SObjectAccessDecision securityInvoiceUpdate = Security.stripInaccessible(AccessType.UPDATABLE, finalCreditNoteList);
        List<Database.saveresult> tenantListInsert = Database.update(securityInvoiceUpdate.getRecords());
    }
    public static void handleDebitNoteNumbering(Set<ID> invoiceIds,Map<String,Integer> buildingCodeToTempNumber,Date startDate,Date endDate,List<blng__DebitNote__c> finalDebitNoteList  ){
        Map<String,String> debitNoteToBuildingCode = new Map<String,String>();
        Map<Id, blng__Invoice__c> invoiceMap = new Map<Id, blng__Invoice__c>();
        
        for(blng__DebitNote__c dn:finalDebitNoteList){
            if(dn.Building_Short_Code__c!=null){
                buildingCodeToTempNumberInvoice.put(dn.Building_Short_Code__c,0);
            }
        }
        
        if(!invoiceIds.isEmpty()){
            InvoiceSelector invSelector = new InvoiceSelector();
            for(blng__Invoice__c inv: invSelector.getSRInvoices(startDate, endDate, buildingCodeToTempNumberInvoice.keySet())){ 
                invoiceMap.put(inv.Id, inv);
                if(buildingCodeToTempNumberInvoice.get(inv.Building_Short_Code__c)==0){
                    buildingCodeToTempNumberInvoice.put(inv.Building_Short_Code__c,Integer.valueOf(inv.Temp_Number__c));
                }
            }
        }
        
        for(blng__DebitNote__c dn : dNoteSelector.getDebitNotesbyId(sObjectIds)){
            buildingCodeToTempNumber.put(dn.Invoice_Id__r.Building_Short_Code__c,0);
            debitNoteToBuildingCode.put(dn.Id,dn.Invoice_Id__r.Building_Short_Code__c);
        }
        
        BillingCustomNumberingHelper.setBuildingCodeToTempNumberMap(buildingCodeToTempNumber); 
        
        for(blng__DebitNote__c dn : finalDebitNoteList){
            String buildingCode = debitNoteToBuildingCode.get(dn.Id);
            dn.Temp_Number__c = buildingCodeToTempNumber.get(buildingCode) + 1;
            buildingCodeToTempNumber.put(buildingCode, Integer.valueOf(dn.temp_Number__c) + 1);
        }
      
        SObjectAccessDecision securityInvoiceUpdate = Security.stripInaccessible(AccessType.UPDATABLE, finalDebitNoteList);
        List<Database.saveresult> tenantListInsert = Database.update(securityInvoiceUpdate.getRecords());
    }
    
    public static void handleInvoiceCustomNumbering(List<blng__Invoice__c> finalInvoiceList,Date startDate,Date endDate){
        InvoiceSelector selector = new InvoiceSelector();
        Map<String,Integer> serviceRetainerInvoiceToTempNumber = new Map<String,Integer>();
        
        for(blng__Invoice__c inv:finalInvoiceList){
            switch on (inv.Invoice_Type__c){
                when 'Service Retainer'{
                    serviceRetainerInvoiceToTempNumber.put(inv.Building_Short_Code__c,0);
                }
                when else{
                    standardInvoiceToTempNumber.put(inv.Building_Short_Code__c,0);    
                }
            }
        }
        
        List<String> invoiceNames = new List<String>();
        
        List<blng__Invoice__c> invoiceSR = selector.getLatestSRInvoices(startDate,endDate,serviceRetainerInvoiceToTempNumber.keySet());
        List<blng__Invoice__c> invoiceNonSR = selector.getLatestNonSRInvoices(startDate,endDate,standardInvoiceToTempNumber.keySet());
        
        Set<Id> nonSRInvoiceId = new Set<Id>();
        for(blng__Invoice__c inv: invoiceNonSR){
            nonSRInvoiceId.add(inv.Id);
        }
        DebitNoteSelector dnSelector = new DebitNoteSelector();            
        for(blng__DebitNote__c dn: dnSelector.getLatestDebitNotes(nonSRInvoiceId)){
            if(!standardDebitNoteToTempNumber.containsKey(dn.Invoice_Id__r.Building_Short_Code__c)){
                standardDebitNoteToTempNumber.put(dn.Invoice_Id__r.Building_Short_Code__c, Integer.valueOf(dn.Temp_Number__c));
            }
        }
        Set<Id> srInvoiceId = new Set<Id>();
        for(blng__Invoice__c inv: invoiceSR){
            srInvoiceId.add(inv.Id);
        }
        List<blng__DebitNote__c> debitNoteSR = dnSelector.getLatestDebitNotes(srInvoiceId);
        for(blng__DebitNote__c dn: debitNoteSR){
            if(!serviceRetainerDebitNoteToTempNumber.containsKey(dn.Invoice_Id__r.Building_Short_Code__c)){
                serviceRetainerDebitNoteToTempNumber.put(dn.Invoice_Id__r.Building_Short_Code__c, Integer.valueOf(dn.Temp_Number__c));
            }
        }
        standardInvoiceToTempNumber = BillingCustomNumberingHelper.setInvoiceMap(invoiceNonSR,standardInvoiceToTempNumber,serviceRetainerDebitNoteToTempNumber);
        serviceRetainerInvoiceToTempNumber = BillingCustomNumberingHelper.setInvoiceMap(invoiceSR, serviceRetainerInvoiceToTempNumber,serviceRetainerDebitNoteToTempNumber);
        BillingCustomNumberingHelper.setCustomNumbers(finalInvoiceList, serviceRetainerInvoiceToTempNumber, standardInvoiceToTempNumber, invoiceNames);
        SObjectAccessDecision securityInvoiceUpdate = Security.stripInaccessible(AccessType.UPDATABLE, finalInvoiceList);
        List<Database.saveresult> tenantListInsert = Database.update(securityInvoiceUpdate.getRecords());
    }
}