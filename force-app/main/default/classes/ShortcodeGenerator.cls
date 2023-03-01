/************************************************************************************************************************************
    Author       :  Shubham Nandwana   
    @Description :  Create unique identifier
    Issue No     :  TWSPG-711
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO        DETAIL
    1           20 August 2021      Shubham Nandwana    TWSPG-711       Initial Developement              
**************************************************************************************************************************************/
public without sharing class ShortcodeGenerator {
    
    private final Integer SHORTCODE_LENGTH = 6;
    private final Decimal PRIME_NO = 1500450271;
    
    public String getMessageShortCode (String uuid){
        String finalVal;
        Integer seed = 0;
        finalVal = getUniqueCode(uuid, seed);
        List<Account> accounts = [SELECT Id FROM Account WHERE Member_Short_Code__c != null AND Member_Short_Code__c =: finalVal LIMIT 1];
        while(!accounts.isEmpty()){
            finalVal = getUniqueCode(uuid, seed++);
            if(Limits.getAggregateQueries() < 101){
                accounts = [SELECT Id FROM Account WHERE Member_Short_Code__c != null AND Member_Short_Code__c =: finalVal LIMIT 1];
            }else{
                return null;
            }
        }
        return finalVal;
    }
    
    private String getUniqueCode(String uuid, Integer seed){
        String resultFinal;
        uuid = uuid.replace('-', '');
        Decimal hexDecValue = hexToDecimal(uuid);
        Decimal seededNo = PRIME_NO + seed;
        Decimal modules = hexDecValue - (seededNo * (Math.floor(hexDecValue / seededNo)));
        resultFinal = generateBase36Number(modules);
        return getValidatedCode(resultFinal);
    }
    
    private Decimal hexToDecimal(String hex) {
        String[] hexCharacters = hex.toLowerCase().split('');
        Decimal result = 0;
        for (Integer i = 0; i < hexCharacters.size(); i++) {
            switch on hexCharacters[i] {
                when '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' {
                    result = (result * 16) + Integer.valueOf(hexCharacters[i]);
                }when 'a' {
                    result = (result * 16) + 10;
                }when 'b' {
                    result = (result * 16) + 11;
                }when 'c' {
                    result = (result * 16) + 12;
                }when 'd' {
                    result = (result * 16) + 13;
                }when 'e' {
                    result = (result * 16) + 14;
                }when 'f' {
                    result = (result * 16) + 15;
                }when else {
                }
            }
        }
        return result;
    }

    private String generateBase36Number(Decimal decimalValue){
        Integer inputBase = 10;
        Integer outputBase = 36;
        String outputValue = ''; 
        String numericBaseData = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        Integer x;
        if(decimalValue == 0){
            return '0';
        }else{
            while(decimalValue > 0){
                X = (Integer)(((decimalValue/outputBase) - (Integer)(decimalValue/outputBase))* outputBase + 1.5);
                outputValue = numericBaseData.subString(X - 1,X)+outputValue;
                decimalValue = Integer.valueOf(decimalValue/outputBase);
            }
        }
        return outputValue;
    }
    
    @TestVisible
    private String getValidatedCode(String key) {
        key = key.toUpperCase();
        key = key.replace('O', '0');
        String finalValue = null;
        if(key.length() < SHORTCODE_LENGTH){
            finalValue = key;
            while(finalValue.length() != SHORTCODE_LENGTH){
                finalValue += 'J';
            }
        }else{
            for (integer i = 0; i < key.length() - SHORTCODE_LENGTH + 1; i++) {
                finalValue = key.substring(i, i + SHORTCODE_LENGTH);
                if (finalValue.isAlphaNumeric()) {
                    break;
                } else {
                    finalValue = null;
                    continue;
                }
            }
        }
        return finalValue;
    }
    
    private class ShortcodeGeneratorException extends Exception {}
    
}