/************************************************************************************************************************************
    Author         : Pawel Biszczak
    Description    : This class provides test utility methods that needs to be run in without sharing scope
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR            DETAIL      ISSUE
    1          19 Jan, 2022    Pawel Biszczak    Refactor    ST-9384
**************************************************************************************************************************************/
@IsTest
public without sharing class TestWithoutSharingUtility {
    public static List<Lead> getLeadsById(Id leadId) {
        return [ SELECT Id, OwnerId, Owner.Name, ConvertedContactId, ConvertedAccountId
                 FROM Lead
                 WHERE Id =: leadId ];
    }
}