/**
 * Universal Mocking class, responds to methods with the corresponding values in responseMap.
 * If no matching value can be found, or responseMap is null, falls back to response value.
 * Logs all method calls with their arguments, accessible through getMethod()
 *
 * @author Grant Adamson, Traction on Demand
 * @date   2017-04-24
 * @group TLMocker
 */
@IsTest
public class TLMocker {
    @TestVisible private static final String METHOD_NOT_CALLED_ERROR = 'The specified method was never called';
    @TestVisible private static final String CALL_INDEX_OUT_OF_BOUNDS_ERROR = 'Call index out of bounds';
    @TestVisible private static final String NO_ARGUMENTS_ERROR =
            'The specified method call does not include any arguments';
    @TestVisible private static final String ARG_INDEX_OUT_OF_BOUNDS_ERROR = 'Argument index out of bounds';

    /**
     * Stub Provider instance created based on constructor values
     */
    public Object stub { get; private set; }
    /**
     * Raw call history, provided as a Map of method name to List of calls, containing child list of arguments passed
     * for each call
     * @deprecated Use of getMethod() and TLMocker.Method, TLMocker.Call types is preferred
     */
    public Map<String, List<List<Object>>> history { get; private set; }

    /**
     * Convenience method to initialize with a single value. Helps in scenarios where the single return value is a Map
     * of String => Object, which could be unintentionally treated as the return value map parameter in the constructor
     *
     * @param t Type of object to be mocked
     * @param retVal Single value that will be returned for any method call
     *
     * @return new TLMocker instance
     * @example
     * TLMocker mocker = TLMocker.createWithValue(MyClassToMock.class, 'A fake value');
     */
    public static TLMocker createWithValue(Type t, Object retVal) {
        return new TLMocker(t, null, retVal);
    }

    /**
     * Convenience method to initialize with a map of return values by method name.
     * Like createWithValue, added for clarity
     *
     * @param t Type of object to be mocked
     * @param retValMap Map of method name (as String) to return value
     *
     * @return new TLMocker instance
     * @example
     * Map<String, Object> returnValueMap = new Map<String, Object>{'aMethod' => 'aReturnValue', 'anotherMethod' => 32};
     * TLMocker mocker = TLMocker.createWithValueMap(MyClassToMock.class, returnValueMap);
     */
    public static TLMocker createWithValueMap(Type t, Map<String, Object> retValMap) {
        return new TLMocker(t, retValMap, null);
    }

    /**
     * Convenience method to initialize with a map of return values by method name and a default value for any method
     * not included in the map. Like createWithValue, provided for clarity.
     *
     * @param t Type of object to be mocked
     * @param retValMap Map of method name (as String) to return value
     * @param retVal Value that will be return for any method not included in retValMap
     *
     * @return new TLMocker instance
     * @example
     * Map<String, Object> returnValueMap = new Map<String, Object>{'aMethod' => 'aReturnValue', 'anotherMethod' => 32};
     * TLMocker mocker = TLMocker.createWithValueMapAndDefault(MyClassToMock.class, returnValueMap, 'a default fake value');
     */
    public static TLMocker createWithValueMapAndDefault(Type t, Map<String, Object> retValMap, Object retVal) {
        return new TLMocker(t, retValMap, retVal);
    }

    /**
     * Create a new TLMocker for the type specified
     *
     * @param  t Type of object to be mocked
     * @example
     * TLMocker mocker = new TLMocker(MyClassToMock.class);
     */
    public TLMocker(Type t) {
        this(t, null, null);
    }

    /**
     * Create a new TLMocker for the type specified
     *
     * @param  t        Type of object to be mocked
     * @param  retVal   Return value for all methods
     * @deprecated use of TLMocker.createWithValue() is preferred
     */
    public TLMocker(Type t, Object retVal) {
        this(t, null, retVal);
    }

    /**
     * Create a new TLMocker for the type specified
     *
     * @param  t            Type of object to be mocked
     * @param  retValMap    Map of Method Name to return value
     * @deprecated use of TLMocker.createWithValueMap() is preferred
     */
    public TLMocker(Type t, Map<String, Object> retValMap) {
        this(t, retValMap, null);
    }

    /**
     * Create a new TLMocker for the type specified
     *
     * @param  t            Type of object to be mocked
     * @param  retValMap    Map of Method Name to return value
     * @param  retVal       Fallback return value for any methods not found in retValMap
     * @deprecated use of TLMocker.createWithValueMapAndDefault() is preferred
     */
    public TLMocker(Type t, Map<String, Object> retValMap, Object retVal) {
        history = new Map<String, List<List<Object>>>();
        stub = Test.createStub(t, new UniversalStub(retValMap, retVal, history));
    }

