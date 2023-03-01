/**
 * @description invocable class that finds a user's CM queue membership for a building
 * @name trac_GetCMBuilding
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-10-18
 */

global with sharing class trac_GetCMBuilding {
    @InvocableMethod(Label='Find CM Building' Description='Pass in the user id to get the user\'s building id')
    public static List<String> getCMBuilding(List<Inputs> inputs) {
        try {
            String userId = inputs[0].userId;
            String prefix = inputs[0].prefix;
            String match = inputs[0].match;

            List<GroupMember> memberships = [
                    SELECT GroupId
                    FROM GroupMember
                    WHERE UserOrGroupId = :userId];

            Set<String> membershipIds = TLList.collectStrings(memberships,GroupMember.GroupId);
            List<Location_Queue__c> locationQueues = [
                    SELECT Id,Location__r.Id
                    FROM Location_Queue__c
                    WHERE Queue_Id__c IN :membershipIds
                    AND Queue_Prefix__c = :prefix
                    ORDER BY Location__r.Name ASC];

            if(locationQueues.size() >= 1 && match.toLowerCase() != 'none') {
                if(locationQueues.size() == 1 || match.toLowerCase() == 'first') {
                    return new List<String>{locationQueues[0].Location__r.Id};
                } else if(match.toLowerCase() == 'last') {
                    return new List<String>{locationQueues[locationQueues.size()-1].Location__r.Id};
                }
            }
            else return null;
        }
        catch (Exception e) { return null; }
        return null;
    }

    global class Inputs {
        @InvocableVariable(Label='User Id' Required=true)
        global String userId;

        @InvocableVariable(Label='Queue Prefix' Required=true)
        global String prefix;

        @InvocableVariable(Label='Multiple Match Result' Description='Either first, last, or none' Required=true)
        global String match;
    }

    class trac_GetCMBuildingException extends Exception {}
}