/*************************************************************************************************************************************
    Author      :   Hemanshu Shah
    Description :   This class allows to send email with related objects for deactivated users
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR            DETAIL
    1          20 Jun, 2018    Hemanshu Shah     Initial deployment
    2          8 Aug, 2021     Pawel Biszczak    Refactor
    3          4 Jan, 2022     Pawel Biszczak    Refactor
**************************************************************************************************************************************/
global class BatchToFindDeactivatedUserIdInObject implements Database.Batchable<sObject>,Database.Stateful {
    @TestVisible
    Integer currentIndex;
    @TestVisible
    Boolean isTextArea = false;
    User deactivatedUser;
    @TestVisible
    Map<String, String> sObjectsToTextBodyCSVMap;
    UserTriggerHandler.SendDeactivateUserStatus settingWrapper;
    Map<String,List<String>> mapOfCurrentObjectFields;
    String sObjectName;
    final String TEXT_AREA_FIELD_TYPE = 'TEXTAREA';
    
    public BatchToFindDeactivatedUserIdInObject(Integer currentIndex, User deactivatedUser,
                                                Map<String, String> sObjectsToTextBodyCSVMap,
                                                UserTriggerHandler.SendDeactivateUserStatus settingWrapper) {
        this.currentIndex = currentIndex;
        this.deactivatedUser = deactivatedUser;
        this.sObjectsToTextBodyCSVMap = sObjectsToTextBodyCSVMap;
        this.settingWrapper = settingWrapper;
        mapOfCurrentObjectFields = settingWrapper.searchInObjects[currentIndex]; 
        sObjectName = new List<String>(mapOfCurrentObjectFields.keySet())[0];
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query;
        Map<String, Schema.SObjectField> sObjectFields =
                Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap();
        for(String field:mapOfCurrentObjectFields.values()[0]){
            if(String.valueOf(sObjectFields.get(field).getDescribe().getType()) == TEXT_AREA_FIELD_TYPE){
                isTextArea = true;
                break;
            }
        }
        query = UserTriggerHandler.queryGenerator(sObjectName, mapOfCurrentObjectFields.values()[0],
                                                  String.valueOf(deactivatedUser.Id).substring(0, 15),
                                                  isTextArea, sObjectFields);
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<sObject> records) {
        try{
            String bodyForSpecificObject = '';
            if (isTextArea) {
                String fieldsValues;
                for (sObject currentObject : records) {
                    fieldsValues = '';
                    for (String fieldToInclude : settingWrapper.searchInObjects[currentIndex].values()[0]) {
                        fieldsValues += (String) currentObject.get(fieldToInclude);
                    }
                    if (fieldsValues.contains(String.valueOf(deactivatedUser.Id).substring(0, 15))) {
                        if (sObjectsToTextBodyCSVMap.containsKey(sObjectName)) {
                            bodyForSpecificObject = sObjectsToTextBodyCSVMap.get(sObjectName);
                            sObjectsToTextBodyCSVMap.put(sObjectName,
                                                         bodyForSpecificObject + '\n' + currentObject.Id +
                                                         '\t' + currentObject.get('Name'));
                        } else {
                            sObjectsToTextBodyCSVMap.put(sObjectName,
                                                         'Id \t Name \n' + currentObject.Id + '\t' +
                                                         currentObject.get('Name'));
                        }
                    }
                }
            } else {
                String tempBody;
                for (sObject currentObject : records) {
                    bodyForSpecificObject += currentObject.Id + '\t' + currentObject.get('Name') + '\n';
                }
                if (sObjectsToTextBodyCSVMap.containsKey(sObjectName)) {
                    tempBody = sObjectsToTextBodyCSVMap.get(sObjectName);
                    sObjectsToTextBodyCSVMap.put(sObjectName, tempBody + bodyForSpecificObject);
                } else {
                    sObjectsToTextBodyCSVMap.put(sObjectName, 'Id \t Name \n' + bodyForSpecificObject);
                }
            }
        } catch(Exception exp) {           
            new ApexDebugLog().createLog( 
                new ApexDebugLog.Error('BatchToFindDeactivatedUserIdInObject', ' ',
                                       null, exp)
            );
        }
    }    
    global void finish(Database.BatchableContext bc) {
        ++currentIndex;
        if(currentIndex < settingWrapper.searchInObjects.size()) {
            Database.executeBatch(
                    new BatchToFindDeactivatedUserIdInObject(currentIndex, deactivatedUser,
                                                             new Map<String,String>(sObjectsToTextBodyCSVMap),
                                                             settingWrapper));
        } else {
            if(sObjectsToTextBodyCSVMap.size() > 0) {
                UserTriggerHandler.sendEmail(deactivatedUser.Id,
                                             deactivatedUser.LastName + ' ' + deactivatedUser.FirstName,
                                             sObjectsToTextBodyCSVMap, settingWrapper.subject,
                                             settingWrapper.emailBody, settingWrapper.Emails);
            }
        } 
    }    
}