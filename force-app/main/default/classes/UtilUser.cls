/**
* @author Gad Sharon    
* @date 01/10/18
* @description Util class for the user object.
*/
@isTest
public class UtilUser {

    public static Integer counter = 0;
   
    public static List<User> createUsers (Integer numberOfRecords, Id profileId, Boolean doInsert){
        List<Map<String,Object>> fieldMap = new List<Map<String,Object>>();
        
        for (Integer i = 0; i < numberOfRecords; i++){
            String diffForTransaction = String.valueOf(i) + '_' + String.valueOf(counter++);
            fieldMap.add(addValuesToMap(diffForTransaction, profileId));
        }

        return UtilGeneral.createTestRecords(User.sObjectType, fieldMap, doInsert); 
    }

    public static List<User> createUsersByProfileId (List <Id> profileIds, Boolean doInsert){
        List<Map<String,Object>> fieldMap = new List<Map<String,Object>>();
        
        for (Integer i = 0; i < profileIds.size(); i++){
            fieldMap.add(addValuesToMap(String.valueOf(profileIds[i]), profileIds[i]));
        }

        return UtilGeneral.createTestRecords(User.sObjectType, fieldMap, doInsert); 
    }

    public static User createUser (Id profileId, Boolean doInsert){
    	return createUsers(1, profileId, doInsert)[0];
    }

    public static Map <String, Object> addValuesToMap(String differentiator, Id profileId){
    	Map<String,Object> mapUserFields = new Map<String,Object>();
        
        mapUserFields.put('LastName', 'UtilUser_' + differentiator);
        mapUserFields.put('Username', 'UtilUser_' + differentiator + System.now().getTime() + '@UtilUser.com');
        mapUserFields.put('Email', 'UtilUser_' + differentiator + '@UtilUser.com');
        mapUserFields.put('CommunitynickName', 'UtilUser_' + differentiator + '@UtilUser.com');
        mapUserFields.put('LanguageLocaleKey','en_US');
        mapUserFields.put('LocaleSidKey','en_US');
        mapUserFields.put('TimeZoneSidKey','America/Los_Angeles');
        mapUserFields.put('EmailEncodingKey','ISO-8859-1');
        mapUserFields.put('ProfileId', profileId);

        return mapUserFields;
    }
}