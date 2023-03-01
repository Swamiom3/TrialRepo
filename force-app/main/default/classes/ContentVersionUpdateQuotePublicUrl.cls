/************************************************************************************************************************************
    Author      :   Arun Vadduri
    Description :   This class generates and updates the PublicURL on Quote.
    Issue No    :   TWSPG-4305, TWSPG-9859
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION      DATE          AUTHOR            DETAIL
    1        1st November 2021 Arun Vadduri      Initial Development
    2        8th June 2022     Maciej Miłosz     Filtering only 'Active' agreements
**************************************************************************************************************************************/
public with sharing class ContentVersionUpdateQuotePublicUrl extends SObjectTriggerHandler {
    public List<ContentVersion> versions;
    private String versionReason = 'Final Signed';
    private ContentDocumentLinkSelector documentLinkSelector = new ContentDocumentLinkSelector();
    private ContentDistributionSelector distributionSelector = new ContentDistributionSelector();
    private ContractAgreementSelector agreementSelector = new ContractAgreementSelector();
    
    public ContentVersionUpdateQuotePublicUrl() {
        this((List<ContentVersion>) Trigger.new);
    }

    @TestVisible
    private ContentVersionUpdateQuotePublicUrl(List<ContentVersion> newVersions) {
        this.versions = newVersions;
    }
    
    public override void afterInsert() {
        updateQuotePublicURL();
    }
    
    private void updateQuotePublicURL() {
        Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>();
        for(ContentVersion version : versions) {
            if(version.ReasonForChange == versionReason) {
                contentVersionMap.put(version.ContentDocumentId, version);
            }
        }
        
        if(contentVersionMap.isEmpty()) {
            return;
        }
        
        Map<Id, Id> documentToAgreement = getDocToAgreementMap(contentVersionMap.keySet());
        List<ContentDistribution> newContDistributions = createContentDistribution(documentToAgreement, contentVersionMap);
        
        if(newContDistributions.isEmpty()) {
            return;
        }
        
        Database.insert(newContDistributions, false);

        List<SBQQ__Quote__c> quotes = getQuotesToUpdate(documentToAgreement);

        Database.update(quotes, false);
    }

    private Map<Id, Id> getDocToAgreementMap(Set<Id> documentIds) {
        String agreementAPIName = APXT_Redlining__Contract_Agreement__c.getSObjectType().getDescribe().getName();
        Map<Id, Id> documentToAgreement = new Map<Id, Id>();
        for(ContentDocumentLink link : documentLinkSelector.getDocLinksByDocumentIds(documentIds)) {
            if(agreementAPIName == link.LinkedEntityId.getSObjectType().getDescribe().getName()) {
                documentToAgreement.put(link.ContentDocumentId, link.LinkedEntityId);
            }
        }
        return documentToAgreement;
    }

    private List<ContentDistribution> createContentDistribution(
        Map<Id, Id> documentToAgreement, Map<Id, ContentVersion> contentVersionMap) {
        List<ContentDistribution> newContDistributions = new List<ContentDistribution>();
        for(Id docId: documentToAgreement.keySet()) {ContentVersion version = contentVersionMap.get(docId);
            newContDistributions.add(new ContentDistribution(ContentVersionId=version.Id, Name = version.Id+' PublicLink'));
        }
        return newContDistributions;
    }

    private List<SBQQ__Quote__c> getQuotesToUpdate(Map<Id, Id> documentToAgreement) {
        Map<Id, Id> agreementToQuote = new Map<Id, Id>();
        String whereClause = 'Quote_Id__c != null AND Id IN :ids AND APXT_Redlining__Status__c = :status';
        for(APXT_Redlining__Contract_Agreement__c agreement: agreementSelector.getAgreementsWithWhereClause(documentToAgreement.values(), 'Active',  whereClause)) {
            agreementToQuote.put(agreement.Id, agreement.Quote_Id__c);
        }

        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        for(ContentDistribution disti: distributionSelector.getRecsByDocumentIds(documentToAgreement.keySet())) {
            if(documentToAgreement.get(disti.ContentDocumentId) != null && 
                agreementToQuote.containsKey(documentToAgreement.get(disti.ContentDocumentId))) {
                    quotes.add(new SBQQ__Quote__c(
                                        Id = agreementToQuote.get(documentToAgreement.get(disti.ContentDocumentId)), 
                                        Contract_Public_URL__c = disti.DistributionPublicUrl
                                    )
                              );
            }
        }
        return quotes;
    }
}