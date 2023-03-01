@isTest
public class MethodTest {
    @isTest
    public static void testMethodEnumclass() {
        Test.startTest();
        System.assertEquals('GET', String.valueOf(Method.GET));
        System.assertEquals('POST', String.valueOf(Method.POST));
        System.assertEquals('PUT', String.valueOf(Method.PUT));
        Test.stopTest();
    }
}