/*********************************************************************************************************
Author        :  Onkar Swami
Description   :  Handler class for triggerto avoid lead duplication on same day 
Issue No.     :  
History       :
-----------------------------------------------------------------------------------------------------------
VERSION        DATE            AUTHOR             DETAIL
1          28--Feb-2023      Onkar Swami          Handler
**********************************************************************************************************/
public class LeadAvoidDuplicationOnSameDayTrH extends SobjectTriggerHandler{
    @TestVisible
    private List<Lead> newLead;
    public LeadAvoidDuplicationOnSameDayTrH(){
        this((List<Lead>) Trigger.new);
    }
    public LeadAvoidDuplicationOnSameDayTrH(List <Lead> newLead){
        this.newLead = newLead;
    }
    public override void beforeInsert(){
        avoidLeadDuplication();
    }
    public void avoidLeadDuplication(){
        List<Lead> leads = [select id , LastName, Email from Lead Where CreatedDate = today ];
        List<String> emails = new List<String>();
        List<String> lastNames = new List<String>();
        if(!leads.isEmpty()){
            for(Lead lead : leads ){
                emails.add(lead.Email.toLowerCase());
                lastNames.add(lead.LastName.toLowerCase());
            }
        }
        for(Lead lead : newLead){
            if(emails.contains(lead.Email.toLowerCase()) && lastNames.contains(lead.LastName.toLowerCase())){
                lead.addError('You Cannot Create New Lead Because You created already today itself');
            }
        }
    } 
}