    /**
     * Return method call history for the method name provided, wrapped in a Method object
     *
     * @param methodName Name of the method, as a string
     * @return Method object for the provided method
     * @example
     * TLMocker mocker = new TLMocker(MyClassToMock.class);
     * MyClassToMock mock = (MyClassToMock)mocker.stub;
     * mock.aMethod();
     * TLMocker.Method method = mocker.getMethod('aMethod'); // returns Method object for "aMethod"
     */
    public Method getMethod(String methodName) {
        return new Method(methodName, history.get(methodName));
    }

    /**
     * Generic StubProvider implementation
     */
    private class UniversalStub implements System.StubProvider {
        private Map<String, Object> retValMap;
        private Object retVal;
        private Map<String, List<List<Object>>> history;

        private UniversalStub(Map<String, Object> retValMap, Object retVal, Map<String, List<List<Object>>> history) {
            this.retValMap = (retValMap != null ? retValMap : new Map<String, Object>());
            this.retVal = retVal;
            this.history = history;
        }

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, Type returnType,
                List<Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {

            logMethodCall(stubbedMethodName, listOfArgs);

            Object returnValue = getReturnValue(stubbedMethodName);

            if(returnValue instanceof Exception) {
                throw (Exception)returnValue;
            }

            if(returnValue instanceof System.StubProvider) {
                return ((System.StubProvider)returnValue).handleMethodCall(stubbedObject, stubbedMethodName, returnType,
                        listOfParamTypes, listOfParamNames, listOfArgs);
            }

            return returnValue;
        }

        private Object getReturnValue(String stubbedMethodName) {
            if(retValMap.containsKey(stubbedMethodName)) {
                return retValMap.get(stubbedMethodName);
            }

            return retVal;
        }

        private void logMethodCall(String stubbedMethodName, List<Object> listOfArgs) {
            if(!history.containsKey(stubbedMethodName)) {
                history.put(stubbedMethodName, new List<List<Object>>());
            }

            history.get(stubbedMethodName).add(listOfArgs);
        }
    }

    /**
     * Wrapper class for methods, encapsulating call history
     *
     * @group TLMocker
     */
    public class Method {
        private String name;
        private List<List<Object>> history;

        private Method(String name, List<List<Object>> history) {
            this.name = name;
            this.history = history;
        }

        /**
         * Was the method called
         *
         * @return True if called, otherwise False
         * @example
         * TLMocker mocker = new TLMocker(MyClassToMock.class);
         * MyClassToMock mock = (MyClassToMock)mocker.stub;
         * mock.aMethod();
         * mocker.getMethod('aMethod').wasCalled(); // returns TRUE
         */
        public Boolean wasCalled() {
            return history != null;
        }

        /**
         * Number of times method was called
         *
         * @return Integer count of times method was called
         * @example
         * TLMocker mocker = new TLMocker(MyClassToMock.class);
         * MyClassToMock mock = (MyClassToMock)mocker.stub;
         * mock.aMethod();
         * mocker.getMethod('aMethod').getCallCount(); // returns 1
         */
        public Integer getCallCount() {
            if(!wasCalled()) {
                return 0;
            }

            return history.size();
        }

        /**
         * Get the list of all calls made with the method
         *
         * @return List of Call objects representing all calls to the method. Will return an empty list for methods
         * that were never called
         * @example
         * TLMocker mocker = new TLMocker(MyClassToMock.class);
         * MyClassToMock mock = (MyClassToMock)mocker.stub;
         * mock.aMethod();
         * List<TLMocker.Call> calls = mocker.getMethod('aMethod').getCalls(); // return list with one Call item
         */
        public List<Call> getCalls() {
            List<Call> allCalls = new List<Call>();

            if(history == null) {
                return allCalls;
            }

            for(Integer i = 0; i < history.size(); i++) {
                allCalls.add(getCall(i));
            }

            return allCalls;
        }

        /**
         * Returns the first call to the method. Provided for convenience.
         *
         * @return Call object for the first call, or throws TLMockerMethodException if method was never called
         * @example
         * TLMocker mocker = new TLMocker(MyClassToMock.class);
         * MyClassToMock mock = (MyClassToMock)mocker.stub;
         * mock.aMethod();
         * TLMocker.Call firstCall = mocker.getMethod('aMethod').getCall(); // returns TLMocker.Call for the first call
         */
        public Call getCall() {
            return getCall(0);
        }

