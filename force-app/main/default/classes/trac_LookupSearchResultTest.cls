@isTest
public class trac_LookupSearchResultTest {
    @isTest
    public static void tracLookupSearchResult(){
     Id id;
     String sObjectType;
     String icon;
     String title;
     String subtitle;
     String apiName;
     Test.startTest();
     trac_LookupSearchResult tracLookup = new trac_LookupSearchResult(id,sObjectType,icon, title,subtitle,apiName);
        Id id1 = tracLookup.getId();
        String sObjectType1 = tracLookup.getSObjectType();
        String title1 = tracLookup.getTitle();
        String subtitle1 = tracLookup.getSubtitle();
        String Icon1 = tracLookup.getIcon();
        String apiname1= tracLookup.getApiName();
        Test.stopTest();
    }
    
}