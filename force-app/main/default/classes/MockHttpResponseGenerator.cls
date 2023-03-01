/******************************************************************************************************************** 
Name              : MockHttpResponseGenerator.cls 
Description       : Mock Http class for tests.

Revision History  :-
Created/Modified by         Created/Modified Date       Requested by         Technical Design Proposal
---------------------------------------------------------------------------------------------------------------------
1. Rashad Saeed (Creator)      31 DEC 2018              WeWork                 SF - Rollbar Integration  Google Doc 
2. Danielle Morse			   25 Aug 2019				WeWork				 Refactored to allow passing body & status code 
---------------------------------------------------------------------------------------------------------------------
*********************************************************************************************************************/
@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {
    private Integer statusCode;
    private String body;

    global MockHttpResponseGenerator(Integer intStatusCode, String strBody){
        this.statusCode = intStatusCode;
        this.body = strBody;
    }

    global MockHttpResponseGenerator(){
        this(200, '{"example":"test"}');
    }

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(statusCode);
        res.setBody(body);
        return res;
    }
}