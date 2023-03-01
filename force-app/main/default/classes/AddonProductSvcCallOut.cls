/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class calls mulesoft getProducts API and gets the addon products per building.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           06 AUG 2021         Salesforce            Initial Developement
**************************************************************************************************************************************/
//Surpressing too many public methods since this class contains all the CPQ API methods.
@SuppressWarnings('PMD.ExcessivePublicCount') 
public with sharing class AddonProductSvcCallOut{
    private static final String CLIENTID = 'client_id';
    private static final String CLIENTSECRET = 'client_secret';
    public static Map<String, ProductServiceOutput> getBuildingAddons(String buildingUUID){
        Map<String, ProductServiceOutput> productSvcOutput = new Map<String, ProductServiceOutput>();
        if(buildingUUID == null){
            return productSvcOutput;
        }
        String accessToken = getOAuthJWTToken();
        if(String.IsBlank(accessToken)){
            return productSvcOutput;
        }
        List<ProductSvcResponseWrapper> responseWrapper = new List<ProductSvcResponseWrapper>();
        Http httpCallout = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndPoint('callout:Mulesoft_ProductAPI/api/v1/addonproduct/products?buildingUuid='+ buildingUUID);
        request.setMethod('GET');
        request.setHeader(CLIENTID, String.valueof('{!$Credential.UserName}'));
        request.setHeader(CLIENTSECRET, String.valueof('{!$Credential.Password}'));
        // NOPMD is added below to suppress the PMD warning for setAuthorization
        request.setHeader('Authorization', 'Bearer ' + accessToken); //NOPMD
        HttpResponse response = httpCallout.send(request);
        if(response.getStatusCode() != 200){
            return productSvcOutput;
        }        
        List<ProductSvcResponseWrapper> productServiceResponseWrapperList = (List<ProductSvcResponseWrapper>)System.JSON.deserialize(response.getBody(),List<ProductSvcResponseWrapper>.class);
        for(ProductSvcResponseWrapper productServiveResponseWrapper : productServiceResponseWrapperList){
            ProductServiceOutput output = new ProductServiceOutput();
            output.productUuid = productServiveResponseWrapper.uuid;
            output.productPrice = productServiveResponseWrapper.Price.price;
            List<Fees> productFees = productServiveResponseWrapper.Fees;
            if(productFees != null){
                for(Integer i=0; i<productFees.size(); i++){
                    if(productFees.get(i).uuid == '9769483d-fb69-4415-a69c-db9dfbd6410c'){
                        output.productSetupFee = productFees.get(i).Price.price;
                    }
                    if(productFees.get(i).uuid == '81646be8-01d3-46c0-86f7-04614a424340'){
                        output.productCoLocationFee = productFees.get(i).Price.price;
                    }                    
                }                
            }
            productSvcOutput.put(productServiveResponseWrapper.uuid, output);
        }
        return productSvcOutput;
    }
    public static String getOAuthJWTToken() {
        TokenWrapper tWrapper = new TokenWrapper();
        Http http = new Http();
        httpRequest request = new httpRequest();
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setHeader('Content-Length', '0');
        request.setEndPoint('callout:Mulesofte_eAPI');
        request.setBody('{"client_id":"{!$Credential.UserName}","client_secret":"{!$Credential.Password}","audience":"wework","grant_type":"client_credentials"}');
        request.setMethod('POST');
        HttpResponse res = new httpResponse();
        res = http.send(request);
        String tokenResBody = res.getBody();
        tokenResBody = tokenResBody.Replace('access_token','accessToken');
        tokenResBody = tokenResBody.Replace('expires_in','expiresIn');
        tokenResBody = tokenResBody.Replace('token_type','tokenType');
        tWrapper = (TokenWrapper)JSON.deserialize(tokenResBody, TokenWrapper.class);
        return tWrapper.accessToken;
    }
    
    public class TokenWrapper{
        public String accessToken {get;set;}
        public Integer expiresIn {get;set;}
        public String tokenType {get;set;}
    }
    
    public class ProductSvcResponseWrapper{
        public String uuid {get;set;}
        public String buildingUuid{get;set;}
        public String name{get;set;}
        public String description{get;set;}
        public Price price {get;set;}
        public List<Fees> fees {get;set;}
    }
    public class Price{
        public String currencyValue;
        public String price;
    }
    public class Fees{
        public String uuid {get;set;}
        public String buildingUuid {get;set;}
        public String name {get;set;}
        public String description {get;set;}
        public Price price {get;set;}
    }    
}