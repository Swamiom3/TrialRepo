/*************************************************************************************************************************************
 Author      :   Arun
 Description :   This class is selector implementation of particular SObject (ContentDocumentLink)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               11/11/2021       Arun        Initial Deployment
 **************************************************************************************************************************************/
public inherited sharing class  ContentDocumentLinkSelector extends SObjectSelector {
    public ContentDocumentLinkSelector() {
        super(ContentDocumentLink.getSObjectType());
    }

    /****************************************************************************************************************************
     Author              : Arun
     Description         : This method is used to get default fields from Object
     Created Date        : 11/11/2021
     *****************************************************************************************************************************/
    public override Set<String> getDefaultFields(){
        return new Set<String>{'Id', 'LinkedEntityId', 'ContentDocumentId'};
    }

    /****************************************************************************************************************************
     Author              : Arun
     Description         : This method is used to get ContentDocumentLinks based on ContentDocumentIds
     Created Date        : 11/11/2021
     *****************************************************************************************************************************/
    public List<ContentDocumentLink> getDocLinksByDocumentIds(Set<Id> documentIds) {
        if(documentIds == null || documentIds.isEmpty()){
            return null;
        }
        List<String> fields = new List<String>{'Id',
                'LinkedEntityId',
                'ContentDocumentId'};
        List<Object> bindings = new List<Object>{documentIds};
        return (List<ContentDocumentLink>) getSObjects(fields, '(ContentDocumentId IN :documentIds AND LinkedEntityId != null)', bindings);
    }
}