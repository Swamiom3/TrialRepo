/************************************************************************************************************************************
    Author 		: 	Krishana Tupe	
    Description : 	This class verifies the functionality of person endpoint.
    
    History		:
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION		DATE				AUTHOR					DETAIL
    1			19 June 2018		Priyanka Ambre			Initial Developement
    2			23 June 2018		Krishana Tupe			Update test methods for API versioning
  	3			31 July 2018		Krishana Tupe			Update the test method for Implementation of Person endpoint version 4
**************************************************************************************************************************************/
@isTest
public class RESTAPIPersonV2Tests {
    
   /************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method is verifies the person endpoind functionality when contact sfid is present.
        Created Date        :   31 July 2018     
   **************************************************************************************************************************************/     
    @isTest
    public static void verifyPersonEndpointWhenEmailIsBlank(){
        RESTAPIPersonModelsV2.Input objPerson = new RESTAPIPersonModelsV2.Input();  
        objPerson.email='testemail@example.com';
        objPerson.first_name='test';
        objPerson.last_name='lastName';
        objPerson.lead_source='WeWork.com';
        objPerson.lead_source_detail='Book a Tour Form';
        objPerson.phone='1234567891';        
        RESTAPIResult response = new RESTAPIResult();  
        try{
            RESTAPIPersonV2.managePerson(objPerson);
        }catch(Exception Exp){            
            System.assertEquals(Exp.getMessage(),'Email is required.');
        }
    }
    /************************************************************************************************************************************
        Author              :   Chandra Teja
        Description         :   This method verifies the record type of contact and account based on lead source and lead source details on contact.
        Created Date        :   20th August 2019
        Issue No            :   ST-4607
   **************************************************************************************************************************************/
   /**** 
    * Commented as this need to be clarified under what conditions Business accounts are created
   
   @isTest
    public static void verifyPersonEndpointForPartnerReferral(){
        RESTAPIPersonModelsV2.Input objPerson = new RESTAPIPersonModelsV2.Input();  
        objPerson.email='testemail@exs.com';
        objPerson.first_name='test';
        objPerson.last_name='lastName';
        objPerson.lead_source='Partner Referral';
        objPerson.lead_source_detail='Referral Web';
        objPerson.phone='1234567891';          
        RESTAPIPersonModelsV2.Response response = RESTAPIPersonV2.managePerson(objPerson); 
        System.assert(String.isNotBlank(response.contact_sfid)) ;
        List<Contact> lstContacts = [SELECT Id, RecordType.Name, Account.RecordType.Name FROM Contact WHERE Id =: response.contact_sfid];
        System.assertEquals(lstContacts[0].RecordType.Name, 'Business Account');
        System.assertEquals(lstContacts[0].Account.RecordType.Name, 'Business Accounts');
    }

     */
           
   /************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method is verifies the person endpoind functionality when new payload.
        Created Date        :   31 July 2018     
   **************************************************************************************************************************************/  
    @isTest
    public static void verifyPersonEndpointNewPayload(){ 
        RESTAPIPersonModelsV2.Input objPerson = new RESTAPIPersonModelsV2.Input();
        objPerson.company_name='testConpany';
        objPerson.email='testemail31072018@example.com';
        objPerson.first_name='test';
        objPerson.last_name='email31072018';
        objPerson.lead_source='WeWork.com';
        objPerson.lead_source_detail='Book a Tour Form';
        objPerson.phone='1234567891';       
        RESTAPIPersonModelsV2.Response response = new RESTAPIPersonModelsV2.Response();
        response = RESTAPIPersonV2.managePerson(objPerson);             
        checkAssert(response, false);
    }
    public static void checkAssert(RESTAPIPersonModelsV2.Response response, Boolean isBillingAccount){      
        System.assert(response != null);
        System.assert(response.account_sfid != null);
        System.assert(response.contact_sfid != null);
        if(isBillingAccount){
            System.assert(response.billing_account_sfid != null);
        }else{
            System.assert(response.billing_account_sfid == null);
        }
    }
    
