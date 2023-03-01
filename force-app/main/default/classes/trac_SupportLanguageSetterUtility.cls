/**
 * Controller for the lightning web component used in the Support community.
 * LWC Name: trac_DefaultLanguageSetter
 * @author Shubham Jain, Traction on Demand
 * @date   6/18/2020
 */
public class trac_SupportLanguageSetterUtility {

    private static final String COMMUNITY_FALLBACK_LANGUAGE = 'en_US';

    /**
    * Retrieve the community language code based on browser language code.
    *
    * @param browserLanguageCode: Browser language code.
    *
    * @return Community language code.
    */

    @AuraEnabled
    public static String getRedirectionLanguageByBrowserLanguage(String browserLanguageCode) {
        List<Browser_Language_Mapping__mdt> browserLanguageMdtList = new List<Browser_Language_Mapping__mdt>();
        browserLanguageMdtList = [
                SELECT Community_Language_Code__c
                FROM Browser_Language_Mapping__mdt
                WHERE Browser_Language_Code__c = :browserLanguageCode
        ];
        return browserLanguageMdtList.isEmpty() ? COMMUNITY_FALLBACK_LANGUAGE : browserLanguageMdtList[0].Community_Language_Code__c;
    }
}