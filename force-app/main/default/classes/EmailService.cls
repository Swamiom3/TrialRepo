/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class is util for Email related classes
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR            DETAIL
    1          2 Jul, 2021    Pawel Biszczak    Initial Deployment
**************************************************************************************************************************************/
public with sharing class EmailService {
    @TestVisible
    private static Map<String, EmailTemplate> emailTemplateByDeveloperName = new Map<String, EmailTemplate>();
    @TestVisible
    private static Set<String> alreadyQueriedTemplates = new Set<String>();
    private static Id organizationWideDefaultAddressId;
    private static final String BASE_URL = System.Url.getSalesforceBaseUrl().toExternalForm();
    @TestVisible
    private static EmailTemplateSelector emailTemplateSelector = new EmailTemplateSelector();
    @TestVisible
    private static OrgWideEmailAddressSelector orgWideEmailAddressSelector = new OrgWideEmailAddressSelector();
    private static final  MetadataSetting__mdt BYPASSED_PROFILE_FOR_EMAIL_SEND_METADATA = Settings.getMetadataSettingByDevName('ProfilesNotValidToSendOwnerChangeEmails');
    private static final Set<Id> BYPASSED_ADMIN_PROFILES = (BYPASSED_PROFILE_FOR_EMAIL_SEND_METADATA == null) ? new Set<Id>() : (Set<Id>)JSON.deserialize(BYPASSED_PROFILE_FOR_EMAIL_SEND_METADATA.Data__c, Set<Id>.class);

    public static EmailTemplate getEmailTemplateByDeveloperName(String developerName){
        if(!alreadyQueriedTemplates.contains(developerName)){
            fetchEmailTemplates(new Set<String>{ developerName });
        }
        return emailTemplateByDeveloperName.get(developerName);
    }

    public static Map<String, EmailTemplate> getEmailTemplatesByDeveloperName(Set<String> developerNames){
        if(alreadyQueriedTemplates.containsAll(developerNames)) {
            return emailTemplateByDeveloperName;
        }
        Set<String> missingTemplates = new Set<String>();
        for (String templateName : developerNames) {
            if(!alreadyQueriedTemplates.contains(templateName)) {
                missingTemplates.add(templateName);
            }
        }
        return fetchEmailTemplates(missingTemplates);
    }

    @TestVisible
    private static Map<String, EmailTemplate> fetchEmailTemplates(Set<String> developerNames){
        List<EmailTemplate> emailTemplates = emailTemplateSelector.getEmailTemplatesByDeveloperNames(new List<String>(developerNames));
        alreadyQueriedTemplates.addAll(developerNames);
        for(EmailTemplate emailTemplateRecord : emailTemplates){
            emailTemplateByDeveloperName.put(emailTemplateRecord.DeveloperName, emailTemplateRecord);
        }
        return emailTemplateByDeveloperName;
    }

    public String replaceText(String baseText, Map<String, String> replacementMap) {
        for (String targetValueKey : replacementMap.keySet()) {
           String replacementValue = replacementMap.get(targetValueKey);
           baseText = replaceText(baseText,
                                  targetValueKey,
                                  (replacementValue != null) ? replacementValue : '');
        }
        return baseText;
    }

    private String replaceText(String baseText, String target, String replacement) {
        return baseText.replace(target, replacement);
    }

    public static Id getOrganizationWideDefaultAddressId() {
        if(organizationWideDefaultAddressId != null) {
            return organizationWideDefaultAddressId;
        }
        List<OrgWideEmailAddress> organizationWideDefaultAddresses =
                orgWideEmailAddressSelector.getOrgWideEmailAddressesByDisplayNames(new List<String>{GlobalConstants.EMAIL_NO_REPLY_ORG_WIDE_ADDRESS_NAME });
        if(organizationWideDefaultAddresses.isEmpty()) {
            return null;
        }
        organizationWideDefaultAddressId = organizationWideDefaultAddresses[0].Id;
        return organizationWideDefaultAddressId;
    }

    public static String getBaseUrl() {
        return BASE_URL;
    }
    public static Boolean isValidUserToSendEmailOnOwnerChange(Id profileId){       
        return (!BYPASSED_ADMIN_PROFILES.contains(profileId));
    }
    public static Boolean isValidUserToSendEmailOnOwnerChange(User recordOwner){       
        return (!BYPASSED_ADMIN_PROFILES.contains(recordOwner.ProfileId));
    }

}