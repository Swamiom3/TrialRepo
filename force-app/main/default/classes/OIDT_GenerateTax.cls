public without sharing class OIDT_GenerateTax {
    
    @AuraEnabled
    public static Map<String,String> getQuoteTaxFields(Id recordid, Boolean async){
        Map<String,String> quoteMapresponse = new Map<String,String>();
        SBQQ__Quote__c quote = getQuoteDetails(recordid);
        List<SBQQ__QuoteLine__c> quotelineList = new List<SBQQ__QuoteLine__c>();
        quotelineList = getQuoteLineDetails(recordid);        
        OIDT_ProductWrapper productWrapper = new OIDT_ProductWrapper();  
        productWrapper.recordId = quote.id;
        productWrapper.invNumber = quote.name;
        productWrapper.customerNum = quote.Billing_Account__r.Member_Short_Code__c;
        productWrapper.currencyCode = quote.CurrencyIsoCode;
        productWrapper.companyId = quote.Building_Id__r.Legal_Entity_id__r.External_Id__c;
        productWrapper.customerName = quote.SBQQ__Account__r.name;
        productWrapper.billToName = quote.Billing_Account__r.name;
        productWrapper.billToCountry = quote.SBQQ__Account__r.BillingCountry;
        productWrapper.billToCity = quote.SBQQ__Account__r.BillingCity;
        productWrapper.billToState = quote.SBQQ__Account__r.BillingState;
        productWrapper.billToPostcode = quote.SBQQ__Account__r.BillingPostalCode;
        productWrapper.building = quote.Building_Id__r.Name;        
        productWrapper.shipToCountry = quote.SBQQ__Account__r.BillingCountry;
        productWrapper.shipToCity = quote.SBQQ__Account__r.BillingCity;
        productWrapper.shipToState = quote.SBQQ__Account__r.BillingState;
        productWrapper.shipToPostcode = quote.SBQQ__Account__r.BillingPostalCode;
        productWrapper.memShortCode = quote.SBQQ__Account__r.Member_Short_Code__c;
        productWrapper.shipFromState = quote.Building_Id__r.Legal_Entity_Id__r.blng__State__c;
        productWrapper.shipFromCity = quote.Building_Id__r.Legal_Entity_Id__r.blng__City__c;
        productWrapper.shipFromPostcode = quote.Building_Id__r.Legal_Entity_Id__r.blng__ZipPostalCode__c;
        productWrapper.shipFromCountry = quote.Building_Id__r.Legal_Entity_Id__r.blng__Country__c != null ? quote.Building_Id__r.Legal_Entity_Id__r.blng__Country__c:'US' ;
        productWrapper.sellerRegistration = quote.Building_Id__r.VAT_Id__c;
        productWrapper.ProductItems = new List<OIDT_ProductWrapper.ProductItemWrapper>();
         for(SBQQ__QuoteLine__c quoteline: quoteLineList){
            OIDT_ProductWrapper.ProductItemWrapper proditem=new OIDT_ProductWrapper.ProductItemWrapper();
            String quoteAutoNumber=quoteline.name; 
            proditem.lineNumber= String.Valueof(quoteAutoNumber.split('-')[1]);
            proditem.quantity = quoteline.SBQQ__Quantity__c; 
            proditem.grossAmount = quoteline.SBQQ__NetTotal__c;
            proditem.productCode = quoteline.SBQQ__Product__r.ProductCode;
            productWrapper.ProductItems.add(proditem); 
        }

        if(quote.SBQQ__Account__r.BillingCountry == null || quote.SBQQ__Account__r.BillingCity == null ||  quote.SBQQ__Account__r.BillingState == null || 
           quote.SBQQ__Account__r.BillingPostalCode == null){
               quoteMapresponse.put('status', 'MissingBillTo');
               return quoteMapresponse;
        }

        if(quote.Building_Id__r.Legal_Entity_Id__r.blng__ZipPostalCode__c == null || quote.Building_Id__r.Legal_Entity_Id__r.blng__City__c == null ||  quote.Building_Id__r.Legal_Entity_Id__r.blng__Country__c == null || 
           quote.Building_Id__r.Legal_Entity_Id__r.blng__State__c == null){
               quoteMapresponse.put('status', 'MissingShipFrom');
                return quoteMapresponse;
        }

        if(quote.SBQQ__Status__c != 'Approved' && quote.SBQQ__Status__c != 'Presented' && quote.SBQQ__Status__c != 'Accepted'){
            quoteMapresponse.put('status', 'invalidStatus');
             return quoteMapresponse;
        }
        
        String xmlRequest = OIDT_XMLGenerateCtrl.generateTaxCalculationReq(productWrapper); 
        if(!String.isBlank(xmlRequest) && async == false){
            try{
                 String xmlResponse = OIDT_SoapAPITaxCallout.UsTaxCallout(xmlRequest,recordid, async);
                 if(xmlResponse != null&& !String.isBlank(xmlResponse)){
                     quoteMapresponse = OIDT_XMLGenerateCtrl.TaxCalcRes(xmlResponse);
                     updateQuote(quoteMapresponse,recordid);
                 }          
            }catch(exception e){
                 ApexDebugLog.logException(e, 'recordid==>'+recordid, 'OIDT_GenerateTax','getQuoteTaxFields');
            }
            
        }else if(!String.isBlank(xmlRequest) && async == true){
            OIDT_SoapAPITaxCallout.UsAsyncTaxCallout(xmlRequest,recordid, async);
        }
         return quoteMapresponse;
    }

    public static void updateQuote(Map<String,String> srcMap,Id recId){
         if(srcMap.isEmpty()){
            return;
        }
        List<SBQQ__Quote__c> orderListUpdate = new List<SBQQ__Quote__c>();
        List<SObject> quoteToUpdate = new List<SObject>();
        //-V- to refactor
        List<SBQQ__Quote__c> orderList = [SELECT Id,Calculated_Tax_Amount__c FROM SBQQ__Quote__c WHERE Id =:recId];
        for(SBQQ__Quote__c qt :orderList){
            if(srcMap.get('totalTax') != null) {
                qt.Calculated_Tax_Amount__c =  Decimal.valueOf(srcMap.get('totalTax'));
                quoteToUpdate.add(qt); 
            }
        }

        List<SBQQ__QuoteLine__c> itemsList = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> orderItemList = [SELECT Id,SBQQ__NetPrice__c,name,Tax_Rate__c,Exempt_Amount__c,SBQQ__QuoteLine__c.SBQQ__Quote__c,
                                                    Idt_HST__c,Idt_GST__c,Idt_QST__c,Idt_CGST_S__c,Idt_IGST_S__c,Idt_SGST_S__c 
                                                  FROM SBQQ__QuoteLine__c  
                                                  WHERE SBQQ__QuoteLine__c.SBQQ__Quote__c = :recId];  
        
        if(srcMap.get('status') != 'fail'){
            for(SBQQ__QuoteLine__c line :orderItemList){
                String lineItemNum = string.valueof(line.name.right(7));
                lineItemNum = lineItemNum.replaceFirst('^0+', '');
                   if(srcMap.get(lineItemNum) != null){
                    line.Tax_Rate__c = Decimal.valueOf(srcMap.get(lineItemNum))*100;    
                }
                if(srcMap.get('exemptAmount'+lineItemNum) != null){
                    line.Exempt_Amount__c = Decimal.valueOf(srcMap.get('exemptAmount'+lineItemNum));
                }
				if( srcMap.get('HST'+lineItemNum) != null){
                        line.Idt_HST__c = Decimal.valueOf(srcMap.get('HST'+lineItemNum));
				}
				if(srcMap.get('QST'+lineItemNum) != null){
					line.Idt_QST__c = Decimal.valueOf(srcMap.get('QST'+lineItemNum));
				}
				if(srcMap.get('GST'+lineItemNum) != null){
					line.Idt_GST__c = Decimal.valueOf(srcMap.get('GST'+lineItemNum));
				}
				if(srcMap.get('CGST'+lineItemNum) != null){
					line.Idt_CGST_S__c = Decimal.valueOf(srcMap.get('CGST'+lineItemNum));
				}
				if(srcMap.get('IGST'+lineItemNum) != null){
					line.Idt_IGST_S__c = Decimal.valueOf(srcMap.get('IGST'+lineItemNum));
				}
				if(srcMap.get('SGST'+lineItemNum) != null){
					line.Idt_SGST_S__c = Decimal.valueOf(srcMap.get('SGST'+lineItemNum));
				}
                
                quoteToUpdate.add(line);
            }
        }
        if(!quoteToUpdate.isEMpty()){
            update quoteToUpdate;
        }
    }
    
    public static Map<String,String> orderTaxFields(Id recordid, Boolean async){
        Map<String,String> orderMapresponse = new Map<String,String>(); 
        Order orderRec = getOrderDetails(recordid);
        List<OrderItem> orderlineList = new List<OrderItem>();
        orderlineList = getOrderLineDetails(recordid);   
        OIDT_ProductWrapper productWrapper = new OIDT_ProductWrapper();
        productWrapper.recordId = orderRec.id;
        productWrapper.invNumber = orderRec.OrderNumber;
        productWrapper.currencyCode = orderRec.CurrencyIsoCode;
        productWrapper.companyId = orderRec.Building_Id__r.Legal_Entity_id__r.External_Id__c ;
        productWrapper.customerName = orderRec.Account.name;
        productWrapper.customerNum = orderRec.account.Member_Short_Code__c;
        productWrapper.billToName =  orderRec.Account.name;
        productWrapper.billToCountry = orderRec.account.BillingCountry;
        productWrapper.billToCity = orderRec.account.BillingCity;
        productWrapper.billToState = orderRec.account.BillingState;
        productWrapper.billToPostcode = orderRec.account.BillingPostalCode;
        productWrapper.building = orderRec.Building_Id__r.Name;
        productWrapper.shipToCountry = orderRec.Account.ShippingCountry;
        productWrapper.shipToCity = orderRec.Account.ShippingCity;
        productWrapper.shipToState = orderRec.Account.shippingState;
        productWrapper.shipToPostcode = orderRec.Account.shippingPostalCode;
        productWrapper.sellerRegistration = orderRec.Building_Id__r.VAT_Id__c;
        productWrapper.shipFromState = orderRec.Building_Id__r.Legal_Entity_Id__r.blng__State__c;
        productWrapper.shipFromCity = orderRec.Building_Id__r.Legal_Entity_Id__r.blng__City__c;
        productWrapper.shipFromPostcode = orderRec.Building_Id__r.Legal_Entity_Id__r.blng__ZipPostalCode__c;
        productWrapper.shipFromCountry = orderRec.Building_Id__r.Legal_Entity_Id__r.blng__Country__c != null ? orderRec.Building_Id__r.Legal_Entity_Id__r.blng__Country__c:'US' ;
        productWrapper.ProductItems = new List<OIDT_ProductWrapper.ProductItemWrapper>();
        for(OrderItem orderline: orderlineList){
            OIDT_ProductWrapper.ProductItemWrapper proditem=new OIDT_ProductWrapper.ProductItemWrapper();
            proditem.lineNumber= orderline.OrderItemNumber;
            proditem.quantity = orderline.Quantity; 
            proditem.grossAmount = orderline.TotalPrice;
            proditem.productCode = orderline.Product2.ProductCode;
            //Added by Avinash
			//proditem.qst=orderline.QST__c;          
            
            
            productWrapper.ProductItems.add(proditem); 
        }
        
        if(orderRec.account.BillingCountry == null || orderRec.account.BillingCity == null ||  orderRec.account.BillingState == null || 
           orderRec.account.BillingPostalCode == null){
               orderMapresponse.put('status', 'MissingBillTo');
               return orderMapresponse;
           }

        if(orderRec.Building_Id__r.Legal_Entity_Id__r.blng__ZipPostalCode__c == null || orderRec.Building_Id__r.Legal_Entity_Id__r.blng__City__c == null ||  orderRec.Building_Id__r.Legal_Entity_Id__r.blng__Country__c == null || 
           orderRec.Building_Id__r.Legal_Entity_Id__r.blng__State__c == null){
               orderMapresponse.put('status', 'MissingShipFrom');
               return orderMapresponse;
           } 
        String xmlRequest = OIDT_XMLGenerateCtrl.generateTaxCalculationReq(productWrapper); 
        if(!String.isBlank(xmlRequest) && async == false){
            try{
                String xmlResponse = OIDT_SoapAPITaxCallout.UsTaxCallout(xmlRequest,recordid, async);
                if(xmlResponse != null&& !String.isBlank(xmlResponse)){
                    orderMapresponse = OIDT_XMLGenerateCtrl.TaxCalcRes(xmlResponse);
                    UpdateOrder(orderMapresponse,recordid);
                }          
            }catch(exception e){
                ApexDebugLog.logException(e, 'recordid==>'+recordid, 'OIDT_GenerateTax','orderTaxFields');
            }
        }
        return orderMapresponse;
    } 
    
    public static Map<String,String> invoiceTaxFields(Id recordId, Boolean async){
        Map<String,String> invoiceMapresponse = new Map<String,String>(); 
        blng__Invoice__c i = getInvoiceDetails(recordId);
        List<blng__InvoiceLine__c> invlineList = new List<blng__InvoiceLine__c>();
        invlineList = getInvoiceLineDetails(recordId);   
        OIDT_ProductWrapper productWrapper = new OIDT_ProductWrapper();
        productWrapper.recordId = i.id;
        productWrapper.customerNum = i.blng__Account__r.Member_Short_Code__c;
        productWrapper.invNumber = i.Name;
        productWrapper.currencyCode = i.CurrencyIsoCode;
        productWrapper.companyId = i.Building_Id__r.Legal_Entity_id__r.External_Id__c ;
        productWrapper.customerName = i.blng__Account__r.name;
        productWrapper.billToName =  i.blng__Account__r.name;
        productWrapper.billToCountry = i.blng__Account__r.BillingCountry;
        productWrapper.billToCity = i.blng__Account__r.BillingCity;
        productWrapper.billToState = i.blng__Account__r.BillingState;
        productWrapper.billToPostcode = i.blng__Account__r.BillingPostalCode;
        productWrapper.building = i.Building_Id__r.Name;
        productWrapper.shipToCountry = i.blng__Account__r.ShippingCountry;
        productWrapper.shipToCity = i.blng__Account__r.ShippingCity;
        productWrapper.shipToState = i.blng__Account__r.shippingState;
        productWrapper.shipToPostcode = i.blng__Account__r.shippingPostalCode;
        productWrapper.shipFromState = i.Building_Id__r.Legal_Entity_Id__r.blng__State__c;
        productWrapper.shipFromCity = i.Building_Id__r.Legal_Entity_Id__r.blng__City__c;
        productWrapper.shipFromPostcode = i.Building_Id__r.Legal_Entity_Id__r.blng__ZipPostalCode__c;
        productWrapper.shipFromCountry = i.Building_Id__r.Legal_Entity_Id__r.blng__Country__c != null ? i.Building_Id__r.Legal_Entity_Id__r.blng__Country__c:'US' ;
        productWrapper.Invoice_Status = i.blng__InvoiceStatus__c;
        productWrapper.auditCheck = i.Audit_Sent__c;
        productWrapper.sellerRegistration = i.Building_Id__r.VAT_Id__c;
        
        productWrapper.ProductItems = new List<OIDT_ProductWrapper.ProductItemWrapper>();
        for(blng__InvoiceLine__c line: invlineList){
            OIDT_ProductWrapper.ProductItemWrapper proditem=new OIDT_ProductWrapper.ProductItemWrapper();
            proditem.lineNumber= line.Invoice_Line_Number__c;
            proditem.quantity = line.blng__OrderProduct__r.Quantity; 
            proditem.grossAmount = line.blng__OrderProduct__r.TotalPrice;
            proditem.productCode = line.blng__OrderProduct__r.Product2.ProductCode;
            productWrapper.ProductItems.add(proditem); 
        }
        if(i.blng__Account__r.BillingCountry == null || i.blng__Account__r.BillingCity == null ||  i.blng__Account__r.BillingState == null || 
           i.blng__Account__r.BillingPostalCode == null){
               invoiceMapresponse.put('status', 'MissingBillTo');
               return invoiceMapresponse;
           }

        if(i.Building_Id__r.Legal_Entity_Id__r.blng__ZipPostalCode__c == null || i.Building_Id__r.Legal_Entity_Id__r.blng__City__c == null ||  i.Building_Id__r.Legal_Entity_Id__r.blng__Country__c == null || 
           i.Building_Id__r.Legal_Entity_Id__r.blng__State__c == null){
               invoiceMapresponse.put('status', 'MissingShipFrom');
               return invoiceMapresponse;
           } 
        
        String xmlRequest = OIDT_XMLGenerateCtrl.generateTaxCalculationReq(productWrapper); 
        if(!String.isBlank(xmlRequest) && async == false){
            try{
                String xmlResponse = OIDT_SoapAPITaxCallout.UsTaxCallout(xmlRequest,recordid, async);
                if(xmlResponse != null&& !String.isBlank(xmlResponse)){
                    invoiceMapresponse = OIDT_XMLGenerateCtrl.TaxCalcRes(xmlResponse);
                    updateInvoice(invoiceMapresponse,recordid);
                }          
            }catch(exception e){
                ApexDebugLog.logException(e, 'recordid==>'+recordId, 'OIDT_GenerateTax','invoiceTaxFields');
            }
            
        }
        return invoiceMapresponse;
    } 
    
    public static Map<String,String> cnTaxFields(Id recordId, Boolean async){
        Map<String,String> creditMapresponse = new Map<String,String>(); 
        blng__CreditNote__c creditNote = getCreditDetails(recordId);
        List<blng__CreditNoteLine__c> crlineList = new List<blng__CreditNoteLine__c>();
        crlineList = getCreditLineDetails(recordId);   
        OIDT_ProductWrapper productWrapper = new OIDT_ProductWrapper();
        productWrapper.recordId=creditNote.id;
        productWrapper.customerNum = creditNote.blng__Account__r.Member_Short_Code__c;
        productWrapper.invNumber = creditNote.Name;
        productWrapper.currencyCode = creditNote.CurrencyIsoCode;
        productWrapper.companyId = creditNote.Building_Id__r.Legal_Entity_id__r.External_Id__c ;
        productWrapper.customerName = creditNote.blng__Account__r.name;
        productWrapper.billToName =  creditNote.blng__Account__r.name;
        productWrapper.billToCountry = creditNote.blng__Account__r.BillingCountry;
        productWrapper.billToCity = creditNote.blng__Account__r.BillingCity;
        productWrapper.billToState = creditNote.blng__Account__r.BillingState;
        productWrapper.billToPostcode = creditNote.blng__Account__r.BillingPostalCode;
        productWrapper.building = creditNote.Building_Id__r.Name;
        productWrapper.shipToCountry = creditNote.blng__Account__r.ShippingCountry;
        productWrapper.shipToCity = creditNote.blng__Account__r.ShippingCity;
        productWrapper.shipToState = creditNote.blng__Account__r.shippingState;
        productWrapper.shipToPostcode = creditNote.blng__Account__r.shippingPostalCode;
        productWrapper.shipFromState = creditNote.Building_Id__r.Legal_Entity_Id__r.blng__State__c;
        productWrapper.shipFromCity = creditNote.Building_Id__r.Legal_Entity_Id__r.blng__City__c;
        productWrapper.shipFromPostcode = creditNote.Building_Id__r.Legal_Entity_Id__r.blng__ZipPostalCode__c;
        productWrapper.shipFromCountry = creditNote.Building_Id__r.Legal_Entity_Id__r.blng__Country__c != null ? creditNote.Building_Id__r.Legal_Entity_Id__r.blng__Country__c:'US' ;
        productWrapper.sellerRegistration = creditNote.Building_Id__r.VAT_Id__c;
        
        productWrapper.ProductItems = new List<OIDT_ProductWrapper.ProductItemWrapper>();
        for(blng__CreditNoteLine__c line:crlineList){
            OIDT_ProductWrapper.ProductItemWrapper proditem=new OIDT_ProductWrapper.ProductItemWrapper();
            proditem.lineNumber= line.Name;
            proditem.quantity =   1;
            proditem.grossAmount = -(line.blng__Subtotal__c);
            proditem.productCode = line.blng__Product__r.ProductCode;
            productWrapper.ProductItems.add(proditem); 
            
        }
        
        if(creditNote.blng__Account__r.BillingCountry == null || creditNote.blng__Account__r.BillingCity == null ||  creditNote.blng__Account__r.BillingState == null || 
           creditNote.blng__Account__r.BillingPostalCode == null){
               creditMapresponse.put('status', 'MissingBillTo');
               return creditMapresponse;
           }

        if(creditNote.Building_Id__r.Legal_Entity_Id__r.blng__ZipPostalCode__c == null || creditNote.Building_Id__r.Legal_Entity_Id__r.blng__City__c == null ||  creditNote.Building_Id__r.Legal_Entity_Id__r.blng__Country__c == null || 
           creditNote.Building_Id__r.Legal_Entity_Id__r.blng__State__c == null){
               creditMapresponse.put('status', 'MissingShipFrom');
               return creditMapresponse;
           } 
        
        String xmlRequest = OIDT_XMLGenerateCtrl.generateTaxCalculationReq(productWrapper); 
        if(!String.isBlank(xmlRequest) && async == false){
            try{
                String xmlResponse = OIDT_SoapAPITaxCallout.UsTaxCallout(xmlRequest,recordid, async);
                if(xmlResponse != null&& !String.isBlank(xmlResponse)){
                    creditMapresponse = OIDT_XMLGenerateCtrl.TaxCalcRes(xmlResponse);
                    updateCreditNote(creditMapresponse,recordid);
                }          
            }catch(exception e){
                ApexDebugLog.logException(e, 'recordid==>'+recordId, 'OIDT_GenerateTax','cnTaxFields');
            }
            
        }
        
        return creditMapresponse;
    } 
    
    public static void updateOrder(Map<String,String> srcMap,String recId){
        if(!srcMap.isEmpty()){
            try{
                List<OrderItem> itemsList = new List<OrderItem>();
                List<Order> orderListUpdate = new List<Order>();
                List<Sobject> ordersToUpdate = new List<Sobject>();
                List<Order> orderList = [SELECT Id,Calculated_Tax_Amount__c FROM Order WHERE Id =:recId LIMIT 1];    
                for(Order qt :orderList){
                    qt.Calculated_Tax_Amount__c =  Decimal.valueOf(srcMap.get('totalTax'));
                    ordersToUpdate.add(qt);   
                } 
                
                List<OrderItem> orderItemList =  [SELECT id,blng__TaxCountry__c,blng__TaxState__c,TotalPrice,SBQQ__TaxAmount__c,
                                                    Calculated_Tax_Amount__c,Tax_Rate__c,OrderId,Exempt_Amount__c,OrderItemNumber, 
                                                    Idt_Hst_Gst_S__c,Idt_Qst_S__c,Idt_Pst_S__c,Idt_CGST_S__c,Idt_IGST_S__c,Idt_SGST_S__c 
                                                  FROM orderItem 
                                                  WHERE orderid =:recId];  
                
                for(OrderItem line :orderItemList){
                    String lineItemNum = String.valueof(line.OrderItemNumber).replaceFirst( '^0+', '');
                    line.Calculated_Tax_Amount__c = Decimal.valueOf(srcMap.get('totalTax'+lineItemNum));
                    line.Tax_Rate__c = Decimal.valueOf(srcMap.get(lineItemNum));
                    if(srcMap.get('exemptAmount'+lineItemNum) != null){
                        line.Exempt_Amount__c = Decimal.valueOf(srcMap.get('exemptAmount'+lineItemNum));
                    }
                    if( srcMap.get('HST'+lineItemNum) != null){
                        line.Idt_Hst_Gst_S__c = Decimal.valueOf(srcMap.get('HST'+lineItemNum));
                    }
                    if(srcMap.get('QST'+lineItemNum) != null){
                        line.Idt_Qst_S__c = Decimal.valueOf(srcMap.get('QST'+lineItemNum));
                    }
                    if(srcMap.get('PST'+lineItemNum) != null){
                        line.Idt_Pst_S__c = Decimal.valueOf(srcMap.get('PST'+lineItemNum));
                    }
					if(srcMap.get('CGST'+lineItemNum) != null){
					line.Idt_CGST_S__c = Decimal.valueOf(srcMap.get('CGST'+lineItemNum));
					}
					if(srcMap.get('IGST'+lineItemNum) != null){
						line.Idt_IGST_S__c = Decimal.valueOf(srcMap.get('IGST'+lineItemNum));
					}
					if(srcMap.get('SGST'+lineItemNum) != null){
						line.Idt_SGST_S__c = Decimal.valueOf(srcMap.get('SGST'+lineItemNum));
					}
                    ordersToUpdate.add(line);
                }                                  
                
                if(ordersToUpdate.size()>0) {        
                	update ordersToUpdate;
                }

            }catch(exception e){
                ApexDebugLog.logException(e, 'recordid==>'+recId, 'OIDT_GenerateTax','updateOrder');
            }
            
        }
    }
    public static void updateInvoice(Map<String,String> srcMap,String recId){
        
        List<blng__Invoice__c> invList = new List<blng__Invoice__c>();
        List<blng__InvoiceLine__c> lines = new List<blng__InvoiceLine__c>();
        List<Sobject> recordsToUpdate = new List<Sobject>();
        try{
            blng__Invoice__c taxList = [SELECT id,Calculated_Tax_Amount__c,blng__InvoiceStatus__c ,Audit_Sent__c FROM blng__Invoice__c WHERE id =:recId];
            if(srcMap.get('totalTax') != null){
               taxList.Calculated_Tax_Amount__c =  Decimal.valueOf(srcMap.get('totalTax')); 
            }
           
            recordsToUpdate.add(taxList);
            List<blng__InvoiceLine__c> linelist= [SELECT id,Is_Tax_Documented__c ,Tax_Rate__c,Invoice_Line_Number__c,Calculated_Tax_Amount__c,
                                                    Idt_Hst_Gst_S__c,Idt_Qst_S__c,Idt_Pst_S__c,Exempt_Amount__c,Idt_CGST_S__c,Idt_IGST_S__c,Idt_SGST_S__c,
                                                    (SELECT Id, Authority_UUID__c FROM Tax_Item_Services__r )
                                                  FROM blng__InvoiceLine__c 
                                                  WHERE blng__Invoice__c =:recId];
            List<Tax_Line_Item_Service__c>allTaxItems = new List<Tax_Line_Item_Service__c>();
            for(blng__InvoiceLine__c line:lineList){
                if(line.Tax_Item_Services__r != null && line.Tax_Item_Services__r.size() > 0) {
                    allTaxItems.addAll(line.Tax_Item_Services__r);
                }
            }
            
            if(!allTaxItems.isEmpty()) {
                delete allTaxItems;
            }
            
            List<Tax_Line_Item_Service__c>taxesToUpdate = new List<Tax_Line_Item_Service__c>();
            for(blng__InvoiceLine__c line:lineList){
                
                String lineItemNum = String.valueof(line.Invoice_Line_Number__c);
                if(srcMap.containsKey('TAX'+lineItemNum) && 'Posted'.equalsIgnoreCase(taxList.blng__InvoiceStatus__c) ) {
                    List<Tax_Line_Item_Service__c>  taxes = (List<Tax_Line_Item_Service__c> )JSON.deserialize(srcMap.get('TAX'+lineItemNum), List<Tax_Line_Item_Service__c> .class);
                    for(Tax_Line_Item_Service__c tax : taxes) {
                       tax.Invoice_Line_Item_Id__c  = line.id;
                        tax.Name = 'Tax '+ lineItemNum;
                        taxesToUpdate.add(tax);
                    }
                     
                }
                if(srcMap.containsKey(lineItemNum) && srcMap.get(lineItemNum)!=null) {
                   line.tax_rate__c = Decimal.valueof(srcMap.get(lineItemNum)); 
                }
                String taxKey = 'totalTax'+lineItemNum;
                    
                if(srcMap.containsKey(taxKey) ) {
                   line.Calculated_Tax_Amount__c = Decimal.valueof(srcMap.get(taxKey)); 
                }
                if(srcMap.get('exemptAmount'+lineItemNum) != null){
                    line.Exempt_Amount__c = Decimal.valueOf(srcMap.get('exemptAmount'+lineItemNum));
                }
                if( srcMap.get('HST'+lineItemNum) != null){
                    line.Idt_Hst_Gst_S__c = Decimal.valueOf(srcMap.get('HST'+lineItemNum));
                }
                if(srcMap.get('QST'+lineItemNum) != null){
                    line.Idt_Qst_S__c = Decimal.valueOf(srcMap.get('QST'+lineItemNum));
                }
                if(srcMap.get('PST'+lineItemNum) != null){
                    line.Idt_Pst_S__c = Decimal.valueOf(srcMap.get('PST'+lineItemNum));
                }
				if(srcMap.get('CGST'+lineItemNum) != null){
					line.Idt_CGST_S__c = Decimal.valueOf(srcMap.get('CGST'+lineItemNum));
				}
				if(srcMap.get('IGST'+lineItemNum) != null){
					line.Idt_IGST_S__c = Decimal.valueOf(srcMap.get('IGST'+lineItemNum));
				}
				if(srcMap.get('SGST'+lineItemNum) != null){
					line.Idt_SGST_S__c = Decimal.valueOf(srcMap.get('SGST'+lineItemNum));
				}
                line.Is_Tax_Documented__c = true;
                recordsToUpdate.add(line);
            }
             taxList.Audit_Sent__c= True;
            if(taxesToUpdate.size() > 0){
                recordsToUpdate.addAll(taxesToUpdate);
            }
            if(recordsToUpdate.size()>0){
                upsert  recordsToUpdate;
            } 
            
        }catch(exception e){
            ApexDebugLog.logException(e, 'recordid==>'+lines, 'OIDT_GenerateTax','updateInvoice');
        }
        
    }
    
    public static void updateCreditNote(Map<String,String> srcMap,String recId){
        List<blng__CreditNote__c> creditList = new List<blng__CreditNote__c>();
        List<Sobject> lines = new List<Sobject>();
        try{
            blng__CreditNote__c credit = [SELECT id,blng__Status__c ,Calculated_Tax_Amount__c FROM blng__CreditNote__c WHERE id =:recId];
            if(srcMap.get('totalTax') != null) {
                credit.Calculated_Tax_Amount__c =  Decimal.valueOf(srcMap.get('totalTax'));
            }
            update credit;
            List<blng__CreditNoteLine__c> lineList= [SELECT id,name,Tax_Rate__c, Is_Tax_Documented__c,Calculated_Tax_Amount__c ,
                                                     Idt_Hst_Gst_S__c,Idt_Qst_S__c,Idt_Pst_S__c,Exempt_Amount__c,Idt_CGST_S__c,Idt_IGST_S__c,Idt_SGST_S__c,
                                                     (SELECT Id,Authority_UUID__c FROM Tax_Item_Services__r )
													FROM blng__CreditNoteLine__c 
                                                    WHERE blng__CreditNote__c =:recId];
            List<Tax_Line_Item_Service__c>allTaxItems = new List<Tax_Line_Item_Service__c>();
            for(blng__CreditNoteLine__c line:lineList){
                if(line.Tax_Item_Services__r != null && line.Tax_Item_Services__r.size() > 0) {
                    allTaxItems.addAll(line.Tax_Item_Services__r);
                }
            }
            if(!allTaxItems.isEmpty()) {
               delete allTaxItems;
            }
            for(blng__CreditNoteLine__c line :lineList){
                String lineItemNum = String.valueof(line.name).replaceFirst( '^0+', '');
                if(srcMap.get(lineItemNum)!=null) {
                    line.Tax_Rate__c = Decimal.valueof(srcMap.get(lineItemNum))*100;
                }
                String taxKey = 'totalTax'+lineItemNum;
                if(srcMap.containsKey(taxKey) ) {
                   line.Calculated_Tax_Amount__c = Decimal.valueof(srcMap.get(taxKey)); 
                }
                 
                line.Is_Tax_Documented__c = true;
                if(srcMap.containsKey('TAX'+lineItemNum) && 'Posted'.equalsIgnoreCase(credit.blng__Status__c) ) {
                    List<Tax_Line_Item_Service__c>  taxes = (List<Tax_Line_Item_Service__c> )JSON.deserialize(srcMap.get('TAX'+lineItemNum), List<Tax_Line_Item_Service__c> .class);
                    for(Tax_Line_Item_Service__c tax : taxes) {
                        tax.Credit_Note_Line_Item_Id__c  = line.id;
                        tax.Name = 'Tax '+ lineItemNum;
                        lines.add(tax);
                    }
                }
                if(srcMap.get('exemptAmount'+lineItemNum) != null){
                    line.Exempt_Amount__c = Decimal.valueOf(srcMap.get('exemptAmount'+lineItemNum));
                }
                if( srcMap.get('HST'+lineItemNum) != null){
                    line.Idt_Hst_Gst_S__c = Decimal.valueOf(srcMap.get('HST'+lineItemNum));
                }
                if(srcMap.get('QST'+lineItemNum) != null){
                    line.Idt_Qst_S__c = Decimal.valueOf(srcMap.get('QST'+lineItemNum));
                }
                if(srcMap.get('PST'+lineItemNum) != null){
                    line.Idt_Pst_S__c = Decimal.valueOf(srcMap.get('PST'+lineItemNum));
                }
				if(srcMap.get('CGST'+lineItemNum) != null){
					line.Idt_CGST_S__c = Decimal.valueOf(srcMap.get('CGST'+lineItemNum));
				}
				if(srcMap.get('IGST'+lineItemNum) != null){
					line.Idt_IGST_S__c = Decimal.valueOf(srcMap.get('IGST'+lineItemNum));
				}
				if(srcMap.get('SGST'+lineItemNum) != null){
					line.Idt_SGST_S__c = Decimal.valueOf(srcMap.get('SGST'+lineItemNum));
				}
                lines.add(line);
            }
            if(!lines.isEmpty()){
                upsert lines;
            }
        }catch(exception e){
            ApexDebugLog.logException(e, 'recordid==>'+lines, 'OIDT_GenerateTax','updateCreditNote');
        }
        
    }

    private static blng__Invoice__c  getInvoiceDetails(Id recordId){
        return [SELECT  id,Name,CurrencyIsoCode,Building_Id__r.Legal_Entity_id__r.External_Id__c ,blng__Account__r.name,blng__Account__r.BillingCountry,
                blng__Account__r.BillingCity,blng__Account__r.Member_Short_Code__c,blng__Account__r.BillingState,blng__Account__r.BillingPostalCode,Building_Id__r.Name,blng__Account__r.ShippingCountry,blng__Account__r.ShippingCity,
                blng__Account__r.shippingState,blng__Account__r.shippingPostalCode,Building_Id__r.Legal_Entity_Id__r.blng__State__c,Building_Id__r.Legal_Entity_Id__r.blng__City__c,Building_Id__r.Legal_Entity_Id__r.blng__ZipPostalCode__c,
                Building_Id__r.Legal_Entity_Id__r.blng__Country__c,Audit_Sent__c,blng__InvoiceStatus__c,Building_Id__r.VAT_Id__c 
                FROM blng__Invoice__c 
                WHERE id =:recordId];
    }
    
    private static List<blng__InvoiceLine__c> getInvoiceLineDetails(Id recordId){
        return [SELECT Id,Invoice_Line_Number__c,blng__OrderProduct__r.OrderItemNumber,blng__OrderProduct__r.Quantity,blng__OrderProduct__r.TotalPrice,blng__OrderProduct__r.Product2.ProductCode 
                FROM blng__InvoiceLine__c  
                WHERE blng__Invoice__c =:recordid ];
    }
        
    private static SBQQ__Quote__c getQuoteDetails(Id recordid){
        return [SELECT id,Name,CurrencyIsoCode,SBQQ__BillingCity__c,SBQQ__BillingCountry__c,SBQQ__BillingName__c,Billing_Account__c,
                SBQQ__BillingPostalCode__c,Billing_Account__r.Member_Short_Code__c,SBQQ__Status__c,Billing_Account__r.name,SBQQ__BillingState__c,SBQQ__Account__r.name,SBQQ__Account__r.BillingCity,
                SBQQ__Account__r.BillingCountry,SBQQ__Account__r.BillingPostalCode,SBQQ__Account__r.BillingState,
                SBQQ__Account__r.shippingCity,SBQQ__Type__c,Building_Id__r.VAT_Id__c,SBQQ__Account__r.Member_Short_Code__c,Building_Id__r.Name,
                SBQQ__Account__r.shippingCountry,SBQQ__Account__r.shippingPostalCode,SBQQ__Account__r.shippingState,Building_Id__r.Legal_Entity_Id__r.blng__ZipPostalCode__c, Building_Id__r.Legal_Entity_Id__r.blng__City__c,
                Building_Id__r.Legal_Entity_Id__r.blng__State__c,Building_Id__r.Legal_Entity_id__r.External_Id__c ,Building_Id__r.Legal_Entity_Id__r.blng__Country__c  
                FROM SBQQ__Quote__c 
                WHERE id =:recordid ];
    }
    
    private static List<SBQQ__QuoteLine__c> getQuoteLineDetails(Id recordid){
        return [SELECT id,name,SBQQ__NetTotal__c,SBQQ__Quantity__c,Capital_Improvements_Projects__c,SBQQ__Product__r.ProductCode  
                FROM SBQQ__QuoteLine__c 
                WHERE SBQQ__Quote__c =:recordid ];
    }
    
    private static order getOrderDetails(Id recordId){
        return [SELECT id,OrderNumber,account.Member_Short_Code__c,CurrencyIsoCode,Account.name,account.BillingCountry,account.BillingCity,account.BillingState,account.BillingPostalCode,Building_Id__r.Name,Account.ShippingCity,Account.shippingState,
                Account.shippingPostalCode,Account.ShippingCountry,Building_Id__r.Legal_Entity_id__r.External_Id__c, Building_Id__r.Legal_Entity_Id__r.blng__State__c, Building_Id__r.Legal_Entity_Id__r.blng__City__c, Building_Id__r.Legal_Entity_Id__r.blng__ZipPostalCode__c,
                Building_Id__r.Legal_Entity_Id__r.blng__Country__c,Building_Id__r.VAT_Id__c 
                FROM order 
                WHERE id =:recordid];
    }
    
    private static List<OrderItem > getOrderLineDetails(Id recordId){
        return [SELECT id,OrderItemNumber,Quantity,TotalPrice,Product2.ProductCode FROM OrderItem WHERE OrderId =:recordid ];
    }
    
    
    private static blng__CreditNote__c   getCreditDetails(Id recordid){
        return [SELECT  id,Name,CurrencyIsoCode,Building_Id__r.Legal_Entity_id__r.External_Id__c,blng__Account__r.name,blng__Account__r.BillingCountry, blng__Account__r.BillingCity,blng__Account__r.BillingState,
                blng__Account__r.BillingPostalCode,Building_Id__r.Name, blng__Account__r.Member_Short_Code__c,blng__Account__r.ShippingCountry, blng__Account__r.ShippingCity,  blng__Account__r.shippingState,  blng__Account__r.shippingPostalCode, 
                Building_Id__r.Legal_Entity_Id__r.blng__State__c, Building_Id__r.Legal_Entity_Id__r.blng__City__c,  Building_Id__r.Legal_Entity_Id__r.blng__ZipPostalCode__c, Building_Id__r.Legal_Entity_Id__r.blng__Country__c,
                Building_Id__r.VAT_Id__c 
                FROM blng__CreditNote__c  
                WHERE id =:recordid];
    }
    
    private static List<blng__CreditNoteLine__c> getCreditLineDetails(Id recordid){
        return [SELECT id,Name,blng__Product__r.ProductCode,blng__Subtotal__c FROM blng__CreditNoteLine__c  WHERE blng__CreditNote__c =:recordid ];
    }
}