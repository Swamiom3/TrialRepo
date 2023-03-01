public with sharing class CPQAmendSingleContract { 
    @InvocableMethod(label='Call CPQ Amend API for Single Contract' description='Amendment API from Flow')
    public static List<AmendResponse> amendServiceContracts(List<AmendRequest> serviceContractRequestIds){
        List<AmendResponse> amendResponses = new List<AmendResponse>();   
        AmendResponse amendResponse = new AmendResponse(); 
        if(serviceContractRequestIds == null){
            return amendResponses;
        }

        String originalServiceContract = serviceContractRequestIds.get(0).quoteId;
        CPQ_ApiDataModels.ContractAmender amender = new CPQ_ApiDataModels.ContractAmender();
        CPQ_ApiDataModels.QuoteModel quoteModel = amender.load(originalServiceContract);
        
        if(quoteModel.record == null){
            amendResponse.errorMessages = 'Service Contract did not Amend ' + originalServiceContract;
        }else{
            amendResponse.cpqQuote = quoteModel.record;
        }

        amendResponses.add(amendResponse);
        return amendResponses;
    }
    public class AmendResponse {
        @InvocableVariable 
        public SBQQ__Quote__c cpqQuote;
        @InvocableVariable 
        public String errorMessages;
    }

    public class AmendRequest {
        @InvocableVariable
        public String quoteId;
    }

}