/**
 * @description Tests for TLMocker. Not required to install TLMocker as TLMocker is @IsTest annotated
 *
 * @author Grant Adamson, Traction on Demand
 * @date 2017-05-01
 * @group TLMocker
 */
@IsTest
private class TLMockerTest {
    private static final Integer STUB_PROVIDER_INPUT_BELOW_ZERO_VALUE = 5;
    private static final Integer STUB_PROVIDER_INPUT_OTHER_VALUE = 10;

    @IsTest
    private static void initWithNoValues() {
        final TLMocker mocker = new TLMocker(TLMockerTestClassToMock.class);
        final TLMockerTestClassToMock mock = (TLMockerTestClassToMock)mocker.stub;

        System.assertEquals(null, mock.returnABoolean(false),
                'I can call a method and it returns a default null value');
        System.assertEquals(null, mock.returnAnInteger(0, 'test'),
                'I can call a method and it returns a default null value');
        System.assertEquals(null, mock.returnAnotherInteger(0),
                'I can call a method and it returns a default null value');
    }

    @IsTest
    private static void initWithSingleValue() {
        final Integer response = 5;
        final TLMocker mocker = new TLMocker(TLMockerTestClassToMock.class, response);
        final TLMockerTestClassToMock mock = (TLMockerTestClassToMock)mocker.stub;

        System.assertEquals(response, mock.returnAnInteger(0, 'test'),
                'I can call a method and it returns the provided value');
        System.assertEquals(response, mock.returnAnotherInteger(0),
                'I can call a method and it returns the provided value');
    }

    @IsTest
    private static void initWithSingleValueStubProvider() {
        final TLMocker mocker = new TLMocker(TLMockerTestClassToMock.class, new TestStubProvider());
        final TLMockerTestClassToMock mock = (TLMockerTestClassToMock)mocker.stub;

        System.assertEquals(STUB_PROVIDER_INPUT_BELOW_ZERO_VALUE, mock.returnAnInteger(0, 'test'),
                'I can call a method and it returns the value determined by the stub provider');
        System.assertEquals(STUB_PROVIDER_INPUT_OTHER_VALUE, mock.returnAnotherInteger(1),
                'I can call a method and it returns the value determined by the stub provider');
    }

    @IsTest
    private static void initWithSingleValueException() {
        final TLMocker mocker = new TLMocker(TLMockerTestClassToMock.class,
                new TLMockerTestClassToMock.TestException('It broke!'));
        final TLMockerTestClassToMock mock = (TLMockerTestClassToMock)mocker.stub;

        Exception caughtException;

        try {
            mock.returnABoolean(true);
        } catch (Exception e) {
            caughtException = e;
        }

        System.assertNotEquals(null, caughtException, 'An exception was thrown');
        System.assert(caughtException instanceof TLMockerTestClassToMock.TestException,
                'The correct type of exception was thrown');
    }

    @IsTest
    private static void initWithMap() {
        final Integer returnAnIntegerValue = 20;
        final Map<String, Object> responseMap = new Map<String, Object>{
                'returnAnInteger' => returnAnIntegerValue,
                'returnAnotherInteger' => new TLMockerTestClassToMock.TestException('It broke!')
        };

        final TLMocker mocker = new TLMocker(TLMockerTestClassToMock.class, responseMap);
        final TLMockerTestClassToMock mock = (TLMockerTestClassToMock)mocker.stub;


        System.assertEquals(returnAnIntegerValue, mock.returnAnInteger(0, 'test'),
                'I can call a method and it returns the provided value');
        System.assertEquals(null, mock.returnABoolean(true),
                'I can call a method and it returns null if no map value was provided');

        Exception caughtException;
        try {
            mock.returnAnotherInteger(0);
        } catch (Exception e) {
            caughtException = e;
        }
        System.assertNotEquals(null, caughtException, 'An exception was thrown');
        System.assert(caughtException instanceof TLMockerTestClassToMock.TestException,
                'I can call a method and it returns the provided value');
    }

    @IsTest
    private static void initWithMapAndFallbackValue() {
        final Integer returnAnIntegerValue = 20;
        final Boolean returnABooleanValue = true;
        final Integer fallbackValue = -1;
        final Map<String, Object> responseMap = new Map<String, Object>{
                'returnAnInteger' => returnAnIntegerValue,
                'returnABoolean' => returnABooleanValue
        };

        final TLMocker mocker = new TLMocker(TLMockerTestClassToMock.class, responseMap, fallbackValue);
        final TLMockerTestClassToMock mock = (TLMockerTestClassToMock)mocker.stub;

        System.assertEquals(returnAnIntegerValue, mock.returnAnInteger(0, 'test'),
                'I can call a method and it returns the provided value');
        System.assertEquals(returnABooleanValue, mock.returnABoolean(true),
                'I can call a method and it returns the provided value');
        System.assertEquals(fallbackValue, mock.returnAnotherInteger(0),
                'I can call a method and it returns the fallback value if the map did not provide one');
    }

    /**
     * An example StubProvider implementation used to test "pass through" functionality, where TLMocker will call
     * handleMethodCall on the provided instance and then return the value;
     */
    private class TestStubProvider implements System.StubProvider {
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, Type returnType,
                List<Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {

            if((Integer)listOfArgs[0] < 1) {
                return STUB_PROVIDER_INPUT_BELOW_ZERO_VALUE;
            }

            return STUB_PROVIDER_INPUT_OTHER_VALUE;
        }
    }
}