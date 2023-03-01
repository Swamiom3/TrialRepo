/**
 * @description apex controller for the sobject lookup lwc
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-08-13
 *
 * Copyright 2019 Salesforce.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 *
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * prefix "trac" added for visibility into the work Traction on Demand has done
 */

public with sharing class trac_LookupController {

    private final static Integer MAX_RESULTS = 5;

//    /* this is the generic search code */
//    @AuraEnabled(Cacheable=true)
//    public static List<trac_LookupSearchResult> search(String sobjectType, String searchTerm, String nameField, String icon, List<String> selectedIds) {
//        // Prepare query paramters
//        searchTerm += '*';
//        // Execute search query
//        String whereClause = selectedIds.size() > 0 ? 'WHERE Id NOT IN (' + String.join(selectedIds,',') + ')' : '';
//        String query = 'FIND \''+ searchTerm + '\' IN ALL FIELDS RETURNING ' + sobjectType + ' (Id, DeveloperName, ' + nameField + ' ' + whereClause + ') LIMIT ' + MAX_RESULTS;
//        System.debug(query);
//        List<SObject>searchResults = Search.query(query)[0];
//        // Prepare results
//        List<trac_LookupSearchResult> results = new List<trac_LookupSearchResult>();
//        for(SObject sobj : searchResults) {
//            //TODO subtitle field
//            results.add(new trac_LookupSearchResult(
//                    sobj.Id,
//                    sobjectType,
//                    icon == null ? 'standard:lightning_component' : icon,
//                    String.valueOf(sobj.get(nameField)),
//                    String.valueOf(sobjectType) + ' - ' + String.valueOf(sobj.get('DeveloperName')),
//                    String.valueOf(sobj.get('DeveloperName')))
//            );
//        }
//        return results;
//    }



    /**
     * @description search controller to find queue sobjects that define queues for cases
     * @param sobjectType not used
     * @param searchTerm used to find matches in the query
     * @param nameField not used
     * @param icon slds icon to display in the front end
     * @param selectedIds ids that have been selected as to not display duplicates to the user
     * @return result object to be parsed and displayed in the front end
     */
    @AuraEnabled(Cacheable=true)
    public static List<trac_LookupSearchResult> search(String sobjectType, String searchTerm, String nameField, String icon, List<String> selectedIds) {
        // query for queue data based on QueueSobject records for case
        List<QueueSobject> searchResults = [
                SELECT QueueId,Queue.DeveloperName,Queue.Name
                FROM QueueSobject
                WHERE SobjectType = 'Case'
                AND (Queue.Name LIKE :('%'+searchTerm+'%') OR Queue.DeveloperName LIKE :('%'+searchTerm+'%'))
                AND QueueId NOT IN :selectedIds
                LIMIT :MAX_RESULTS];

        // Prepare results
        List<trac_LookupSearchResult> results = new List<trac_LookupSearchResult>();
        for(QueueSobject qsobj : searchResults) {
            results.add(new trac_LookupSearchResult(
                    qsobj.QueueId,
                    'Group',
                    icon == null ? 'standard:lightning_component' : icon,
                    qsobj.Queue.Name,
                    'Queue - ' + qsobj.Queue.DeveloperName,
                    qsobj.Queue.DeveloperName)
            );
        }

        return results;
    }
}