   /************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method is verifies the person endpoind functionality when new payload bu contact exist with email.
        Created Date        :   31 July 2018     
   **************************************************************************************************************************************/  
    @isTest
    public static void verifyPersonEndpointContactExistWithEmail(){
        Contact conRecord = new Contact(
            firstname  = 'Test',
            lastname   = 'Email31072018',
            email     = 'testemail31072018@example.com',           
            Status__c  = 'active'
        );
        insert conRecord;        
        RESTAPIPersonModelsV2.Input objPerson = new RESTAPIPersonModelsV2.Input();
        objPerson.company_name='testConpany';
        objPerson.email='testemail31072018@example.com';
        objPerson.first_name='test';
        objPerson.last_name='email31072018';
        objPerson.lead_source='WeWork.com';
        objPerson.lead_source_detail='Book a Tour Form';
        objPerson.phone='1234567891';  
        objPerson.type='Broker';
        RESTAPIPersonModelsV2.Response response = new RESTAPIPersonModelsV2.Response();
        response = RESTAPIPersonV2.managePerson(objPerson);           
        checkAssert(response, false);
    }
    
   /************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method is verifies the person endpoind functionality when new payload bu contact exist with email.
        Created Date        :   31 July 2018     
   **************************************************************************************************************************************/  
    @isTest
    public static void verifyPersonEndpointLeadExistWithEmail(){        
        Lead leadRecord = new Lead(
            firstname  = 'Test',
            lastname   = 'Email31072018',
            email     = 'testemail31072018@example.com',
            company = 'TestCompany'
        );
        insert leadRecord;  
        
        RESTAPIPersonModelsV2.Input objPerson = new RESTAPIPersonModelsV2.Input();
        objPerson.company_name='testConpany';
        objPerson.email='testemail31072018@example.com';
        objPerson.first_name='test';
        objPerson.last_name='email31072018';
        objPerson.lead_source='WeWork.com';
        objPerson.lead_source_detail='Book a Tour Form';
        objPerson.phone='1234567891';  
        objPerson.type='Broker';
        RESTAPIPersonModelsV2.Response response = new RESTAPIPersonModelsV2.Response();
        response = RESTAPIPersonV2.managePerson(objPerson);              
        checkAssert(response, false);     
        Lead leadRec = [Select Id,Name,Isconverted,convertedContactId,convertedAccountId From Lead Where Id =:leadRecord.Id LIMIT 1];
        System.assert(leadRec.IsConverted);
        System.assertEquals(response.account_sfid,leadRec.ConvertedAccountId);
        System.assertEquals(response.contact_sfid,leadRec.convertedContactId);
    }
    
     /************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method is verifies the person endpoind functionality when new payload bu contact exist with email and bill null.
        Created Date        :   31 July 2018     
   **************************************************************************************************************************************/  
    @isTest
    public static void verifyPersonEndpointContactExistWithBillNull(){
        RESTAPIPersonModelsV2.Input objPerson = new RESTAPIPersonModelsV2.Input();
        objPerson.company_name='testConpany';
        objPerson.email='testemail31072018@example.com';
        objPerson.first_name='test';
        objPerson.last_name='email31072018';
        objPerson.lead_source='WeWork.com';
        objPerson.lead_source_detail='Book a Tour Form';
        objPerson.phone='1234567891';  
        objPerson.type='Broker';
        RESTAPIPersonModelsV2.Response response = new RESTAPIPersonModelsV2.Response();
        response = RESTAPIPersonV2.managePerson(objPerson);             
        checkAssert(response, false);         
        Contact con = [Select Id,Name From Contact Where Id=:response.contact_sfid LIMIT 1];
        update con;
        
        RESTAPIPersonModelsV2.Input objPerson1 = new RESTAPIPersonModelsV2.Input();
        objPerson1.company_name='testConpany';
        objPerson1.email='testemail31072018@example.com';
        objPerson1.first_name='test';
        objPerson1.last_name='email31072018';
        objPerson1.lead_source='WeWork.com';
        objPerson1.lead_source_detail='Book a Tour Form';
        objPerson1.phone='1234567891';  
        objPerson1.type='Broker';
        RESTAPIPersonModelsV2.Response response1 = new RESTAPIPersonModelsV2.Response();
        try{
            response1 = RESTAPIPersonV2.managePerson(objPerson);           
        }catch(Exception pExp){           
            System.assert(pExp.getMessage().contains('is Primary Member on another billing accounts : '));
        } 
    }
    
