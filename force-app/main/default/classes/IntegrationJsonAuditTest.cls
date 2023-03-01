/*************************************************************************************************************************************
    Author      :   Tayo Chestnut
    Description :   This class provides sufficient test coverage for Json Audit classes
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             DETAIL
    1          29 Dec, 2021    Tayo Chestnut   Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class IntegrationJsonAuditTest {
   
    @isTest
    static void jsonAuditPositive(){
        ChargebackWrapper chargebackWrap = new ChargebackWrapper();
        chargebackWrap.amount = 100;
        chargebackWrap.currencyCode = 'CAD';
        IntegrationJsonAudit.Request dataRequest = new IntegrationJsonAudit.Request();        
        dataRequest.category = 'Chargebacks';
        dataRequest.inboundAPItoProcess = chargebackWrap;

        List<IntegrationJsonAudit.Request> requests = new List<IntegrationJsonAudit.Request>();
        requests.add(dataRequest);
        List<IntegrationJsonAudit.ReturnOutput> results =  IntegrationJsonAudit.quickJsonAudit(requests);
        IntegrationJsonAudit.ReturnOutput finalresult = results.get(0);        
        System.assertEquals('{"reversalDateTime":null,"reason":null,"originalUUID":null,"originalMerchantTransactionId":null,"currencyCode":"CAD","chargebackUUID":null,"chargebackDateTime":null,"amount":100}', finalresult.inboundAPIProcessed,'JSON Failed');
    }

    @isTest
    static void jsonAuditPositivePaymentMethod(){
        PaymentMethods paymentWrapper = new PaymentMethods();
        paymentWrapper.paymentMethod = 'ABC';
        paymentWrapper.uuid = 'DEF';
        IntegrationJsonAudit.Request dataRequest = new IntegrationJsonAudit.Request();        
        dataRequest.category = 'Payment Methods';
        dataRequest.inboundcurrentPayMethod = paymentWrapper;

        List<IntegrationJsonAudit.Request> requests = new List<IntegrationJsonAudit.Request>();
        requests.add(dataRequest);
        List<IntegrationJsonAudit.ReturnOutput> results =  IntegrationJsonAudit.quickJsonAudit(requests);
        IntegrationJsonAudit.ReturnOutput finalresult = results.get(0);        
        System.assertEquals('{"uuid":"DEF","typename":null,"refundMethod":null,"paymentType":null,"paymentMethod":"ABC","gatewayName":null,"displayData":null,"chargingProfileUuid":null,"beneficiaryStateProvince":null,"beneficiaryPostalCode":null,"beneficiaryCountry":null,"beneficiaryCity":null,"beneficiaryAddressLine2":null,"beneficiaryAddressLine1":null}', finalresult.currentPaymentMethod,'JSON Failed');
    }

    @isTest
    static void jsonAuditPositiveOverages(){
        OverageParameters overageParams = new OverageParameters();
        overageParams.locationUUID = 'Location';
        overageParams.accountUUID = 'Account';
        IntegrationJsonAudit.Request dataRequest = new IntegrationJsonAudit.Request();        
        dataRequest.category = 'Overages';
        dataRequest.inboundOverageParam = overageParams;

        List<IntegrationJsonAudit.Request> requests = new List<IntegrationJsonAudit.Request>();
        requests.add(dataRequest);
        List<IntegrationJsonAudit.ReturnOutput> results =  IntegrationJsonAudit.quickJsonAudit(requests);
        IntegrationJsonAudit.ReturnOutput finalresult = results.get(0);   
        System.assertEquals('{"locationUUID":"Location","accountUUID":"Account"}', finalresult.overageParams,'JSON Failed');
    }

    @isTest
    static void jsonAuditNegative(){
        ChargebackWrapper chargebackWrap = new ChargebackWrapper();
        chargebackWrap.amount = 100;
        chargebackWrap.currencyCode = 'CAD';
        IntegrationJsonAudit.Request dataRequest = new IntegrationJsonAudit.Request();        
        dataRequest.category = 'InvalidCategory';
        dataRequest.inboundAPItoProcess = chargebackWrap;

        List<IntegrationJsonAudit.Request> requests = new List<IntegrationJsonAudit.Request>();
        requests.add(dataRequest);
        List<IntegrationJsonAudit.ReturnOutput> results =  IntegrationJsonAudit.quickJsonAudit(requests);
        IntegrationJsonAudit.ReturnOutput finalresult = results.get(0);
        System.assertEquals('Invalid Category', finalresult.inboundAPIProcessed,'JSON Succeeded');
    }

}