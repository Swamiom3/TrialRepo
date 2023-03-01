/************************************************************************************************************************************
    Author      :   Ajaysinh Chauhan
    Description :   This class contain a logic of Person Endpoint.....

    History     :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           19 June 2018        Ajaysinh Chauhan        Initial Developement
    2           22 June 2018        Krishana Tupe           Changes and API Versioning
  	3           31 July 2018        Krishana Tupe           Implementation of Person endpoint version 4
**************************************************************************************************************************************/
public class PersonEndpointHelper {
    //this is used in OrganizationHelper
    public static Id personContactId;
    @TestVisible
    private static ContactSelector contactSelector = new ContactSelector();

    /************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method has business logic of person endpoint.
        Created Date        :   31 July 2018
   **************************************************************************************************************************************/
    public static Map<String,String> managePerson(RESTAPIPersonModelsV2.Input body){
        Contact contactRecord = new Contact();
        if(String.isNotBlank(body.email)){
            List<Contact> personContacts = contactSelector.getContactsWithPersonFieldsByEmails(new List<String>{ body.email });
            Contact personContact;
            if(!personContacts.isEmpty()){
                personContact = personContacts[0];
                if(String.isBlank(personContact.AccountId)){
                    if(String.isNotBlank(body.type) && body.type.equalsIgnoreCase('broker')){
                    	personContactId = personContact.Id;
                    }
                    personContact.AccountId = OrganizationHelper.findOrCreateRelatedOrg(personContact);
                    PersonEndpointHelper.updateCICompany(personContact);
                    update personContact;
                }
                //'Billing account' can be verified by standard junction object AccountContactRelations where Roles = Primary Memebr
                if (!personContact.AccountContactRelations.isEmpty()) {
                    if (personContact.AccountContactRelations[0].Account.RecordType.DeveloperName == GlobalConstants.ACCOUNT_BILLING_ACCOUNT_RECORD_TYPE_DEV_NAME) {
                        Account acc = new Account();
                        acc.Id = personContact.AccountContactRelations[0].AccountId;
                        acc.Ultimate_Parent_Org__c = personContact.AccountId;
                        update acc;
                    }
                    contactRecord = fillContactByPerson(body, personContact);
                    contactRecord.Id = personContact.Id;
                    update contactRecord;
                } else {
                    contactRecord.Id = createPersonStructure(body, personContact);
                    contactRecord = fillContactByPerson(body, personContact);
                    update contactRecord;
                }
            } else {
                contactRecord.Id = createPersonStructure(body,null);
            }
        }else{
            throw new RESTAPIPersonV2.PersonEndpointException('Email is required.');
        }
        if (String.isNotBlank(contactRecord.Id)) {
            Contact conRecord = contactSelector.getContactsWithPersonFieldsByIds(new List<Id> { contactRecord.Id })[0];
            return new Map<String, String>{'contact_sfid'=>conRecord.Id,
                                           'account_sfid'=> conRecord.AccountId,
                                           'billing_account_sfid'=> !conRecord.AccountContactRelations.isEmpty()
                                                                        && conRecord.AccountContactRelations[0].Roles == GlobalConstants.ACCOUNT_CONTACT_RELATION_ROLE_PRIMARY_MEMBER 
                                                                        && conRecord.AccountContactRelations[0].Account.RecordType.DeveloperName == GlobalConstants.ACCOUNT_BILLING_ACCOUNT_RECORD_TYPE_DEV_NAME
                                                                    ? conRecord.AccountContactRelations[0].AccountId
                                                                    : null,
                                           'contact_uuid'=> conRecord.UUID__c};
        }
        return null;
    }
    /************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method is used to create new contact for personn endpoint with billing account.
        Created Date        :   31 July 2018
   **************************************************************************************************************************************/
    public static Id createPersonStructure(RESTAPIPersonModelsV2.Input body,Contact objContact){
        Contact contactRecord;
        if(objContact == null){
            contactRecord = getContactByPerson(body);
            insert contactRecord;
            List<Contact> lstPersonContacts = contactSelector.getContactsWithPersonFieldsByIds(new List<Id>{ contactRecord.Id });
            if(String.isNotBlank(body.type) && body.type.equalsIgnoreCase('broker')){
                personContactId = contactRecord.Id;
            }
            contactRecord.AccountId = OrganizationHelper.findOrCreateRelatedOrg(lstPersonContacts[0]);
            contactRecord.CI_Company__c = lstPersonContacts[0].CI_Company__c;
            PersonEndpointHelper.updateCICompany(contactRecord);
        }else{
            contactRecord = fillContactByPerson(body, objContact);
            contactRecord = objContact;
        }
        update contactRecord;
        return contactRecord.Id;
    }

