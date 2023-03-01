@isTest
private class ContentVersionUpdateQuotePublicUrlTest {
@testSetup
    static void testSetup() {
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        insert quote;
        
        APXT_Redlining__Contract_Agreement__c fw = new APXT_Redlining__Contract_Agreement__c(Quote_Id__c = quote.Id,  APXT_Redlining__Status__c = 'Active');
        insert fw;
        
        List<ContentVersion> cvs = new List<ContentVersion>();
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        cvs.add(cv);
        
        cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        cvs.add(cv);
        insert cvs;
        
        cvs = [Select Id, ContentDocumentId From ContentVersion Where Id IN :cvs];
        
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        ContentDocumentLink link = new ContentDocumentLink(
            LinkedEntityId = fw.Id, ContentDocumentId = cvs[0].ContentDocumentId, ShareType = 'V');
        links.add(link);
        link = new ContentDocumentLink(
            LinkedEntityId = quote.Id, ContentDocumentId = cvs[1].ContentDocumentId, ShareType = 'V');
        links.add(link);
        insert links;
    }
    
    @isTest
    static void testPublicURLUpdate() {
        APXT_Redlining__Contract_Agreement__c fw = [
            SELECT Id, Quote_Id__c 
            FROM APXT_Redlining__Contract_Agreement__c LIMIT 1];
        ContentDocumentLink link = [
            SELECT Id, ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId =: fw.Id];
        
        ContentVersion cv = new ContentVersion();
        cv.ContentDocumentId = link.ContentDocumentId;
        cv.Title = 'Test Document 2';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        cv.ReasonForChange = 'Final Signed';
        
        Test.startTest();
        insert cv;
        Test.stopTest();
        
        SBQQ__Quote__c quote = [
            SELECT Id, Contract_Public_URL__c 
            FROM SBQQ__Quote__c 
            WHERE Id =: fw.Quote_Id__c];
        System.assert(quote.Contract_Public_URL__c != null, 'Failed to update Contract Public URL on Quote');
    }
    
    @isTest
    static void testNegativeFlow() {
        SBQQ__Quote__c quote = [
            SELECT Id 
            FROM SBQQ__Quote__c LIMIT 1];
        ContentDocumentLink link = [
            SELECT Id, ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId =: quote.Id];
        
        ContentVersion cv = new ContentVersion();
        cv.ContentDocumentId = link.ContentDocumentId;
        cv.Title = 'Test Document 2';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        cv.ReasonForChange = 'Final Signed';
        
        Test.startTest();
        insert cv;
        Test.stopTest();
        
        quote = [
            SELECT Id, Contract_Public_URL__c 
            FROM SBQQ__Quote__c 
            WHERE Id =: quote.Id];
        System.assert(quote.Contract_Public_URL__c == null, 'Contract Public URL should not be updated on Quote');
    }
}