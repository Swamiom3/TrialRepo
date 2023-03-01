@isTest
private class SObjectTriggerHandlerTest {
    private static final String TRIGGER_CONTEXT_ERROR = 'Trigger handler called outside of Trigger execution';
    private static String lastMethodCalled;
    private static SObjectTriggerHandlerTest.SObjectTestHandler handler;
    static {
        handler = new SObjectTriggerHandlerTest.SObjectTestHandler();
        handler.isTriggerExecuting = true;
    }

    @isTest
    static void testBeforeInsert() {
        beforeInsertMode();
        handler.run();
        System.assertEquals(
            'beforeInsert',
            lastMethodCalled,
            'last method should be beforeInsert'
        );
    }

    @isTest
    static void testBeforeUpdate() {
        beforeUpdateMode();
        handler.run();
        System.assertEquals(
            'beforeUpdate',
            lastMethodCalled,
            'last method should be beforeUpdate'
        );
    }

    @isTest
    static void testBeforeDelete() {
        beforeDeleteMode();
        handler.run();
        System.assertEquals(
            'beforeDelete',
            lastMethodCalled,
            'last method should be beforeDelete'
        );
    }

    @isTest
    static void testAfterInsert() {
        afterInsertMode();
        handler.run();
        System.assertEquals(
            'afterInsert',
            lastMethodCalled,
            'last method should be afterInsert'
        );
    }

    @isTest
    static void testAfterUpdate() {
        afterUpdateMode();
        handler.run();
        System.assertEquals(
            'afterUpdate',
            lastMethodCalled,
            'last method should be afterUpdate'
        );
    }

    @isTest
    static void testAfterDelete() {
        afterDeleteMode();
        handler.run();
        System.assertEquals(
            'afterDelete',
            lastMethodCalled,
            'last method should be afterDelete'
        );
    }

    @isTest
    static void testAfterUndelete() {
        afterUndeleteMode();
        handler.run();
        System.assertEquals(
            'afterUndelete',
            lastMethodCalled,
            'last method should be afterUndelete'
        );
    }

    @isTest
    static void testNonTriggerContext() {
        try {
            handler.run();
            System.assert(false, 'the handler ran but should have thrown');
        } catch (SObjectTriggerHandler.SObjectTriggerHandlerException te) {
            System.assertEquals(
                TRIGGER_CONTEXT_ERROR,
                te.getMessage(),
                'the exception message should match'
            );
        } catch (Exception e) {
            System.assert(
                false,
                'the exception thrown was not expected: ' +
                e.getTypeName() +
                ': ' +
                e.getMessage()
            );
        }
    }
    // instance method tests

    @isTest
    static void testLoopCount() {
        beforeInsertMode();

        // set the max loops to 2
        handler.setMaxLoopCount(2);
        handler.setThrowException(true);
        handler.run();
        handler.run();

        // clear the tests
        resetTest();

        try {
            // try running it. This should exceed the limit.
            handler.run();
            System.assert(
                false,
                'the handler should throw on the 3rd run when maxloopcount is 3'
            );
        } catch (SObjectTriggerHandler.SObjectTriggerHandlerException te) {
            System.assertEquals(null, lastMethodCalled, 'last method should be null');
        } catch (Exception e) {
            System.assert(
                false,
                'the exception thrown was not expected: ' +
                e.getTypeName() +
                ': ' +
                e.getMessage()
            );
        }

        // clear the tests
        resetTest();

        // now clear the loop count
        handler.clearMaxLoopCount();

        try {
            // re-run the handler. We shouldn't throw now.
            handler.run();
            System.assertEquals(
                'beforeInsert',
                lastMethodCalled,
                'last method should be beforeInsert'
            );
        } catch (SObjectTriggerHandler.SObjectTriggerHandlerException te) {
            System.assert(
                false,
                'running the handler after clearing the loop count should not throw'
            );
        } catch (Exception e) {
            System.assert(
                false,
                'the exception thrown was not expected: ' +
                e.getTypeName() +
                ': ' +
                e.getMessage()
            );
        }
    }

    @isTest
    static void testCanExecuteHandler() {
        beforeInsertMode();
        System.assertEquals(false, SObjectTriggerHandler.loopCountMap.containsKey(handler.handlerName), 'LoopCountMap should be empty');
        handler.canExecuteHandler();
        System.assertEquals(true, SObjectTriggerHandler.loopCountMap.containsKey(handler.handlerName), 'LoopCountMap should contain handler');
        beforeUpdateMode();
        handler.canExecuteHandler();
        System.assertEquals(2, SObjectTriggerHandler.loopCountMap.get(handler.handlerName).values().size(), 'LoopCountMap should contain 2 values - for insert and update context');
    }

