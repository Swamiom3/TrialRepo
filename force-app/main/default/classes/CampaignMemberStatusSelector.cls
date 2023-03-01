/*********************************************************************************************************
	Author        :  Krishna Somwanshi
	Description   :  Selector class for CampaignMemberStatus object
	Issue No.     :  ST-10132
	History       :
-----------------------------------------------------------------------------------------------------------
	VERSION        DATE            AUTHOR             DETAIL
	1          14-01-2022      Krishna Somwanshi    Initial development 
**********************************************************************************************************/
public inherited sharing class CampaignMemberStatusSelector extends SObjectSelector {
    
    private static final List<String> DEFAULT_FIELDS = new List<String>{'Id',
                                                                        'Label',
                                                                        'CampaignId'};
                                                                             
    public CampaignMemberStatusSelector() {
        super(CampaignMemberStatus.getSObjectType());
    }
    
    public override Set<String> getDefaultFields(){
        return new Set<String>(DEFAULT_FIELDS);
    }
    
    public List<CampaignMemberStatus> getCampaignMemberStatusById(List<Id> ids){
        if (ids == null || ids.isEmpty()) {
            return new List<CampaignMemberStatus>();
        }
        List<String> fields = new List<String>{'Id',
                                               'Label',
                                               'CampaignId'};
        String whereClause = '(CampaignId IN : ids)';
        return (List<CampaignMemberStatus>) getSObjects(fields, whereClause, new List<Object>{ids});
    }
}