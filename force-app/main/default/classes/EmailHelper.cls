/************************************************************************************************************************************
    Author      :   Maciej Miłosz
    Description :   Helper class for email connected activities
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           28 Jan 2021         Maciej Miłosz           Trigger refactoring
**************************************************************************************************************************************/
public inherited sharing class EmailHelper {
    private static Set<Schema.SObjectType> validSObjectTypes = new Set<Schema.SObjectType>{Schema.Contact.getSObjectType(), Schema.Lead.getSObjectType()};
    public static void setEmailDomain(List<SObject> newSObjects, Map<Id, SObject> oldSObjectsMap){
        if(newSObjects == null || newSObjects.isEmpty()){
            return;
        }
        if(!validSObjectTypes.contains(newSObjects[0].getSObjectType())){
            throw new EmailHelperException('Invalid SObject Type for email domain setting.');
        }
        for(SObject record : newSObjects){
            SObject oldRecord = oldSObjectsMap?.get((Id)record.get('Id'));
            if(String.isNotBlank((String)record.get('Email')) 
                && (oldRecord == null
                    || (oldRecord != null && Settings.isChanged((String)record.get('Email'), (String)oldRecord.get('Email'))))) {
                record.put('Email_Domain_Text__c', String.valueOf(record.get('Email')).toLowerCase().split('@')[1]);
            }
        }
    }

    public class EmailHelperException extends Exception{}
}