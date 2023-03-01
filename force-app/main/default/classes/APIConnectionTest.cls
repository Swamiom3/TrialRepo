/************************************************************************************************************************************
    Author      :   Tal Sabati
    Description :   This class contain all test methods related to APIConnection class.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           25 June 2019       Tal Sabati       Initial Developement
**************************************************************************************************************************************/
@isTest
public class APIConnectionTest {
    
    /************************************************************************************************************************************
    Author              : Tal sabati
    Description         : This method tests the APIConnection.
    Created Date        : 25 June 2019
    Issue No            : CSI-2109
    **************************************************************************************************************************************/
    static testMethod void testAPIConnection(){
        //Get Integration Data from custom metadata types
        list<Integration_Data__mdt> cmtList = [SELECT DeveloperName FROM Integration_Data__mdt WHERE Is_Active__c = true LIMIT 1] ; 

        //If there are no cmt records
        if(cmtList.isEmpty()){
            return;
        }

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        string endPOint = APIConnection.getEndPointWithEnv(cmtList[0].DeveloperName);
        APIConnection req = new APIConnection(cmtList[0].DeveloperName);
        req.setEndPointParams(new list <String>{'testParam'});
        req.setHeader('testHeaderParam', 'testValue');
        HttpResponse resp = req.sendRequest('testBody');
        Test.stopTest();
    }
}