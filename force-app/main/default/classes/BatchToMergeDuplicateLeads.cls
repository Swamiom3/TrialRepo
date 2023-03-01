/************************************************************************************************************************************
Author		: 	Ashish Sharma
Description	: 	This batch will merge the duplicate leads into master lead.
Issue       :   ST-5321
----------------------------------------------------------------------------------------------------------------------------------
VERSION		DATE	        		AUTHOR                     	DETAIL
1	    	17 December 2019		Ashish Sharma             	Initial Developement
**************************************************************************************************************************************/
public class BatchToMergeDuplicateLeads implements Schedulable, Database.Batchable<AggregateResult>, Database.Stateful {  
    public BatchData objBatchData;
    public Set<Id> setIdsWithErrors = new Set<Id>();
    public String successCSV;
    public String failedCSV;
    public String successHeader;
    public String failedHeader;
    public Boolean isHasMoreRecords = false;
    public BatchToMergeDuplicateLeads() {}
    public BatchToMergeDuplicateLeads(Set<Id> setIdsWithErrors, String successCSV, String failedCSV) {
        initializeData();
        MetadataSetting__mdt objData = Settings.getMetadataSettingByDevName('ConvertLeadBatchData');
        if(objData != NULL) {
            objBatchData = (BatchData)JSON.deserialize(objData.Data__c, BatchData.class);
        }
        this.successCSV = successCSV;
        this.failedCSV = failedCSV;
        this.setIdsWithErrors = setIdsWithErrors;
        successHeader = objBatchData.headerFields;
        failedHeader = objBatchData.headerFields+',Exception';
    }
    
    public void initializeData() {
        objBatchData = new BatchData();
        objBatchData.NumberOfDays = 2;
        objBatchData.limitQuery = 200;
        objBatchData.countById = 1;
        objBatchData.batchSizeForConvertBatch = 50;
        objBatchData.batchSizeForMergeBatch = 1;
        objBatchData.SOQLLimit = 90;
        objBatchData.DMLLimit = 120;
        objBatchData.headerFields = 'Id,Email';
        objBatchData.targetUserIds = new Set<Id>{UserInfo.getUserId()};
    }
    
    public void execute(SchedulableContext sc) {        
        Database.executeBatch(new BatchToMergeDuplicateLeads(NULL, NULL, NULL), objBatchData.batchSizeForMergeBatch);
    }
    
    public Iterable<AggregateResult> start(Database.BatchableContext bc) {
        Integer count = objBatchData.countById;
        Integer limitQuery = objBatchData.limitQuery;             
        Datetime startDate = System.now() - objBatchData.NumberOfDays;
        DateTime endDate = System.now();
        String addListFilter;        
        objBatchData.targetUserIds.add(UserInfo.getUserId());
        this.isHasMoreRecords = false;
        if(setIdsWithErrors != NULL){
            addListFilter  =  ' AND Id NOT IN :setIdsWithErrors ';
        } else {
            addListFilter = ' ';
            setIdsWithErrors = new Set<Id>();
        }        
        String query = 'SELECT count(Id) countOfId, Email FROM Lead WHERE isConverted = FALSE AND Email != NULL'+addListFilter+'AND CreatedDate >:startDate AND CreatedDate <= :endDate GROUP BY Email HAVING count(Id) > :count LIMIT :limitQuery';
        return (List<AggregateResult>)Database.query(query);        
    }
    
