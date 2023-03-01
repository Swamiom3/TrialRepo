/*************************************************************************************************************************************
 Author      :   Maciej Milosz
 Description :   This class is providing MockService interface
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               7 Apr, 2021    Pawel Biszczak       Initial Deployment
 **************************************************************************************************************************************/
@isTest
public class MockService {
    private MockService() {}

    public static MockProvider getInstance(Map<String, Object> stubbedMethodMap) {
        return new MockProvider (stubbedMethodMap);
    }

    public static Object createMock(Type typeToMock, Map<String, Object> stubbedMethodMap) {
        return Test.createStub(typeToMock, MockService.getInstance(stubbedMethodMap));
    }
}