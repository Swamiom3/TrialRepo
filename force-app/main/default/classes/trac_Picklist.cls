/**
 * @description Utilities for Picklist fields
 * @author Shubham Jain, Traction on Demand
 * @date 2019-08-07
 */
public class trac_Picklist {

    /**
     *  @description Returns picklist labels in a list of strings for input object, field and recordtype,
     *  returns empty list if invalid field/object using rest api call.
     *  @author      Shubham Jain, Traction on Demand.
     *  @param objectAPIName - object api name
     *  @param fieldAPIName - picklist field api name
     *  @param recordTypeDeveloperName - record type developer name
     *  @return picklistValues - list of picklist values
     */
    @AuraEnabled
    public static List<String> getPicklistValueBasedUponRecordType(String objectAPIName, String fieldAPIName, String recordTypeDeveloperName) {

        List<String> picklistValues = new List<String>();

        try {
            //get record type Id
            List<RecordType> recordTypes = [
                    SELECT Id, Name
                    FROM RecordType
                    WHERE SobjectType = :objectAPIName AND DeveloperName = :recordTypeDeveloperName
                    limit 1
            ];
            Id recordTypeId = (!recordTypes.isEmpty()) ? recordTypes.get(0).Id : null;

            if (recordTypeId != null) {

                String method = 'GET';
                String endpoint = String.format('/services/data/v41.0/ui-api/object-info/{0}/picklist-values/{1}/{2}', new String[]{
                        objectAPIName, recordTypeId, fieldAPIName
                });

                HttpRequest request = new HttpRequest();
                request.setEndpoint('callout:' + TLOrgConstants.CALL_ME_BACK_NAMED_CREDENTIALS + endPoint);
                request.setMethod(method);

                HTTPResponse response = (new Http()).send(request);

                if (response.getStatusCode() == 200) {

                    Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    if (root.containsKey('values')) {
                        List<Object> picklistVals = (List<Object>) root.get('values');
                        for (Object picklistVal : picklistVals) {
                            Map<String, Object> picklistValMap = (Map<String, Object>) picklistVal;
                            picklistValues.add((String) picklistValMap.get('label'));
                        }
                    }

                }

            }
        } catch (Exception e) {
            System.debug('Error in get picklist labels: line' + e.getLineNumber() + ', ' + e.getMessage());
        }
        return picklistValues;
    }

    /**
    * @description Returns a map storing controlling picklist value and
    * list of dependent picklist values
    * @param objectApiName - object api name
    * @param controllingField - controlling picklist field api name
    * @param dependentField - dependent picklist field api name
    * @return picklistMap - map of controlling picklist to list of dependent picklist values.
    */
    @AuraEnabled
    public static Map<String, List<String>> getDependentMap(String objectApiName, string contrfieldApiName, string depfieldApiName) {
        String controllingField = contrfieldApiName.toLowerCase();
        String dependentField = depfieldApiName.toLowerCase();

        Map<String, List<String>> objResults = new Map<String, List<String>>();

        Map<String, Schema.SObjectType> objectGlobalMap = Schema.getGlobalDescribe();

        try{
            //get the type being dealt with
            Schema.SObjectType objType = objectGlobalMap.get(objectApiName);

            if (objType == null) {
                return objResults;
            }

            Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();

            if (!objFieldMap.containsKey(controllingField) || !objFieldMap.containsKey(dependentField)) {
                return objResults;
            }

            Schema.SObjectField theField = objFieldMap.get(dependentField);
            Schema.SObjectField ctrlField = objFieldMap.get(controllingField);

            List<Schema.PicklistEntry> contrEntries = ctrlField.getDescribe().getPicklistValues();
            List<PicklistEntryWrapper> depEntries = wrapPicklistEntries(theField.getDescribe().getPicklistValues());
            List<String> controllingValues = new List<String>();

            for (Schema.PicklistEntry ple : contrEntries) {
                String label = ple.getValue();
                objResults.put(label, new List<String>());
                controllingValues.add(label);
            }

            for (PicklistEntryWrapper plew : depEntries) {
                String label = plew.label;
                String validForBits = base64ToBits(plew.validFor);
                for (Integer i = 0; i < validForBits.length(); i++) {
                    String bit = validForBits.mid(i, 1);
                    if (bit == '1') {
                        objResults.get(controllingValues.get(i)).add(label);
                    }
                }
            }
        }catch(Exception e){
            System.debug('Error in get dependent picklist map: line' + e.getLineNumber() + ', ' + e.getMessage());
        }

        return objResults;
    }

    public static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }

    public static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor)) return '';

        String validForBits = '';

        for (Integer i = 0; i < validFor.length(); i++) {
            String thisChar = validFor.mid(i, 1);
            Integer val = base64Chars.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }

        return validForBits;
    }

    private static final String base64Chars = '' +
            'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
            'abcdefghijklmnopqrstuvwxyz' +
            '0123456789+/';


    private static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> PLEs) {
        return (List<PicklistEntryWrapper>)
                JSON.deserialize(JSON.serialize(PLEs), List<PicklistEntryWrapper>.class);
    }

    public class PicklistEntryWrapper {
        public String active { get; set; }
        public String defaultValue { get; set; }
        public String label { get; set; }
        public String value { get; set; }
        public String validFor { get; set; }
        public PicklistEntryWrapper() {
        }

    }
}