/************************************************************************************************************************************
Author      :   Tayo Chestnut
Description :   Gets Prefix to Decide which direction to take a particular Flow
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION      DATE         AUTHOR              DETAIL
    1            2/5/2022   Tayo Chestnut     Execute from Flow
**************************************************************************************************************************************/
public with sharing class ObjectTypeFinder {

    @InvocableMethod (label='Object Finder' description='Pulls Prefix from ID to Find Object API Name' category='RevCloud Toolkit')
    public static List<ReturnOutput> findObjectNameByPrefix (List<Request> requests) {
        List<ReturnOutput> returnedObjectList = new List<ReturnOutput>();

        for(request r: requests){
            Id myId = r.sfId;
            String sObjName = myId.getSObjectType().getDescribe().getName();
            ReturnOutput ro = new ReturnOutput();
            ro.objectName = sObjName;
            returnedObjectList.add(ro);
        }
        return returnedObjectList;
    }

    public class Request{
        @InvocableVariable
        public String sfId;
    }

    public class ReturnOutput{
        @InvocableVariable
        public String objectName;
    }
}