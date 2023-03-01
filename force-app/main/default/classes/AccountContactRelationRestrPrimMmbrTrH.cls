/*********************************************************************************************************
    Author        :  Krishna Somwanshi
    Description   :  No users are allowed to edit Primary Members on Billing Accounts in SFDC
    Issue No.     :  TWSPG-14844
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR                DETAIL
    1             12-Oct-2022      Krishna Somwanshi     Initial
**********************************************************************************************************/
public with sharing class AccountContactRelationRestrPrimMmbrTrH extends SObjectTriggerHandler{
    @TestVisible
    private List<AccountContactRelation> newAccountContactRelation;
    @TestVisible
    private List<AccountContactRelation> oldAccountContactRelations;
    @TestVisible
    private Map<Id, AccountContactRelation> oldAccountContactRelationMap;
    private static final String ERROR_MESSAGE = 'Please go to Spacestation to edit Primary Member assignments to this Billing Account';
    
    public AccountContactRelationRestrPrimMmbrTrH() {
        this((List<AccountContactRelation>) Trigger.new, (List<AccountContactRelation>) Trigger.Old, (Map<Id, AccountContactRelation>) trigger.oldMap);
    }
    
    @TestVisible
    private AccountContactRelationRestrPrimMmbrTrH(List<AccountContactRelation> newAccountContactRelation, List<AccountContactRelation> oldAccountContactRelations, Map<Id, AccountContactRelation> oldAccountContactRelationMap) {
        this.newAccountContactRelation = newAccountContactRelation;
        this.oldAccountContactRelations = oldAccountContactRelations;
        this.oldAccountContactRelationMap = oldAccountContactRelationMap;
    }
    
    public override void beforeUpdate() {
        restrictPrimaryMemberChange();
    }
    
    public Override void beforeDelete() {
        restrictPrimaryMemberDelete();
    }
    
    private void restrictPrimaryMemberChange(){
        if(UserInfo.getName() == 'Mulesoft Integration User'){
            return;
        }
        for(AccountContactRelation accConRel : newAccountContactRelation){
            AccountContactRelation oldAccountContactRelation = oldAccountContactRelationMap?.get(accConRel.Id);
            if(accConRel.Roles == 'Primary Member' || oldAccountContactRelation.Roles == 'Primary Member'){
                accConRel.addError(ERROR_MESSAGE);
            }	
        }
    }
    
    private void restrictPrimaryMemberDelete(){
        if(UserInfo.getName() == 'Mulesoft Integration User'){
            return;
        }
        for(AccountContactRelation accConRel : oldAccountContactRelations){
            if(accConRel.Roles.contains('Primary Member')){
                accConRel.addError(ERROR_MESSAGE);
            }	
        }
    }
}