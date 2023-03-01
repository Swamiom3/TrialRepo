/************************************************************************************************************************************
	Author		 	:	Roshan kankrayane
	Description 	:	This class send email alert on rea case creation.
---------------------------------------------------------------------------------------------------------------------------------------------
	VERSION	  	DATE	            Issue No.   	AUTHOR                  DETAIL
	1	     	07 September 2021   ST-8904		    Roshan kankrayane     	Initial Developement
**************************************************************************************************************************************/
public class CaseEmailAlertOnReaCaseCreationTrH extends SObjectTriggerHandler {
    @TestVisible
    private List<Case> newCases;
    @TestVisible
    private static final Id REA_CASE_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByName().get(GlobalConstants.CASE_RT_NAME_REA).getRecordTypeId();
    @TestVisible
    private final static String REA_OPS_EMAIL = 'rea-ops@wework.com';
    private GroupMemberSelector grpMemberSelector = new GroupMemberSelector();
    
    public CaseEmailAlertOnReaCaseCreationTrH() {
        this(
            (List<Case>) Trigger.new
        );
    }
    
    @TestVisible
    private CaseEmailAlertOnReaCaseCreationTrH(List<Case> newCases) {
        this.newCases = this.returnOnlyObjectWithValidRT(Case.SObjectType, 
                                                          newCases,
                                                          CaseConstants.CASE_SALES_RECORD_TYPE);
    }
    
    public override void afterInsert() {
        sendEmailNotificationOnCaseCreation();
    }
   
    public void sendEmailNotificationOnCaseCreation() {
        List<Case> caseToSendMail = new List<Case>();
        Set<Id> groupIds = new Set<Id>();
        for (Case newCase: newCases) {
            if(newCase.RecordTypeId == REA_CASE_RECORD_TYPE_ID) {
                caseToSendMail.add(newCase);
                if(newCase.OwnerId.getSobjectType() == Group.getSobjectType()) {
                    groupIds.add(newCase.OwnerId);
                }
            }
        }
        if(caseToSendMail.isEmpty()) {
            return;
        }
        sendEmail(caseToSendMail, groupIds);
    }
    
    public void sendEmail(List<Case> caseToSendMail, Set<Id> groupIds) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        EmailTemplate emailTemplate = Settings.getEmailTemplateByDeveloperName('REA_Case_Created_vf');
        if(emailTemplate == null) {
            return;
        }
        Map<Id, Set<String>> groupIdsToMembers = groupIds.isEmpty() 
                                                     ? new Map<Id, Set<String>>() 
                                                     : getMemberEmails(groupIds);
        Set<String> toAddresses = new Set<String>();
        for(Case caseRec : caseToSendMail) {
            toAddresses.addAll(getToAddresses(caseRec.OwnerId, groupIdsToMembers));
            toAddresses.add(getUserEmail(UserInfo.getUserId()));
            toAddresses.add(REA_OPS_EMAIL);
            toAddresses.remove(null);
            if(toAddresses.isEmpty()) {
                continue;
            }
            Messaging.SingleEmailMessage singleMail = new Messaging.SingleEmailMessage();
            singleMail.setCharset(GlobalConstants.EMAIL_CHARSET_UTF_8);
            singleMail.setTargetObjectId(UserInfo.getUserId());
            singleMail.setWhatId(caseRec.Id);
            singleMail.setTemplateId(emailTemplate.Id);
            singleMail.setTreatTargetObjectAsRecipient(false);
            singleMail.setSaveAsActivity(false);
            singleMail.toaddresses = new List<String>(toAddresses);
            emailsToSend.add(singleMail);
        }
        if(!emailsToSend.isEmpty()) {
            Messaging.sendEmail(emailsToSend);
        }
    }

    private Map<Id, Set<String>> getMemberEmails(Set<Id> groupIds) {
        Map<Id, Set<String>> groupIdsToMembers = new Map<Id, Set<String>>();
        for(GroupMember groupMember : [SELECT GroupId, UserOrGroupId, Group.Email FROM GroupMember 
                                       WHERE GroupId IN :groupIds]) {
            Set<String> memberEmails = new Set<String>{getUserEmail(groupMember.UserOrGroupId), groupMember.Group.Email};
            memberEmails.remove(null);
            if(groupIdsToMembers.containsKey(groupMember.GroupId)) {
                groupIdsToMembers.get(groupMember.GroupId).addAll(memberEmails);
            } else {
                groupIdsToMembers.put(groupMember.GroupId, memberEmails);
            }
        }
        return groupIdsToMembers;
    }	
    
    private Set<String> getToAddresses(Id ownerId, Map<Id, Set<String>> groupIdsToMembers) {
        if(OwnerId.getSobjectType() == User.getSobjectType()) {
            return new Set<String>{getUserEmail(ownerId)};
        }
        return groupIdsToMembers.isEmpty() ? new Set<String>() : groupIdsToMembers.get(ownerId);
    }
    
    private String getUserEmail(Id userId){ 
        if(userId == null){
            return null;
        }
        User userRec =  UserUtility.getUserById(userId);
        if(userRec == null || !EmailService.isValidUserToSendEmailOnOwnerChange(userRec)){
            return null;   
        }    
        return userRec.Email;
    }
}