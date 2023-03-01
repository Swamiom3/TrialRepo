/**
 * @description class to route cases. Uses custom metadata records to determine how to route cases.
 * @note all maps should use all lowercase keys to simplify data input and retrieval
 * @name trac_CaseRouting
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-08-14
 */

public class trac_CaseRouting {
    // final routing message
    private final static String MESSAGE_CASE_ROUTED_TO = 'Case has been routed to the queue `{0} [{1}]`';

    // main container for all cases that are to be routed
    private static Map<String, CaseWrapper> caseObjectByIdx = new Map<String, CaseWrapper>();


    /**
     * @description main algorythm to determine routing based on the custom routing metadata
     * @note as an examplt for a case record myCase and the field - myCase.Primary_Account__r.Account_Value__c
     *       any reference to objectName would be the sobjecttype (Account)
     *       any reference to caseField would be the lookup from account to the sobject (Primary_Account__c)
     *       any reference to objectField would be a field that reside on a lookup to case (Account_Value__c)
     * @param cases list of case records to be routed
     */
    public static void route(List<Case> cases) {
        List<Case> casesToRoute = TLTrigger.filterByFieldCriteria(cases, Case.Route__c, new List<Object>{
                true
        });

        // exit if no routing is to take place
        if (casesToRoute.size() < 1) return;

        TLLog.saveLoggingLevel.put(LoggingLevel.INFO, true);
        TLLog.saveLoggingLevel.put(LoggingLevel.WARN, true);

        // get all necessary fields and relationships for the routing criteria
        Set<String> fieldSet = trac_CaseRoutingHelper.getRoutingField();
        fieldSet.add('escalate__c');  // used for escalation routing

        // get all fields that need data (from index setting)
        Map<String, Set<String>> sobjToFields = new Map<String, Set<String>>();
        Map<String, FieldWrapper> ogFieldMap = new Map<String, FieldWrapper>();
        for (String field : fieldSet) {
            // collect all the fields that are lookups
            if (field.contains('.')) {
                List<String> fields = field.split('\\.', 2);
                if (fields.size() > 1) {
                    String sobj = trac_CaseRoutingHelper.getSObectFromField(fields[0]);
                    Set<String> tempFields = new Set<String>();
                    tempFields.add(fields[1]);
                    if (sobjToFields.keySet().contains(sobj)) {
                        tempFields.addAll(sobjToFields.get(sobj));
                    }
                    sobjToFields.put(sobj, tempFields);

                    FieldWrapper fieldWrap = new FieldWrapper();
                    fieldWrap.CaseField = trac_CaseRoutingHelper.relationshipToField(fields[0]);
                    fieldWrap.ObjectName = sobj;
                    fieldWrap.ObjectField = fields[1];

                    ogFieldMap.put(field, fieldWrap);
                }
            }
        }


        // get the ids of the related objects
        Map<String, Set<String>> sobjectNameToIds = new Map<String, Set<String>>();
        for (Case cs : casesToRoute) {
            for (FieldWrapper fieldWrap : ogFieldMap.values()) {
                Set<String> actualIds = new Set<String>();
                if (cs.get(fieldWrap.CaseField) != null) {
                    actualIds.add(cs.get(fieldWrap.CaseField).toString());
                    if (sobjectNameToIds.get(fieldWrap.ObjectName) != null) {
                        actualIds.addAll(sobjectNameToIds.get(fieldWrap.ObjectName));
                    }
                    sobjectNameToIds.put(fieldWrap.ObjectName, actualIds);
                }
            }
        }


        // query the data from related objects that relate to the case records
        Map<String, Map<String, SObject>> objectNameToIdToRecord = new Map<String, Map<String, SObject>>();
        for (String key : sobjToFields.keySet()) {
            Map<String, SObject> sobjectById = new Map<String, SObject>();
            List<String> fields = new List<String>(sobjToFields.get(key));
            List<String> ids = new List<String>(sobjectNameToIds.get(key));
            if (ids.size() > 0) {
                String query = 'SELECT Id,' + String.join(fields, ',') + ' ' +
                        'FROM ' + (key.substring(key.length() - 2, key.length()) == 'Id'
                            ? key.substring(0, key.length() - 2)
                            : key) + ' ' +
                        'WHERE Id IN (\'' + String.join(ids, '\',\'') + '\')';
                for (SObject sobj : Database.query(query)) {
                    sobjectById.put(sobj.Id, sobj);
                }
            }
            objectNameToIdToRecord.put(key, sobjectById);
        }

        Map<String, String> routingModelToField = trac_CaseRoutingHelper.createRoutingFieldMap();
        Integer x = 10000000;

        for (Case cs : cases) {
            CaseWrapper caseObj = new CaseWrapper(cs);
            for (String caseField : ogFieldMap.keySet()) {
                FieldWrapper fieldWrap = ogFieldMap.get(caseField);
                String sObjectRecordId = String.valueOf(cs.get(fieldWrap.CaseField));
                String fieldValue = '';
                try {
                    List<String> rFields = caseField.split('\\.');
                    if (rFields.size() > 2) {
                        SObject so = objectNameToIdToRecord.get(fieldWrap.ObjectName).get(sObjectRecordId);
                        for (Integer i = 1; i < rFields.size() - 1; i++) {
                            so = so.getSObject(rFields[i]);
                        }
                        fieldValue = String.valueOf(so.get(rFields[rFields.size() - 1]));
                    } else {
                        fieldValue = String.valueOf(objectNameToIdToRecord.get(fieldWrap.ObjectName)
                                .get(sObjectRecordId)
                                .get(fieldWrap.ObjectField));
                    }
                } catch (Exception e) {
                    System.debug('There was an error getting the field value ' +
                            '- routing will not use this field for routing');
                }
                caseObj.fields.put(caseField, fieldValue);
            }
            caseObjectByIdx.put(String.valueOf(x++), caseObj);
        }

        for (String idx : caseObjectByIdx.keySet()) {
            CaseWrapper cs = caseObjectByIdx.get(idx);
            for (String caseField : ogFieldMap.keySet()) {
                FieldWrapper fieldWrap = ogFieldMap.get(caseField);

                String sObjectRecordId = String.valueOf(caseObjectByIdx.get(idx)
                        .fields
                        .get(fieldWrap.CaseField.toLowerCase()));
                String fieldValue = '';
                try {
                    List<String> rFields = caseField.split('\\.');
                    if (rFields.size() > 2) {
                        SObject so = objectNameToIdToRecord.get(fieldWrap.ObjectName).get(sObjectRecordId);
                        for (Integer i = 1; i < rFields.size() - 1; i++) {
                            so = so.getSObject(rFields[i]);
                        }
                        fieldValue = String.valueOf(so.get(rFields[rFields.size() - 1]));
                    } else {
                        fieldValue = String.valueOf(objectNameToIdToRecord.get(fieldWrap.ObjectName)
                                .get(sObjectRecordId)
                                .get(fieldWrap.ObjectField));
                    }
                } catch (Exception e) {
                    System.debug('There was an error getting the field value');
                }
                cs.fields.put(caseField, fieldValue);
            }
        }

        Map<String, String> idxToQueueDevName = new Map<String, String>();
        Map<String, String> idxToLocationId = new Map<String, String>();
        Map<String, String> idxToPrefix = new Map<String, String>();

        List<Case_Routing__mdt> rules = [
                SELECT Id, Label, Run_On_Escalate__c,Routing_Model__c,Routing_Name__c, Weight__c, (
                        SELECT Case_Routing__c, Field__c, Value__c
                        FROM Case_Routing_Line_Items__r
                        WHERE Is_Active__c = TRUE
                )
                FROM Case_Routing__mdt
                WHERE Is_Active__c = TRUE
        ];

        for (String idx : caseObjectByIdx.keySet()) {
            CaseWrapper cs = caseObjectByIdx.get(idx);
            for (Case_Routing__mdt ruleMdt : rules) {

                Rule rule = new Rule(ruleMdt);
                rule.CriteriaWeight = ruleMdt.Case_Routing_Line_Items__r.size();

                Integer all = ruleMdt.Case_Routing_Line_Items__r.size();
                Integer none = ruleMdt.Case_Routing_Line_Items__r.size();
                for (Case_Routing_Line_Item__mdt lineItem : ruleMdt.Case_Routing_Line_Items__r) {
                    Criterion currentCriterion = new Criterion(lineItem);
                    currentCriterion.setMatch(cs.fields);
                    if (currentCriterion.Match) {
                        all--;
                    } else {
                        none--;
                    }
                    rule.Criteria.add(currentCriterion);
                }

                if (all == 0) {
                    rule.Match = MatchTypes.FULL;
                    cs.RoutingModel = rule.RoutingModel;
                    cs.RoutingName = rule.RoutingName;
                    cs.addRule(rule);
                } else if (none != 0) {
                    rule.Match = MatchTypes.PARTIAL;
                    cs.addRule(rule);
                }
            }
        }

        for (String idx : caseObjectByIdx.keySet()) {
            CaseWrapper cs = caseObjectByIdx.get(idx);

            if (cs.matchedRules.size() > 0) {
                Rule rule = cs.getWeightiestMatch();

                if (rule == null) {
                } else if (rule.RoutingModel == null) {
                    cs.log.add('ERR NO ROUTING MODEL -- The selected routing rule does not have a specified routing ' +
                            'model. The routing rule "' + rule.RoutingModel + '" needs to be fixed by an admin');
                } else if (rule.RoutingModel == 'Queue') {
                    idxToQueueDevName.put(idx, rule.RoutingName);
                } else if (!routingModelToField.keySet().contains(rule.RoutingModel)) {
                    cs.log.add('ERR NO LOCATION QUEUE TYPE -- No queues are set up to route based on this location ' +
                            'record type. This rule "' + rule.RoutingModel + '" be fixed by an admin or a new ' +
                            'Location Queue Type has to be created for this scenario');
                } else {
                    System.debug('DANIEL -- 5');
                    Object model = cs.fields.get(routingModelToField.get(rule.RoutingModel).toLowerCase());
                    if (model == null) {
                        cs.log.add('ERR BAD LOCATION DATA -- The location has no data for ' + rule.RoutingModel);
                    } else {
                        idxToLocationId.put(idx, model.toString());
                        idxToPrefix.put(idx, rule.RoutingName);
                        cs.RoutingLocationId = model.toString();
                        cs.RoutingPrefix = rule.RoutingName;
                    }
                }
            } else {
                System.debug('NO RULE WAS MATCHED');
            }
        }

        // ************ START QUEUE QUERIES ************ //
        // single routing
        if (idxToQueueDevName.values().size() > 0) {
            Map<String, String> apiToId = new Map<String, String>();
            for (Group grp : [
                    SELECT Id,DeveloperName
                    FROM Group
                    WHERE Type = 'Queue'
                    AND DeveloperName IN :idxToQueueDevName.values()
            ]) {
                apiToId.put(grp.DeveloperName, grp.Id);
            }
            for (String idx : idxToQueueDevName.keySet()) {
                String queueId = idxToQueueDevName.get(idx);
                if (apiToId.get(queueId) != null) {
                    caseObjectByIdx.get(idx).QueueId = apiToId.get(queueId);
                    break;
                }
            }
        }

        // location based routing
        if (idxToLocationId.values().size() > 0) {
            Map<Id, Location_Queue__c> locQueueMap = new Map<Id, Location_Queue__c>([
                    SELECT Queue_Id__c, Queue_Prefix__c, Location__c
                    FROM Location_Queue__c
                    WHERE Location__c IN :idxToLocationId.values()
                    AND Queue_Prefix__c IN :idxToPrefix.values()
            ]);
            if (locQueueMap.size() < 1) {
                TLLog.w('NO LOCATION QUEUE FOUND',
                        'Could not find location queue for location ids {0} with prefixes {1}',
                        idxToLocationId, idxToPrefix.values());
            }
            for (String idx : idxToLocationId.keySet()) {
                for (Location_Queue__c locQueue : locQueueMap.values()) {
                    if (idxToLocationId.get(idx) == locQueue.Location__c
                            && idxToPrefix.get(idx) == locQueue.Queue_Prefix__c) {
                        caseObjectByIdx.get(idx).QueueId = locQueue.Queue_Id__c;
                        break;
                    }
                }
            }
        }

        // ************ START SET OWNER ************ //
        for (String idx : caseObjectByIdx.keySet()) {
            CaseWrapper cs = caseObjectByIdx.get(idx);

            if (cs.QueueId != null && cs.QueueId != '') {
                cs.caseRecord.OwnerId = cs.QueueId;
                cs.log.add(String.format('**SUPPORT REQUEST ROUTED -- ' + MESSAGE_CASE_ROUTED_TO + '**',
                        new List<Object>{
                                cs.RoutingName, cs.QueueId
                        }));
            } else {
                if (cs.partialMatchedRules.size() == 0) {
                    cs.log.add('_This record didn\'t match any of the '
                            + (Boolean.valueOf(cs.fields.get('escalate__c')) ? '' : 'non-') + 'escalate criteria_');
                }
                cs.log.add('**NO QUEUE -- No queue was found for routing**');
            }
            cs.caseRecord.Route__c = false;

            String logString = String.join(cs.log, '\n');
            Integer maxSize = 32768;
            if (logString.length() > maxSize) {
                logString = logString.substring(0, maxSize - 40);
                logString += '...(log has been truncated to fit field)';
            }
            cs.caseRecord.Routing_Log__c = logString;
        }
    }


/************************************************** WRAPPER CLASSES **************************************************/
    /**
     * @description Wrapper for related fields
     */
    public class FieldWrapper {
        public String CaseField;
        public String ObjectName;
        public String ObjectField;
    }


