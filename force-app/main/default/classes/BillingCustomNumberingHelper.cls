/************************************************************************************************************************************
Author      :   Dheeraj Perumalla
Description :   Helper class for BillingCustomNumbering
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           13 Feb 2022          Dheeraj Perumalla         Initial Developement
************************************************************************************************************************************/
public with sharing class BillingCustomNumberingHelper {
    public static DebitNoteSelector dNoteSelector = new DebitNoteSelector();
    public static void setCustomNumbers(List<blng__Invoice__c> finalInvoiceList, Map<String,Integer> serviceRetainerInvoiceToTempNumber, Map<String,Integer> standardInvoiceToTempNumber, List<String> invoiceNames){
        
        for(blng__Invoice__c inv:finalInvoiceList){
            if(inv.Invoice_Type__c=='Service Retainer'){
                inv.Temp_Number__c = serviceRetainerInvoiceToTempNumber.get(inv.Building_Short_Code__c) + 1;
                serviceRetainerInvoiceToTempNumber.put(inv.Building_Short_Code__c, Integer.valueOf(inv.Temp_Number__c) + 1);    
                if(BillingCustomNumbering.serviceRetainerDebitNoteToTempNumber.containsKey(inv.Building_Short_Code__c) && BillingCustomNumbering.serviceRetainerDebitNoteToTempNumber.get(inv.Building_Short_Code__c) >= inv.Temp_Number__c){
                    inv.Temp_Number__c = BillingCustomNumbering.serviceRetainerDebitNoteToTempNumber.get(inv.Building_Short_Code__c) + 1;
                }            
            }
            else{
                inv.Temp_Number__c = standardInvoiceToTempNumber.get(inv.Building_Short_Code__c) + 1;
                BillingCustomNumbering.standardInvoiceToTempNumber.put(inv.Building_Short_Code__c, Integer.valueOf(inv.Temp_Number__c) + 1);
                if(BillingCustomNumbering.standardDebitNoteToTempNumber.containsKey(inv.Building_Short_Code__c) && BillingCustomNumbering.standardDebitNoteToTempNumber.get(inv.Building_Short_Code__c) >= inv.Temp_Number__c){
                    inv.Temp_Number__c = BillingCustomNumbering.standardDebitNoteToTempNumber.get(inv.Building_Short_Code__c) + 1;
                }
            }
            invoiceNames.add(inv.Name);
        }
    }    
    public static void setBuildingCodeToTempNumberMap(Map<String,Integer> buildingCodeToTempNumber){
        for(blng__DebitNote__c biNon : dNoteSelector.getLatestDebitNotes(BillingCustomNumbering.startDate,BillingCustomNumbering.endDate,BillingCustomNumbering.buildingCodeToTempNumber.keySet())){
            if(buildingCodeToTempNumber.get(biNon.Invoice_Id__r.Building_Short_Code__c) != 0){
                continue;
            }
            buildingCodeToTempNumber.put(biNon.Invoice_Id__r.Building_Short_Code__c,Integer.valueOf(biNon.Temp_Number__c));

            if(BillingCustomNumbering.buildingCodeToTempNumberInvoice.containsKey(biNon.Invoice_Id__r.Building_Short_Code__c) && BillingCustomNumbering.buildingCodeToTempNumberInvoice.get(biNon.Invoice_Id__r.Building_Short_Code__c) > Integer.valueOf(biNon.Temp_Number__c)){
                buildingCodeToTempNumber.put(biNon.Invoice_Id__r.Building_Short_Code__c,BillingCustomNumbering.buildingCodeToTempNumberInvoice.get(biNon.Invoice_Id__r.Building_Short_Code__c));
            }
        }
    } 
    public static Map<String,Integer> setInvoiceMap(List<blng__Invoice__c> invoices, Map<String,Integer> invoiceToTempNumberParam, 
                                                    Map<String,Integer> serviceRetainerDebitNoteToTempNumber){
        Map<String,Integer> returnMap = new Map<String,Integer>();
        for(blng__Invoice__c biNon:invoices){
            if(invoiceToTempNumberParam.get(biNon.Building_Short_Code__c) != 0){ 
                continue;
            }
          returnMap.put(biNon.Building_Short_Code__c,Integer.valueOf(biNon.Temp_Number__c));
            invoiceToTempNumberParam.put(biNon.Building_Short_Code__c,Integer.valueOf(biNon.Temp_Number__c));
            
            if(serviceRetainerDebitNoteToTempNumber.get(biNon.Building_Short_Code__c)!=null){
                if(Integer.valueOf(biNon.Temp_Number__c) < serviceRetainerDebitNoteToTempNumber.get(biNon.Building_Short_Code__c)){
                    returnMap.put(biNon.Building_Short_Code__c,serviceRetainerDebitNoteToTempNumber.get(biNon.Building_Short_Code__c));
                }
            }
        }
        for(String buildingCode: invoiceToTempNumberParam.keyset()){
            if(!returnMap.containsKey(buildingCode)){
                returnMap.put(buildingCode, 
                             invoiceToTempNumberParam.get(buildingCode));
            }
        }
        return returnMap;
    }
}