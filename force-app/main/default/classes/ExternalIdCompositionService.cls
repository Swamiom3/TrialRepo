/*************************************************************************************************************************************
 Author      :   Oleg Krasko
 Description :   This class keeps the service method which constructs encoded External ID based on set of fields passed
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               02/10/2022      Oleg Krasko         Initial Deployment
 **************************************************************************************************************************************/
public with sharing class ExternalIdCompositionService {
    @TestVisible
    private String externalIdAPIName;
    private Set<String> fieldsToCombine;
    private String collectedFieldValues;
    private String encodedFieldValues;
    private AlgorithmName algorithmName = ExternalIdCompositionService.AlgorithmName.SHA_256;
    private EncodingMethod encodingMethod = ExternalIdCompositionService.EncodingMethod.BASE64ENCODE;
    private List<SObject> sObjects;
    private static integer counter = 0;

    public ExternalIdCompositionService(List<SObject> sObjects, Set<String> fieldsToCombine, String externalIdAPIName,
                                    AlgorithmName algorithmName, EncodingMethod encodingMethod){
        if (algorithmName != null) {
            this.algorithmName = algorithmName;
        }
        if (encodingMethod != null) {
            this.encodingMethod = encodingMethod;
        }
        this.externalIdAPIName = externalIdAPIName;
        this.fieldsToCombine = fieldsToCombine;
        this.sObjects = sObjects;
    }
    
    public ExternalIdCompositionService(List<SObject> sObjects, Set<String> fieldsToCombine, String externalIdAPIName){
        this(sObjects, fieldsToCombine, externalIdAPIName, null, null);
    }
    
    public ExternalIdCompositionService(List<SObject> sObjects, Set<String> fieldsToCombine, String externalIdAPIName, AlgorithmName algorithmName){
        this(sObjects, fieldsToCombine, externalIdAPIName, algorithmName, null);
    }

    private void gatherFieldValuesIntoString(SObject inputSObject){
        collectedFieldValues = '';
        for(String field : fieldsToCombine){
            if (inputSObject.get(field) == null) {
                if (field == 'name' && isAutoNumberFieldName(inputSObject, field)) {
                    collectedFieldValues += 'Auto Number';
                }
                continue;
            }
            collectedFieldValues += inputSObject.get(field);
        }
        collectedFieldValues += '_' + counter++;
    }

    private void encodeFieldValues(){
        encodedFieldValues = '';
        Blob targetBlob = Blob.valueOf(collectedFieldValues);
        Blob hashBlob = Crypto.generateDigest(algorithmName.name().replace('_', '-'), targetBlob);
        encodedFieldValues = encodingMethod == ExternalIdCompositionService.EncodingMethod.BASE64ENCODE ?
                        EncodingUtil.base64Encode(hashBlob) : EncodingUtil.convertToHex(hashBlob);
    }

    public void assignExternalID(){
        if (validateBaseParams()) {
            return;
        }
        for (SObject sObj : sObjects) {
            if (sObj.get(externalIdAPIName) != null) {
                continue;
            }
            gatherFieldValuesIntoString(sObj);
            makeUnique();
            encodeFieldValues();
            sObj.put(externalIdAPIName, encodedFieldValues);
        }
    }

    private void makeUnique(){
        collectedFieldValues += System.now().getTime() + UserInfo.getOrganizationId() + '_' + counter++;
    }

    private Boolean validateBaseParams(){
        return sObjects?.isEmpty() != false 
            || fieldsToCombine?.isEmpty() != false
            || externalIdAPIName == null 
            || !sObjects[0].getSObjectType().getDescribe().fields.getMap().containsKey(externalIdAPIName);
    }

    private Boolean isAutoNumberFieldName(SObject inputSObject, String fieldApiName){
        return inputSObject.getSObjectType().getDescribe().fields.getMap()
                            .get(fieldApiName).getDescribe().isAutoNumber();
    }

    public enum AlgorithmName {
        MD5,
        SHA1,
        SHA3_256,
        SHA3_384,
        SHA3_512,
        SHA_256,
        SHA_512
    }

    public enum EncodingMethod{
        BASE64ENCODE,
        CONVERT_TO_HEX
    }
}