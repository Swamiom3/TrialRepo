/**
 * @description Base class aiding in the implemetnation of a Domain Model around SObject collections
 * 
 * Domain (software engineering). a set of common requirements, terminology, and functionality 
 * for any software program constructed to solve a problem in that field,
 * en.wikipedia.org/wiki/Domain_software_engineering
 *
 * "Domain Model, An object model of the domain that incorporates both behavior and data
 * At its worst business logic can be very complex. Rules and logic describe many different
 * cases and slants of behavior, and it's this complexity that objects were designed to work with...""
 * Martin Fowler, EAA Patterns
 * martinfowler.com/eaaCatalog/domainModel.html
 *
 * Some methods have been commented out for lack of use and code coverage
 *
 * @group Trigger Utilities
 * @author (Modified from FFLib repo)
 * @date 04-02-2016
 */

public virtual class SObjectDomain {

    // Retains the trigger tracking configuration used for each domain
    private static Map<String, TriggerEvent> triggerEventByClassName = new Map<String, TriggerEvent>();

    // Flag for tracking which domain instance is the top level domain
    private static Boolean tldFlag = true;

    // If true, then this SObjectDomain instance is the top level domain
    public Boolean isTld;

    // The data represented by this domain class
    public List<SObject> records;
    

    public SObjectDomain() {
        if (Trigger.isDelete) {
            records = Trigger.old.clone();
        } else {
            records = Trigger.new.clone();
        }
        isTld = SObjectDomain.requestTld();
    }

    /**
     * Constructs the domain class
     *
     * @param sObjectList A concrete list (e.g. List<Account> vs List<SObject>) of records
     */
    public SObjectDomain(List<SObject> sObjectList) {
        records = sObjectList.clone();
        isTld = SObjectDomain.requestTld();
    }

    // First domain instance to call this method is the top level domain
    public static Boolean requestTld() {
        if (!tldFlag) return false;
        tldFlag = false;
        return true;
    }

    /**
     * Calls the applicable override methods such as beforeInsert, beforeUpdate etc. based on trigger context
     * @param domainObject The domain containing the override methods to call
     */
    public static void triggerHandler(SObjectDomain domainObject) {
        // If this event has been disabled
        if(!getTriggerEvent(domainObject).isEnabled(Trigger.isBefore, Trigger.isAfter,
                Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete, Trigger.isUndelete)) {
            // Nothing to do
            return;
        }

        if(Trigger.isBefore) {
            if(Trigger.isInsert) domainObject.handleBeforeInsert();
            else if(Trigger.isUpdate) domainObject.handleBeforeUpdate(Trigger.oldMap);
            else if(Trigger.isDelete) domainObject.handleBeforeDelete();
        } else {
            if(Trigger.isInsert) domainObject.handleAfterInsert();
            else if(Trigger.isUpdate) domainObject.handleAfterUpdate(Trigger.oldMap);
            else if(Trigger.isDelete) domainObject.handleAfterDelete();
            else if(Trigger.isUndelete) domainObject.handleAfterUndelete();
        }
    }

    /**
     * When a test class mocks record, it will specify all the trigger parameters
     * @param domainObject The domain containing the override methods to call
     * @param isBefore The before context of the record
     * @param isAfter The after context of the record
     * @param isInsert The insert context of the record
     * @param isUpdate The update context of the record
     * @param isDelete The delete context of the record
     * @param isUnDelete The Undelete context of the record
     * @param newRecords The new records
     * @param oldRecordsMap The old record map
     */
    public static void triggerHandler(SObjectDomain domainObject,
            Boolean isBefore,
            Boolean isAfter,
            Boolean isInsert,
            Boolean isUpdate,
            Boolean isDelete,
            Boolean isUndelete,
            Map<Id, SObject> oldRecordsMap) {
        if(!getTriggerEvent(domainObject).isEnabled(isBefore, isAfter,
                isInsert, isUpdate, isDelete, isUndelete)) {
            return;
        }

        if(isBefore) {
            if(isInsert) domainObject.handleBeforeInsert();
            else if(isUpdate) domainObject.handleBeforeUpdate(oldRecordsMap);
            else if(isDelete) domainObject.handleBeforeDelete();
        } else {
            if(isInsert) domainObject.handleAfterInsert();
            else if(isUpdate) domainObject.handleAfterUpdate(oldRecordsMap);
            else if(isDelete) domainObject.handleAfterDelete();
            else if(isUndelete) domainObject.handleAfterUndelete();
        }
    }

    /**
     * @param domainClassInstance The domain class
     * @return The trigger event object instance related to the given domain class
     */
    public static TriggerEvent getTriggerEvent(Object domainClassInstance) {
        String domainClassName = String.valueOf(domainClassInstance).split(':')[0];
        if(!triggerEventByClassName.containsKey(domainClassName)) {
            triggerEventByClassName.put(domainClassName, new TriggerEvent());
        }
        return triggerEventByClassName.get(domainClassName);
    }

    /**
     * Base handler for the Apex Trigger event Before Insert
     */
    public void handleBeforeInsert() {
        onApplyDefaults();
        onBeforeInsert();
    }

    /**
     * Base handler for the Apex Trigger event Before Update
     */
    public void handleBeforeUpdate(Map<Id,SObject> existingRecords) {
        onBeforeUpdate(existingRecords);
    }

    /**
     * Base handler for the Apex Trigger event Before Delete
     */
    public void handleBeforeDelete() {
        onBeforeDelete();
    }

    /**
     * Base handler for the Apex Trigger event After Insert
     */
    public void handleAfterInsert() {
        onValidate();
        onAfterInsert();
    }

    /**
     * Base handler for the Apex Trigger event After Update
     */
    public void handleAfterUpdate(Map<Id,SObject> existingRecords) {
        onValidate(existingRecords);
        onAfterUpdate(existingRecords);
    }

    /**
     * Base handler for the Apex Trigger event After Delete
     */
    public void handleAfterDelete() {
        onAfterDelete();
    }

    /**
     * Base handler for the Apex Trigger event After Undelete
     */
    public void handleAfterUndelete() {
        onAfterUndelete();

        List<SObject> mergeLoserRecords = new List<SObject>();
        for (SObject record : records) {
            Id recordId = (Id) record.get('Id');
            if(recordId.getSObjectType() != Case.SObjectType){
                // MasterRecordId is only set during after delete merge triggers
                if (record.get('MasterRecordId') != null) {
                    mergeLoserRecords.add(record);
                }
            }
        }
        
        if(!mergeLoserRecords.isEmpty()){
            onAfterMergeDelete(mergeLoserRecords);
        }
    }

    /**
     * Override this to apply defaults to the records, this is called by the handleBeforeInsert method
     */
    public virtual void onApplyDefaults() { }

    /**
     * Override this to apply general validation to be performed during insert or update, called by the handleAfterInsert and handleAfterUpdate methods
     */
    public virtual void onValidate() {  }

    /**
     * Override this to apply validation to be performed during insert, called by the handleAfterUpdate method
     */
    public virtual void onValidate(Map<Id,SObject> existingRecords) { }

    /**
     * Override this to perform processing during the before insert phase, this is called by the handleBeforeInsert method
     */
    public virtual void onBeforeInsert() { }

    /**
     * Override this to perform processing during the before update phase, this is called by the handleBeforeUpdate method
     */
    public virtual void onBeforeUpdate(Map<Id,SObject> existingRecords) { }

    /**
     * Override this to perform processing during the before delete phase, this is called by the handleBeforeDelete method
     */
    public virtual void onBeforeDelete() { }

    /**
     * Override this to perform processing during the after insert phase, this is called by the handleAfterInsert method
     */
    public virtual void onAfterInsert() { }

    /**
     * Override this to perform processing during the after update phase, this is called by the handleAfterUpdate method
     */
    public virtual void onAfterUpdate(Map<Id,SObject> existingRecords) { }

    /**
     * Override this to perform processing during the after delete phase, this is called by the handleAfterDelete method
     */
    public virtual void onAfterDelete() { }

    /**
     * Override this to perform processing on the event of merge deletion of records
     */
    public virtual void onAfterMergeDelete(List<SObject> mergeLoserRecords) { }

    /**
     * Override this to perform processing during the after undelete phase, this is called by the handleAfterDelete method
     */
    public virtual void onAfterUndelete() { }

    /**
     * Contains the disabled/enabled status of all trigger events for some SObjectDomain instance
     */
    public class TriggerEvent {
        public Boolean BeforeInsertEnabled;
        public Boolean BeforeUpdateEnabled;
        public Boolean BeforeDeleteEnabled;

        public Boolean AfterInsertEnabled;
        public Boolean AfterUpdateEnabled;
        public Boolean AfterDeleteEnabled;
        public Boolean AfterUndeleteEnabled;

        public TriggerEvent() {
            if(Automation_Settings__c.getInstance().Triggers_Disabled__c) {
                this.disableAll();
            } else {
                this.enableAll();
            }
        }

        public TriggerEvent enableBeforeInsert() {BeforeInsertEnabled = true; return this;}
        public TriggerEvent enableBeforeUpdate() {BeforeUpdateEnabled = true; return this;}
        public TriggerEvent enableBeforeDelete() {BeforeDeleteEnabled = true; return this;}
        public TriggerEvent enableAfterInsert() {AfterInsertEnabled = true; return this;}
        public TriggerEvent enableAfterUpdate() {AfterUpdateEnabled = true; return this;}
        public TriggerEvent enableAfterDelete() {AfterDeleteEnabled = true; return this;}
        public TriggerEvent enableAfterUndelete() {AfterUndeleteEnabled = true; return this;}

        public TriggerEvent disableBeforeInsert() {BeforeInsertEnabled = false; return this;}
        public TriggerEvent disableBeforeUpdate() {BeforeUpdateEnabled = false; return this;}
        public TriggerEvent disableBeforeDelete() {BeforeDeleteEnabled = false; return this;}
        public TriggerEvent disableAfterInsert() {AfterInsertEnabled = false; return this;}
        public TriggerEvent disableAfterUpdate() {AfterUpdateEnabled = false; return this;}
        public TriggerEvent disableAfterDelete() {AfterDeleteEnabled = false; return this;}
        public TriggerEvent disableAfterUndelete(){AfterUndeleteEnabled = false; return this;}

        public TriggerEvent enableAll() {
            return this.enableAllBefore().enableAllAfter();
        }

        public TriggerEvent disableAll() {
            return this.disableAllBefore().disableAllAfter();
        }

        public TriggerEvent enableAllBefore() {
            return this.enableBeforeInsert().enableBeforeUpdate().enableBeforeDelete();
        }

        public TriggerEvent disableAllBefore() {
            return this.disableBeforeInsert().disableBeforeUpdate().disableBeforeDelete();
        }

        public TriggerEvent enableAllAfter() {
            return this.enableAfterInsert().enableAfterUpdate().enableAfterDelete().enableAfterUndelete();
        }

        public TriggerEvent disableAllAfter() {
            return this.disableAfterInsert().disableAfterUpdate().disableAfterDelete().disableAfterUndelete();
        }

        /**
         * Given current trigger event varibles, returns status of that event
         * @return True if the current trigger event is enabled, false otherwise
         */
        public Boolean isEnabled(Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete) {
            if(isBefore) {
                if(isInsert) return BeforeInsertEnabled;
                else if(isUpdate) return BeforeUpdateEnabled;
                else if(isDelete) return BeforeDeleteEnabled;
            } else if(isAfter) {
                if(isInsert)        return AfterInsertEnabled;
                else if(isUpdate)   return AfterUpdateEnabled;
                else if(isDelete)   return AfterDeleteEnabled;
                else if(isUndelete) return AfterUndeleteEnabled;
            }
            return true; // shouldnt ever get here!
        }
    }

}

/**
 * Copyright (c) 2012, FinancialForce.com, inc
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, 
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice, 
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice, 
 *      this list of conditions and the following disclaimer in the documentation 
 *      and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors 
 *      may be used to endorse or promote products derived from this software without 
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */