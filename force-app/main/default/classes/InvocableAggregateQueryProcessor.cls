public with sharing class InvocableAggregateQueryProcessor {
    @InvocableMethod (label='Group by Queries from Revenue Cloud Flows' description='Receive an ID and a Category will drive the query to run' category='SOQL Functions')
    public static List<Output> executeRevenueCloudQuery(List<Request> inboundRequests){

        
        List<Output> outputList = new List<Output>();
        for(Request inboundRequest: inboundRequests){
            switch on (inboundRequest.soqlCategory){
                when ('Monthly Run Rate'){
                    outputList = getMonthlyRunRate(inboundRequest.buildingAccountId);
                }when ('On Account'){
                    outputList = getOnAccountBalance(inboundRequest.buildingAccountId);
                }when ('Invoice Balances'){
                    outputList = getInvoiceBalances(inboundRequest.buildingAccountId);
                }when ('Credit Allotments'){
                    outputList = getCreditAllotments(inboundRequest.billingAccountId);
                }when else{
                    return outputList;      
                }
            }
        }
        
        return outputList;
    }

    public static List<Output> getMonthlyRunRate(String buildingAccountId){
        Double myRunRate = 0;
        AggregateResult[] groupedResults = [SELECT Building_Account_Id__c, SUM(Billable_Unit_Price_Raw__c) Price, SUM(SBQQ__SubscriptionTerm__c) Term
                                            FROM OrderItem WHERE (Product_Family__c =:CPQConstants.WORKSPACE OR Product_Family__c =:CPQConstants.ALL_ACCESS) AND Order.Building_Account_Id__c=:buildingAccountId
                                            GROUP BY Building_Account_Id__c];
    
        for (AggregateResult ar : groupedResults){
            Double myTerm = Double.valueOf(ar.get('Term') == null ? 1 : Double.valueOf(ar.get('Term'))); 
            myRunRate = Double.valueOf(ar.get('Price')) / myTerm;
        }

        List<Output> outputList = new List<Output>();
        Output o = new Output();
        o.runRate = myRunRate;
        outputList.add(o);
        return outputList;
    }

    public static List<Output> getOnAccountBalance(String buildingAccountId){
        Double accountBalance = 0;
        Double accountBalanceUSD = 0;
        AggregateResult[] groupedResults = [SELECT Payment_Building_Account_Id__c, SUM(Balance_Raw__c) paymentBalance, SUM(Balance_Raw_USD__c) paymentBalanceUSD 
                                                FROM blng__Payment__c WHERE blng__Status__c= :InvoiceConstants.POSTED AND Payment_Building_Account_Id__c=:buildingAccountId AND blng__Balance__c >0
                                                GROUP BY Payment_Building_Account_Id__c];
    
        for (AggregateResult ar : groupedResults){
            accountBalance = Double.valueOf(ar.get('paymentBalance'));
            accountBalanceUSD = Double.valueOf(ar.get('paymentBalanceUSD'));
        }

        List<Output> outputList = new List<Output>();
        Output o = new Output();
        o.onAccountBalance = accountBalance;
        o.onAccountBalanceUSD = accountBalanceUSD;
        outputList.add(o);
        return outputList;
    }

    public static List<Output> getInvoiceBalances(String buildingAccountId){
        List<InvoiceTotals> myInvoiceTotals = new List<InvoiceTotals>();
        AggregateResult[] groupedResults = [SELECT Building_Account_Id__c, Invoice_Type__c, MAX(blng__BaseCurrencyFXRate__c) exchangeRate,SUM(Balance_Raw__c) balance, SUM(Payments_Raw__c) payments, SUM(Debit_Raw__c) debits, SUM(Debit_Payment_Raw__c) debitPayments, SUM(blng__BaseCurrencyAmount__c) usdAmount, SUM(Tax_Amount_Raw__c) taxAmount
                                                FROM blng__Invoice__c WHERE blng__InvoiceStatus__c =:InvoiceConstants.POSTED AND Building_Account_Id__c=:buildingAccountId
                                                GROUP BY Building_Account_Id__c, Invoice_Type__c];
    
            for (AggregateResult ar : groupedResults){
                InvoiceTotals singleInvoice = new InvoiceTotals();
                singleInvoice.invoiceType = String.valueOf(ar.get('Invoice_Type__c'));
                singleInvoice.amount = Double.valueOf(ar.get('balance'));
                singleInvoice.paid = Double.valueOf(ar.get('payments')) + Double.valueOf(ar.get('debitPayments'));
                singleInvoice.usdAmount = Double.valueOf(ar.get('balance')) / Double.valueOf(ar.get('exchangeRate'));
                singleInvoice.usdPaid = singleInvoice.paid / Double.valueOf(ar.get('exchangeRate'));
                singleInvoice.taxAmount = Double.valueOf(ar.get('taxAmount'));
                myInvoiceTotals.add(singleInvoice);
            }

            List<Output> outputList = new List<Output>();
            Output o = new Output();
            o.invoiceTotals = myInvoiceTotals;
            outputList.add(o);
            return outputList; 
    }

    public static List<Output> getCreditAllotments(String billingAccountId){
        Output o = new Output();
        
        AggregateResult[] groupedResults = [SELECT SBQQSC__Product__r.Name productcategory, SUM(Allotment__c) allotments
                                            FROM ContractLineItem WHERE ServiceContract.SBQQSC__Quote__r.Billing_Account__c =:billingAccountId AND Allotment__c !=null AND ServiceContract.Status = 'Active'
                                            GROUP BY SBQQSC__Product__r.Name];
    
        for (AggregateResult ar : groupedResults){
            String allotmentCategory = String.valueOf(ar.get('productcategory'));

            switch on (allotmentCategory){
                when ('Black & White Printing Credit'){
                    o.blackAndWhiteAllotment = Double.valueOf(ar.get('allotments'));
                }when ('Color Printing Credit'){
                    o.colorAllotment = Double.valueOf(ar.get('allotments'));
                }when ('Conference Room Credit'){
                    o.conferenceRoomAllotment = Double.valueOf(ar.get('allotments'));
                }
            }
        }

        List<Output> outputList = new List<Output>();
        outputList.add(o);
        return outputList;
    }

    public class Request{
        @InvocableVariable
        public String buildingAccountId;

        @InvocableVariable
        public String billingAccountId;

        @InvocableVariable
        public String soqlCategory;
    }

    public class Output{
        @InvocableVariable
        public Double runRate;

        @InvocableVariable
        public Double onAccountBalance;

        @InvocableVariable
        public Double onAccountBalanceUSD;

        @InvocableVariable
        public List<InvoiceTotals> invoiceTotals;

        @InvocableVariable
        public Double blackAndWhiteAllotment;

        @InvocableVariable
        public Double colorAllotment;

        @InvocableVariable
        public Double conferenceRoomAllotment;
        
    }

}