    public void execute(Database.BatchableContext bc, List<AggregateResult> lstRecords) {
        LeadTriggerHandler.isLeadDeletedFromMergeBatch = true;
        Map<String, Integer> mapLeadEmailWithCount = new Map<String, Integer>();        
        if(String.isBlank(failedCSV)){
            this.failedCSV = failedHeader;
        }        
        if(String.isBlank(successCSV)){
            this.successCSV = successHeader;
        }            
        Map<Id, Lead> mapLeads;   
        try {
            this.isHasMoreRecords = true;
            for(AggregateResult objAgrResult : lstRecords) {
                mapLeadEmailWithCount.put(objAgrResult.get('Email').toString(), Integer.valueOf(objAgrResult.get('countOfId')));
            }
            if(mapLeadEmailWithCount.size() == 1) {
                Set<String> setEmails = mapLeadEmailWithCount.keySet();
                String query = 'SELECT '+objBatchData.headerFields+' FROM Lead WHERE Email IN :setEmails AND isConverted = FALSE ORDER BY CreatedDate ASC LIMIT '+objBatchData.limitQuery;
                List<Lead> lstLeads = Database.query(query);
                mapLeads = new Map<Id, Lead>(lstLeads);
                if(!mapLeads.isEmpty()) {
                    Lead objMasterLead = mapLeads.values()[0];
                    mapLeads.remove(objMasterLead.Id);
                    do { 
                        List<Lead> lstSecondaryLeads = new List<Lead>();
                        if(mapLeads.size() > 1){
                            lstSecondaryLeads.add(mapLeads.remove(mapLeads.values()[0].Id));
                            lstSecondaryLeads.add(mapLeads.remove(mapLeads.values()[0].Id));  
                        }else if(mapLeads.size() == 1) {
                            lstSecondaryLeads.add(mapLeads.remove(mapLeads.values()[0].Id));
                        }
                        if(objMasterLead != NULL && !lstSecondaryLeads.isEmpty()){
                            Database.MergeResult[] results = Database.merge(objMasterLead, lstSecondaryLeads, false);
                            for(Integer resultIndex = 0; resultIndex < results.size(); resultIndex++) {
                                List<String> lstFields = successHeader.split(',');
                                for(SObject objLead : lstSecondaryLeads) {
                                    if(!results.get(resultIndex).isSuccess()) {
                                        Database.Error errors =  results.get(resultIndex).getErrors().get(0);
                                        setIdsWithErrors.add(objLead.Id);
                                        failedCSV += '\n';
                                        for(String strField : lstFields) {
                                            failedCSV += objLead.get(strField)+',';
                                        }
                                        failedCSV += ''+errors.getMessage();
                                    }else {
                                        successCSV += '\n';
                                        for(String strField : lstFields) {
                                            successCSV += objLead.get(strField)+',';
                                        }
                                        successCSV = successCSV.removeEnd(',');
                                    }
                                }
                            }
                        }
                    } while(!mapLeads.isEmpty() && Limits.getQueries() < objBatchData.SOQLLimit && Limits.getDmlStatements() < objBatchData.DMLLimit);
                }
            }
        } catch(Exception pEx) {
            ApexDebugLog.logException(pEx, mapLeads != null ? JSON.serialize(mapLeads.values()) : '', 'BatchToMergeDuplicateLeads', 'EXECUTE');
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        if(((successCSV != NULL && !successCSV.containsOnly(successHeader))|| (failedCSV != NULL && !failedCSV.containsOnly(failedHeader))) && (!this.isHasMoreRecords || Test.isRunningTest())) {
            List<Messaging.SingleEmailMessage> lstMails = new List<Messaging.SingleEmailMessage>();            
            EmailTemplate successfullTemplate = [SELECT Id, Body, HtmlValue FROM EmailTemplate WHERE Name = 'Lead_Merge_Convert_Email' LIMIT 1];
            
            for(Id userIds : objBatchData.targetUserIds) {
                User userInfo = UserUtility.getUserById(userIds);
                if(userInfo == null) {
                    continue;
                }
                List<Messaging.Emailfileattachment> lstEmailAttachments = new List<Messaging.Emailfileattachment>();
                Messaging.SingleEmailMessage summuryEmail = new Messaging.SingleEmailMessage();
                summuryEmail.setSubject('Leads Merge To Master Lead');
                summuryEmail.setTargetObjectId(userInfo.Id);
                summuryEmail.setTemplateId(successfullTemplate.Id);
                summuryEmail.setSaveAsActivity(false);
                
                if(successCSV != NULL && !successCSV.containsOnly(successHeader)) {
                    Messaging.Emailfileattachment successEmailAttachment = new Messaging.Emailfileattachment();
                    successEmailAttachment.setFileName('Leads_Successfully_merged.csv');
                    successEmailAttachment.setBody(Blob.valueOf(successCSV));
                    lstEmailAttachments.add(successEmailAttachment);
                }
                if(failedCSV != NULL && !failedCSV.containsOnly(failedHeader)) {
                    Messaging.Emailfileattachment failedEmailAttachment = new Messaging.Emailfileattachment();
                    failedEmailAttachment.setFileName('Leads_failed_merged.csv');
                    failedEmailAttachment.setBody(Blob.valueOf(failedCSV));
                    lstEmailAttachments.add(failedEmailAttachment);
                }
                if(lstEmailAttachments != null && lstEmailAttachments.size()>0) {
                    summuryEmail.setFileAttachments(lstEmailAttachments );
                }
                String htmlBody = successfullTemplate.Body;
                htmlBody = htmlBody.replace('{!User.FirstName}', userInfo.Name);
                summuryEmail.setHtmlBody(htmlBody);
                lstMails.add(summuryEmail);
            }
            if(!lstMails.isEmpty())
                Messaging.SendEmailResult[] arrEmailResult = Messaging.sendEmail(lstMails);
        }
        if(this.isHasMoreRecords && !Test.isRunningTest()) {
            Database.executeBatch(new BatchToMergeDuplicateLeads(this.setIdsWithErrors, successCSV, failedCSV), objBatchData.batchSizeForMergeBatch);
        }
    }
    
    public class BatchData {
        public Integer NumberOfDays;
        public Integer limitQuery;
        public Integer countById;
        public Integer batchSizeForConvertBatch;
        public Integer batchSizeForMergeBatch;
        public Integer SOQLLimit;
        public Integer DMLLimit;
        public String headerFields;
        public Set<Id> targetUserIds;
    }
}