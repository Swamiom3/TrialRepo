/************************************************************************************************************************************
    Author      :   Maciej Miłosz	
    Description :   Based on Simon Goodyear trigger framework
                    https://developer.salesforce.com/blogs/2019/08/live-coding-with-simon-goodyear.html
                    This is a base class for each SObject specific trigger hanlders. This class must ve extended in order
                    for the trigger hanlder to be executed.
                    Handlers bypass and recursion control will be used after all triggers are migrated to this framework
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           13/08/2020          Maciej Miłosz           Trigger redesign
    2           15/04/2021          Liubomyr Mishchykha     Implemented DML consolidation
**************************************************************************************************************************************/
public virtual class SObjectTriggerHandler {
    @TestVisible
    private static Map<String, Map<TriggerContext, LoopCount>> loopCountMap;
    private static Set<String> bypassedHandlers;
    @TestVisible
    private static Boolean isExecutable = true;
    @TestVisible
    protected DmlConsolidator dml;
    @TestVisible
    protected DmlConsolidatorPartialSuccess dmlPartial;

    static {
		System.debug('sObjectcls :- static block');
        loopCountMap = new Map<String, Map<TriggerContext, LoopCount>>();
        bypassedHandlers = new Set<String>();
    }

    // the current context of the trigger, overridable in tests
    @TestVisible
    protected TriggerContext context;
    @TestVisible
    private Boolean isTriggerExecuting;
    @TestVisible
    private String handlerName;
    @TestVisible
    private Boolean throwException;
    @TestVisible
    private Boolean isForcedExecution = false;

    public SObjectTriggerHandler() {
	System.debug('sObjectcls :- SObjectTriggerHandler constructor block');
        this.setTriggerContext();
        this.throwException = false;
        this.handlerName = getHandlerName();
    }

    // main method that will be called during execution
    public virtual void run() {
		System.debug('sObjectcls :- run METHOD ');
        if(!validateRun()){
		System.debug('sObjectcls :- run if  METHOD block ');
            return;
        }
        if(!canExecuteHandler()){
		//System.debug('sObjectcls :- run if canExecuteHandler  METHOD block ');
            if(throwException){
                throw new SObjectTriggerHandlerException(
                    'Trigger recursion control: Execution limit exceeded'
                ); 
            }
            return;
        }

        switch on this.context {
            when BEFORE_INSERT {
				//System.debug('sObjectcls:- switch context before insert');
                this.beforeInsert();
            }
            when BEFORE_UPDATE {
				//System.debug('sObjectcls:- switch context BEFORE_UPDATE');
                this.beforeUpdate();
            }
            when BEFORE_DELETE {
				//System.debug('sObjectcls:- switch context BEFORE_DELETE');
                this.beforeDelete();
            }
            when AFTER_INSERT {
                //System.debug('sObjectcls:- switch context AFTER_INSERT');
                this.afterInsert();
            }
            when AFTER_UPDATE {
                //System.debug('sObjectcls:- switch context AFTER_UPDATE');
                this.afterUpdate();
            }
            when AFTER_DELETE {
                //System.debug('sObjectcls:- switch context AFTER_DELETE');
                this.afterDelete();
            }
            when AFTER_UNDELETE {
               // System.debug('sObjectcls:- switch context AFTER_UNDELETE');
                this.afterUndelete();
            }
        }
    }

    public void forceExecution(){
        System.debug('sObjectcls :- forceExecution method ');
        this.isForcedExecution = true;
    }

    public Boolean isForcedExecution(){
        System.debug('sObjectcls :- isForcedExecution method ');
        return this.isForcedExecution;
    }

    public void setThrowException(Boolean throwException){
        System.debug('sObjectcls :- setThrowException method ');
        this.throwException = throwException;
    }

    public void setMaxLoopCount(Integer max) {
        System.debug('sObjectcls :- setMaxLoopCount method ');
        if (!SObjectTriggerHandler.loopCountMap.containsKey(handlerName)) {
            System.debug('sObjectcls :- setMaxLoopCount if method block ');
            SObjectTriggerHandler.loopCountMap.put(handlerName, new Map<TriggerContext, LoopCount>{context => new LoopCount(max)});
        } else {
            System.debug('sObjectcls :- setMaxLoopCount else method block ');
            Map<TriggerContext, LoopCount> contextToLoopCountMap = SObjectTriggerHandler.loopCountMap.get(handlerName);
            if(!contextToLoopCountMap.containsKey(context)){
                System.debug('sObjectcls :- setMaxLoopCount else inside if method block ');
                contextToLoopCountMap.put(context, new LoopCount(max));
            } else {
                System.debug('sObjectcls :- setMaxLoopCount else method block ');
                contextToLoopCountMap.get(context).setMax(max);
            }
        }
    }

    public void clearMaxLoopCount() {
        System.debug('sObjectcls :- clearMaxLoopCount method block ');
        this.setMaxLoopCount(-1);
    }

    /*
    *   This is a trigger handlers controll
    *   Can be used to supress whole trigger handlers and should replace TriggerSettings
    *
    */
    public static void bypass(String handlerName) {
		System.debug('sObjectcls :- bypass method block ');        
        SObjectTriggerHandler.bypassedHandlers.add(handlerName);
    }

    public static void clearBypass(String handlerName) {
        System.debug('sObjectcls :- clearBypass method block '); 
        SObjectTriggerHandler.bypassedHandlers.remove(handlerName);
    }

    public static void clearLoopCount(){
         System.debug('sObjectcls :- clearLoopCount method block ');
        SObjectTriggerHandler.loopCountMap = new Map<String, Map<TriggerContext, LoopCount>>();
    }

    public static void clearLoopCount(String handlerName){
        System.debug('sObjectcls :- clearLoopCount method block with parameter');
        if(!SObjectTriggerHandler.loopCountMap.containsKey(handlerName)){
            System.debug('sObjectcls :- clearLoopCount method if block with parameter');
            return;
        }
        SObjectTriggerHandler.loopCountMap.put(handlerName, new Map<TriggerContext, LoopCount>());
    }

    public static Boolean isBypassed(String handlerName) {
        System.debug('sObjectcls :- isBypassed method block with parameter');
        return SObjectTriggerHandler.bypassedHandlers.contains(handlerName);
    }

    public static void clearAllBypasses() {
        System.debug('sObjectcls :- clearAllBypasses method block');
        SObjectTriggerHandler.bypassedHandlers.clear();
    }

    public static void enableExecution() {
        System.debug('sObjectcls :- enableExecution method block');
        SObjectTriggerHandler.isExecutable = true;
    }

    @TestVisible
    protected Boolean isExecutable() {
        System.debug('sObjectcls :- isExecutable method block');
        return SObjectTriggerHandler.isExecutable;
    }

    public static void disableExecution() {
        System.debug('sObjectcls :- disableExecution method block');
        SObjectTriggerHandler.isExecutable = false;
    }

    @TestVisible
    private void setTriggerContext() {
        System.debug('sObjectcls :- setTriggerContext method block');
        this.setTriggerContext(null, false);
    }

    @TestVisible
    private void setTriggerContext(String ctx, Boolean testMode) {
        System.debug('sObjectcls :- setTriggerContext method block with parameter string ctx and boolean testmode');
        if (!Trigger.isExecuting && !testMode) {
            System.debug('sObjectcls :- setTriggerContext method if block with parameter string ctx and boolean testmode');
            this.isTriggerExecuting = false;
            return;
        } else {
            System.debug('sObjectcls :- setTriggerContext method else block with parameter string ctx and boolean testmode');
            this.isTriggerExecuting = true;
        }

        if (ctx != null) {
            //System.debug('sObjectcls :- ctx is not method ');
            switch on ctx {
                when 'before insert' {
                    System.debug('sObjectcls:- switch CTX context BEFORE_insert');
                    this.context = TriggerContext.BEFORE_INSERT;
                }
                when 'before update' {
                    System.debug('sObjectcls:- switch CTX context BEFORE_update');
                    this.context = TriggerContext.BEFORE_UPDATE;
                }
                when 'before delete' {
                    System.debug('sObjectcls:- switch CTX context BEFORE_delete');
                    this.context = TriggerContext.BEFORE_DELETE;
                }
                when 'after insert' {
                    System.debug('sObjectcls:- switch CTX context after_insert');
                    this.context = TriggerContext.AFTER_INSERT;
                }
                when 'after update' {
                    System.debug('sObjectcls:- switch CTX context after update');
                    this.context = TriggerContext.AFTER_UPDATE;
                }
                when 'after delete' {
                    System.debug('sObjectcls:- switch CTX context after delete');
                    this.context = TriggerContext.AFTER_DELETE;
                }
                when 'after undelete' {
                    System.debug('sObjectcls:- switch CTX context after undelete');
                    this.context = TriggerContext.AFTER_UNDELETE;
                }
            }
        } else {
            switch on Trigger.operationType {
                when BEFORE_INSERT {
                    System.debug('sObjectcls:- operationType switch CTX else context before insert');
                    this.context = TriggerContext.BEFORE_INSERT;
                }
                when BEFORE_UPDATE {
                    System.debug('sObjectcls:- operationType switch CTX else context before update');
                    this.context = TriggerContext.BEFORE_UPDATE;
                }
                when BEFORE_DELETE {
                    System.debug('sObjectcls:-operationType switch CTX context before delete');
                    this.context = TriggerContext.BEFORE_DELETE;
                }
                when AFTER_INSERT {
                    System.debug('sObjectcls:-operationType switch CTX else context after insert');
                    this.context = TriggerContext.AFTER_INSERT;
                }
                when AFTER_UPDATE {
                    System.debug('sObjectcls:-operationType switch CTX else context after update');
                    this.context = TriggerContext.AFTER_UPDATE;
                }
                when AFTER_DELETE {
                    System.debug('sObjectcls:-operationType switch CTX else context after delete');
                    this.context = TriggerContext.AFTER_DELETE;
                }
                when AFTER_UNDELETE {
                    System.debug('sObjectcls:-operationType switch CTX else context after undelete');
                    this.context = TriggerContext.AFTER_UNDELETE;
                }
            }
        }
    }

    // increment the loop count and check if can execute handler
    @TestVisible
    private Boolean canExecuteHandler() {
        if (isForcedExecution()) {
            System.debug('sObjectcls:- canExecuteHandler if block isForcedExecution');
            return true;
        }
        if (SObjectTriggerHandler.loopCountMap.containsKey(handlerName)) {
            System.debug('sObjectcls:- loopCountMap if block handlerName');
            Map<TriggerContext, LoopCount> contextToLoopCountMap = SObjectTriggerHandler.loopCountMap.get(handlerName);
            if(!contextToLoopCountMap.containsKey(context)){
                System.debug('sObjectcls:- contextToLoopCountMap if block ');
                setMaxLoopCount(2);
                return !contextToLoopCountMap.get(context).increment();
            } else {
                System.debug('sObjectcls:- contextToLoopCountMap else block ');
                return !contextToLoopCountMap.get(context).increment();
            }
        } else {
            setMaxLoopCount(2);
            System.debug('sObjectcls:- setMaxLoopCount(2); block ');
            return !SObjectTriggerHandler.loopCountMap.get(handlerName).get(context).increment();
        }
    }

    //return list of record which are in correct Record type
    public List<SObject> returnOnlyObjectWithValidRT(Schema.SObjectType objType, List<SObject> objectsTocheck, Set<String> validRecordTypes) {
        if (objType ==  null || objectsTocheck == null || objectsTocheck.isEmpty() || validRecordTypes == null || validRecordTypes.isEmpty()) {
            System.debug('sObjectcls:- returnOnlyObjectWithValidRT if block ');
            throw new SObjectTriggerHandlerException(
                'Trigger handler check RT is not properly defined for ' + handlerName
            );
        }
        System.debug('sObjectcls:- returnOnlyObjectWithValidRT after if block ');
        List<SObject> objectWithValidRT = new List<SObject>();
        Map<Id, Schema.RecordTypeInfo> rtMap = objType.getDescribe().getRecordTypeInfosById();
        for (SObject record : objectsTocheck) {
            Id currentRecordRTId = (Id)record?.get('RecordTypeId');
            if (currentRecordRTId != null
                && rtMap.containsKey(currentRecordRTId)
                && validRecordTypes.contains(rtMap.get(currentRecordRTId).getName())) {
                objectWithValidRT.add(record);
            }
            
        }
        return objectWithValidRT;
    }

    // make sure this trigger should continue to run
    @TestVisible
    private Boolean validateRun() {
        if (!this.isTriggerExecuting || this.context == null) {
            System.debug('sObjectcls:- validateRun mothod ');
            throw new SObjectTriggerHandlerException(
                'Trigger handler called outside of Trigger execution'
            );
        }
        if(SObjectTriggerHandler.bypassedHandlers.contains(handlerName)){
            System.debug('sObjectcls:- bypassedHandlers mothod ');
            return false;
        }
        return true;
    }

    @TestVisible
    private String getHandlerName() {
        System.debug('sObjectcls:- getHandlerName mothod ');
        return String.valueOf(this).substring(0, String.valueOf(this).indexOf(':'));
    }

    // context-specific methods for override
    @TestVisible
    protected virtual void beforeInsert() {
        System.debug('sObjectcls:- beforeInsert mothod ');
    }
    @TestVisible
    protected virtual void beforeUpdate() {
        System.debug('sObjectcls:- beforeUpdate mothod ');
    }
    @TestVisible
    protected virtual void beforeDelete() {
        System.debug('sObjectcls:- beforeDelete mothod ');
    }
    @TestVisible
    protected virtual void afterInsert() {
        System.debug('sObjectcls:- afterInsert mothod ');
    }
    @TestVisible
    protected virtual void afterUpdate() {
        System.debug('sObjectcls:- afterUpdate mothod ');
    }
    @TestVisible
    protected virtual void afterDelete() {
        System.debug('sObjectcls:- afterDelete mothod ');
    }
    @TestVisible
    protected virtual void afterUndelete() {
        System.debug('sObjectcls:- afterUndelete mothod ');
    }

    // inner class for managing the loop count per handler
    @TestVisible
    private class LoopCount {
        
        private Integer max;
        private Integer count;

        public LoopCount() {
            this.max = 5;
            this.count = 0;
        }
		//System.debug('sObjectcls:- after LoopCount mothod ');

        public LoopCount(Integer max) {
             System.debug('sObjectcls:- LoopCount method with paramater integer max ');
            this.max = max;
            this.count = 0;
        }

        public Boolean increment() {
            System.debug('sObjectcls:- increment method  ');
            this.count++;
            return this.exceeded();
        }

        public Boolean exceeded() {
            if (this.max < 0) {
                System.debug('sObjectcls:- exceeded method  if ');
                return false;
            }
            if (this.count > this.max) {
                System.debug('sObjectcls:- exceeded if 2 method  ');
                return true;
            }
            return false;
        }

        public Integer getMax() {
            System.debug('sObjectcls:- getMax method ');
            return this.max;
        }

        public Integer getCount() {
            System.debug('sObjectcls:- getCount method  ');
            return this.count;
        }

        public void setMax(Integer max) {
            System.debug('sObjectcls:- setMax method   ');
            this.max = max;
        }
    }

    @TestVisible
    protected virtual SObjectTriggerHandler registerDmlConsolidator(DmlConsolidator dmlConsolidator) {
        if (dmlConsolidator instanceof DmlConsolidatorPartialSuccess) {
            System.debug('sObjectcls:- registerDmlConsolidator method  ');
            dmlPartial = (DmlConsolidatorPartialSuccess) dmlConsolidator;
        } else {
            System.debug('sObjectcls:- LoopCount method with paramater integer max ');
            dml = dmlConsolidator;
        }
        return this;
    }

    @TestVisible 
    public enum TriggerContext {
        
        BEFORE_INSERT,
        BEFORE_UPDATE,
        BEFORE_DELETE,
        AFTER_INSERT,
        AFTER_UPDATE,
        AFTER_DELETE,
        AFTER_UNDELETE
        //System.debug('sObjectcls:- TriggerContext method');
    }

    public class SObjectTriggerHandlerException extends Exception {
        //System.debug('sObjectcls:- SObjectTriggerHandlerException method  ');
    }
}