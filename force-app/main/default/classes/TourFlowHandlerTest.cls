@isTest
public class TourFlowHandlerTest { 
    @isTest
    public static void returnObjectName_test_positive(){
        Lead testLead = new Lead(Status = 'Open', Email='testlead123@test.com', Phone='1234567890', Salutation = 'Mr.', FirstName = 'Test', LastName = 'Lead123', Company = 'Test Company');        
        insert testLead;
        List<String> objectNames = TourFlowHandler.returnObjectName(new List<String> {testLead.Id});
        System.assertEquals('Lead', objectNames[0], 'The objectName should be matched');
    }
    @isTest
    public static void returnObjectName_test_negative(){
        List<String> objectNames = TourFlowHandler.returnObjectName(new List<String>());
        System.assertEquals(null, TourFlowHandler.returnObjectName(new List<String>()), 'Method should return null');
    }
}