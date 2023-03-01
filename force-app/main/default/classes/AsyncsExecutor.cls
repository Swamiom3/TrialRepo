/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class is helper for all Asyncs to avoid jobs limit
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION         DATE            AUTHOR              DETAIL
    1               6 Jun, 2021    Pawel Biszczak      Initial Deployment
**************************************************************************************************************************************/
public with sharing class AsyncsExecutor {
    private Type classType;
    private Map<String, Object> constructorValues;
    @TestVisible
    private Queueable queueableInstance;
    private String actionName;

    public AsyncsExecutor(Type classType, String actionName, Map<String, Object> constructorValues) {
        this.classType = classType;
        this.constructorValues = constructorValues;
        this.actionName = actionName;
    }

    public AsyncsExecutor(Type classType, Map<String, Object> constructorValues) {
        this.classType = classType;
        this.constructorValues = constructorValues;
        this.actionName = 'call';
    }

    public void execute() {
        if(classType == null || constructorValues == null) {
            return;
        }
        setupSchedulableInstance();
        executeInProperScope();
    }

    public void setupSchedulableInstance() {
        Callable extension = (Callable) classType.newInstance();
        queueableInstance = (Queueable) extension.call(actionName, constructorValues);
    }

    public void executeInProperScope() {
        if(Limits.getQueueableJobs() == 0) {
            System.enqueueJob(queueableInstance);
            return;
        }
        queueableInstance.execute(null);
    }

}