    @isTest
    static void testLoopCountClass() {
        SObjectTriggerHandler.LoopCount lc = new SObjectTriggerHandler.LoopCount();
        System.assertEquals(5, lc.getMax(), 'max should be five on init');
        System.assertEquals(0, lc.getCount(), 'count should be zero on init');

        lc.increment();
        System.assertEquals(1, lc.getCount(), 'count should be 1');
        System.assertEquals(
            false,
            lc.exceeded(),
            'should not be exceeded with count of 1'
        );

        lc.increment();
        lc.increment();
        lc.increment();
        lc.increment();
        System.assertEquals(5, lc.getCount(), 'count should be 5');
        System.assertEquals(
            false,
            lc.exceeded(),
            'should not be exceeded with count of 5'
        );

        lc.increment();
        System.assertEquals(6, lc.getCount(), 'count should be 6');
        System.assertEquals(
            true,
            lc.exceeded(),
            'should be exceeded with count of 6'
        );
    }

    @isTest
    static void testGetHandlerName() {
        beforeInsertMode();
        System.assertEquals(
            'SObjectTestHandler',
            handler.getHandlerName(),
            'handler name should match class name'
        );
    }

    @isTest
    static void testreturnOnlyObjectWithValidRT() {
        SObjectTriggerHandler sObjTrHandler = new SObjectTriggerHandler();
        try {
            sObjTrHandler.returnOnlyObjectWithValidRT(null, null, null);
        } catch (SObjectTriggerHandler.SObjectTriggerHandlerException te) {
            System.assert(
                true,
                'should throw exception Trigger handler check RT is not properly defined'
            );
        } 
        Case dummyCase = new Case();
        List<SObject> results = sObjTrHandler.returnOnlyObjectWithValidRT(Case.getSobjecttype(), 
                                                                           new List<sObject>{dummyCase}, 
                                                                           new Set<String>{'no such a RT'});
        System.assertEquals(true, results.isEmpty(),'No valid records should be passed');                                                                   
    }

    @isTest
    static void testVirtualMethods() {
        SObjectTriggerHandler h = new SObjectTriggerHandler();
        h.beforeInsert();
        h.beforeUpdate();
        h.beforeDelete();
        h.afterInsert();
        h.afterUpdate();
        h.afterDelete();
        h.afterUndelete();
    }
    
    @isTest
    private static void testForcedExecution() {
        beforeInsertMode();
        handler.forceExecution();
        System.assert(
            handler.isForcedExecution(),
            'Execution should be forced'
        );
    }
    
    @isTest
    private static void verifyGetRunTriggers(){        
        Boolean triggerRuns = handler.isExecutable();
        System.assertEquals(true, triggerRuns, 'triggerRuns default value shoule be true');
        MetadataDrivenTriggerHandler.disableExecution();
        triggerRuns = handler.isExecutable();
        System.assertEquals(false, triggerRuns, 'triggerRuns value shoule be false');
        MetadataDrivenTriggerHandler.enableExecution();
        triggerRuns = handler.isExecutable();
        System.assertEquals(true, triggerRuns, 'triggerRuns value shoule be true');
    }
    
    private static void resetTest() {
        lastMethodCalled = null;
    }
    
    // modes for testing
    private static void beforeInsertMode() {
        handler.setTriggerContext('before insert', true);
    }
    private static void beforeUpdateMode() {
        handler.setTriggerContext('before update', true);
    }
    private static void beforeDeleteMode() {
        handler.setTriggerContext('before delete', true);
    }
    private static void afterInsertMode() {
        handler.setTriggerContext('after insert', true);
    }
    private static void afterUpdateMode() {
        handler.setTriggerContext('after update', true);
    }
    private static void afterDeleteMode() {
        handler.setTriggerContext('after delete', true);
    }
    private static void afterUndeleteMode() {
        handler.setTriggerContext('after undelete', true);
    }

    private class SObjectTestHandler extends SObjectTriggerHandler {
        public override void beforeInsert() {
            SObjectTriggerHandlerTest.lastMethodCalled = 'beforeInsert';
        }
        public override void beforeUpdate() {
            SObjectTriggerHandlerTest.lastMethodCalled = 'beforeUpdate';
        }
        public override void beforeDelete() {
            SObjectTriggerHandlerTest.lastMethodCalled = 'beforeDelete';
        }
        public override void afterInsert() {
            SObjectTriggerHandlerTest.lastMethodCalled = 'afterInsert';
        }
        public override void afterUpdate() {
            SObjectTriggerHandlerTest.lastMethodCalled = 'afterUpdate';
        }
        public override void afterDelete() {
            SObjectTriggerHandlerTest.lastMethodCalled = 'afterDelete';
        }
        public override void afterUndelete() {
            SObjectTriggerHandlerTest.lastMethodCalled = 'afterUndelete';
        }
    }
}