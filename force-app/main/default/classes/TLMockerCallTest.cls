/**
 * @description Tests for TLMocker.Call
 *
 * @author Grant Adamson, Traction on Demand
 * @date 2019-03-18
 * @group TLMocker
 */
@IsTest
private class TLMockerCallTest {
    @IsTest
    static void hasArgs() {
        TLMocker mocker = TLMockerTestHelper.getMockerForHistoryTests();

        System.assert(mocker.getMethod('returnABoolean').getCall().hasArgs(),
                'It returns true if the call had arguments');
        System.assert(mocker.getMethod('returnAnInteger').getCall().hasArgs(),
                'It returns true if the call had arguments');
        System.assertEquals(false, mocker.getMethod('returnAString').getCall().hasArgs(),
                'It returns false if the call did not have any arguments');
    }

    @IsTest
    static void getArgCount() {
        TLMocker mocker = TLMockerTestHelper.getMockerForHistoryTests();

        System.assertEquals(1, mocker.getMethod('returnABoolean').getCall().getArgCount(),
                'The first call contains the expected number of parameters');
        System.assertEquals(1, mocker.getMethod('returnABoolean').getCall(1).getArgCount(),
                'The second call contains the expected number of parameters');
        System.assertEquals(2, mocker.getMethod('returnAnInteger').getCall().getArgCount(),
                'The call contains the expected number of parameters');
        System.assertEquals(0, mocker.getMethod('returnAString').getCall().getArgCount(),
                'The call contains the expected number of parameters');
    }

    @IsTest
    static void getArg() {
        TLMocker mocker = TLMockerTestHelper.getMockerForHistoryTests();

        System.assertEquals(TLMockerTestHelper.HISTORY_RETURN_A_BOOLEAN_CALL_1_ARG,
                (Boolean)mocker.getMethod('returnABoolean').getCall().getArg());
        System.assertEquals(TLMockerTestHelper.HISTORY_RETURN_A_BOOLEAN_CALL_2_ARG,
                (Boolean)mocker.getMethod('returnABoolean').getCall(1).getArg());
        System.assertEquals(TLMockerTestHelper.HISTORY_RETURN_AN_INTEGER_ARG_1,
                (Integer)mocker.getMethod('returnAnInteger').getCall().getArg(),
                'The entry contains the expected parameter value');
        System.assertEquals(TLMockerTestHelper.HISTORY_RETURN_AN_INTEGER_ARG_2,
                (String)mocker.getMethod('returnAnInteger').getCall().getArg(1),
                'The entry contains the expected parameter value');
    }

    @IsTest
    static void getArgNoArgs() {
        TLMocker mocker = TLMockerTestHelper.getMockerForHistoryTests();

        Exception caughtException;

        try {
            mocker.getMethod('returnAString').getCall().getArg();
        } catch (Exception e) {
            caughtException = e;
        }

        System.assertNotEquals(null, caughtException, 'It should throw an exception');
        System.assert(caughtException instanceof TLMocker.TLMockerCallException, 'It should be of the correct type');
        System.assertEquals(TLMocker.NO_ARGUMENTS_ERROR, caughtException.getMessage(),
                'It should have the correct error message');
    }

    @IsTest
    static void getArgInvalidIndex() {
        TLMocker mocker = TLMockerTestHelper.getMockerForHistoryTests();

        Exception caughtException;

        try {
            mocker.getMethod('returnABoolean').getCall().getArg(1);
        } catch (Exception e) {
            caughtException = e;
        }

        System.assertNotEquals(null, caughtException, 'It should throw an exception');
        System.assert(caughtException instanceof TLMocker.TLMockerCallException, 'It should be of the correct type');
        System.assertEquals(TLMocker.ARG_INDEX_OUT_OF_BOUNDS_ERROR, caughtException.getMessage(),
                'It should have the correct error message');
    }

    @IsTest
    static void getArgs() {
        TLMocker mocker = TLMockerTestHelper.getMockerForHistoryTests();

        List<Object> returnABooleanArgs = mocker.getMethod('returnABoolean').getCall().getArgs();
        List<Object> returnAnIntegerArgs = mocker.getMethod('returnAnInteger').getCall().getArgs();
        List<Object> returnAStringArgs = mocker.getMethod('returnAString').getCall().getArgs();

        System.assertEquals(1, returnABooleanArgs.size(), 'It should return all the arguments provided to the call');
        System.assertEquals(TLMockerTestHelper.HISTORY_RETURN_A_BOOLEAN_CALL_1_ARG, (Boolean)returnABooleanArgs[0],
                'The correct argument value should be included in the list');

        System.assertEquals(2, returnAnIntegerArgs.size(),  'It should return all the arguments provided to the call');
        System.assertEquals(TLMockerTestHelper.HISTORY_RETURN_AN_INTEGER_ARG_1, (Integer)returnAnIntegerArgs[0],
                'The correct argument value should be included in the list');
        System.assertEquals(TLMockerTestHelper.HISTORY_RETURN_AN_INTEGER_ARG_2, (String)returnAnIntegerArgs[1],
                'The correct argument value should be included in the list');

        System.assertEquals(0, returnAStringArgs.size(), 'It should return all the arguments provided to the call');
    }
}