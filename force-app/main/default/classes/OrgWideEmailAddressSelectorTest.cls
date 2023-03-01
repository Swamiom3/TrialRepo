/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for OrgWideEmailAddressSelector class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR            DETAIL
    1          6 Jul, 2021    Pawel Biszczak    Initial Deployment
**************************************************************************************************************************************/
@isTest
public with sharing class OrgWideEmailAddressSelectorTest {
    private static OrgWideEmailAddressSelector orgWideEmailAddressSelector = new OrgWideEmailAddressSelector();

    @isTest
    static void shouldGetRecordsByDisplayNamesIfOrgWideAddressesPresented(){
        List<OrgWideEmailAddress> addresses;
        List<OrgWideEmailAddress> existingAddresses;

        Test.startTest();
        existingAddresses = [SELECT Id, DisplayName
                             FROM OrgWideEmailAddress
                             LIMIT 1];
        addresses = orgWideEmailAddressSelector.getOrgWideEmailAddressesByDisplayNames(new List<String>{
                existingAddresses[0].DisplayName
        });
        Test.stopTest();

        System.assert(!addresses.isEmpty(), 'List should not be empty');
        System.assertEquals(existingAddresses[0].Id, addresses[0].Id, 'Org Wide Email Address Id should have same value');
    }

    @isTest
    static void shouldRetrieveNoRecords(){
        List<OrgWideEmailAddress> addressesForFakeName;
        List<OrgWideEmailAddress> addressesForEmptyList;

        Test.startTest();
        addressesForFakeName = orgWideEmailAddressSelector.getOrgWideEmailAddressesByDisplayNames(new List<String>{
                   'Fake_Email_Display_Name_For_OrgWideEmailAddressSelectorTest'
        });
        addressesForEmptyList = orgWideEmailAddressSelector.getOrgWideEmailAddressesByDisplayNames(new List<String>());
        Test.stopTest();

        System.assert(addressesForFakeName.isEmpty(), 'List should be empty on fake org wide address name');
        System.assert(addressesForEmptyList.isEmpty(), 'List should be empty on empty org wide address names list');
    }
}