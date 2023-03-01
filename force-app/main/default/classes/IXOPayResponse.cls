/************************************************************************************************************************************
Author      :   Salesforce
Description :   Apex wrapper class for receipt of serialized JSON response from IXOPayment gateway API
----------------------------------------------------------------------------------------------------------------------------------
    VERSION      DATE         AUTHOR              DETAIL
    1            02/09/2022   Salesforce          Initial creation
**************************************************************************************************************************************/
public class IXOPayResponse{
    public Boolean success;
    public String uuid;
    public String purchaseId;
    public String redirectUrl;
    public String paymentMethod;
    public String expiresAt;
    public String returnType;
    public List<errors> errors;
    
    public class Errors{
        public String errorMessage;
        public String errorCode;
    }
}