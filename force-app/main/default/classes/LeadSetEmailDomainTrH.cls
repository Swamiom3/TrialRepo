/************************************************************************************************************************************
    Author      :   Krishana Tupe
    Description :   This class will contain buisness logic of Lead trigger which updates Email Domain on the Lead record.
    Issue No    :   ST-
    History     :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           08 April 2019       Krishana Tupe           Initial Developement
    2           28 Jan 2021         Maciej Miłosz           Trigger refactoring
**************************************************************************************************************************************/
public with sharing class LeadSetEmailDomainTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Lead> newLeads;
    @TestVisible
    private Map<Id, Lead> oldLeadsMap;

    public LeadSetEmailDomainTrH(){
        this(
            (List<Lead>) Trigger.new,
            (Map<Id, Lead>) Trigger.oldMap
        );
    }

    @TestVisible
    private LeadSetEmailDomainTrH(List<Lead> newLeads, Map<Id, Lead> oldLeadsMap){
        this.newLeads = newLeads;
        this.oldLeadsMap = oldLeadsMap;
    }

    public override void beforeInsert(){
        EmailHelper.setEmailDomain(newLeads, null);
    }

    public override void beforeUpdate(){
        EmailHelper.setEmailDomain(newLeads, oldLeadsMap);
    }
}