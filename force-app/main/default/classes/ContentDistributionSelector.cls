/*************************************************************************************************************************************
 Author      :   Arun
 Description :   This class is selector implementation of particular SObject (ContentDistribution)
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               11/11/2021       Arun        Initial Deployment
 **************************************************************************************************************************************/
public inherited sharing class ContentDistributionSelector extends SObjectSelector {
	public ContentDistributionSelector() {
        super(ContentDistribution.getSObjectType());
    }
    
    /****************************************************************************************************************************
     Author              : Arun
     Description         : This method is used to get default fields from Object
     Created Date        : 11/11/2021
     *****************************************************************************************************************************/
    public override Set<String> getDefaultFields(){
        return new Set<String>{'Id', 'DistributionPublicUrl', 'ContentDocumentId'};
    }
    
    /****************************************************************************************************************************
     Author              : Arun
     Description         : This method is used to get ContentDistribution based on ContentDocumentIds
     Created Date        : 11/11/2021
     *****************************************************************************************************************************/
    public List<ContentDistribution> getRecsByDocumentIds(Set<Id> documentIds) {
        if(documentIds == null || documentIds.isEmpty()){
            return null;
        }
        List<Object> bindings = new List<Object>{documentIds};
        return (List<ContentDistribution>) getSObjects(null, '(ContentDocumentId IN :documentIds)', bindings);
    }
}