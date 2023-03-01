/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides test coverage for AsyncsExecutor
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION         DATE            AUTHOR              DETAIL
    1               6 Jun, 2021    Pawel Biszczak      Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class AsyncsExecutorTest {

    private static final String PARAMETER_TO_TEST = 'Test Parameter';

    @isTest
    static void testAsyncsWithNoActionParameter(){
        Test.startTest();
        AsyncsExecutor asyncsExecutor = new AsyncsExecutor(
                                                AsyncsExecutorCallableClassTest.class,
                                                new Map<String, Object>{
                                                        'parameterToTest'=> PARAMETER_TO_TEST
                                                });
        asyncsExecutor.execute();
        Test.stopTest();

        List<Task> tasks = [SELECT Id, Subject
                            FROM Task
                            WHERE Subject =: PARAMETER_TO_TEST];
        System.assertEquals(1, tasks.size(), 'Should contain one record');
    }

    @isTest
    static void testAsyncsWithActionParameter(){
        Test.startTest();
        AsyncsExecutor asyncsExecutor = new AsyncsExecutor(
                                                AsyncsExecutorCallableClassTest.class,
                                                'testActionName',
                                                new Map<String, Object>{
                                                        'parameterToTest'=> PARAMETER_TO_TEST
                                                });
        asyncsExecutor.execute();
        Test.stopTest();

        List<Task> tasks = [SELECT Id, Subject
                            FROM Task
                            WHERE Subject =: PARAMETER_TO_TEST];
        System.assertEquals(1, tasks.size(), 'Should contain one record');
    }

}