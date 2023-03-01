/************************************************************************************************************************************
    Author 		: Shobhit Gahlot
    Description : This class will have all the logic to test PolymorphicRelatedFieldBinder
--------------------------------------------------------------------------------------------------------------------------------------
    VERSION					DATE					AUTHOR							DETAIL
    1					    10 June, 2020		    Shobhit Gahlot               	Initial Development
*************************************************************************************************************************************/
@isTest
public class PolymorphicRelatedFieldBinderTest {
    
    @TestSetup
    static void testDataSetup(){
        //SalesConsoleSettings.createSettings();
        UtilAccount.GetNewAccounts(1, true);
    } 
    
    @isTest
    public static void getvalueToDisplay(){
        List<Account> lstAccount = new List<Account>([SELECT Id, Name FROM Account LIMIT 1]);
        system.assert(!lstAccount.isEmpty());
        PolymorphicRelatedFieldBinder objPolymorphicRelatedFieldBinder = new PolymorphicRelatedFieldBinder();
        objPolymorphicRelatedFieldBinder.sObjectId = lstAccount[0].Id;
        objPolymorphicRelatedFieldBinder.fieldApiName = 'Name';
        objPolymorphicRelatedFieldBinder.getvalueToDisplay();
        system.assert(objPolymorphicRelatedFieldBinder.valueToDisplay == lstAccount[0].Name);
    }
}