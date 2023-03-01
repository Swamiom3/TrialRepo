/**
 * Mock implementation of TLMailSenderService to prevent test failures when email deliverability is off
 * Will return success for all messages. To mock failures, create a custom TLMailSenderService implementation
 * 
 * @author Grant Adamson, Traction on Demand
 * @date 2019-03-27
 *
 */
@IsTest
public class TLMailSenderServiceMock implements TLMailSenderService {
    private static final String SEND_EMAIL_RESULT_JSON = '{"success": "true"}';

    @TestVisible
    private Boolean isSendEmailCalled = false;
    @TestVisible
    private List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();

    /**
     * Mock implementation that creates and returns a SendEmailResult with success = true for each email message passed
     */
    public List<Messaging.SendEmailResult> sendEmail(List<Messaging.SingleEmailMessage> messages) {
        isSendEmailCalled = true;
        this.messages = messages;

        List<Messaging.SendEmailResult> result = new List<Messaging.SendEmailResult>();
        for(Messaging.SingleEmailMessage msg : messages) {
            result.add(createNewSendEmailResult());
        }

        return result;
    }

    /**
     * We can't instantiate Message.SendEmailResult directly, but we can deserialize it from JSON
     */
    private Messaging.SendEmailResult createNewSendEmailResult() {
        return (Messaging.SendEmailResult)JSON.deserialize(SEND_EMAIL_RESULT_JSON, Messaging.SendEmailResult.class);
    }

}