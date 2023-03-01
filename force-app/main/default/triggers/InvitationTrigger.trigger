trigger InvitationTrigger on medallia_xm__Invitation__c (before insert) {
	List<medallia_xm__Invitation__c> inviteList = new List<medallia_xm__Invitation__c>();
    for(medallia_xm__Invitation__c invite : Trigger.New){
        if(invite.medallia_xm__ParentId__c != null){
            invite.Support_Request__c = invite.medallia_xm__ParentId__c;
        }
    }
}