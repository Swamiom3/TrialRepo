/**
* Controller class for checklist component .
* @author Shubham Jain, Traction on Demand
* @date 2019-08-07
*/

public with sharing class trac_ChecklistCaseComponentController {

    /**
* @description Returns a list of CategoryWrappers which contains Category field picklist values
* based upon recordtype call REST Api to get picklist values based on recordtype.
* @param objectApiName - object api name
* @param fieldApiName - picklist field api name
* @param recordTypeDeveloperName - record type developer name
* @return categoryWrappers - list of CategoryWrapper object
*/
    @AuraEnabled
    public static List<CategoryWrapper> getCategoryWrappers() {
        try {
            //Call trac_Picklist method to fetch picklist values based upon recordtype
            List<String> categories = new List<String>{
            /*'Cleaning',*/ 'Food and Beverage', 'Repair and Maintenance', 'Technology Services','Walkthrough Completed'
            };

            //Map of Category Name to related Icon Name used in lightning component.
            Map<String, String> categoryNameToIconMap = TLOrgConstants.CATEGORY_ICON_MAP;
            List<CategoryWrapper> categoryWrappers = new List<trac_ChecklistCaseComponentController.CategoryWrapper>();
            CategoryWrapper cWrapper;

            //Loop over all categories
            for (String cat : categories) {
                if (categoryNameToIconMap.containsKey(cat)) {
                    cWrapper = new CategoryWrapper(cat, categoryNameToIconMap.get(cat));
                    cWrapper.categoryName = cat;
                    cWrapper.iconName = categoryNameToIconMap.get(cat);
                    categoryWrappers.add(cWrapper);
                }
            }
            return categoryWrappers;
        } catch (Exception ex) {
            System.debug('Exception occured ' + ex);
            return null;
        }

    }


    /**
* @description Inserts a case record of Support Request type and attach files if provided.
* @param newCase - New case instance
* @param uploadedFileIds - uploaded attachment files ids
* @return caseInfo - String contains id of inserted case record.
*/
    @AuraEnabled
    public static String createCaseRecord(Id newCaseId, List<Map<String, String>> uploadedFileIds) {
        try {
            if (uploadedFileIds.size() > 0) {
                attachFilesToCase(newCaseId, uploadedFileIds);
            }
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
        return newCaseId;
    }

    /**
* @description create a new link between the uploaded files and the case created
* @param caseId - newly created case
* @param uploadedFileIds - list of json objects where { name : documentId }
* @return whether the link was successfully created
*/
    @AuraEnabled
    public static String attachFilesToCase(String caseId, List<Map<String, String>> uploadedFileIds) {
        if (uploadedFileIds.size() > 0) {

        }
        List<ContentDocumentLink> newDocumentLinks = new List<ContentDocumentLink>();
        List<String> ids = new List<String>();

        for (Map<String, String> file : uploadedFileIds) {
            ids.add(file.get('documentId')); // This is a JSON object where {name : documentId}
        }

        List<ContentDocumentLink> queriedDocumentLinks = [
                SELECT ContentDocumentId,Id,IsDeleted,LinkedEntityId,ShareType,SystemModstamp,Visibility
                FROM ContentDocumentLink
                WHERE ContentDocumentId IN :ids
        ];

        for (ContentDocumentLink file : queriedDocumentLinks) {
            ContentDocumentLink newLink = file.clone(false);
            newLink.LinkedEntityId = caseId;
            newLink.ShareType = 'V'; // V C I
            newDocumentLinks.add(newLink);
        }

        String error = 'false';
        try {
            insert newDocumentLinks;
        } catch (Exception e) {
            error = e.getMessage();
        }

        try {
            if (error == 'false') delete queriedDocumentLinks;
        } catch (Exception e) {
        }

        return error;
    }

    /**
* @description query location associated with currently logged in user
* @return location record
*/
    @AuraEnabled
    public static List<Building__c> getLocation() {
        //Set<String> locationName = new Set<String> ();
        List<Building__c> locations = new List<Building__c>();
        Id loggedInUserId = UserInfo.getUserId();

        List<GroupMember> groupMembers = [
                SELECT Group.Name, Group.Id
                FROM GroupMember
                WHERE UserOrGroupId = :loggedInUserId AND Group.Type = 'Queue' AND Group.DeveloperName LIKE 'CM%'
        ];
        if (!groupMembers.isEmpty()) {
            Set<Id> queueIds = new Set<Id>();
            for (GroupMember grpMember : groupMembers) {
                //locationName.add((grpMember.Group.Name).substringAfter(': '));
                queueIds.add(grpMember.Group.Id);
            }
            /*if (locationName.size() > 0) {
                locations = [
                        SELECT Id, Name
                        FROM Building__c
                        WHERE Name IN :locationName
                        AND RecordTypeId = :TLOrgConstants.BUILDING_RECORD_TYPE_ID
                        Order By CreatedDate ASC
                ];
            }*/
            
            if(!queueIds.isEmpty()){
                List<Location_Queue__c> locationQueues = [SELECT Id, Building_Id__c, Building_Id__r.Name, Queue_Id__c, Queue_Label__c, Queue_Prefix__c FROM Location_Queue__c WHERE Queue_Id__c IN: queueIds];
                if(!locationQueues.isEmpty()){
                    for(Location_Queue__c locQueue : locationQueues ){
                        Building__c loc = new Building__c();
                        loc.Id = locQueue.Building_Id__c;
                        loc.Name = locQueue.Building_Id__r.Name;
                        locations.add(loc);
                    }
                }
            }
        }
        return locations;
    }

    /**
* @description query the logged in user's Person Account using the Email field
* @return Person Account Id
*/
    @AuraEnabled(cacheable=true)
    public static Id getContactId(){
        Id contactId = null;

        String userEmail = UserInfo.getUserEmail();

        if(!string.isEmpty(userEmail)){
            for(Contact relatedContact : [SELECT Id FROM Contact WHERE Email =:userEmail]){
                contactId = relatedContact.Id;
            }
        }
        return contactId;
    }

    @AuraEnabled
    public static string getRecordTypeId() {
        return TLOrgConstants.SUPPORT_REQUEST_RECORD_TYPE_ID;
    }

    public class CategoryWrapper {
        @AuraEnabled
        public String categoryName { get; set; }
        @AuraEnabled
        public String iconName { get; set; }

        public CategoryWrapper(String cName, String iName) {
            categoryName = cName;
            iconName = iName;
        }
    }
}