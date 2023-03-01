@isTest(SeeAllData = true)
public with sharing class LightningLoginFormControllerTest {

 @isTest
 static void testLoginWithInvalidCredentials() {
  System.assertEquals(null, LightningLoginFormController.login('testUser', 'fakepwd', null), 'Argument 1 cannot be null');
 }

 @isTest
 static void LightningLoginFormControllerInstantiation() {
  LightningLoginFormController controller = new LightningLoginFormController();
  System.assertNotEquals(controller, null);
 }

 @IsTest
 static void testIsUsernamePasswordEnabled() {
  System.assertEquals(true, LightningLoginFormController.getIsUsernamePasswordEnabled());
 }

 @isTest
 static void testIsSelfRegistrationEnabled() {
  System.assertEquals(false, LightningLoginFormController.getIsSelfRegistrationEnabled());
 }

 @isTest
 static void testGetSelfRegistrationURL() {
  System.assertEquals(null, LightningLoginFormController.getSelfRegistrationUrl());
 }

 @isTest
 static void testAuthConfig() {
  Auth.AuthConfiguration authConfig = LightningLoginFormController.getAuthConfig();
  System.assertNotEquals(null, authConfig);
 }

 @isTest
 static void testResetPassword() {
  String forgotUrl = LightningLoginFormController.getForgotPasswordUrl();
  LightningLoginFormController.setExperienceId('test');
  System.assertEquals(null, forgotUrl);
 }
}