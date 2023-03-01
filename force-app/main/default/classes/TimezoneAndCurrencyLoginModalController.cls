public with sharing class TimezoneAndCurrencyLoginModalController {
    @TestVisible private static final String LANGUAGE_AND_TIME_ZONE_URL = '/lightning/settings/personal/LanguageAndTimeZone/home';
    @TestVisible private static Boolean isSandbox = [SELECT IsSandbox FROM Organization].IsSandbox;
    private Login_Flow_Flag__c lff;

    public PageReference redirectToLoginFlowLanguageAndTimeZone() {
        return Auth.SessionManagement.finishLoginFlow(LANGUAGE_AND_TIME_ZONE_URL);
    }

    public PageReference redirectToLoginFlowHome() {
        return Auth.SessionManagement.finishLoginFlow();
    }

    public PageReference handleRedirect() {
        lff = Login_Flow_Flag__c.getInstance(UserInfo.getUserId());
        if (isSandbox) {
            if (!lff.Is_Tester_User__c) {
                return this.redirectToLoginFlowHome();
            }
            return null;
        } else {
            return this.handleFlagsOnProd();
        }
    }

    private PageReference handleFlagsOnProd() {
        if (lff.Was_Time_Zone_Message_on_Login_Shown__c) {
            return this.redirectToLoginFlowHome();
        } else {
            lff.Was_Time_Zone_Message_on_Login_Shown__c = true;
            try {
                upsert lff;
            } catch(DmlException e) {
                ApexPages.addMessages(e);
            }
        }

        return null;
    }
}