        /**
         * Return the specified call to the method
         *
         * @param callIndex Index of the call to retrieve
         *
         * @return Call object for the specified call, or throws TLMockerMethodException if method was never called
         * or index provided is invalid
         * @example
         * TLMocker mocker = new TLMocker(MyClassToMock.class);
         * MyClassToMock mock = (MyClassToMock)mocker.stub;
         * mock.aMethod();
         * mock.aMethod();
         * TLMocker.Call firstCall = mocker.getMethod('aMethod').getCall(1); // returns TLMocker.Call for the 2nd call
         */
        public Call getCall(Integer callIndex) {
            if(history == null) {
                throw new TLMockerMethodException(METHOD_NOT_CALLED_ERROR);
            }

            if(callIndex >= history.size()) {
                throw new TLMockerMethodException(CALL_INDEX_OUT_OF_BOUNDS_ERROR);
            }

            return new Call(callIndex, history[callIndex]);
        }
    }

    /**
     * Wrapper for method call history, encapsulating arguments passed in the call
     *
     * @group TLMocker
     */
    public class Call {
        private Integer index;
        private List<Object> args;

        private Call(Integer index, List<Object> args) {
            this.index = index;
            this.args = args;
        }

        /**
         * Get the number of arguments passed in the method call
         *
         * @return Integer count of arguments
         * @example
         * TLMocker mocker = new TLMocker(MyClassToMock.class);
         * MyClassToMock mock = (MyClassToMock)mocker.stub;
         * mock.aMethod('aValue');
         * TLMocker.Call firstCall = mocker.getMethod('aMethod').getCall();
         * firstCall.getArgCount() // returns 1;
         */
        public Integer getArgCount() {
            return args.size();
        }

        /**
         * Did the method call pass any arguments
         *
         * @return True if arguments provided, otherwise False
         * @example
         * TLMocker mocker = new TLMocker(MyClassToMock.class);
         * MyClassToMock mock = (MyClassToMock)mocker.stub;
         * mock.aMethod();
         * TLMocker.Call firstCall = mocker.getMethod('aMethod').getCall();
         * firstCall.hasArgs() // returns FALSE
         */
        public Boolean hasArgs() {
            return getArgCount() > 0;
        }

        /**
         * Get the argument at index provided
         *
         * @param argIndex Index of argument
         *
         * @return Object value representing the argument passed, or throws TLMockerCallException if the call did not
         * include any arguments, or the argument index provided is invalid
         * @example
         * TLMocker mocker = new TLMocker(MyClassToMock.class);
         * MyClassToMock mock = (MyClassToMock)mocker.stub;
         * mock.aMethod('aValue', 'anotherValue');
         * TLMocker.Call firstCall = mocker.getMethod('aMethod').getCall();
         * (String)firstCall.getArg(1) // returns 'anotherValue'
         */
        public Object getArg(Integer argIndex) {
            if(!hasArgs()) {
                throw new TLMockerCallException(NO_ARGUMENTS_ERROR);
            }

            if(argIndex >= getArgCount()) {
                throw new TLMockerCallException(ARG_INDEX_OUT_OF_BOUNDS_ERROR);
            }

            return args[argIndex];
        }

        /**
         * Returns the first argument provided to the call
         *
         * @return Object value representing the argument passed, or throws TLMockerCallException if the call did not
         * include any arguments
         * @example
         * TLMocker mocker = new TLMocker(MyClassToMock.class);
         * MyClassToMock mock = (MyClassToMock)mocker.stub;
         * mock.aMethod('aValue');
         * TLMocker.Call firstCall = mocker.getMethod('aMethod').getCall();
         * (String)firstCall.getArg() // returns 'aValue'
         */
        public Object getArg() {
            return getArg(0);
        }

        /**
         * Get a list of all arguments provided in the method call
         *
         * @return List of Object values representing the arguments passed. Will return an empty list for calls where
         * no arguments were provided.
         * @example
         * TLMocker mocker = new TLMocker(MyClassToMock.class);
         * MyClassToMock mock = (MyClassToMock)mocker.stub;
         * mock.aMethod('aValue', 'anotherValue');
         * TLMocker.Call firstCall = mocker.getMethod('aMethod').getCall();
         * List<Object> args = firstCall.getArgs(); // returns list of arguments { 'aValue', 'anotherValue'}
         */
        public List<Object> getArgs() {
            return args;
        }
    }

    /**
     * Exception thrown in response to errors when querying Method objects, such as attempting to get a
     * specific call from a method that was never called
     *
     * @group TLMocker
     */
    public class TLMockerMethodException extends Exception {}
    /**
     * Exception thrown in response to errors when querying Call objects, such as attempting to get an
     * argument for a call where no arguments were provided
     *
     * @group TLMocker
     */
    public class TLMockerCallException extends Exception {}
}