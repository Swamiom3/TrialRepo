/************************************************************************************************************************************
    Author      :   Ashish Mishra    
    Description :   This class contain methods that are used in EnziDependentPicklist lightning component. 
    
    History     :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1          05-06-2019         	Ashish Mishra      		Initial Developement
	2		   06-06-2019			Krishna Tupe			Code Optimization and make more genric 
**************************************************************************************************************************************/
public class DependentPicklistController {
    public class LightningComponentControllerException extends Exception{}
    public static Boolean isInvoker = false;
    public static Savepoint sp {get;set;}
    static {
        isInvoker = ApexDebugLog.registerRootInvoker(ApexDebugLog.InvokerType.AURA, 'DependentPicklistController' + 'getDependentMap', ApexDebugLog.InvokerType.AURA);
    }
    public static final String base64Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    
   /****************************************************************************************************************************
        Author              : Ashish Mishra
        Description         : This Method is use to get dependent picklist value of given sobject,controlling field and dependent field.
        Created Date        : 05-06-2019
       	Issue               : ST-4034
		LastModified Date   : 06-06-2019
		LastModified By		: Krishana Tupe
   *****************************************************************************************************************************/
    @AuraEnabled 
    public static DatabaseResult getDependentMap(String sObjectName, String controllingFieldAPIName, String dependentFieldAPIName) {
        try{
            sp = Database.setSavepoint();        
            Map<String, List<String>> mapSobjectResults = new Map<String, List<String>>();
            if(String.isBlank(sObjectName) || String.isBlank(controllingFieldAPIName) || String.isBlank(dependentFieldAPIName)){
                return new DatabaseResult(mapSobjectResults);
            }        
            Type objType = Type.forName(sObjectName);
            sObject objNewSobject = (sObject)objType.newInstance();
            String strControllingField = controllingFieldAPIName.toLowerCase();
            String strDependentField = dependentFieldAPIName.toLowerCase(); 
            Map<String, Schema.SObjectField> mapSobjectFieldMap = objNewSobject.getSObjectType().getDescribe().fields.getMap();
            if(!mapSobjectFieldMap.containsKey(strControllingField) || !mapSobjectFieldMap.containsKey(strDependentField)){
                return new DatabaseResult(mapSobjectResults); 
            }
            Schema.SObjectField controlilngFieldSchema = mapSobjectFieldMap.get(strControllingField);
            Schema.SObjectField dependentFieldSchema = mapSobjectFieldMap.get(strDependentField);        
            
            List<Schema.PicklistEntry> lstControlilngFieldPicklistEntries = controlilngFieldSchema.getDescribe().getPicklistValues();
            List<PicklistEntryWrapper> lstDependentFieldPicklistEntries = getDependentPicklistEntriesWrapper(dependentFieldSchema.getDescribe().getPicklistValues());
            
            List<String> lstControllingValues = new List<String>();        
            for (Schema.PicklistEntry objSchemaPicklistEntry : lstControlilngFieldPicklistEntries) {
                String strLabel = objSchemaPicklistEntry.getLabel();
                mapSobjectResults.put(strLabel, new List<String>());
                lstControllingValues.add(strLabel);
            }
            for(PicklistEntryWrapper objPicklistEntryWrapper : lstDependentFieldPicklistEntries){
                String strValidForBits = base64ToBits(objPicklistEntryWrapper.validFor);
                if(String.isNotBlank(strValidForBits)){
                    for(Integer iIndex = 0; iIndex < strValidForBits.length(); iIndex++){
                        String strBit = strValidForBits.mid(iIndex, 1);
                        if (strBit == '1') {
                            mapSobjectResults.get(lstControllingValues.get(iIndex)).add(objPicklistEntryWrapper.label);
                        }
                    }  
                }            
            }
            return new DatabaseResult(mapSobjectResults);
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx,'sObjectName:'+sObjectName+' controllingFieldAPIName'+controllingFieldAPIName+' dependentFieldAPIName'+dependentFieldAPIName, 'DependentPicklistController' , 'getDependentMap');
            return (new DatabaseResult(pEx));
        }
    }
    
    public static List<PicklistEntryWrapper> getDependentPicklistEntriesWrapper(List<Schema.PicklistEntry> lstPicklistEntries) {        
        return lstPicklistEntries != NULL ? (List<PicklistEntryWrapper>)JSON.deserialize(JSON.serialize(lstPicklistEntries), List<PicklistEntryWrapper>.class) : NULL;
    }
    
    /****************************************************************************************************************************
        Author              : Ashish Mishra
        Description         : This method is used to convert decimalToBinary.
        Created Date        : 06-06-2019
       	Issue               : ST-4034
		LastModified Date   : 06-06-2019
		LastModified By		: Krishana Tupe
   *****************************************************************************************************************************/
    public static String decimalToBinary(Integer indexOfMidChar) {
        String strBits = '';
        while (indexOfMidChar > 0) {
            Integer remainder = Math.mod(indexOfMidChar, 2);
            indexOfMidChar = Integer.valueOf(Math.floor(indexOfMidChar / 2));
            strBits = String.valueOf(remainder) + strBits;
        }
        return strBits;
    }
    
    /****************************************************************************************************************************
        Author              : Ashish Mishra
        Description         : This method is used to convert base64ToBits.
        Created Date        : 06-06-2019
       	Issue               : ST-4034
		LastModified Date   : 06-06-2019
		LastModified By		: Krishana Tupe
   *****************************************************************************************************************************/
    public static String base64ToBits(String strValidFor){
        if(String.isBlank(strValidFor)){
            return NULL; 
        }        
        String strValidForBits = '';        
        for(Integer iIndex = 0; iIndex < strValidFor.length(); iIndex++) {
            String thisChar = strValidFor.mid(iIndex, 1);            
            Integer indexOfMidChar = base64Chars.indexOf(thisChar);            
            String bits = decimalToBinary(indexOfMidChar).leftPad(6, '0');
            strValidForBits += bits;
        }       
        return strValidForBits;
    }
    
   /****************************************************************************************************************************
        Author              : Ashish Mishra
        Description         : It is a Picklist Wrapper Class.
        Created Date        : 05-06-2019
       	Issue               : ST-4034
		LastModified Date   : 06-06-2019
		LastModified By		: Krishana Tupe
   *****************************************************************************************************************************/
    public class PicklistEntryWrapper{
        public String active {get;set;}
        public String defaultValue {get;set;}
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public String value {get;set;}
        public String validFor {get;set;}

        public PicklistEntryWrapper(){}

        public PicklistEntryWrapper(String label, String value){
            this.label = label; 
            this.value = value; 
        }
    }    
}