@IsTest
private class TimezoneAndCurrencyLoginModalCntrlrTest {
    @IsTest
    static void testRedirectToLoginFlowLanguageAndTimeZone() {
        Test.startTest();
        String result = new TimezoneAndCurrencyLoginModalController().redirectToLoginFlowLanguageAndTimeZone().getUrl();
        Test.stopTest();

        System.assertEquals(TimezoneAndCurrencyLoginModalController.LANGUAGE_AND_TIME_ZONE_URL, result, 'There is a mismatch in actual result');
    }

    @IsTest
    static void testRedirectToLoginFlowHome() {
        Test.startTest();
        String result = new TimezoneAndCurrencyLoginModalController().redirectToLoginFlowHome().getUrl();
        Test.stopTest();

        final String EXPECTED_RESULT = '/';
        System.assertEquals(EXPECTED_RESULT, result, 'There is a mismatch in actual result');
    }

    @IsTest
    static void testHandleRedirect_isSandboxAndIsTesterUser() {
        TimezoneAndCurrencyLoginModalController.isSandbox = true;
        upsert new Login_Flow_Flag__c (SetupOwnerId = Userinfo.getUserId(), Is_Tester_User__c = true);

        Test.startTest();
        PageReference result = new TimezoneAndCurrencyLoginModalController().handleRedirect();
        Test.stopTest();

        System.assertEquals(null, result, 'There is a mismatch in actual result');
    }

    @IsTest
    static void testHandleRedirect_isSandboxAndIsNotTesterUser() {
        TimezoneAndCurrencyLoginModalController.isSandbox = true;

        Test.startTest();
        String result = new TimezoneAndCurrencyLoginModalController().handleRedirect().getUrl();
        Test.stopTest();

        final String EXPECTED_RESULT = '/';
        System.assertEquals(EXPECTED_RESULT, result, 'There is a mismatch in actual result');
    }

    @IsTest
    static void testHandleRedirect_isProdAndTimezoneMessageWasShown() {
        TimezoneAndCurrencyLoginModalController.isSandbox = false;
        upsert new Login_Flow_Flag__c (SetupOwnerId = Userinfo.getUserId(), Was_Time_Zone_Message_on_Login_Shown__c = true);

        Test.startTest();
        String result = new TimezoneAndCurrencyLoginModalController().handleRedirect().getUrl();
        Test.stopTest();

        final String EXPECTED_RESULT = '/';
        System.assertEquals(EXPECTED_RESULT, result, 'There is a mismatch in actual result');
    }

    @IsTest
    static void testHandleRedirect_isProdAndTimezoneMessageWasNotShown() {
        TimezoneAndCurrencyLoginModalController.isSandbox = false;

        Test.startTest();
        PageReference result = new TimezoneAndCurrencyLoginModalController().handleRedirect();
        Test.stopTest();

        Login_Flow_Flag__c lff = Login_Flow_Flag__c.getInstance(UserInfo.getUserId());
        System.assertEquals(null, result, 'There is a mismatch in actual result');
        System.assert(lff.Was_Time_Zone_Message_on_Login_Shown__c, 'There is a mismatch in lff Was_Time_Zone_Message_on_Login_Shown__c');
    }
}