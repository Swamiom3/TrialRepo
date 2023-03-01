// FileUploadTest.apxc

@IsTest
public class FileUploadTest {
    
    @IsTest
    public static void FileUploadTestMethod() {
        
        Account acc = new Account(
          BillingStreet = '123 ST',
            BillingState = 'NY',
            BillingCountry = 'US',
            BillingPostalCode = '00000',
            BillingCity = 'City',
            Name = 'Test'
        );
        
        insert acc;
        
        ContentVersion cv = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'test.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        
        insert cv;    
        
        ContentDocument cd = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument LIMIT 1];
        
        //create ContentDocumentLink record 
        ContentDocumentLink cdl = New ContentDocumentLink(
          LinkedEntityId = acc.id,
            ContentDocumentId = cd.Id,
            ShareType = 'V'
        );

        insert cdl;
        
        LightningFileUploadHandler.getFiles(acc.Id);
    }
}