/**
 * @description apex controller for the case routing config component
 * @name trac_CaseRoutingController
 * @group CaseRouting
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-08-15
 */

public with sharing class trac_CaseRoutingController {
    public static final Integer MAX_LABEL_LENGTH = 40;

    /**
     * @description retrieves all routing rules based on if they're flagged as active
     * @return list of routing rules
     */
    @AuraEnabled(Cacheable=true)
    public static List<Object> getAllRoutingRules() {
        return [SELECT Id,DeveloperName,Label,Routing_Name__c,Routing_Model__c,Routing_Label__c,Is_Active__c,Run_On_Escalate__c, (
                SELECT Id
                FROM Case_Routing_Line_Items__r
                WHERE Is_Active__c = TRUE)
        FROM Case_Routing__mdt];
    }


    /**
     * @description retrieves all routing criteria based on if they're flagged as active
     * @param routingId the parent routing rule id
     * @return list of routing criteria
     */
    @AuraEnabled(Cacheable=true)
    public static List<Object> getChildCriteria(String routingId) {
        System.debug(routingId);
        return [SELECT Id,DeveloperName,Label,Field__c,Value__c,Is_Active__c
        FROM Case_Routing_Line_Item__mdt
        WHERE Case_Routing__c = :routingId];
    }


    /**
     * @description gets a list of prefixes for each queue type
     * @return map of type to list of prefixes
     */
    @AuraEnabled(Cacheable=true)
    public static Map<String,List<String>> getPrefixes() {
        Map<String,List<String>> typeToPrefixes = new Map<String, List<String>>();
        List<Location_Queue_Type__mdt> queueTypes = [SELECT Id, Queue_Name_Prefix__c, Location_Record_Type__c FROM Location_Queue_Type__mdt];
        for(Location_Queue_Type__mdt queueType : queueTypes) {
            List<String> prefixes = new List<String>{queueType.Queue_Name_Prefix__c};
            if(typeToPrefixes.get(queueType.Location_Record_Type__c) != null) {
                prefixes.addAll(typeToPrefixes.get(queueType.Location_Record_Type__c));
            }
            typeToPrefixes.put(queueType.Location_Record_Type__c,prefixes);
        }
        return typeToPrefixes;
    }


    /**
     * @description creates or updates parent and child metadata records
     * @param routingRule parent routing rule metadata record
     * @param criteria children routing criteria metadata records
     * @return map of result and message
     */
    @AuraEnabled
    public static Map<String,String> upsertRoutingRule(Object routingRule, List<Object> criteria) {
        try {
            System.debug(routingRule);
            for (Object c : criteria) System.debug(c);

            // Parent metadata record
            Map<String, Object> rule = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(routingRule));

            // children metadata records
            List<Object> childCriteria = (List<Object>) JSON.deserializeUntyped(JSON.serialize(criteria));

            Long now = Datetime.now().getTime();

            String parentDevName;
            Map<String, Object> fieldMap = new Map<String, Object>();
            if (rule.get('DeveloperName') != null) {
                parentDevName = String.valueOf(rule.get('DeveloperName'));
            } else {
                parentDevName = 'R' + now + +UserInfo.getUserId().substring(3, 18);  // generateDevName(String.valueOf(rule.get('Label')));
                if ([SELECT Id FROM Case_Routing__mdt WHERE DeveloperName = :parentDevName].size() >= 1) {
                    return new Map<String, String>{
                            'error' => 'A routing rule with this name already exists. Please choose a different name.'
                    };
                }
            }
            if(rule.get('Routing_Name__c') != null)    { fieldMap.put('Routing_Name__c',     String.valueOf(rule.get('Routing_Name__c'))); }
            if(rule.get('Routing_Label__c') != null)   { fieldMap.put('Routing_Label__c',    String.valueOf(rule.get('Routing_Label__c'))); }
            if(rule.get('Routing_Model__c') != null)   { fieldMap.put('Routing_Model__c',    String.valueOf(rule.get('Routing_Model__c'))); }
            if(rule.get('Is_Active__c') != null)       { fieldMap.put('Is_Active__c',       Boolean.valueOf(rule.get('Is_Active__c'))); }
            if(rule.get('Run_On_Escalate__c') != null) { fieldMap.put('Run_On_Escalate__c', Boolean.valueOf(rule.get('Run_On_Escalate__c'))); }


            // Metadata container for deployment
            List<Metadata.CustomMetadata> allMetadata = new List<Metadata.CustomMetadata>();

            // Add the parent metadata routing record
            allMetadata.add(trac_MetadataUtils.buildCustomMetadata(
                    'Case_Routing.' + parentDevName,
                    String.valueOf(rule.get('Label')),
                    fieldMap)
            );
            System.debug(childCriteria);
            // Add the children routing criteria
            for (Integer i = 0; i < childCriteria.size(); i++) {
                Map<String, Object> criterion = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(childCriteria[i]));
                String uniqueName = (criterion.get('DeveloperName') != null) ? String.valueOf(criterion.get('DeveloperName')) : 'C' + now + (i - 100 < 0 ? (i - 10 < 0 ? '00' + i : '0' + i) : String.valueOf(i)) + UserInfo.getUserId().substring(3, 18);
                String childField = String.valueOf(criterion.get('Field__c'));

                Map<String, Object> childFieldToValue = new Map<String, Object>();
                if(criterion.get('Is_Active__c') != null) {
                    childFieldToValue.put('Is_Active__c', Boolean.valueOf(criterion.get('Is_Active__c')));
                }
                childFieldToValue.put('Field__c', childField);
                childFieldToValue.put('Value__c', String.valueOf(criterion.get('Value__c')));
                childFieldToValue.put('Case_Routing__c', parentDevName);

                String parentLabel = String.valueOf(rule.get('Label'));
                String fullName = parentLabel + '-' + childField;
                if (fullName.length() > MAX_LABEL_LENGTH) {
                    fullName = parentLabel.substring(0,(parentLabel.length()-(fullName.length()-MAX_LABEL_LENGTH))) + '-' + childField;
                }
                if(fullName.length() > MAX_LABEL_LENGTH) {
                    fullName = fullName.substring(1,MAX_LABEL_LENGTH+1);
                }

                allMetadata.add(trac_MetadataUtils.buildCustomMetadata(
                        'Case_Routing_Line_Item.' + uniqueName,
                        fullName,
                        childFieldToValue)
                );
            }

            String jobId = trac_MetadataUtils.createUpdateMetadata(allMetadata);
//            String jobId = '';
            return new Map<String, String>{'success' => jobId};
        }
        catch (Exception e) {
            System.debug(e.getStackTraceString());
            return new Map<String,String>{'error' => e.getMessage()};
        }
    }


    @AuraEnabled
    public static Map<String,String> routingRuleActivation(String routingDevName, String label, Boolean setActiveTo) {
        try {
            // Metadata container for deployment
            List<Metadata.CustomMetadata> allMetadata = new List<Metadata.CustomMetadata>();

            Map<String, Object> fieldMap = new Map<String, Object>();
            fieldMap.put('Is_Active__c',setActiveTo);

            // Add the parent metadata routing record
            allMetadata.add(trac_MetadataUtils.buildCustomMetadata(
                    'Case_Routing.' + routingDevName,
                    label,
                    fieldMap)
            );

            String jobId = trac_MetadataUtils.createUpdateMetadata(allMetadata);
            return new Map<String, String>{'success' => jobId};
        }
        catch (Exception e) {
            System.debug(e.getStackTraceString());
            return new Map<String,String>{'error' => e.getMessage()};
        }

    }





    public static String generateDevName(String input) {
        Integer outputMaxLength = 40;
        String output = '';
        List<String> charGroups = input.split('[^A-Za-z0-9]');
        for (Integer i = 0; i < charGroups.size(); i++) {
            if(charGroups[i] == '' || charGroups[i] == null) {
                charGroups.remove(i--);
            }
        }
        output = String.join(charGroups,'_');
        try {
            output = output.substring(0, outputMaxLength-2) + '_X';
        } catch (Exception e) {}
        return output;
    }





    //TODO put in a utils class
    static List<String> hexMap = new List<String> {
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'};
    public static String NewGuid(Boolean includeDashes) {
        String randomStringAsHex = EncodingUtil.convertToHex(Crypto.generateAesKey(128));

        String versionHexBits = randomStringAsHex.substring(14,16); // 7th bit
        String variantHexBits = randomStringAsHex.substring(18,20); // 9th bit

        Integer versionIntBits = convertHexToInt(versionHexBits);
        Integer variantIntBits = convertHexToInt(variantHexBits);

        Integer versionShiftedIntBits = versionIntBits & 15 | 64;  // (i & 0x0f) | 0x40
        Integer variantShiftedIntBits = variantIntBits & 63 | 128; // (i & 0x3f) | 0x80

        String versionShiftedHexBits = convertIntToHex(versionShiftedIntBits); // Always begins with 4
        String variantShiftedHexBits = convertIntToHex(variantShiftedIntBits); // Always begins with one of 8,9,a,b

        String sep = includeDashes ? '-' : '';

        return randomStringAsHex.substring(0,8)
                + sep + randomStringAsHex.substring(8,12)
                + sep + versionShiftedHexBits + randomStringAsHex.substring(14,16)
                + sep + variantShiftedHexBits + randomStringAsHex.substring(18,20)
                + sep + randomStringAsHex.substring(20);
    }

    static Integer convertHexToInt(String hex) {
        Integer d0 = hexMap.indexOf(hex.substring(1,2));
        Integer d1 = hexMap.indexOf(hex.substring(0,1));

        return d0 + (d1*16);
    }

    static String convertIntToHex(Integer intval) {
        // https://stackoverflow.com/a/13465128
        String hs0 = hexMap.get(intval & 15); // i & 0x0f
        String hs1 = hexMap.get(((intval >> 4) & 15)); //(i >> 4) & 0x0f
        return hs1+hs0;
    }
}