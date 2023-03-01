/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class is selector implementation of particular SObject (OrgWideEmailAddress)
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR            DETAIL
    1          5 Jul, 2021    Pawel Biszczak    Initial Deployment
**************************************************************************************************************************************/
public with sharing class OrgWideEmailAddressSelector extends SObjectSelector {
    private static final List<String> DEFAULT_FIELDS = new List<String>{ 'Id',
                                                                         'Address',
                                                                         'DisplayName' };

    public OrgWideEmailAddressSelector() {
        super(OrgWideEmailAddress.getSObjectType());
    }

    public override Set<String> getDefaultFields(){
        return new Set<String> (DEFAULT_FIELDS);
    }

    public List<OrgWideEmailAddress> getOrgWideEmailAddressesByDisplayNames(List<String> names){
        if (names == null || names.isEmpty()) {
            return new List<OrgWideEmailAddress>();
        }
        return (List<OrgWideEmailAddress>) getSObjectByField(DEFAULT_FIELDS, 'DisplayName', names, false);
    }
}