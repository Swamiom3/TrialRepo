/**
* Controller class for Case Translation Component component .
* @author Shubham Jain, Traction on Demand
* @date 2019-10-09
*/
public with sharing class trac_TranslationControllerCase {

    /**
     * @description
     * Given a recordID ane the target language and returns translated text
     * for Case's Subject and Description
     * @param recordID
     * @param targetLanguage : the language to translate to
     * @return returns TranslationWrapper which contains translated text for Subject and Description fields.
     */
    @AuraEnabled
    public static TranslationWrapper doTranslation(String recordID, String targetLanguage) {
        try {
            String translatedText = trac_TranslationControllerGeneric.doTranslationHelper(
                    recordID,
                    targetLanguage,
                    'Case',
                    'Description',
                    'Subject');
            if (translatedText == null) return null;
            TranslationWrapper translationWrapper = new TranslationWrapper(translatedText.substringBefore(TLOrgConstants.SEPARATOR), translatedText.substringAfter(TLOrgConstants.SEPARATOR));
            return translationWrapper;
        } catch (Exception ex) {
            return null;
        }
    }

    @AuraEnabled
    public static List<LanguageWrapper> getLanguageOptions() {
        try {
            List<LanguageWrapper> languageWrappers = new List<LanguageWrapper>();
            for (Supported_Language__mdt supportedLanguage : [
                    SELECT MasterLabel, DeveloperName, Language_Code__c
                    FROM Supported_Language__mdt
            ]) {
                languageWrappers.add(new LanguageWrapper(supportedLanguage.Language_Code__c, supportedLanguage.MasterLabel));
            }
            return languageWrappers;
        } catch (Exception ex) { return null; }

    }

    public class TranslationWrapper {
        @AuraEnabled
        public String description { get; set; }
        @AuraEnabled
        public String subject { get; set; }

        public TranslationWrapper(String des, String sub) {
            description = des;
            subject = sub;
        }
    }

    public class LanguageWrapper {
        @AuraEnabled
        public String languageCode { get; set; }
        @AuraEnabled
        public String languageLabel { get; set; }

        public LanguageWrapper(String lCode, String lLabel) {
            languageCode = lCode;
            languageLabel = lLabel;
        }
    }

}