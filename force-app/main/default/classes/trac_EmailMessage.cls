/**
 * @description Location class for the Case trigger
 * @name trac_Case
 * @author Shubham Jain, Traction on Demand
 * @date 2019-08-27
 */

public with sharing class trac_EmailMessage extends SObjectDomain {
    public static Boolean beenHere = false;
    public List<EmailMessage> emailMessages;

    public trac_EmailMessage() {
        super();
        this.emailMessages = (List<EmailMessage>) records;
    }


    public override void onBeforeInsert() {
        trac_EmailMessageHandler.checkCcAddresses(emailMessages);
        trac_EmailMessageHandler.maskCreditCardNumbers(emailMessages);
    }

    public override void onAfterInsert() {
        System.debug('@@@Pumasok');
        trac_EmailMessageHandler.completeFirstResponseEmail(emailMessages);
        trac_EmailMessageHandler.revertCompleteResolutionTimeMilestones(emailMessages);
    }
}