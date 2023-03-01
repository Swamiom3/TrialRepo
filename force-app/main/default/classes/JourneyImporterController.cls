/************************************************************************************************************************************
    Author      :   Prashant Mane
    Description :   This class contain all aura methods related to Journey Importer Component.
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           10 Jan 2019         Prashant Mane        	Initial Developement
**************************************************************************************************************************************/
global without sharing class JourneyImporterController {
    public static Boolean isInvoker = false;
    public static Savepoint sp {get;set;}
    static {
        isInvoker = ApexDebugLog.registerRootInvoker(ApexDebugLog.InvokerType.AURA, 'JourneyImporterController' + 'getsObjectPrefix', ApexDebugLog.InvokerType.AURA);        
    }
    /****************************************************************************************************************************
		Author              :   Samadhan kadam
		Description         :   This method is used to get parse data of lead object from csv which is imported via Lead/Journey importer 
								and send data to JourneyImporterBatch to insert.
		Created Date        :   12 June 2018            
	*********************************************************************************************************************************/    
    @AuraEnabled
    global static DatabaseResult insertJourneysForKickBoxImporter(List<Lead> lstLeads, String strCSV, Boolean generateJourney, String campaignId, string[] apiNamesOfCSVColumns, List<String> failColumns, List<String> successColumns, Boolean routeToInsideSales){
        try{    
            sp = Database.setSavepoint();
            Map<String, Lead> mapLeadWithEmails = new Map<String, Lead>();
            Id strHoldBackQueueId =  (Id)LeadConverterHelper.getHoldBackQueueId();
            UserUtility.getAllUsers();
            for(Lead leadRec : lstLeads) {  
                if(String.isBlank(leadRec.OwnerId) || !UserUtility.idToUser.containsKey(leadRec.OwnerId)) {
                    leadRec.OwnerId = strHoldBackQueueId;                   
                }               
                if(String.isNotBlank(leadRec.Email)) {
                    mapLeadWithEmails.put(leadRec.Email.toLowerCase(), leadRec);    
                }
            }
            lstLeads.clear();
            lstLeads.addAll(mapLeadWithEmails.values());
            set<string> setInsertedLeadEmails = new set<string>();
            set<Id> setInsertedLeads = new set<Id>();
            map<string,list<sObject>> mapSobjectRecords = new map<string,list<sObject>>(); 
            map<string,integer> mapOfSummaryCounts = new map<string,integer>();
            
            Kickbox_Verification__c objKickboxVerification = new Kickbox_Verification__c();
            objKickboxVerification.Create_From_Journey_Importer__c = true;
            objKickboxVerification.Generate_Journey__c = generateJourney;       
            if(!String.isBlank(campaignId)){
                objKickboxVerification.Campaign__c = campaignId;
            }
            insert objKickboxVerification;
            List<Attachment> lstAttachments = new List<Attachment>();
            
            Attachment objAttachment = new Attachment();
            objAttachment.Name = 'Lead Importer Data';
            objAttachment.IsPrivate = false;
            objAttachment.ContentType = 'text/csv';
            objAttachment.Body =  Blob.valueof(strCSV);
            objAttachment.OwnerId = UserInfo.getUserId();
            objAttachment.ParentId = objKickboxVerification.Id;
            lstAttachments.add(objAttachment);
            if(lstAttachments.size()>0){
                insert lstAttachments;
            }
            Integer chunkSize = (String.isNotBlank(Label.JourneyImporterBatch_BatchSize) && !Test.isRunningTest()) ? Integer.valueOf(Label.JourneyImporterBatch_BatchSize) : 30;
            Database.executeBatch(new JourneyImporterBatch(lstLeads, routeToInsideSales, objKickboxVerification,(String.join(successColumns,',')+'\n'),(String.join(failColumns,',')+',Error\n'),apiNamesOfCSVColumns), chunkSize);
            return new DatabaseResult(true);
        }catch(Exception pEx){
            LightningComponentController.rollbackTransaction(sp);
            ApexDebugLog.logException(pEx,'startDate==>', 'JourneyImporterController', 'insertJourneysForKickBoxImporter');            
            return (new DatabaseResult(pEx));  
        } 
    } 
 }