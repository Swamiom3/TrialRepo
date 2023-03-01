/**
 * @description unit tests for the trac_MatchProfile class
 * @name trac_MatchProfileTest
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-11-01
 */

@IsTest
private class trac_MatchProfileTest {
    @IsTest
    static void testMatchProfile() {
        String adminProfile = [SELECT Id FROM Profile WHERE Name = :TLOrgConstants.PROFILE_SYSTEM_ADMIN].Id;
        List<trac_MatchProfile.Inputs> inputs = new List<trac_MatchProfile.Inputs>();
        trac_MatchProfile.Inputs input = new trac_MatchProfile.Inputs();
        input.profileId = adminProfile;
        input.profileDevName = TLOrgConstants.PROFILE_SYSTEM_ADMIN;
        inputs.add(input);

        String isMatch = trac_MatchProfile.matchProfile(inputs)[0];
        System.assert(Boolean.valueOf(isMatch),'Profile id did not match the given name');
    }
}