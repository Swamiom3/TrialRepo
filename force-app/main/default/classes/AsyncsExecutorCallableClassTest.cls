/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides template class for Testing purpose and UnitTest coverage, indepdenend from Queueable classes scope
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION         DATE            AUTHOR              DETAIL
    1               6 Jun, 2021    Pawel Biszczak      Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class AsyncsExecutorCallableClassTest implements Queueable, Callable {
    @TestVisible
    private String parameterToTest;

    public AsyncsExecutorCallableClassTest(){}

    public AsyncsExecutorCallableClassTest(String parameterToTest){
        this.parameterToTest = parameterToTest;
    }

    public AsyncsExecutorCallableClassTest call(String action, Map<String, Object> args) {
        return new AsyncsExecutorCallableClassTest((String)args.get('parameterToTest'));
    }

    public void execute(QueueableContext context) {
        List<Task> tasks = (List<Task>) MockTestingUtility.getRecords(new Map<String, Object>{'objectName' => 'Task', 'numberOfRecords' => 1},
                                                                        false,
                                                                        new Map<String, String>{ 'Status' => 'Not Started'});
        tasks[0].Subject = parameterToTest;
        insert tasks;
    }
}