    /**
     * @description Wrapper for the case object and related details
     */
    private class CaseWrapper {
        public Case caseRecord;
        public Map<String, Object> fields = new Map<String, Object>();
        public String RoutingLocationId;
        public String RoutingPrefix;
        public List<Rule> matchedRules = new List<Rule>();
        public List<Rule> partialMatchedRules = new List<Rule>();
        public String QueueId;
        public String RoutingModel;
        public String RoutingName;
        public List<String> log = new List<String>();
        public Boolean IsEscalte;

        public CaseWrapper(Case cs) {
            this.caseRecord = cs;
            this.IsEscalte = cs.Escalate__c;
            this.log.add('# ' + (this.IsEscalte ? 'Escalation' : 'Routing') + ' log - `' +
                    Datetime.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ') + '`');
            Map<String, Object> fieldMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(cs));
            for (String key : fieldMap.keySet()) {
                this.fields.put(key.toLowerCase(), fieldMap.get(key));
            }
        }

        public void addRule(Rule rule) {
            if (rule.Match == MatchTypes.FULL) {
                this.matchedRules.add(rule);
                this.log.add('## FULL MATCH -- ' + rule.Label);
            } else if (rule.Match == MatchTypes.PARTIAL) {
                this.partialMatchedRules.add(rule);
                this.log.add('## PARTIAL MATCH -- ' + rule.Label);
            }
            for (Criterion cri : rule.Criteria) {
                this.log.add('* ' + (cri.Match ? '✅' : '❌') +
                        ' CRITERIA: `Case.' + cri.Field + ' == ' +
                        (cri.Match ? cri.ActualValue : '(' + cri.ActualValue + ')') + '`');
            }
            this.log.add('');
        }

