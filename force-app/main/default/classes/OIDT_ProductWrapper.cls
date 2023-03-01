public without sharing class OIDT_ProductWrapper {
    public String recordId {get;set;}
    public String customerName {get;set;}
    public String billToName {get;set;}
    public String customerNum {get;set;}
    public String sellerRegistration {get;set;}
    public String companyId {get;set;}
    public String currencyCode {get;set;}
    public String invoice_Status {get;set;}
    public Boolean auditCheck {get;set;}
    public String invNumber {get;  set;}
    public String parentId {get;  set;}
    public String shipFromCity {get;set;}
    public String shipFromPostcode {get;set;}
    public string quoteDate {get;set;}
    public String shipFromGeocode {get;set;}
    public String shipFromState {get;set;}
    public String shipFromCountry {get;set;}
    public String shipToCountry {get;set;}
    public String shipToState {get;set;}
    public String shipToCity {get;set;}
    public String shipToPostcode {get;set;}
    public String shipToGeocode {get;set;} 
    public String billToCountry {get;set;}
    public String billToState {get;set;}
    public String billToCity {get;set;}
    public String billToPostcode {get;set;}
    public String billToGeocode {get;set;} 
    public Boolean exemptCustomer{get;set;}
    public String transType {get;set;}
    public String memShortCode {get;set;}
    public String building {get;set;}
    //Adding gst and tax feilds by Avinash
    public decimal gst{set;get;}
    public decimal qst{Set;get;}
    public decimal pst{set;get;}
    public decimal hst{set;get;}
    public decimal igst{set;get;}
    public decimal cgst{set;get;}
    public decimal sgst{get;set;}
    //Avinash ending
    public List<ProductItemWrapper> productItems {get; set;}
    public Class ProductItemWrapper {
        public String lineNumber {get;set;}
        public String productCode {get;set;}
        public String capitalImpr {get;set;}
        public Decimal grossAmount {get;set;}
        public Decimal quantity {get;set;}
        //public Decimal gst {get;set;}
        //public Decimal qst {get;set;}
        //public Decimal pst {get;set;}
        
    }
}