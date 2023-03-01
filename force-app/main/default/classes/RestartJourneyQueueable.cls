public class RestartJourneyQueueable implements Queueable, Callable {
    String strSource;
    Set<Id> setLeadOrContactIds = new Set<Id>();

    public RestartJourneyQueueable(){}

    public RestartJourneyQueueable( Set<Id> setLeadIds){
        this.setLeadOrContactIds = setLeadIds;
        this.strSource = 'FROM_LEAD_TRIGGER';
    }

    public RestartJourneyQueueable(Set<Id> setContactIds, String strSource){
        this.setLeadOrContactIds = setContactIds;
        this.strSource = strSource;
    }

    public RestartJourneyQueueable call(String action, Map<String, Object> args) {
        switch on action {
            when 'leads' {
                return new RestartJourneyQueueable((Set<Id>)args.get('leadIds'));
            }
            when 'contacts' {
                return new RestartJourneyQueueable((Set<Id>)args.get('contactIds'), (String)args.get('source'));
            }
        }
        return null;
    }
    
    public void execute(QueueableContext context) {
        try{
            if(this.setLeadOrContactIds != NULL && !this.setLeadOrContactIds.isEmpty() && String.isNotBlank(this.strSource)){
                if(this.strSource.equalsIgnoreCase('FROM_LEAD_TRIGGER')){
                    new JourneyRestartService().restartJourneyForLead(setLeadOrContactIds);
                }else if(this.strSource.equalsIgnoreCase('FROM_CONTACT_TRIGGER')){
                    new JourneyRestartService().restartJourneyForContact(setLeadOrContactIds);
                }
            }        
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,JSON.serialize(this.setLeadOrContactIds), 'RestartJourneyQueueable', 'execute');
            System.debug('Exception Occured ==>'+pEx.getStackTraceString());
            throw new RestartJourneyQueueableException(pEx.getMessage());
        }       
    }
    public class RestartJourneyQueueableException extends Exception{}
}