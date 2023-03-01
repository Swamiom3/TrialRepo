/*************************************************************************************************************************************
    Author      :   Maciej Milosz
    Description :   This class is providing Mocks for test classes data
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR            DETAIL
    1          7 Apr, 2021    Pawel Biszczak    Initial Deployment
**************************************************************************************************************************************/
@isTest
public class MockProvider implements System.StubProvider {
    private Map<String, Object> stubbedMethodMap;

    public MockProvider(Map<String, Object> stubbedMethodMap) {
        this.stubbedMethodMap = stubbedMethodMap;
    }

    public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                                   Type returnType, List<Type> parametersTypes,
                                   List<String> parametersNames, List<Object> arguments) {

        return stubbedMethodMap.get(stubbedMethodName);
    }
}