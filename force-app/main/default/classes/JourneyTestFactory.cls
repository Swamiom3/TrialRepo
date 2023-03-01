/************************************************************************************************************************************
    Author      :   Shubham Nandwana 
    Description :   This class contain all methods related to journey test methods
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     ISSUE NUMBER    DATE                AUTHOR                  DETAIL
    1           TWSPG-408       9 July 2019      	Shubham Nandwana        Initial Developement
**************************************************************************************************************************************/
@isTest
public class JourneyTestFactory {
    
    static final String LEAD_SOURCE_DETAIL = 'Website';
    static final Decimal INTERESTED_DESKS = 100;
    
    public static void createUpdateJourneysOwner(){
        Profile weworkSystemAdmin = [SELECT Id FROM Profile WHERE Name='Wework System Administrator'];
        Map<String,Object> apiUserRecordMap = new Map<String,Object>();
        apiUserRecordMap.put('LastName','API User');
        apiUserRecordMap.put('Username','testapiuser89833@wework.com.example');
        apiUserRecordMap.put('Email','testapiuser8956@wework.com.example');
        User apiUser = TestingUtility.insertUserWithAssert(weworkSystemAdmin.Id, apiUserRecordMap, true);
    }
    
    public static Journey__c buildJourneyRecord(Id parentId, String strStatus){
        Journey__c objJourney = new Journey__c();
        objJourney.Name = 'testJourney';
        objJourney.CurrencyIsoCode = 'USD';
        if(parentId.getSObjectType() == Contact.getSObjectType()){
            objJourney.Primary_Contact__c = parentId;
        }else{
            objJourney.Primary_Lead__c = parentId;
        }        
        objJourney.NMD_Next_Contact_Date__c = Date.today();
        objJourney.Status__c = strStatus;
        objJourney.Lead_Source_Detail__c = LEAD_SOURCE_DETAIL;
        objJourney.Interested_in_Number_of_Desks__c = INTERESTED_DESKS;
        return objJourney;
    }   
}