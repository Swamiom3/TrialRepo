@isTest
public class OppContractAgreementPopulationTrHTest {
    @testSetup
    static void setup(){
        Building__c building = new Building__c();
        building.Name ='testbuild-001';
        building.Building_ID__c ='test';
        building.UUID__c ='test';
        insert building;  
        
        Account account = TestingUtility.createAccount('Acme OppClosedWonContractAgreementPopulationTrHTest', true);
        Opportunity opp = TestingUtility.createOpportunity(account.Id, true);

        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.Building_Id__c = building.Id;
        quote.SBQQ__Opportunity2__c = opp.Id;
        quote.Subscription_Type__c = 'Commitment Term';
        quote.SBQQ__Primary__c = true;
        quote.SBQQ__Ordered__c = true;
        insert quote;

        APXT_Redlining__Contract_Agreement__c agreement = new APXT_Redlining__Contract_Agreement__c(Quote_Id__c = quote.Id, APXT_Redlining__Status__c = 'Active');
        insert agreement;
        
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        insert cv;
        
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        ContentDocumentLink link = new ContentDocumentLink(
        LinkedEntityId = agreement.Id, ContentDocumentId = cv.ContentDocumentId, ShareType = 'V');
        insert link;
        
        ContentVersion cv2 = new ContentVersion();
        cv2.ContentDocumentId = link.ContentDocumentId;
        cv2.Title = 'Test Document 2';
        cv2.PathOnClient = 'TestDocument.pdf';
        cv2.VersionData = Blob.valueOf('Test Content');
        cv2.IsMajorVersion = true;
        cv2.ReasonForChange = 'Final Signed';
        insert cv2;
    }

    @isTest
    private static void closeWonOpportunityTest(){
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.StageName = GlobalConstants.OPP_CLOSED_WON_STAGE_NAME;
        Test.startTest();
            update opp;
        Test.stopTest();
        Opportunity result = [SELECT Id, Signed_Contract_URL__c, Contract_UUID__c FROM Opportunity WHERE Id = :opp.Id];
        APXT_Redlining__Contract_Agreement__c agreement = [SELECT Id FROM APXT_Redlining__Contract_Agreement__c LIMIT 1];
        System.assert(!String.isBlank(result.Signed_Contract_URL__c), 'Contract URL should not be blank');
        System.assert(agreement.Id == result.Contract_UUID__c, 'Contract UUID should be set to APXT_Redlining__Contract_Agreement__c ID');
    }

}