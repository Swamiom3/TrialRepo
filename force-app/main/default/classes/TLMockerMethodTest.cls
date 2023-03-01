/**
 * @description Tests for TLMocker.Method
 * 
 * @author Grant Adamson, Traction on Demand
 * @date 2019-03-18
 * @group TLMocker
 */
@IsTest
private class TLMockerMethodTest {

    @IsTest
    static void wasCalled() {
        TLMocker mocker = TLMockerTestHelper.getMockerForHistoryTests();

        System.assert(mocker.getMethod('returnABoolean').wasCalled(),
                'It returns true for methods that were called');
        System.assert(mocker.getMethod('returnAnInteger').wasCalled(),
                'It returns true for methods that were called');
        System.assertEquals(false, mocker.getMethod('returnAnotherInteger').wasCalled(),
                'It returns false for methods that were not called');
    }

    @IsTest
    static void getCallCount() {
        TLMocker mocker = TLMockerTestHelper.getMockerForHistoryTests();

        System.assertEquals(2, mocker.getMethod('returnABoolean').getCallCount(),
                'The correct number of calls is returned');
        System.assertEquals(1, mocker.getMethod('returnAnInteger').getCallCount(),
                'The correct number of calls is returned');
        System.assertEquals(0, mocker.getMethod('returnAnotherInteger').getCallCount(),
                'It returns 0 if a method was never called');

    }

    @IsTest
    static void getCalls() {
        TLMocker mocker = TLMockerTestHelper.getMockerForHistoryTests();

        System.assertEquals(2, mocker.getMethod('returnABoolean').getCalls().size(), 'It returns a list of all calls');
        System.assertEquals(0, mocker.getMethod('returnAnotherInteger').getCalls().size(),
                'It returns an empty list if the method was never called');
    }

    @IsTest
    static void getCall() {
        TLMocker mocker = TLMockerTestHelper.getMockerForHistoryTests();

        TLMocker.Call call1 = mocker.getMethod('returnABoolean').getCall();
        System.assertEquals(TLMockerTestHelper.HISTORY_RETURN_A_BOOLEAN_CALL_1_ARG,
                (Boolean)call1.getArg(0), 'It returns the first call');

        TLMocker.Call call2 = mocker.getMethod('returnABoolean').getCall(1);
        System.assertEquals(TLMockerTestHelper.HISTORY_RETURN_A_BOOLEAN_CALL_2_ARG, (Boolean)call2.getArg(0),
                'It returns the second call');
    }

    @IsTest
    static void getCallMethodNeverCalled() {
        TLMocker mocker = TLMockerTestHelper.getMockerForHistoryTests();

        Exception caughtException;
        try {
            mocker.getMethod('returnAnotherInteger').getCall();
        } catch (Exception e) {
            caughtException = e;
        }

        System.assertNotEquals(null, caughtException,
                'An exception should have been thrown if the method was never called');
        System.assert(caughtException instanceof TLMocker.TLMockerMethodException, 'It should be of the correct type');
        System.assertEquals(TLMocker.METHOD_NOT_CALLED_ERROR,
                caughtException.getMessage(), 'It should have the expected error message');
    }

    @IsTest
    static void getCallInvalidIndex() {
        TLMocker mocker = TLMockerTestHelper.getMockerForHistoryTests();

        Exception caughtException;
        try {
            mocker.getMethod('returnAnInteger').getCall(1);
        } catch (Exception e) {
            caughtException = e;
        }

        System.assertNotEquals(null, caughtException,
                'An exception should have been thrown if the call index is out of bounds');
        System.assert(caughtException instanceof TLMocker.TLMockerMethodException, 'It should be of the correct type');
        System.assertEquals(TLMocker.CALL_INDEX_OUT_OF_BOUNDS_ERROR,
                caughtException.getMessage(), 'It should have the expected error message');
    }
}