        public Rule getWeightiestMatch() {
            Rule ruleToUse;
            Integer manualWeight;
            Integer weight = 0;
            for (Rule rule : this.matchedRules) {
                if (rule.Match == MatchTypes.FULL) {
                    if (rule.ManualWeight != null) {
                        if (manualWeight == null) {
                            manualWeight = rule.ManualWeight;
                            ruleToUse = rule;
                        } else if (rule.ManualWeight >= manualWeight) {
                            ruleToUse = rule;
                        }
                    } else if (manualWeight == null && rule.CriteriaWeight >= weight) {
                        weight = rule.CriteriaWeight;
                        ruleToUse = rule;
                    }
                }
            }
            this.log.add('<hr>The rule `' +
                    ruleToUse.Label +
                    '` was selected because it ' +
                    (manualWeight == null ? ' had '
                            + weight +
                            ' criteria' : ' was manually assigned a weight of '
                            + manualWeight) + '.');
            return ruleToUse;
        }
    }


    // enumeration of the match type options
    public enum MatchTypes {
        NONE, PARTIAL, FULL
    }


    /**
     * @description Wrapper class for a rule (Case_Routing__mdt)
     */
    private class Rule {
        public List<Criterion> Criteria = new List<Criterion>();
        public String RoutingModel;
        public String RoutingName;
        public MatchTypes Match = MatchTypes.NONE;
        public Integer CriteriaWeight = 0;
        public Integer ManualWeight = 0;
        public String Label;
        public Boolean IsEscalate;

        public Rule(Case_Routing__mdt ruleMdt) {
            this.RoutingModel = ruleMdt.Routing_Model__c;
            this.RoutingName = ruleMdt.Routing_Name__c;
            this.Label = ruleMdt.Label;
            this.ManualWeight = (ruleMdt.Weight__c != null && ruleMdt.Weight__c > 0)
                    ? Integer.valueOf(ruleMdt.Weight__c)
                    : null;
            this.IsEscalate = ruleMdt.Run_On_Escalate__c;
        }
    }


    /**
     * @description Wrapper class for a rule (Case_Routing_Line_Item__mdt)
     */
    private class Criterion {
        public String Field;
        public List<String> values = new List<String>();
        public Boolean Match = false;
        public Object ActualValue;

        public Criterion(Case_Routing_Line_Item__mdt mdt) {
            this.Field = mdt.Field__c.toLowerCase();
            this.values = mdt.Value__c != null ? mdt.Value__c.split(';') : new List<String>();
        }

        public Boolean setMatch(Map<String, Object> caseData) {
            this.ActualValue = caseData.get(this.Field);
            if (this.ActualValue != null && this.values.contains(this.ActualValue.toString())) {
                this.Match = true;
            }
            return this.Match;
        }
    }

}