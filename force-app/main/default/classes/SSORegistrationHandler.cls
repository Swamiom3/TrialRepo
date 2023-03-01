global class SSORegistrationHandler implements Auth.RegistrationHandler{
	
    @TestVisible
    private static UserSelector userSelector = new UserSelector();
    
    global User createUser(Id portalId, Auth.UserData data){
        String email = sanitizeEmail(data.email);
        String suffix = '.service';
        if(runningInASandbox()){
            String baseUrl = System.URL.getSalesforceBaseUrl().toExternalForm();
            suffix = suffix + '.' + baseUrl.substringBetween('--','.');
        }
        String federationIdentifier = email + suffix;
        List<User> users = userSelector.getUserByFederationId(federationIdentifier);
        if (users.isEmpty()) {
            throw new RegHandlerException('Cannot find the user. Please contact your administrator.'); 
        } 
        return users[0];
    }

    private Boolean runningInASandbox() {
        return [SELECT IsSandbox FROM Organization].IsSandbox;
    }

    @testVisible
    private String sanitizeEmail(String email){
        if(email.endsWith('.invalid')){
            return email.removeEnd('.invalid');
        }
        return email;
    }
    
    global void updateUser(Id userId, Id portalId, Auth.UserData data){}

    class RegHandlerException extends Exception {}
}