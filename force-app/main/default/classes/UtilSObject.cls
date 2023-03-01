/************************************************************************************************************************************
    Author       :     Mikolaj Juras    
    Description  :     Class to Support sObject operations
    Issue No     :     ST-7780
    History      :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO        DETAIL
    1           9 April 2021        Mikolaj Juras       ST-7780         Initial Developement
    3           13 July 2021        Mikolaj Juras       ST-8584         Add method to trim picklist if over 100 values
**************************************************************************************************************************************/
public class UtilSObject {
    public static void trimTooLongPicklist(SObject currentObject, Schema.SObjectField picklistField) {
        if (currentObject?.get(picklistField) == null || picklistField.getDescribe().getType() != Schema.DisplayType.MULTIPICKLIST){
            return;
        }
        String currentPicklist = (String) currentObject.get(picklistField);
        List <String> picklistValues = currentPicklist.split(';');
        if(picklistValues.size() <= 100) {
            return;
        }
        while (picklistValues.size() > 100) {
            picklistValues.remove(picklistValues.size() - 1);
        }
        currentObject.put(picklistField, String.join(picklistValues, ';'));
    }

    public static void trimTooLongPicklist(SObject currentObject, List <Schema.SObjectField> picklistFields) {
        for (Schema.SObjectField fied : picklistFields) {
            trimTooLongPicklist(currentObject, fied);
        }    
    }
}