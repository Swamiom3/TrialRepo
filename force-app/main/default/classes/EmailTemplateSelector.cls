/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class is selector implementation of particular SObject (EmailTemplate)
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR            DETAIL
    1          5 Jul, 2021    Pawel Biszczak    Initial Deployment
**************************************************************************************************************************************/
public with sharing class EmailTemplateSelector extends SObjectSelector {
    private static final List<String> DEFAULT_FIELDS = new List<String>{ 'Id',
                                                                         'Body',
                                                                         'DeveloperName',
                                                                         'HtmlValue',
                                                                         'IsActive',
                                                                         'Markup',
                                                                         'Name',
                                                                         'Subject' };

    public EmailTemplateSelector() {
        super(EmailTemplate.getSObjectType());
    }

    public override Set<String> getDefaultFields(){
        return new Set<String> (DEFAULT_FIELDS);
    }

    public List<EmailTemplate> getEmailTemplatesByDeveloperNames(List<String> developerNames){
        if (developerNames == null || developerNames.isEmpty()) {
            return new List<EmailTemplate>();
        }
        return (List<EmailTemplate>) getSObjectByField(DEFAULT_FIELDS, 'DeveloperName', developerNames, false);
    }
}