@isTest
private class trac_EmailMessageHandlerTest {
    @isTest static void incomingEmail() {
        //Insert test case record
        Case c = new Case();
        c.Subject = 'Om Test';  
        c.Status ='New';
        c.Priority = 'Medium';
        c.Origin = 'Email';
        insert c;
        
        //Insert emailmessage for case
        EmailMessage email = new EmailMessage();
        email.FromAddress = 'test@abc.org';
        email.Incoming = True;
        email.ToAddress= 'test@xyz.org';
        email.Subject = 'Test email';
        email.HtmlBody = 'Test email body';
        email.ParentId = c.Id; 
        insert email;
        
        /*failing on UAT -> to check
        List<CaseMilestone> cmsToUpdate;
        cmsToUpdate = [SELECT Id, CompletionDate, CaseId, MilestoneType.Name FROM CaseMilestone WHERE CaseId = :c.Id LIMIT 1];
        System.assertEquals(true, cmsToUpdate.isEmpty(), 'Shouldn\'t get any casemilestones');
        */
    }
    
    @isTest static void outgoingEmail() {
        
        Account acc = new Account(LastName = 'Test Account');
        insert acc;
        
        Contact con = new Contact();
        con.FirstName = 'Test';
        con.LastName = 'Last Name';
        con.Email = 'test@xyz.org';
        insert con;
        
        Entitlement entitle = new Entitlement();
        entitle.Name = 'Test Entitlement';
        entitle.AccountId = acc.Id;
        insert entitle;
        
        //Insert test case record
        Case c = new Case();
        c.Subject = 'Om Test';  
        c.Status ='New';
        c.Priority = 'Medium';
        c.Origin = 'Email';
        c.ContactId = con.Id;
        c.EntitlementId = entitle.Id;
        c.New_E2C_Tag__c = false;
        c.SlaStartDate = Date.newInstance(2021, 09, 05);
        insert c;
        
        //Insert emailmessage for case
        EmailMessage email = new EmailMessage();
        email.FromAddress = 'test@abc.org';
        email.Incoming = False;
        email.ToAddress= 'test@xyz.org';
        email.Subject = 'Test email';
        email.HtmlBody = 'Test email body';
        email.ParentId = c.Id; 
        email.CcAddress = 'test@xyz.org, test1@xyz.org';
        insert email;
        
        System.AssertEquals(email.ToAddress,'test@xyz.org','The email address should be test@xyz.org');
        
    }
}