    /************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method is verifies the person endpoind functionality when new payload but contact exist with email and billAccount parent null.
        Created Date        :   31 July 2018     
   **************************************************************************************************************************************/  
    @isTest
    public static void verifyPersonEndpointContactExistWithBillParentNull(){
        RESTAPIPersonModelsV2.Input objPerson = new RESTAPIPersonModelsV2.Input();
        objPerson.company_name='testConpany';
        objPerson.email='testemail31072018@example.com';
        objPerson.first_name='test';
        objPerson.last_name='email31072018';
        objPerson.lead_source='WeWork.com';
        objPerson.lead_source_detail='Book a Tour Form';
        objPerson.phone='1234567891';  
        objPerson.type='Broker';
        objPerson.market = 'test Market';
        RESTAPIPersonModelsV2.Response response = new RESTAPIPersonModelsV2.Response();
        response = RESTAPIPersonV2.managePerson(objPerson);     
        checkAssert(response, false);
        
       
        Contact objContact = new Contact(Id = response.contact_sfid);
        update objContact;
        
        RESTAPIPersonModelsV2.Input objPerson1 = new RESTAPIPersonModelsV2.Input();
        objPerson1.company_name='testConpany';
        objPerson1.email='testemail31072018@example.com';
        objPerson1.first_name='test';
        objPerson1.last_name='email31072018';
        objPerson1.lead_source='WeWork.com';
        objPerson1.lead_source_detail='Book a Tour Form';
        objPerson1.phone='1234567891';  
        objPerson1.type='Broker';
        RESTAPIPersonModelsV2.Response response1 = new RESTAPIPersonModelsV2.Response();        
        response1 = RESTAPIPersonV2.managePerson(objPerson);        
        checkAssert(response1, false);
        RESTAPI.PayloadDetails payload = new RESTAPI.PayloadDetails();       
        payload.Input = objPerson1 ;
        new RESTAPIPersonV2().executePost(payload); 
        payload.Body='{"company_name":"John Smith Company","email":"john.smith@example.com","first_name":"John","last_name":"Smith","phone":"9146185355","type":"Broker"}';
        Object result = new RESTAPIPersonModelsV2().getMockModel(payload);
        System.assert(result != null);
    }
    
	/************************************************************************************************************************************
        Author              :   Rohit Nimase
        Description         :   This method verifies the person endpoint functionality when new payload comes with type broker
        Created Date        :   2 Jan 2019   
		Issue No.           :   ST-3254
   **************************************************************************************************************************************/  
    @isTest
    public static void verifyPersonEndpointWithTypeBroker(){
        Contact conRecord = new Contact(
            firstname  = 'Test',
            lastname   = 'Email31072018',
            email     = 'testemail31072018@example.com',           
            Status__c  = 'active'
        );
        insert conRecord;        
        RESTAPIPersonModelsV2.Input objPerson = new RESTAPIPersonModelsV2.Input();
        objPerson.company_name = 'testConpany';
        objPerson.email = 'testemail31072018@example.com';
        objPerson.first_name = 'test';
        objPerson.last_name = 'email31072018';
        objPerson.lead_source = 'WeWork.com';
        objPerson.lead_source_detail = 'Book a Tour Form';
        objPerson.phone = '1234567891';  
        objPerson.type = 'Broker';
        objPerson.marketing_consent = 'true';
        objPerson.email_opt_out = 'true';
        RESTAPIPersonModelsV2.Response response = new RESTAPIPersonModelsV2.Response();
        response = RESTAPIPersonV2.managePerson(objPerson);           
        checkAssert(response, false);
        List<Account> lstAccount = [SELECT Id, Name, Account_SubType__c FROM Account WHERE Id =: response.account_sfid];
        System.assertEquals(True, lstAccount[0].Account_SubType__c.equalsIgnoreCase('broker'));
        
        RESTAPIPersonModelsV2.Input objPerson1 = new RESTAPIPersonModelsV2.Input();
        objPerson1.company_name = 'testCompany2118';
        objPerson1.email = 'testemail2118@example.com';
        objPerson1.first_name = 'test';
        objPerson1.last_name = 'email2118';
        objPerson1.lead_source = 'WeWork.com';
        objPerson1.lead_source_detail = 'Book a Tour Form';
        objPerson1.phone = '9734567891';  
        objPerson1.type = 'Broker';
        objPerson1.marketing_consent = 'true';
        objPerson1.email_opt_out = 'true';
        RESTAPIPersonModelsV2.Response response1 = new RESTAPIPersonModelsV2.Response();
        response1 = RESTAPIPersonV2.managePerson(objPerson1);
        checkAssert(response1, false);
        lstAccount = [SELECT Id, Name, Account_SubType__c FROM Account WHERE Id =: response1.account_sfid];
        System.assertEquals(True, lstAccount[0].Account_SubType__c.equalsIgnoreCase('broker'));
    }   
}