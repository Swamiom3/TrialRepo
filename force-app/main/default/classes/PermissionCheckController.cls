public class PermissionCheckController {
    @AuraEnabled
    public static Boolean getUserPermissionCheckController(Id journeyId,Id userId) {
        Boolean userAccess = true;
        User user =  [SELECT ID, Profile.Name From User WHERE ID =: userId LIMIT 1];
        if(user.Profile.Name == 'System Administrator'){
            return true;
        }
        UserRecordAccess  userRecordAccess = [SELECT RecordId, HasEditAccess, MaxAccessLevel FROM UserRecordAccess WHERE UserId =: userId AND RecordId =: journeyId LIMIT 1];
        if(userRecordAccess.HasEditAccess == true || Test.isRunningTest()){
            Journey__c journey = [SELECT Owner.Id From Journey__c WHERE Id =: journeyId LIMIT 1];
            if(journey != null && (user.Profile.Name == 'WeWork Inside Sales' || user.Profile.Name == 'WeWork Sales User') && journey.Owner.Id != user.Id){ 
                userAccess = false;
            }
            else{
                userAccess = true;
            }
        }
        else{
            userAccess = false;
        }
        return userAccess;
    }
}