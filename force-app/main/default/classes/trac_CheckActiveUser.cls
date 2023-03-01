/**
* @description Apex class trac_CheckActiveQueueMembers
* @author Shubham Jain, Traction on Demand
* @date 5/1/2020
*/

global without sharing class trac_CheckActiveUser {

    @InvocableVariable(Label='Queue Id' Required=true)
    global String newQId;
    @TestVisible
    private static UserSelector userSelector = new UserSelector();

    @InvocableMethod(Label='Check Active Members' Description='Pass in a Group Id')
    //Method to check Queue has atleast one active member associated with it.
    global static List<List<String>> checkActiveMemberExist(List<String> newQIdList) {
        System.debug(newQIdList);
        Map<Id, String> qIdToActiveMap = new Map<Id, String>();
        try {
            Map<Id, List<Id>> qIdToUserIdsMap = new Map<Id, List<Id>>();
            Set<Id> userIds = new Set<Id>();
            for (GroupMember gm : [SELECT UserOrGroupId, GroupId FROM GroupMember WHERE GroupId IN :newQIdList]) {
                if (String.valueOf(gm.UserOrGroupId).startsWith('005')) { //Check if GroupMember is user or role
                    userIds.add(gm.UserOrGroupId);
                    List<Id> uIds = new List<Id>();
                    if (qIdToUserIdsMap.containsKey(gm.GroupId)) {
                        uIds = qIdToUserIdsMap.get(gm.GroupId);
                        uIds.add(gm.UserOrGroupId);
                        qIdToUserIdsMap.put(gm.GroupId, uIds);
                    } else {
                        uIds.add(gm.UserOrGroupId);
                        qIdToUserIdsMap.put(gm.GroupId, uIds);
                    }
                }

            }

            List<Id> activeUserIds = new List<Id>();
            for (User u : userSelector.getUsersById(userIds)) {
                activeUserIds.add(u.Id);
            }
            //Using newQIdList to maintain order of returned list
            for (String qId : newQIdList) {
                if (qIdToUserIdsMap.containsKey(qId)) {             //If any users are found in the queue
                    for (Id uId : qIdToUserIdsMap.get(qId)) {
                        if (activeUserIds.contains(uId)) {          //If users of the queue are also there in activeUserIds set
                            qIdToActiveMap.put(qId, 'True');
                            break;
                        }
                    }
                }
                //If no 'Active' users are there for a queue OR there are no Users in the queue
                // then set to false.
                if (qIdToActiveMap.get(qId) != 'True') {
                    qIdToActiveMap.put(qId, 'False');
                }
            }

            List<List<String>> listOfList = new List<List<String>>();
            for (String qId : newQIdList) {
                listOfList.add(new List<String>{
                        qIdToActiveMap.get(qId)
                });
            }
            System.debug(listOfList);
            return listOfList;

        } catch (Exception e) {
            System.debug(e.getMessage() + ' - ' + e.getStackTraceString());
            throw new trac_CheckActiveQueueMembersException();
        }
    }

    class trac_CheckActiveQueueMembersException extends Exception {

    }
}