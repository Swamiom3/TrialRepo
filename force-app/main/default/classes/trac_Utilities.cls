/**
 * @description general use classes for utilities
 * @name trac_Utilities
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-08-07
 */

public with sharing class trac_Utilities {
    @InvocableMethod(Label='Quick Exit' Description='Doesn\'t do anything, just a short cut to exit a Process Flow')
    public static void QuickExit() {}


    /**
     * @description finds credit card numbers in any given field and replaces the number with X's
     * @param sobjects list of sobjects to process
     * @param fieldsToCheck list of fields to check in the sobjects for masking
     */
    public static void maskCreditCardNumbers(List<SObject> sobjects, Set<String> fieldsToCheck) {
        final String creditCardRegex = '(?:\\d[ -]*?){13,16}';
        final String creditCardReplacement = '****-****-****-****';

        for(SObject record : sobjects) {
            for(String field : fieldsToCheck) {
                if(record.get(field) != null) {
                    record.put(field,String.valueOf(record.get(field)).replaceAll(creditCardRegex,creditCardReplacement));
                }
            }
        }
    }


    /**
     * @description general use mail sender method for debugging email-to-case
     * @param toAddress the email address to receive the email
     * @param subject subject line of the email
     * @param message message body of the email
     * @param parameter object to debug in the email message body
     */
    public static void sendMail(String toAddress, String subject, String message, Object parameter) {
        sendMail(toAddress,subject,String.format(message,new List<Object>{parameter}));
    }

    /**
     * @description general use mail sender method for debugging email-to-case
     * @param toAddress the email address to receive the email
     * @param message message body of the email
     * @param parameter object to debug in the email message body
     */
    public static void sendMail(String toAddress, String message, Object parameter) {
        sendMail(toAddress,'Mail Utility',String.format(message,new List<Object>{parameter}));
    }

    /**
     * @description general use mail sender method for debugging email-to-case
     * @param toAddress the email address to receive the email
     * @param subject subject line of the email
     * @param message message body of the email
     * @param parameter list of objects to debug in the email message body
     */
    public static void sendMail(String toAddress, String subject, String message, List<Object> parameters) {
        sendMail(toAddress,subject,String.format(message,parameters));
    }

    /**
     * @description general use mail sender method for debugging email-to-case
     * @param toAddress the email address to receive the email
     * @param subject subject line of the email
     * @param message message body of the email
     */
    public static void sendMail(String toAddress, String subject, String message){
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        List<String> to = new List<String>();
        to.add(toAddress);
        email.setToAddresses(to);
        email.setSubject(subject);
        email.setHtmlBody(message);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }

    /**
    * @description general use support request email notification sender
    * @param toAddress the email address to receive the email
    * @param parentId what id of the email
    * @param templateId email template id
    */

    public static void sendMailNotification(String toAddress, String parentId, String templateId){
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        List<String> to = new List<String>();
        to.add(toAddress);
        email.setToAddresses(to);
        email.setTemplateId(templateId);
        email.setWhatId(parentId);
        if(Test.isRunningTest()){
            email.setTargetObjectId(userInfo.getUserId());
             email.setSaveAsActivity(false);
            email.setWhatId(null);
        }
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
}