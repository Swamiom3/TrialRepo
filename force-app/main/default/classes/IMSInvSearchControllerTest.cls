/************************************************************************************************************************************
Author      :   Vamsi
Description :   This class provides sufficient test coverage for IMSInvSearchController class
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                  DETAIL
1           20 Nov 2021         Vamsi             Initial Developement
**************************************************************************************************************************************/
@isTest
public class IMSInvSearchControllerTest {
    @isTest
    static void loadIFrameURLTest(){
        Building__c build = new Building__c();
        build.Name = 'Test Building';
        build.CreatedDate = System.today();
        insert build;
        String url = IMSInvSearchController.loadIFrameURL(build.Id);
        System.assertEquals('https://spacestation-staging.wework.com/#/locations/inventory/search', url,'URL Check Complete');
    }
}