public without sharing class OIDT_XMLGenerateCtrl {
    static String ns = Label.OIDT_Name_Space;
    static String soapns = Label.OIDT_Soap_NS;
    static String wsse = Label.OIDT_security_wsse;
    @TestVisible static Boolean isExceptionOccured=false;

    public static String generateTaxCalculationReq(OIDT_ProductWrapper prodWrapper){   
        String taxCalStr = '';
        Id objectId = prodWrapper.recordId;
        String regList = prodWrapper.sellerRegistration;
        List<String> sellerRegList = new List<String>();
        sellerRegList = regList?.split(',');
        String[] buyerRegList;
        
        // added by sridhar
        
        User_Settings__c us = User_Settings__c.getValues('UAT USER');
        String uName = decryptUsrDtl(us.User_Name__c);
        String uPW = decryptUsrDtl(us.User_Password__c);
        
        // add end by sridhar
        
        try{
            String objectname=objectId.getSObjectType().getDescribe().getName();
            List<String> shiptoZipGeo = prodWrapper.shipToPostcode?.split('-', 2);
            List<String> shipFromZipGeo = prodWrapper.shipFromPostcode?.split('-', 2);
            List<String> billtoZipGeo = prodWrapper.billToPostcode?.split('-', 2);
            
            Dom.Document doc = new Dom.Document();
            Dom.Xmlnode envelope = doc.createRootElement('Envelope', soapns, 'soapenv');
            Envelope.setAttribute('xmlns:ns', Label.OIDT_Name_Space);
            Dom.XmlNode header = envelope.addChildElement('Header', soapns, null);
            Dom.XmlNode security = header.addChildElement('Security', wsse, 'wsse');
            security.setAttribute('xmlns:wsu', Label.OIDT_security_wsse);
            Dom.XmlNode usernameToken = security.addChildElement('UsernameToken',wsse,'wsse');
            usernameToken.setAttribute('wsu:Id','UsernameToken-C2DBBC789B0E87AEC915580245662442');
            //Dom.XmlNode username = usernameToken.addChildElement('Username',wsse,'wsse').addTextNode('^WeWork-SF-SSID-UAT');
            Dom.XmlNode username = usernameToken.addChildElement('Username',wsse,'wsse').addTextNode(uName);
            Dom.XmlNode password = usernameToken.addChildElement('Password',wsse,'wsse');
            Password.setAttribute('Type', Label.OIDT_Password_Type);
            //Password.addTextNode('Wework-sf-SSID-uat$');
            Password.addTextNode(uPW);

			Dom.XmlNode body = envelope.addChildElement('Body', soapns, null);
            Dom.XmlNode taxCalculationRequest = Body.addChildElement('taxCalculationRequest',ns, 'ns');
            Dom.XmlNode indata = taxCalculationRequest.addChildElement('INDATA',ns,null);
            indata.setAttribute('version', 'G');
            
            //Invoice block starts from here
            Dom.XmlNode invoice = indata.addChildElement('INVOICE', ns, null);
            Dom.XmlNode hostSystem = invoice.addChildElement('HOST_SYSTEM', ns, null).addTextNode('Salesforce');      
            Dom.XmlNode callingSystem = invoice.addChildElement('CALLING_SYSTEM_NUMBER', ns, null).addTextNode('CPQ');      
            Dom.XmlNode externalCompanyId = invoice.addChildElement('EXTERNAL_COMPANY_ID', ns, null).addTextNode(prodwrapper.companyId);    
            Dom.XmlNode calculationDirection = invoice.addChildElement('CALCULATION_DIRECTION', ns, null).addTextNode('F');
            Dom.XmlNode companyRole = invoice.addChildElement('COMPANY_ROLE', ns, null).addTextNode('S'); 
            Dom.XmlNode currencyCode = invoice.addChildElement('CURRENCY_CODE', ns, null).addTextNode(prodWrapper.currencyCode); 
            Dom.XmlNode customerNumber = invoice.addChildElement('CUSTOMER_NUMBER', ns, null).addTextNode(prodWrapper.customerNum !=null ? prodWrapper.customerNum:'' );
            Dom.XmlNode customerName = invoice.addChildElement('CUSTOMER_NAME', ns, null).addTextNode(prodWrapper.CustomerName != null ? prodWrapper.CustomerName:'' );
            Dom.XmlNode invoiceDate = invoice.addChildElement('INVOICE_DATE', ns, null).addTextNode('2021-09-09');        
            Dom.XmlNode invoiceNumber = invoice.addChildElement('INVOICE_NUMBER', ns, null).addTextNode(prodWrapper.INVNUMBER !=null ? prodWrapper.INVNUMBER:'');
            if ((objectname=='blng__Invoice__c' && prodWrapper.Invoice_Status=='Posted' && prodWrapper.auditCheck==false)||
                objectname=='blng__Invoice__c' && prodWrapper.Invoice_Status=='Rebilled')
            {
                Dom.XmlNode isAudited = invoice.addChildElement('IS_AUDITED', ns, null).addTextNode('TRUE');         
            }else{
                Dom.XmlNode isAudited = invoice.addChildElement('IS_AUDITED', ns, null).addTextNode('FALSE');
            }
            
            Dom.XmlNode pott = invoice.addChildElement('POINT_OF_TITLE_TRANSFER', ns, null).addtextNode('I');
            Dom.XmlNode transactionType = invoice.addChildElement('TRANSACTION_TYPE', ns, null).addTextNode('GS' );
            
            if(prodWrapper.exemptCustomer == true){
                Dom.XmlNode isExempt = invoice.addChildElement('IS_EXEMPT', ns, null);
                Dom.XmlNode exemptAll = isExempt.addChildElement('ALL', ns, null).addTextNode('true');
                Dom.XmlNode exemptReason = invoice.addChildElement('EXEMPT_REASON', ns, null);
                Dom.XmlNode countryExempt = exemptReason.addChildElement('COUNTRY', ns, null).addTextNode('99');   
                Dom.XmlNode provinceExempt = exemptReason.addChildElement('PROVINCE', ns, null).addTextNode('99');   
                Dom.XmlNode stateExempt = exemptReason.addChildElement('STATE', ns, null).addTextNode('99');   
                Dom.XmlNode countyExempt = exemptReason.addChildElement('COUNTY', ns, null).addTextNode('99');   
                Dom.XmlNode cityExempt = exemptReason.addChildElement('CITY', ns, null).addTextNode('99');   
                Dom.XmlNode districtExempt = exemptReason.addChildElement('DISTRICT', ns, null).addTextNode('99');   
                Dom.XmlNode postcodeExempt = exemptReason.addChildElement('POSTCODE', ns, null).addTextNode('99');   
                Dom.XmlNode geocodeExempt = exemptReason.addChildElement('GEOCODE', ns, null).addTextNode('99');   
                
            }
            if(prodWrapper.transType != null){
                Dom.XmlNode transType = invoice.addChildElement('USER_ELEMENT', ns, null);
                Dom.XmlNode transTypeKey = transType.addChildElement('NAME', ns, null).addTextNode('ATTRIBUTE39');
                Dom.XmlNode transTypeValue = transType.addChildElement('VALUE', ns, null).addTextNode(prodWrapper.transType );
                
            }
            if(prodWrapper.memShortCode != null){
                Dom.XmlNode scType = invoice.addChildElement('USER_ELEMENT', ns, null);
                Dom.XmlNode scTypeKey = scType.addChildElement('NAME', ns, null).addTextNode('ATTRIBUTE10');
                Dom.XmlNode scTypeValue = scType.addChildElement('VALUE', ns, null).addTextNode(prodWrapper.memShortCode );
                
            }
            if(prodWrapper.building != null){
                Dom.XmlNode building = invoice.addChildElement('USER_ELEMENT', ns, null);
                Dom.XmlNode buildingKey = building.addChildElement('NAME', ns, null).addTextNode('ATTRIBUTE11');
                Dom.XmlNode buildingValue = building.addChildElement('VALUE', ns, null).addTextNode(prodWrapper.building );
                
            }
            if(prodWrapper.billToName != null){
                Dom.XmlNode billToName = invoice.addChildElement('USER_ELEMENT', ns, null);
                Dom.XmlNode billToNameKey = billToName.addChildElement('NAME', ns, null).addTextNode('ATTRIBUTE14');
                Dom.XmlNode billToNameValue = billToName.addChildElement('VALUE', ns, null).addTextNode(prodWrapper.billToName );
                
            }
            
            if( prodWrapper.shipFromCountry != null &&!prodWrapper.shipFromCountry.equals('USA') && !prodWrapper.shipFromCountry.equals('US') && !ProdWrapper.shipFromCountry.equals('United States')){
                Dom.XmlNode buyerPrimary = invoice.addChildElement('BUYER_PRIMARY', ns, null);    
                Dom.XmlNode buyerCity = BuyerPrimary.addChildElement('CITY', ns, null).addTextNode(prodWrapper.shipToCity);
                Dom.XmlNode buyerState = BuyerPrimary.addChildElement('PROVINCE', ns, null).addTextNode(prodWrapper.shipToState);
                Dom.XmlNode buyerPostal = BuyerPrimary.addChildElement('POSTCODE', ns, null).addTextNode(prodWrapper.shipToPostcode);
                Dom.XmlNode buyerCountry = BuyerPrimary.addChildElement('COUNTRY', ns, null).addTextNode(prodWrapper.shipToCountry);
                Dom.XmlNode sellerPrimary = invoice.addChildElement('SELLER_PRIMARY', ns, null);    
                Dom.XmlNode sellerPrimCity = SellerPrimary.addChildElement('CITY', ns, null).addTextNode(prodWrapper.shipFromCity);
                Dom.XmlNode sellerPrimState = SellerPrimary.addChildElement('PROVINCE', ns, null).addTextNode(prodWrapper.shipFromState);
                Dom.XmlNode sellerPrimZip = SellerPrimary.addChildElement('POSTCODE', ns, null).addTextNode(prodWrapper.shipFromPostcode);
                Dom.XmlNode sellerPrimCountry = SellerPrimary.addChildElement('COUNTRY', ns, null).addTextNode(prodWrapper.shipFromCountry);
                
                Dom.XmlNode registrations = invoice.addChildElement('REGISTRATIONS', ns, null);
                if(sellerRegList?.size()>0){
                    for(integer i=0;i<sellerRegList.size();i++){
                        Dom.XmlNode sellerRole = registrations.addChildElement('SELLER_ROLE', ns, null).addTextNode(sellerRegList[i]);    
                    }    
                }
                
            }
            Dom.XmlNode supplyAddr = invoice.addChildElement('SUPPLY', ns, null);    
            Dom.XmlNode supplyCity = SupplyAddr.addChildElement('CITY', ns, null).addTextNode(ProdWrapper.shipToCity);
            if(!ProdWrapper.shipToCountry.equals('USA') && !ProdWrapper.shipToCountry.equals('US') && !ProdWrapper.shipToCountry.equals('United States')){
                Dom.XmlNode supplyState = SupplyAddr.addChildElement('PROVINCE', ns, null).addTextNode(ProdWrapper.shipToState);  
            }else{
                Dom.XmlNode supplyState = SupplyAddr.addChildElement('STATE', ns, null).addTextNode(ProdWrapper.shipToState);
            }
            
            Dom.XmlNode supplyZip = SupplyAddr.addChildElement('POSTCODE', ns, null).addTextNode(ProdWrapper.shipToPostcode);
            Dom.XmlNode supplyCountry = SupplyAddr.addChildElement('COUNTRY', ns, null).addTextNode(ProdWrapper.shipToCountry);
            
            Dom.XmlNode orderAcc = invoice.addChildElement('ORDER_ACCEPTANCE', ns, null);    
            Dom.XmlNode orderAccCity = orderAcc.addChildElement('CITY', ns, null).addTextNode(ProdWrapper.shipToCity);
            if(!ProdWrapper.shipToCountry.equals('USA') && !ProdWrapper.shipToCountry.equals('US') && !ProdWrapper.shipToCountry.equals('United States')){
                Dom.XmlNode orderAccState = orderAcc.addChildElement('PROVINCE', ns, null).addTextNode(ProdWrapper.shipToState);  
            }else{
                Dom.XmlNode orderAccState = orderAcc.addChildElement('STATE', ns, null).addTextNode(ProdWrapper.shipToState);     
            }    
            
            Dom.XmlNode orderAccZip = orderAcc.addChildElement('POSTCODE', ns, null).addTextNode(ProdWrapper.shipToPostcode);
            Dom.XmlNode orderAccCountry = orderAcc.addChildElement('COUNTRY', ns, null).addTextNode(ProdWrapper.shipToCountry);
            Dom.XmlNode shipfrom = invoice.addChildElement('SHIP_FROM', ns, null);
            Dom.XmlNode cityFrom = Shipfrom.addChildElement('CITY', ns, null).addTextNode(ProdWrapper.shipFromCity !=null ? ProdWrapper.shipFromCity:'');
            if(!ProdWrapper.shipFromCountry.equals('USA') && !ProdWrapper.shipFromCountry.equals('US') && !ProdWrapper.shipFromCountry.equals('United States')){
                Dom.XmlNode stateFrom = Shipfrom.addChildElement('PROVINCE', ns, null).addTextNode(ProdWrapper.shipFromState);  
            }else{
                Dom.XmlNode stateFrom = Shipfrom.addChildElement('STATE', ns, null).addTextNode(ProdWrapper.shipFromState !=null ? ProdWrapper.shipFromState:'');     
            }   
            
            if(shipFromZipGeo?.size()>1){
                Dom.XmlNode postcodeFrom = Shipfrom.addChildElement('POSTCODE', ns, null).addTextNode(shipFromZipGeo[0]);
                Dom.XmlNode geocodeFrom = Shipfrom.addChildElement('GEOCODE', ns, null).addTextNode(shipFromZipGeo[1]);
                
            }else{
                
                Dom.XmlNode postcodeFrom = Shipfrom.addChildElement('POSTCODE', ns, null).addTextNode(shipFromZipGeo[0] != null? shipFromZipGeo[0]:'');
            }
            
            Dom.XmlNode countryFrom = Shipfrom.addChildElement('COUNTRY', ns, null).addTextNode(ProdWrapper.shipFromCountry !=null ? ProdWrapper.shipFromCountry:'');
            Dom.XmlNode shipto = invoice.addChildElement('SHIP_TO', ns, null);
            Dom.XmlNode cityTo = Shipto.addChildElement('CITY', ns, null).addTextNode(ProdWrapper.shipToCity!=null ? ProdWrapper.shipToCity:'');
            if(!ProdWrapper.shipToCountry.equals('USA') && !ProdWrapper.shipToCountry.equals('US') && !ProdWrapper.shipToCountry.equals('United States')){
                Dom.XmlNode stateTo = Shipto.addChildElement('PROVINCE', ns, null).addTextNode(ProdWrapper.shipToState);  
            }else{
                Dom.XmlNode stateTo = Shipto.addChildElement('STATE', ns, null).addTextNode(ProdWrapper.shipToState !=null ? ProdWrapper.shipToState:'');       
            }
            
            if(shiptoZipGeo?.size()>1){
                Dom.XmlNode postcodeTo = Shipto.addChildElement('POSTCODE', ns, null).addTextNode(shiptoZipGeo[0]);         
                Dom.XmlNode geocodeTo = Shipto.addChildElement('GEOCODE', ns, null).addTextNode(shiptoZipGeo[1]);         
            }else{
                Dom.XmlNode postcodeTo = Shipto.addChildElement('POSTCODE', ns, null).addTextNode(shiptoZipGeo[0] != null ? shiptoZipGeo[0]:'');         
            }
            
            Dom.XmlNode countryTo = Shipto.addChildElement('COUNTRY', ns, null).addTextNode(ProdWrapper.shipToCountry !=null ? ProdWrapper.shipToCountry:'');
            
            Dom.XmlNode billto = invoice.addChildElement('BILL_TO', ns, null);
            Dom.XmlNode cityBillTo = billto.addChildElement('CITY', ns, null).addTextNode(ProdWrapper.billToCity!=null ? ProdWrapper.billToCity:'');
            if(!ProdWrapper.billToCountry.equals('USA') && !ProdWrapper.billToCountry.equals('US') && !ProdWrapper.billToCountry.equals('United States')){
                Dom.XmlNode stateBillTo = billto.addChildElement('PROVINCE', ns, null).addTextNode(ProdWrapper.billToState);  
            }else{
                Dom.XmlNode stateBillTo = billto.addChildElement('STATE', ns, null).addTextNode(ProdWrapper.billToState !=null ? ProdWrapper.billToState:'');        
            }    
            
            if(billtoZipGeo?.size()>1){
                Dom.XmlNode postcodeBillTo = billto.addChildElement('POSTCODE', ns, null).addTextNode(billtoZipGeo[0]);         
                Dom.XmlNode geoCodeBillTo = billto.addChildElement('GEOCODE', ns, null).addTextNode(billtoZipGeo[1]);         
            }else{
                Dom.XmlNode postcodeBillTo = billto.addChildElement('POSTCODE', ns, null).addTextNode(billtoZipGeo[0] != null ? billtoZipGeo[0]:'');         
            }
            
            Dom.XmlNode countryBillTo = billto.addChildElement('COUNTRY', ns, null).addTextNode(ProdWrapper.billToCountry !=null ? ProdWrapper.billToCountry:'');
            
            for(integer i=0;i<ProdWrapper.ProductItems.size();i++){
                Dom.XmlNode line = invoice.addChildElement('LINE', ns, null);
                LINE.setAttribute('ID', string.valueof(i+1));
                Dom.XmlNode grossAmount = LINE.addChildElement('GROSS_AMOUNT', ns, null).addTextNode(string.valueof(ProdWrapper.ProductItems[i].GROSSAMOUNT !=null ? ProdWrapper.ProductItems[i].GROSSAMOUNT: 0));
                Dom.XmlNode linenumber = LINE.addChildElement('LINE_NUMBER', ns, null).addTextNode(string.valueof(ProdWrapper.ProductItems[i].LINENUMBER));
                Dom.XmlNode prodcode = LINE.addChildElement('PRODUCT_CODE', ns, null).addTextNode(string.valueof(ProdWrapper.ProductItems[i].productCode !=null ? ProdWrapper.ProductItems[i].productCode:''));
                Dom.XmlNode quantities = LINE.addChildElement('QUANTITIES', ns, null);
                Dom.XmlNode quantity = quantities.addChildElement('QUANTITY', ns, null);
                Dom.XmlNode quantityAmount = QUANTITY.addChildElement('AMOUNT', ns, null).addTextNode(string.valueof(ProdWrapper.ProductItems[i].quantity));
                Dom.XmlNode uomQuantity  = quantity.addChildElement('UOM', ns, null).addTextNode('each');
                Dom.XmlNode capimpr = line.addChildElement('USER_ELEMENT', ns, null);
                Dom.XmlNode capimprKey = Capimpr.addChildElement('NAME', ns, null).addTextNode('ATTRIBUTE15');
                Dom.XmlNode capimprValue = Capimpr.addChildElement('VALUE', ns, null).addTextNode(ProdWrapper.ProductItems[i].capitalImpr !=null ? ProdWrapper.ProductItems[i].capitalImpr: 'False');
                
            }
            return doc.toXmlString();
        }
        catch(Exception e){
            isExceptionOccured=true;
            ApexDebugLog.logException(e, 'recordid==>'+objectId, 'OIDT_XMLGenerateCtrl','generateTaxCalculationReq');
            
        }
        return taxCalStr;
    }
    
    public static Map<String,String> taxCalcRes(String responseXML) 
    {   
        Map<String,String> myMap = new Map<String,String>();
        DOM.Document doc = new DOM.Document();
        String toParse = responseXML;
        doc.load(toParse);
        DOM.XMLNode root = doc.getRootElement();
        String nms = root.getNameSpace();
        String eRPCODE = '';
        String zone = '';
        String autherizationType='';
        Boolean lineChange = false;
        Decimal stateSum = 0;
        Decimal districtSum = 0;
        Decimal citySum = 0;
        Decimal countySum = 0;
        String lineNumber;
        DOM.XMLNode body = root.getChildElement('Body', nms);
        DOM.XMLNode outdata = body.getChildElement('Outdata', nms);
        DOM.XMLNode fault = body.getChildElement('Fault', nms);
        List<DOM.XMLNode> taxresp = body.getChildElements();
        //BZ-439
        if(false == true){
            mymap.put('status', 'fail');
            mymap.put('desc','Fault in tax calculation (Unmarshalling Error: unexpected element)');
        }
        //BZ-439
        else{
            for (DOM.XMLNode taxres: taxresp){
                List<DOM.XMLNode> outresp = taxres.getChildElements();
                for (DOM.XMLNode outres: outresp){
                    List<DOM.XMLNode> reqStat = outres.getChildElements();
                    for (DOM.XMLNode reqStatus: reqStat){
                        List<DOM.XMLNode> outreqStat = reqStatus.getChildElements();
                        for (DOM.XMLNode outReqStatus: OutReqStat){
                            if(outReqStatus.getName()== 'IS_SUCCESS'){
                                string resStatus = OutReqStatus.getText();
                                if (resStatus == 'false'){
                                    mymap.put('status', 'fail');
                                    
                                }else{
                                    mymap.put('status', 'success');
                                }
                            }
                            linechange = false;
                            if (OutReqStatus.getName() == 'TOTAL_TAX_AMOUNT'){
                                string totalTax = OutReqStatus.getText();
                                myMap.put('totalTax',totalTax);
                                if(totalTax.substring(1, 1) == '-') {
                                    mymap.put('status', 'fail');   
                                }
                                
                            }
                            List<Tax_Line_Item_Service__c>  taxes = new List<Tax_Line_Item_Service__c> ();
                            List<DOM.XMLNode> outReqStat1 = OutReqStatus.getChildElements();
                            for (DOM.XMLNode outReqStatus1: OutReqStat1){
                                
                                if (OutReqStatus1.getName() == 'LINE_NUMBER')
                                {
                                    if(OutReqStatus1.getText()!=LineNumber){
                                        lineChange = true; 
                                    }
                                    if(lineChange == true ){
                                        districtSum = 0; 
                                        stateSum = 0;
                                        citySum = 0;
                                        countySum = 0;
                                    }
                                    lineNumber = OutReqStatus1.getText();
                                }
                                if (OutReqStatus1.getName() == 'TOTAL_TAX_AMOUNT'){
                                    string totalTax = OutReqStatus1.getText();
                                    myMap.put('totalTax'+LineNumber,totalTax);
                                }
                                string errorcode = '';
                               
                                List<DOM.XMLNode> outReqStat2 = OutReqStatus1.getChildElements();
                                Tax_Line_Item_Service__c tax;
                                if('TAX'.equals(outReqStatus1.getName())) {
                                    tax = new Tax_Line_Item_Service__c();
                                }
                                for (DOM.XMLNode outReqStatus2: OutReqStat2){
                                   	if('TAX'.equals(outReqStatus1.getName())) {
                                        if(OutReqStatus2.getName() =='ADMIN_ZONE_LEVEL'){
                                            tax.Admin_Zone_Level__c  = OutReqStatus2.gettext();
                                        }
                                        if(OutReqStatus2.getName() =='AUTHORITY_NAME' && String.isNotBlank(OutReqStatus2.gettext())){
                                            tax.Authority_Name__c   =  OutReqStatus2.gettext().left(80);
                                        }
                                        if(OutReqStatus2.getName() =='AUTHORITY_TYPE'){
                                            tax.Authority_Type__c   = OutReqStatus2.gettext();
                                        }
                                        if(OutReqStatus2.getName() =='ERP_TAX_CODE'){
                                            tax.ERP_Tax_Code__c   = OutReqStatus2.gettext();
                                        }
                                        if(OutReqStatus2.getName() =='ZONE_LEVEL'){
                                            tax.Zone_Level__c   = OutReqStatus2.gettext();
                                        }
                                        if(OutReqStatus2.getName() =='ZONE_NAME'){
                                            tax.Zone_Name__c   = OutReqStatus2.gettext();
                                        }
                                        if(OutReqStatus2.getName() =='TAX_TYPE'){
                                            tax.Tax_Type__c   = OutReqStatus2.gettext();
                                        }
                                        if(OutReqStatus2.getName() =='TAX_RATE_CODE'){
                                            tax.Tax_Rate_Code__c   = OutReqStatus2.gettext();
                                        }
                                        if(OutReqStatus2.getName() =='TAXABLE_COUNTRY'){
                                            tax.Taxable_Country__c   = OutReqStatus2.gettext();
                                        }
                                        if(OutReqStatus2.getName() =='AUTHORITY_CURRENCY_CODE'){
                                            tax.CurrencyIsoCode    = OutReqStatus2.gettext();
                                        }
                                        if(OutReqStatus2.getName() =='AUTHORITY_UUID'){
                                            tax.Authority_UUID__c    = OutReqStatus2.gettext();
                                        }
                                        if(OutReqStatus2.getName() == 'TAX_RATE' && OutReqStatus2.gettext() !=null){
                                            tax.Tax_Rate__c    =  Decimal.valueOf(OutReqStatus2.gettext());
                                        }
                                    }
                                    if(OutReqStatus2.getName() =='Code'){
                                        errorcode = OutReqStatus2.getName()+':'+ OutReqStatus2.gettext();
                                    }
                                    if(OutReqStatus2.getName() =='Description'){
                                        mymap.put('desc',errorcode+'\n'+OutReqStatus2.gettext());
                                    }
                                    if(OutReqStatus2.getName() =='ERP_TAX_CODE'){
                                        mymap.put('erpTaxCode'+LineNumber,OutReqStatus2.gettext());
                                        ERPCODE = OutReqStatus2.gettext(); 
                                    }
                                    if(OutReqStatus2.getName() =='EXEMPT_CERTIFICATE'){
                                        mymap.put('exemptCert',OutReqStatus2.gettext());
                                        
                                    }
                                    if(OutReqStatus2.getName() =='EXEMPT_REASON'){
                                        mymap.put('exemptReason',OutReqStatus2.gettext());
                                        
                                    }
                                    if(OutReqStatus2.getName() =='EFFECTIVE_ZONE_LEVEL'){
                                        mymap.put(OutReqStatus2.gettext()+'ERPCODE'+LineNumber, ERPCODE);
                                        zone =OutReqStatus2.gettext();
                                    }
                                    if(OutReqStatus2.getName() =='AUTHORITY_TYPE'){
                                        autherizationType =OutReqStatus2.gettext();
                                    }
                                    if(OutReqStatus2.getName() =='INVOICE_DESCRIPTION'){
                                        mymap.put('InvDesc'+LineNumber, OutReqStatus2.gettext());  
                                    }
                                    if(OutReqStatus2.getName() =='JURISDICTION_TEXT'){
                                        mymap.put('jurisdictionTxt'+LineNumber, OutReqStatus2.gettext());  
                                    }
                                    if (OutReqStatus2.getName() == 'TAXABLE_COUNTRY'){
                                        string taxableCountry = OutReqStatus2.getText();
                                        myMap.put('taxableCountry',taxableCountry);
                                    }
                                    if (OutReqStatus2.getName() == 'TAXABLE_STATE'||OutReqStatus2.getName() == 'TAXABLE_PROVINCE'){
                                        string taxableregion = OutReqStatus2.getText();
                                        myMap.put('taxableregion',taxableregion);
                                    }
                                    if (OutReqStatus2.getName() == 'TAX_TYPE'){
                                        string taxtype = OutReqStatus2.getText();
                                        myMap.put('taxtype'+LineNumber,taxtype);
                                    }  
                                    if (OutReqStatus2.getName() == 'TAX_RATE_CODE'){
                                        
                                        myMap.put('taxrateCODE'+LineNumber, OutReqStatus2.getText());
                                    }
                                    if (OutReqStatus2.getName() == 'EFFECTIVE_TAX_RATE'){
                                        string effTaxRate = OutReqStatus2.getText();
                                        myMap.put('effTaxRt',effTaxRate);
                                        myMap.put(Linenumber,effTaxRate);
                                    }    
                                    if (OutReqStatus2.getName() == 'EXEMPT_AMOUNT'){
                                        string exemptAmount = OutReqStatus2.getText();
                                        myMap.put('exemptAmount'+LineNumber,exemptAmount);
                                    } 
                                    
                                    if (OutReqStatus2.getName() == 'TAXABLE_BASIS'){
                                        string taxableAmount = OutReqStatus2.getText();
                                        myMap.put('taxableAmount'+LineNumber,taxableAmount);
                                        
                                    }  
                                    List<DOM.XMLNode> outRequestStat = OutReqStatus2.getChildElements();
                                    
                                    for (DOM.XMLNode OutRequestStatus: outRequestStat){
                                        
                                        if(OutReqStatus2.getName()=='TAX_AMOUNT'){
                                            if(OutRequestStatus.getName()=='AUTHORITY_AMOUNT'){
                                                
                                                if(OutRequestStatus.gettext() != null){
                                                    tax.Tax_Amount__c   =  Decimal.valueOf(OutRequestStatus.gettext());
                                                }
                                                if (zone=='District'){
                                                    districtSum = DistrictSum + decimal.valueOf(OutRequestStatus.getText());
                                                }
                                                if (zone=='State'){
                                                    stateSum = StateSum + decimal.valueOf(OutRequestStatus.getText());
                                                }
                                                if (zone=='City'){
                                                    citySum = CitySum + decimal.valueOf(OutRequestStatus.getText());
                                                }
                                                if (zone=='County'){
                                                    countySum = CountySum + decimal.valueOf(OutRequestStatus.getText());
                                                }
                                                myMap.put('districterp'+lineNumber,string.valueof(DistrictSum));
                                                myMap.put('Stateerp'+lineNumber,string.valueof(StateSum));
                                                myMap.put('cityerp'+lineNumber,string.valueof(CitySum));
                                                myMap.put('countyerp'+lineNumber,string.valueof(CountySum));
                                                if(autherizationType=='GST'){
                                                    myMap.put('GST'+lineNumber,OutRequestStatus.getText());  
                                                }
                                                if(autherizationType=='QST'){
                                                    myMap.put('QST'+lineNumber,OutRequestStatus.getText());  
                                                }
                                                if(autherizationType=='HST'){
                                                    myMap.put('HST'+lineNumber,OutRequestStatus.getText());  
                                                }
                                                if(autherizationType=='PST'){
                                                    myMap.put('PST'+lineNumber,OutRequestStatus.getText());  
                                                }
												if(autherizationType=='CGST'){
                                                    myMap.put('CGST'+lineNumber,OutRequestStatus.getText());  
                                                }
												if(autherizationType=='IGST'){
                                                    myMap.put('IGST'+lineNumber,OutRequestStatus.getText());  
                                                }
												if(autherizationType=='SGST'){
                                                    myMap.put('SGST'+lineNumber,OutRequestStatus.getText());  
                                                }
                                            } 
                                            if(OutRequestStatus.getName()=='UNROUNDED_DOCUMENT_AMOUNT'){
                                         		if(OutRequestStatus.getText() != null){
                                                    tax.Undocumented_Tax_Amount__c   =  Decimal.valueOf(OutRequestStatus.getText());
                                                }
                                         	}
                                        }
                                        
                                     }
                                    
                                }  
                                
                                if(tax != null  && String.isNotEmpty(tax.Authority_UUID__c)) {
                                    taxes.add(tax);
                                    mymap.put('TAX'+lineNumber,JSON.serialize(taxes));       
                                }
                            }
                        }
                    }
                }
            }
        }
        return myMap;
    }
    
    public static String decryptUsrDtl(String uStr){
        Blob decodeduStrBlob1 = EncodingUtil.base64Decode(uStr);  
        return decodeduStrBlob1.toString();
    }
}