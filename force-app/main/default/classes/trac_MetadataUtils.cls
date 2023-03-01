/**
 * @description class to handle deploying new routing metadata records
 * @name trac_MetadataUtils
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-08-15
 */

public class trac_MetadataUtils implements Metadata.DeployCallback {

    /**
     * @description debugs the deployment result
     * @param result deployment result
     * @param context callback context
     */
    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
        if (result.status == Metadata.DeployStatus.Succeeded) {
            System.debug(' success : '+ result);
        } else {
            System.debug(' fail : '+ result);
        }
    }


    /**
     * @description builds a properly format custom metadata object based on some inputs
     * @param developerName unique metadata name
     * @param label readable metadata label
     * @param fieldToValue map of a metadata field to its value
     * @return custom metadata object
     */
    public static Metadata.CustomMetadata buildCustomMetadata(String developerName, String label, Map<String,Object> fieldToValue){
        Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
        customMetadata.fullName = developerName;
        customMetadata.label = label;

        for(String key : fieldToValue.keySet()){
            Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
            customField.field = key;
            customField.value = fieldToValue.get(key);
            customMetadata.values.add(customField);
        }
        return customMetadata;
    }


    /**
     * @description deploys the custom metadata
     * @param customMetadatas list of custom metadata objects
     * @return id of the deployment
     */
    public static String createUpdateMetadata(List<Metadata.CustomMetadata> customMetadatas){
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        for(Metadata.CustomMetadata customMetadata : customMetadatas) {
            mdContainer.addMetadata(customMetadata);
        }

        trac_MetadataUtils callback = new trac_MetadataUtils();

        Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
        return String.valueOf(jobId);
    }
}