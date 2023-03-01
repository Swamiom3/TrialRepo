/**
 * @description Shared constants and methods used by TLMocker Tests
 * 
 * @author Grant Adamson, Traction on Demand
 * @date 2019-03-18
 * @group TLMocker
 */
@IsTest
public class TLMockerTestHelper {
    public static final Boolean HISTORY_RETURN_A_BOOLEAN_CALL_1_ARG = false;
    public static final Boolean HISTORY_RETURN_A_BOOLEAN_CALL_2_ARG = true;
    public static final Integer HISTORY_RETURN_AN_INTEGER_ARG_1 = -1;
    public static final String HISTORY_RETURN_AN_INTEGER_ARG_2 = 'test';

    public static TLMocker getMockerForHistoryTests() {
        final TLMocker mocker = new TLMocker(TLMockerTestClassToMock.class);
        final TLMockerTestClassToMock mock = (TLMockerTestClassToMock)mocker.stub;

        mock.returnABoolean(HISTORY_RETURN_A_BOOLEAN_CALL_1_ARG);
        mock.returnABoolean(HISTORY_RETURN_A_BOOLEAN_CALL_2_ARG);
        mock.returnAnInteger(HISTORY_RETURN_AN_INTEGER_ARG_1, HISTORY_RETURN_AN_INTEGER_ARG_2);
        mock.returnAString();

        return mocker;
    }
}