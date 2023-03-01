/*************************************************************************************************************************************
 Author      :   Pawel Biszczak
 Description :   This class is used to get Metadata records without queries
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               26 Apr, 2021    Pawel Biszczak      Initial Deployment
 **************************************************************************************************************************************/
public with sharing class MetadataUtils {
    private static final String METADATA_OBJECT_ENDING = '__mdt';
    private static final String CALLER_CLASS_ENDING = 'Caller';
    private static final String METADATA_CLASS_PREFIX = 'MetadataUtils.';

    public static List<SObject> getAllRecords(String metadataType){
        if(metadataType == null){
            return new List<SObject>();
        }
        MetadataRecordsCaller caller = getCaller(metadataType);
        if(caller == null) {
            return new List<SObject>();
        }
        return caller.getAll();
    }

    public static List<SObject> getRecordsByDeveloperName(String metadataType, String developerName){
        if(metadataType == null || developerName == null){
            return new List<SObject>();
        }
        MetadataRecordsCaller caller = getCaller(metadataType);
        if(caller == null) {
            return new List<SObject>();
        }
        return caller.getRecordsByDeveloperName(developerName);
    }

    private static MetadataRecordsCaller getCaller(String metadataType){
        String className = METADATA_CLASS_PREFIX + metadataType.removeEnd(METADATA_OBJECT_ENDING) + CALLER_CLASS_ENDING;
        Type callerType = (Type.forName(className));
        return (callerType != null) ? (MetadataUtils.MetadataRecordsCaller) (Type.forName(className)).newInstance() : null;
    }

    public Map<String, Regional_Migration__mdt> getAllRegions() {
        return Regional_Migration__mdt.getAll();
    }

    public class OpportunityStagesSettingCaller extends MetadataRecordsCaller {
        public override List<SObject> getRecordsByDeveloperName(String developerName){
            return new List<SObject> { OpportunityStagesSetting__mdt.getInstance(developerName) };
        }

        public override List<SObject> getAll(){
            return new List<SObject> ((List<SObject>)OpportunityStagesSetting__mdt.getAll().values());
        }
    }

    public class OpportunityProductCodeCaller extends MetadataRecordsCaller {
        public override List<SObject> getRecordsByDeveloperName(String developerName){
            return new List<SObject> { OpportunityProductCode__mdt.getInstance(developerName) };
        }

        public override List<SObject> getAll(){
            return new List<SObject> ((List<SObject>)OpportunityProductCode__mdt.getAll().values());
        }
    }

    public abstract class MetadataRecordsCaller {
        public abstract List<SObject> getRecordsByDeveloperName(String developerName);
        public abstract List<SObject> getAll();
    }
}