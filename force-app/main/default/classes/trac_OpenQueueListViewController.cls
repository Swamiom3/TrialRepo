/**
 * @description apex controller for the tracOpenQueueListView component
 * @name trac_OpenQueueListViewController
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-08-02
 */

public with sharing class trac_OpenQueueListViewController {

    /**
     * @description gets number of relevant sobject records beyond the limit of whats shown in the list
     * @param statuses string csv of sobjects statuses
     * @param include boolean flag whether to include or exclude the statuses
     * @return integer of the count of sobject records
     */
    @AuraEnabled(Cacheable=true)
    public static Integer getRecordCount(String sobjectType, String statuses, Boolean include, List<String> fields) {
        String query = '';
        if(sobjectType == 'Case') {
            query = getAllCasesForLocationsQuery(sobjectType, statuses, null, include, fields);
        }

        String countQuery = query.replaceFirst('SELECT.*FROM','SELECT COUNT() FROM');
        return Database.countQuery(countQuery);
    }


    /**
     * @description get all sobject records related to the current user's location queues
     * @param statuses string csv of sobjects statuses
     * @param recordLimit integer of limit of records to query
     * @param include boolean flag whether to include or exclude the statuses
     * @return list sobject records
     */
    @AuraEnabled(Cacheable=true)
    public static List<SObject> getAllSObjectsForLocations(String sobjectType, String statuses, Integer recordLimit, Boolean include, List<String> fields) {
//        System.debug();
        System.debug('sobjectType' + sobjectType);
        System.debug('statuses' + statuses);
        System.debug('recordLimit' + recordLimit);
        System.debug('include' + include);
        System.debug('fields' + fields);
        String query = '';
        if(sobjectType == 'Case') {
            query = getAllCasesForLocationsQuery(sobjectType, statuses, recordLimit, include, fields);
        }

        return Database.query(query);
    }


    /**
     * @description query for all the sobjects for the current user's location queues
     * @param statuses string csv of sobjects statuses
     * @param recordLimit integer of limit of records to query
     * @param include boolean flag whether to include or exclude the statuses
     * @return string to use to query for sobject records
     */
    public static String getAllCasesForLocationsQuery(String sobjectType, String statuses, Integer recordLimit, Boolean include, List<String> fields) {
        //TODO can the group ids be static so we dont waste a query for evey apex call???
        Set<String> groupIds = TLList.collectStrings(getUserGroupMembership(),GroupMember.GroupId);

        List<Location_Queue__c> locationQueues = [SELECT Id, Building_Id__c FROM Location_Queue__c WHERE Queue_Id__c IN :groupIds];
        Set<String> locationIds = new Set<String>();
        for(Location_Queue__c locQueue : locationQueues) {
            locationIds.add(locQueue.Building_Id__c);
        }

        fields.add('Id');
        fields.add('CaseNumber');

        TLQueryBuilder query = new TLQueryBuilder();
        query.setFields(fields);
        query.setObject(sobjectType);
        query.setLimit(recordLimit);
        TLQueryBuilder.Operator operator = new TLQueryBuilder.Operator();
        operator.addCondition(new TLQueryBuilder.Condition(
                'Location__c',
                TLQueryBuilder.IN_OPERATOR,
                locationIds));
        query.baseOperator.addOperator(operator);
        if(statuses != null) {
            query.setLogicalOperator(TLQueryBuilder.AND_OPERATOR);
            query.baseOperator.addCondition(new TLQueryBuilder.Condition(
                    'Status',
                    include ? TLQueryBuilder.IN_OPERATOR : TLQueryBuilder.NOT_IN_OPERATOR,
                    statuses.split(',')));
        }
        return query.build();
    }


    /**
     * @description query for all of the current user's group memberships
     * @return list of GroupMember records
     */
    public static List<GroupMember> getUserGroupMembership() {
        return [SELECT GroupId, Group.Name,Id FROM GroupMember WHERE UserOrGroupId = :UserInfo.getUserId()];
    }

}