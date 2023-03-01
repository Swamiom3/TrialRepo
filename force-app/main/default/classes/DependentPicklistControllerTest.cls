/************************************************************************************************************************************
    Author      :   Ashish Mishra    
    Description :   This class contain test methods that are used in DependentPicklistController class. 
    
    History     :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1          05-06-2019         	Ashish Mishra      		Initial Developement
**************************************************************************************************************************************/
@isTest
public class DependentPicklistControllerTest {
    
    /****************************************************************************************************************************
        Author              : Ashish Mishra
        Description         : This Method is use to test,getting a dependent picklist value for given sobject,controlling field and dependent field.
        Created Date        : 06-06-2019
       	Issue               : ST-4034
   *****************************************************************************************************************************/
    public static testMethod void testgetDependentPicklistMap() {
        DatabaseResult result = DependentPicklistController.getDependentMap('Lead', 'LeadSource','LeadSource_Sub_Type__c');
        Map<String, List<String>> mapFields = (Map<String, List<String>>)result.data;
        System.assert(mapFields.get('Event').size() > 0);
        System.assert(result.data != null, 'Dependent picklist is not comming');
    }
    /****************************************************************************************************************************
        Author              : Ashish Mishra
        Description         : This Method is use to test,getting a dependent picklist value for given sobject,controlling field is null and dependent field is null.
        Created Date        : 06-06-2019
       	Issue               : ST-4034
   *****************************************************************************************************************************/
    public static testMethod void testgetDependentWhenObjectWithNoFieldValue() {
        DatabaseResult result = DependentPicklistController.getDependentMap('Lead', null, null);
        Map<String, List<String>> mapFields = (Map<String, List<String>>)result.data;
        System.assert(mapFields.isEmpty());
    }
    /****************************************************************************************************************************
        Author              : Ashish Mishra
        Description         : This Method is use to test,getting a dependent picklist value for given sobject,controlling field is not present in given sobject and dependent field.
        Created Date        : 06-06-2019
       	Issue               : ST-4034
   *****************************************************************************************************************************/
    public static testMethod void testgetDependentWhenObjectNotContainField() {
        DatabaseResult result = DependentPicklistController.getDependentMap('Contact', 'isTest','LeadSource_Sub_Type__c');
        Map<String, List<String>> mapFields = (Map<String, List<String>>)result.data;
        System.assert(mapFields.isEmpty());
    }
}