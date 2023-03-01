@isTest
private class UserAttributeValidateAttributesTrHTest {
    private static final String OVERLAP_ERR_MSG = Label.User_Att_Overlap;
    @isTest
    private static void validateAttributesTestOnInsert() {
        Id USER_HISTORY_ID = (Id) WeworkEngine.getObjectRecordTypeId('User_Attribute__c', 'User History');
        Test.startTest();
        List<User_Attribute__c> userAttrToInsert = new List<User_Attribute__c>();
        Id currentUserId = UserInfo.getUserId();
        userAttrToInsert.add(new User_Attribute__c(As_of_Date__c = Date.newInstance(2021, 01, 10)));
        userAttrToInsert.add(new User_Attribute__c(User__c = currentUserId, Sales_Team__c = 'Leasing', RecordTypeId = USER_HISTORY_ID));
        userAttrToInsert.add(new User_Attribute__c(User__c = currentUserId, As_of_Date__c = Date.today().addDays(10), Sales_Team__c = 'Leasing',RecordTypeId = USER_HISTORY_ID));
        userAttrToInsert.add(new User_Attribute__c(User__c = currentUserId, Sales_Team__c = 'Leasing', RecordTypeId = USER_HISTORY_ID, As_of_Date__c = Date.newInstance(2020, 08, 01), End_Date__c = Date.newInstance(2021, 01, 01)));
        
        List<Database.SaveResult> results = Database.insert(userAttrToInsert, false);
        
        Test.stopTest();
        System.assertEquals(false, results[0].isSuccess(), 'UA should not be inserted when User__c is null.');
        String errorMsg = results[0].getErrors()[0].getMessage();
        System.assertEquals(Label.User_Att_User_Required, errorMsg, 'UA should not be inserted when User__c is null.');
        
        System.assertEquals(false, results[1].isSuccess(), 'UA should not be inserted when As_of_Date__c is null.');
        errorMsg = results[1].getErrors()[0].getMessage();
        System.assertEquals(Label.User_Att_As_of_Date, errorMsg, 'UA should not be inserted when As_of_Date__c is null.');
        
        System.assertEquals(false, results[2].isSuccess(), 'UA should not be inserted when As_of_Date__c is future date.');
        errorMsg = results[2].getErrors()[0].getMessage();
        System.assertEquals(Label.User_Att_As_of_Date_Future, errorMsg, 'UA should not be inserted when As_of_Date__c is future date.');
        
        System.assertEquals(true, results[3].isSuccess(), 'UA be inserted successfully.');
        
        MetadataDrivenTriggerHandler.clearLoopCount('UserAttributeValidateAttributesTrH');
        userAttrToInsert.clear();
        userAttrToInsert.add(new User_Attribute__c(User__c = currentUserId, Sales_Team__c = 'Leasing', RecordTypeId = USER_HISTORY_ID, As_of_Date__c = Date.newInstance(2020, 10, 01)));
        userAttrToInsert.add(new User_Attribute__c(User__c = currentUserId, Sales_Team__c = 'Leasing', RecordTypeId = USER_HISTORY_ID, As_of_Date__c = Date.newInstance(2020, 09, 01), End_Date__c = Date.newInstance(2021, 02, 01)));
        userAttrToInsert.add(new User_Attribute__c(User__c = currentUserId, Sales_Team__c = 'Leasing', RecordTypeId = USER_HISTORY_ID, As_of_Date__c = Date.newInstance(2020, 02, 01)));
        results = Database.insert(userAttrToInsert, false);
        System.assertEquals(false, results[0].isSuccess(), 'UA should not be inserted when dates overlaps.');
        errorMsg = results[0].getErrors()[0].getMessage();
        System.assert(errorMsg.contains(OVERLAP_ERR_MSG), 'There should be overlaps in date.');
        
        System.assertEquals(false, results[1].isSuccess(), 'UA should not be inserted when dates overlaps.');
        errorMsg = results[1].getErrors()[0].getMessage();
        System.assert(errorMsg.contains(OVERLAP_ERR_MSG), 'There should be overlaps in date.');
        
        System.assertEquals(false, results[2].isSuccess(), 'UA should not be inserted when dates overlaps.');
        errorMsg = results[2].getErrors()[0].getMessage();
        System.assert(errorMsg.contains(OVERLAP_ERR_MSG), 'There should be overlaps in date.');
    }
    
    @isTest
    private static void validateAttributesTestOnUpdate() {
        Id USER_HISTORY_ID = (Id) WeworkEngine.getObjectRecordTypeId('User_Attribute__c', 'User History');
        Test.startTest();
        List<User_Attribute__c> userAttrToInsert = new List<User_Attribute__c>();
        Id currentUserId = UserInfo.getUserId();
        userAttrToInsert.add(new User_Attribute__c(User__c = currentUserId, Sales_Team__c = 'Leasing', RecordTypeId = USER_HISTORY_ID, As_of_Date__c = Date.newInstance(2020, 08, 01), End_Date__c = Date.newInstance(2021, 01, 01)));
        userAttrToInsert.add(new User_Attribute__c(User__c = currentUserId, Sales_Team__c = 'Leasing', RecordTypeId = USER_HISTORY_ID, As_of_Date__c = Date.newInstance(2020, 06, 01), End_Date__c = Date.newInstance(2020, 07, 01)));
        userAttrToInsert.add(new User_Attribute__c(User__c = currentUserId, Sales_Team__c = 'Leasing', RecordTypeId = USER_HISTORY_ID, As_of_Date__c = Date.newInstance(2019, 06, 01), End_Date__c = Date.newInstance(2019, 07, 01)));
        TestingUtility.insertListWithAssert(userAttrToInsert);
        
        List<User_Attribute__c> uaToInsert = new List<User_Attribute__c>();
        User_Attribute__c uaToUpdate = userAttrToInsert[1];
        uaToUpdate.As_of_Date__c = Date.newInstance(2020, 10, 01);
        uaToUpdate.End_Date__c = null;
        uaToInsert.add(uaToUpdate);
        
        uaToUpdate = userAttrToInsert[2];
        uaToUpdate.User__c = null;
        uaToInsert.add(uaToUpdate);
        List<Database.SaveResult> results = Database.update(uaToInsert, false);
        Test.stopTest();
        
        System.assertEquals(false, results[0].isSuccess(), 'UA should not be updated when dates overlap.');
        String errorMsg = results[0].getErrors()[0].getMessage();
        System.assert(errorMsg.contains(OVERLAP_ERR_MSG), 'There should be overlaps in date and should not be updated.');
        
        System.assertEquals(false, results[1].isSuccess(), 'UA should not be updated when dates overlap.');
        errorMsg = results[1].getErrors()[0].getMessage();
        System.assertEquals(Label.User_Att_User_Required, errorMsg, Label.User_Att_User_Required);
    }
}