  /************************************************************************************************************************************
    Author         		: Krishana Tupe
    Description    		: This method used to update Account CI_Company__c to Contact CI_Company__c if Account CI_Company__c is not blank.
    Created Date   		: 25 March 2019
    Issue No       		: ST-3672
 *****************************************************************************************************************************************/
    public static Contact updateCICompany(Contact objContact){
        if(String.isNotBlank(objContact.AccountId) && String.isBlank(objContact.CI_Company__c)){
            Account objAccount = [SELECT Id, CI_Company__c FROM Account WHERE Id =: objContact.AccountId];
            if(String.isNotBlank(objAccount.CI_Company__c)){
                objContact.CI_Company__c = objAccount.CI_Company__c;
                objContact.CI_Updated_DateTime__c = System.now();
            }
        }
        return objContact;
    }


   /************************************************************************************************************************************
        Author              :   Ajaysinh Chauhan
        Description         :   This method returns the contact object from person endpoint payload.
        Created Date        :   19 June 2018
   **************************************************************************************************************************************/
    public static Contact getContactByPerson(RESTAPIPersonModelsV2.Input body){       
        Map<String, Object> mapSetting = Settings.getMetadataSettingByDevNameAsMap('PartnerReferralLSandLSDforEntRecordType');
        Contact objContact = new contact();
        objContact.Email = body.email;
        objContact.Company__c = (String.isNotBlank(body.company_name)) ? body.company_name : (body.first_name+' '+body.last_name);
        objContact.FirstName = body.first_name;
        objContact.LastName = body.last_name;
        objContact.Phone = body.phone;
        objContact.Type__c = body.type;
        objContact.LeadSource = body.lead_source;
        objContact.LeadSource_Sub_Type__c = body.lead_source_subtype;
        objContact.Lead_Source_Detail__c = body.lead_source_detail;
        objContact.utm_campaign__c = body.utm_campaign;
        objContact.utm_content__c = body.utm_content;
        objContact.utm_medium__c = body.utm_medium;
        objContact.utm_source__c = body.utm_source;
        objContact.utm_term__c = body.utm_term;
        objContact.Locale__c = body.locale;
        objContact.Country_Code__c = body.country_code;
        objContact.Market__c = body.market;
        if(String.isNotBlank(body.marketing_consent)){
            objContact.Marketing_Consent__c = Boolean.valueOf(body.marketing_consent);
        }
        if(String.isNotBlank(body.email_opt_out)){
            objContact.HasOptedOutOfEmail = Boolean.valueOf(body.email_opt_out);
        }
        if(String.isNotBlank(body.lead_source) && String.isNotBlank(body.lead_source_detail) && !mapSetting.isEmpty() && ((List<Object>)mapSetting.get('leadsource')).contains(body.lead_source.toLowerCase()) && ((List<Object>)mapSetting.get('leadsourcedetail')).contains(body.lead_source_detail.toLowerCase())){		
            objContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Contact').getRecordTypeId();		
        }
        return objContact;
    }

    /************************************************************************************************************************************
        Author              :   Ajaysinh Chauhan
        Description         :   This method fills the contact information from person endpoint payload.
        Created Date        :   19 June 2018
    **************************************************************************************************************************************/
    public static Contact fillContactByPerson(RESTAPIPersonModelsV2.Input body,Contact objContact){
        if(objContact.Email==null)
            objContact.Email = body.email;
        if(objContact.FirstName==null)
            objContact.FirstName = body.first_name;
        if(objContact.LastName==null)
            objContact.LastName = body.last_name;
        if(objContact.Phone==null)
            objContact.Phone = body.phone;
        if(objContact.Type__c==null)
            objContact.Type__c = body.type;
        if(objContact.LeadSource==null)
            objContact.LeadSource = body.lead_source;
        if(objContact.Lead_Source_Detail__c==null)
            objContact.Lead_Source_Detail__c = body.lead_source_detail;
        if(objContact.utm_campaign__c==null)
            objContact.utm_campaign__c = body.utm_campaign;
        if(objContact.utm_content__c==null)
            objContact.utm_content__c = body.utm_content;
        if(objContact.utm_medium__c==null)
            objContact.utm_medium__c = body.utm_medium;
        if(objContact.utm_source__c==null)
            objContact.utm_source__c = body.utm_source;
        if(objContact.utm_term__c==null)
            objContact.utm_term__c = body.utm_term;
        if(objContact.Locale__c==null)
            objContact.Locale__c = body.locale;
        if(objContact.Country_Code__c==null)
            objContact.Country_Code__c = body.country_code;
        if(String.isNotBlank(body.market))
            objContact.Market__c = body.market;
        if(String.isNotBlank(body.marketing_consent))
            objContact.Marketing_Consent__c = Boolean.valueOf(body.marketing_consent);
        if(String.isNotBlank(body.email_opt_out))
            objContact.HasOptedOutOfEmail = Boolean.valueOf(body.email_opt_out);
        return objContact;
    }
}