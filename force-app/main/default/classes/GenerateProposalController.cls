/**********************************************************************************************************
    Author        :  Ashish Sharma
    Description   :  Controller for generateProposal component
    Issue No.     :  ST-8071
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE          AUTHOR           DETAIL
      1         06-May-2021    Ashish Sharma      ST-8071
**********************************************************************************************************/
public with sharing class GenerateProposalController {
    @AuraEnabled
    public static Opportunity getOppInfo(Id oppId) {
        return [SELECT Id, StageName, Actual_Start_Date__c, Account.Name, Desired_Term_Length_in_months__c, Building__c
                FROM Opportunity WHERE Id =:oppId];
    }
        
    @AuraEnabled(cacheable=true)
    public static Inventory getInventories(Id buildingId, Id oppId) {
        Inventory inventory = new Inventory();
        Map<Id, Inventory__c> idToInventory = new Map<Id, Inventory__c>(
            [SELECT Id, Name, Building__c, Building__r.Name, Building__r.UUID__c, Capacity__c, Floor_Name__c,
                    List_Price__c, Contract_Status__c, UUID__c
             FROM Inventory__c 
             WHERE Building__c = :buildingId AND Archived_Date__c = null AND Contract_Status__c = 'Contract Sent']
        );
        Set<Id> matchingInventoryIds = new Set<Id>();
        List<Interest__c> interestsWithoutInventories = new List<Interest__c>();
        for(Interest__c interest :  [SELECT Inventory_Id__c, Building__c FROM Interest__c WHERE Opportunity__c =:oppId]) {
            if(idToInventory.containsKey(interest.Inventory_Id__c)) {
                matchingInventoryIds.add(interest.Inventory_Id__c);
            }
            if(interest.Building__c != null && interest.Inventory_Id__c == null) {
                interestsWithoutInventories.add(interest);
            }
        }
        inventory.matchingInventoryIds = matchingInventoryIds.isEmpty() ? null : matchingInventoryIds;
        inventory.inventoriesForBuilding = idToInventory.isEmpty() ? null : idToInventory.values();
        inventory.userRec = UserUtility.getUserById(UserInfo.getUserId());
        inventory.interestsWithoutInventories = interestsWithoutInventories;
        return inventory;
    }

    @AuraEnabled
    public static List<Inventory__c> searchInventories(String inventoryName) {
        if(String.isBlank(inventoryName)) {
            return null;
        }
        inventoryName = '%'+inventoryName+'%';
        return [SELECT Id, Name, Building__c, Building__r.Name, Building__r.UUID__c, Capacity__c, 
                       Floor_Name__c, List_Price__c, Contract_Status__c, UUID__c 
                FROM Inventory__c 
                WHERE Name LIKE :inventoryName AND Archived_Date__c = null AND Contract_Status__c = 'Contract Sent'];
    }
    
    @AuraEnabled
    public static DatabaseResult generateProposal(String body, Opportunity opportunityToUpdate, List<Interest__c> interests) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Generate_Proposal_Service_' + getEnvName());
        System.debug(getEnvName());
        request.setMethod('POST');
        request.setHeader('Content-Type','application/json');
        request.setBody(body);
        
        HTTPResponse response = new Http().send(request);
        system.debug('response' +response);
        if(response.getStatusCode() != 200) {
            return new DatabaseResult(false, null, response.getStatus());
        }
        if(opportunityToUpdate != null) {
            MetadataDrivenTriggerHandler.disableExecution();
            opportunityToUpdate.Proposal_URL__c = response.getBody();
            update opportunityToUpdate;
            MetadataDrivenTriggerHandler.enableExecution();
        }        
        if(interests != null && !interests.isEmpty()) {
            InterestDuplicateManagementTrH.isFromGenerateProposal = true;
            upsert interests;
        }
        return new DatabaseResult(true, response.getBody(), 'Proposal generated');        
    }
    
    private static String getEnvName() {
        if(!LightningComponentController.runningInASandbox()) {
            return 'Prod';
        } else {
            return URL.getSalesforceBaseUrl().getHost().SubStringBefore('.').substringAfter('--').capitalize();
        }
    }
    
    public class Inventory {
        @AuraEnabled
        public List<Inventory__c> inventoriesForBuilding{get;set;}
        @AuraEnabled
        public Set<Id> matchingInventoryIds{get;set;}
        @AuraEnabled
        public List<Interest__c> interestsWithoutInventories{get;set;}
        @AuraEnabled
        public User userRec{get;set;}
    }
}