/************************************************************************************************************************************
    Author      :  Sunil Bhosale
    Description :  Forcefully update longstanding Journeys.
    Issue No    :  ST-1547

    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION		DATE      		AUTHOR            	DETAIL
        1                 	Sunil Bhosale      		Initial Developement
        2   	14/11/2018  	Jitesh Adwani      	ST-3033 Change Name of the fields.
		3  		8 April 2019	Dipak Pawar			ST-3700 Journey: Modify Auto-Complete query to exclude records
**************************************************************************************************************************************/
global class BatchToForceFullyUpdateJourneys implements Database.Batchable<sObject>, Database.Stateful,Schedulable {
    public String query;
    public Set<String> excludedStages, excludedLeadSources, excludedLeadSourcesDetails, emailAddresses;
    public Datetime dateToFilter;
    public Datetime startDate;
    public List<String> errors = new List<String>();
    public Integer totalSucceededRecords = 0, totalFailedRecords = 0, numberOfDays = 30;
    @TestVisible static Integer emailLimits;

    global void execute(SchedulableContext SC) {
        Database.executeBatch(new BatchToForceFullyUpdateJourneys(), 200);
    }
    global BatchToForceFullyUpdateJourneys() {
        MetadataSetting__mdt batchMetadataSettingRecord = Settings.getMetadataSettingByDevName('BatchToForceFullyUpdateJourneys');

        if(batchMetadataSettingRecord != null && String.isNotBlank(batchMetadataSettingRecord.Data__c)){
            MetadataSetting batchSettings = (MetadataSetting) System.JSON.deserialize(batchMetadataSettingRecord.Data__c, MetadataSetting.class);

            if(batchSettings != null){
                if(batchSettings.ExcludedStages != null && batchSettings.ExcludedStages.size() > 0){
                    excludedStages = new Set<String>(batchSettings.ExcludedStages);
                }

                if(batchSettings.ExcludedLeadSource != null && batchSettings.ExcludedLeadSource.size() > 0){
                    excludedLeadSources = new Set<String>(batchSettings.ExcludedLeadSource);
                }

                if(batchSettings.ExcludedLeadSourceDetails != null && batchSettings.ExcludedLeadSourceDetails.size() > 0){
                    excludedLeadSourcesDetails = new Set<String>(batchSettings.ExcludedLeadSourceDetails);
                }

                if(batchSettings.NumberOfDays != null && !Test.isRunningTest()){ //Added !Test.isRunningTest() to handler change in Custom Metadata for Test methods
                    numberOfDays = batchSettings.NumberOfDays;
                }

                if(batchSettings.StartDate != null && batchSettings.EndDate != null){
                    startDate = batchSettings.StartDate;
                    dateToFilter = batchSettings.EndDate;
                }else{
                    dateToFilter = Date.today().addDays(-numberOfDays);
                }

                if(batchSettings.Emails != null && batchSettings.Emails.size() > 0){
                    emailAddresses = new Set<String>(batchSettings.Emails);
                }
                query = 'SELECT Id, ' + String.join(getJourneyFields(), ', ') + ', (SELECT Id, ' + String.join(getActivityFields(), ', ') + ' FROM OpenActivities ORDER BY LastModifiedDate DESC) FROM Journey__c WHERE IsAuto_Complete_Expiration__c = FALSE AND CreatedDate <= :dateToFilter'+(startDate != NULL ? ' AND CreatedDate >= :startDate ' :' ')+ 'AND Status__c NOT IN :excludedStages AND Lead_Source__c NOT IN :excludedLeadSources  AND Lead_Source_Detail__c NOT IN :excludedLeadSourcesDetails';
            }
        }
    }

    static List<String> getJourneyFields(){
        Set<String> journeyFields = new Set<String>();
        journeyFields.add('CreatedDate');
        journeyFields.add('Auto_Complete_Expiration__c');
        journeyFields.add('NMD_Next_Contact_Date__c');
        journeyFields.add('CreatedDate');
        journeyFields.add('LastModifiedDate');
        return new List<String>(journeyFields);
    }

    static List<String> getActivityFields(){
        Set<String> activityFields = new Set<String>();
        activityFields.add('LastModifiedDate');
        activityFields.add('ActivityDate');
        return new List<String>(activityFields);
    }

    global Database.QueryLocator start(Database.BatchableContext batchContext){
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Journey__c> journeys) {
        try{
            Boolean isJourneyToClose;
            Date autoCompleteExpirationDate = Date.today();
            List<Journey__c> journeysToUpdate = new List<Journey__c>();
            for(Journey__c journeyRecord : journeys){
                isJourneyToClose = false;
                for(OpenActivity activityRecord : journeyRecord.OpenActivities){
                    if(activityRecord.ActivityDate != null && activityRecord.ActivityDate < dateToFilter){
                        isJourneyToClose = true;
                        autoCompleteExpirationDate = activityRecord.ActivityDate.addDays(numberOfDays);
                    } else if(activityRecord.LastModifiedDate < dateToFilter){
                        isJourneyToClose = true;
                        autoCompleteExpirationDate = Date.valueOf(activityRecord.LastModifiedDate).addDays(numberOfDays);
                    }
                    break;
                }
                if(!isJourneyToClose && journeyRecord.NMD_Next_Contact_Date__c < dateToFilter || journeyRecord.LastModifiedDate < dateToFilter){
                    isJourneyToClose = true;
                    autoCompleteExpirationDate = Date.valueOf(journeyRecord.NMD_Next_Contact_Date__c).addDays(numberOfDays);
                }
                if(!isJourneyToClose) {
                    continue;
                }
                journeyRecord.Auto_Complete_Expiration__c = autoCompleteExpirationDate;
                journeyRecord.IsAuto_Complete_Expiration__c = true;
                journeyRecord.Status__c = 'Deferred';
                journeyRecord.Deferred_Reason__c = 'Auto-Complete / Expiration';
                journeysToUpdate.add(journeyRecord);
            }

            if(journeysToUpdate.isEmpty()){
                return;
            }
            for(Database.SaveResult saveResultRecord: Database.update(journeysToUpdate, false)){
                if(saveResultRecord.isSuccess()){
                    totalSucceededRecords += 1;
                } else {
                    totalFailedRecords += 1;
                }
            }
        } catch (Exception ex) {
            ApexDebugLog.logException(ex, JSON.serialize(journeys), 'BatchToForceFullyUpdateJourneys', 'execute');
        }
    }

    global void finish(Database.BatchableContext BC) {
        EmailTemplate emailTemplateRecord = Settings.getEmailTemplateByDeveloperName('Journey_Forcefully_Closed');
        List<String> emailAddressesForNotification = new List<String>(emailAddresses);

        String htmlBody = emailTemplateRecord.Markup;
        htmlBody = htmlBody.replace('{{TotalRecords}}', String.valueOf(totalSucceededRecords + totalFailedRecords));
        htmlBody = htmlBody.replace('{{SucceededRecords}}', String.valueOf(totalSucceededRecords));
        htmlBody = htmlBody.replace('{{FailedRecords}}', String.valueOf(totalFailedRecords));

        if(emailAddressesForNotification.isEmpty()) {
            emailLimits = Limits.getEmailInvocations();
            return;
        }
        Messaging.SingleEmailMessage singleMail = new Messaging.SingleEmailMessage();
        singleMail.setCharset(GlobalConstants.EMAIL_CHARSET_UTF_8);
        singleMail.setTemplateId(emailTemplateRecord.Id);
        singleMail.setTargetObjectId(UserInfo.getUserId());
        singleMail.setSenderDisplayName('WeWork');
        singleMail.setTreatTargetObjectAsRecipient(false);
        singleMail.setSaveAsActivity(false);
        singleMail.setToAddresses(emailAddressesForNotification);
        singleMail.setHtmlBody(htmlBody);
        singleMail.setSubject('Journey Forcefully Completed: ' + Date.today().format());
        Messaging.sendEmail(new List<Messaging.Email>{ singleMail }, false);
        emailLimits = Limits.getEmailInvocations();
    }

    class MetadataSetting {
        List<String> ExcludedStages;
        List<String> ExcludedLeadSource;
        List<String> ExcludedLeadSourceDetails;
        Integer NumberOfDays;
        DateTime StartDate;
        DateTime EndDate;
        List<String> Emails;
    }
}