public class LeadConversionAsyncQueueable implements Queueable, Callable {
    
    List<Lead> lstLeads  = NULL;
    Boolean isInsert = true;
    Map<Id, Lead> mapLeadsEmailChanged;
    Boolean isLeadFromWeb = false;
    String strSource;

    public LeadConversionAsyncQueueable(){}

    public LeadConversionAsyncQueueable(List<Lead> lstLeads, Boolean isInsert, Map<Id, Lead> mapLeadsEmailChanged, Boolean isLeadFromWeb){
        this.lstLeads = lstLeads;
        this.isInsert = isInsert;
        this.mapLeadsEmailChanged = mapLeadsEmailChanged;
        this.isLeadFromWeb = isLeadFromWeb;
        this.strSource = 'FROM_LEAD_TRIGGER';
    }
    
    public LeadConversionAsyncQueueable(List<Lead> lstLeadsToConvert, String strSource){
        this.lstLeads = lstLeadsToConvert;
        this.strSource = strSource;
    }

    public LeadConversionAsyncQueueable call(String action, Map<String, Object> args) {
        switch on action {
            when 'leads' {
                return new LeadConversionAsyncQueueable((List<Lead>)args.get('leads'), (String)args.get('source'));
            }
            when 'leadsWithEmails' {
                return new LeadConversionAsyncQueueable((List<Lead>)args.get('leads'), (Boolean)args.get('isInsert'), (Map<Id, Lead>)args.get('leadsEmailChanged'), (Boolean)args.get('isLeadFromWeb'));
            }
        }
        return null;
    }
    
    public void execute(QueueableContext context) {
        try{
            LeadConverterHelper.isCreateActivity = false; 
            if(this.lstLeads != NULL && !this.lstLeads.isEmpty() && String.isNotBlank(this.strSource)){
                if(this.strSource.equalsIgnoreCase('FROM_LEAD_TRIGGER')){
                    LeadConverterHelper.isInsert = isInsert;                
                    LeadTriggerHandler.mapLeadsEmailChanged = mapLeadsEmailChanged;
                    RESTInboundLeadAPIHelper.isLeadFromWeb = isLeadFromWeb;
                    LeadConverterHelper.manageLead(this.lstLeads);  
                }else if(this.strSource.equalsIgnoreCase('FROM_CONTACT_TRIGGER')){
                    LeadConverterHelper.manageJourneyForLead(lstLeads, false); 
                }  
            }
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,JSON.serialize(this.lstLeads), 'LeadConversionAsyncQueueable', 'execute');
            System.debug('Exception Occured ==>'+pEx.getStackTraceString());
            throw new LeadConversionAsyncQueueableException(pEx.getMessage());
        }       
    }
    public class LeadConversionAsyncQueueableException extends Exception{}
}