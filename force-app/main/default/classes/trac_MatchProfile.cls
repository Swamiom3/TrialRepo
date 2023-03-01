/**
 * @description indicates whether a given profile id matches a given profile name, because flows can't query for profiles very well
 * @name trac_MatchProfile
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-11-01
 */

global with sharing class trac_MatchProfile {
    @InvocableMethod(Label='Match User Profile to Profile Dev Name')
    public static List<String> matchProfile(List<Inputs> inputs) {
        String profileId = inputs[0].profileId;
        String profileDevName = inputs[0].profileDevName;
        List<Profile> matchedProfiles = [SELECT Id FROM Profile WHERE Id = :profileId AND Name = :profileDevName];
        return new List<String>{String.valueOf(matchedProfiles.size() > 0)};
    }

    global class Inputs {
        @InvocableVariable(Label='User Profile Id' Required=true)
        global String profileId;
        @InvocableVariable(Label='Profile Dev Name to Match' Required=true)
        global String profileDevName;
    }
}