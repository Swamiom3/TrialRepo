/**
 * @description Apex class trac_ContentDocumentLink
 * @author Daniel Labonte, Traction on Demand
 * @date 2020-03-03
 */

public with sharing class trac_ContentDocumentLink extends SObjectDomain {
    public List<ContentDocumentLink> links;

    @TestVisible
    private List<Maintenance_Attachment__e> linkEvents = new List<Maintenance_Attachment__e>();

    private trac_CaseSelector parentSelector = new trac_CaseSelector();

    public trac_ContentDocumentLink() {
        super();
        this.links = (List<ContentDocumentLink>) records;
    }

    public trac_ContentDocumentLink(List<ContentDocumentLink> links) {
        super(links);
        this.links = links;
    }


    public override void onAfterInsert() {
        publishCustomEvent();
    }



    private void publishCustomEvent() {
        Map<Id,Profile> sysApiProfilIds = new Map<Id, Profile>([SELECT Id FROM Profile WHERE Name = 'System API']);
        if(sysApiProfilIds.keySet().contains(UserInfo.getProfileId())) return;

        Map<Id,Case> linkedCases = parentSelector.getCasesFromIdSet(
                TLList.collectIds(links,ContentDocumentLink.LinkedEntityId),
                new Set<String>{'Corrigo_Event_Flag__c'});
        if(linkedCases.isEmpty()) return;

        Map<Id,ContentDocument> documents = new Map<Id, ContentDocument>([
                SELECT Id, LatestPublishedVersionId
                FROM ContentDocument
                WHERE Id IN :TLList.collectIds(links,ContentDocumentLink.ContentDocumentId)]);

        Map<Id,ContentVersion> versions = new Map<Id, ContentVersion>([
                SELECT Id,ContentUrl,ContentSize,FileType,Description,SharingPrivacy,Title
                FROM ContentVersion
                WHERE Id IN :TLList.collectIds(documents.values(),ContentDocument.LatestPublishedVersionId)]);

        for(ContentDocumentLink link : links) {
            if(Id.valueOf(link.LinkedEntityId).getSobjectType() == Case.SObjectType) {
                Case linkedCase = linkedCases.get(link.LinkedEntityId);
                if(linkedCase != null && (linkedCase.Corrigo_Event_Flag__c || Test.isRunningTest())) {
                    ContentVersion version = versions.get(documents.get(link.ContentDocumentId).LatestPublishedVersionId);
                    linkEvents.add(new Maintenance_Attachment__e(
                            ContentVersionId__c = version.Id,
                            ContentVersionURL__c = version.ContentUrl,
                            BodyLength__c = version.ContentSize,
                            ContentType__c = version.FileType,
                            Description__c = version.Description,
                            IsPartnerShared__c = false,
                            isPrivate__c = version.SharingPrivacy == 'Private',
                            Name__c = version.Title,
                            ParentId__c = link.LinkedEntityId));
                }
            }
        }

        List<Database.SaveResult> results = EventBus.publish(linkEvents);
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                }
            }
        }
    }
}