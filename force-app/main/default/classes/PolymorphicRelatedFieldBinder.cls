/************************************************************************************************************************************
    Author 		: Shobhit Gahlot
    Description : This class will have all the logic to query and get related field value for WhoId and WhatId
--------------------------------------------------------------------------------------------------------------------------------------
    VERSION					DATE					AUTHOR							DETAIL
    1					    10 June, 2020		    Shobhit Gahlot               	Initial Development
*************************************************************************************************************************************/
public class PolymorphicRelatedFieldBinder {
    public Id sObjectId{get;set;}
    public String fieldApiName{get;set;}
    public String valueToDisplay;
    
    public String getvalueToDisplay() {
        if(String.isNotBlank(sObjectId)){
            String query = 'SELECT Id, '+fieldApiName+' FROM '+sObjectId.getSobjectType().getDescribe().getName()+' WHERE Id=: sObjectId';
            sObject objWhoData = Database.query(query);
            valueToDisplay = String.valueOf(objWhoData.get(fieldApiName));
        }
        return valueToDisplay;
    }
}