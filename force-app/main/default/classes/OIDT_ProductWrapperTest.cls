@isTest
public class OIDT_ProductWrapperTest {
   
    @IsTest
    static void OIDT_ProductWrapperTest(){
        OIDT_ProductWrapper owp = new OIDT_ProductWrapper();
        String se = owp.recordId;
        se = owp.customerName;
        se = owp.billToName;
        se = owp.customerNum;
        se = owp.sellerRegistration;
        se = owp.companyId;
        se = owp.currencyCode;
        se = owp.invoice_Status;
        Boolean be = owp.auditCheck;
        se = owp.invNumber;
        se = owp.parentId;
        se = owp.shipFromCity;
        se = owp.shipFromPostcode;
        se = owp.quoteDate;
        se = owp.shipFromGeocode;
        se = owp.shipFromState;
        se = owp.shipFromCountry;
        se = owp.shipToCountry;
        se = owp.shipToState;
        se = owp.shipToCity;
        se = owp.shipToPostcode;
        se = owp.shipToGeocode;
        se = owp.billToCountry;
        se = owp.billToState;
        se = owp.billToCity;
        se = owp.billToPostcode;
        se = owp.billToGeocode;
        be = owp.exemptCustomer;
        se = owp.transType;
        se = owp.memShortCode;
        se = owp.building;
        Decimal de = owp.gst;
        de = owp.qst;
        de = owp.pst;
        de = owp.hst;
        de = owp.igst;
        de = owp.cgst;
        de = owp.sgst;
        
        OIDT_ProductWrapper.ProductItemWrapper pli = new OIDT_ProductWrapper.ProductItemWrapper();
        pli.lineNumber = 'test';
        pli.productCode = 'test';
        pli.capitalImpr = 'test';
        pli.grossAmount = 21;
        pli.quantity = 9;  
    }
}