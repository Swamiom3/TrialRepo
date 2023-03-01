/**
* Generic Translation Controller class.
* @author Shubham Jain, Traction on Demand
* @date 2019-10-09
*/
public with sharing class trac_TranslationControllerGeneric {

/**
 * @description
 * Given a recordID, the target language, and the specified string to translate to,
 * this function translates the language and return translated text
 *
 * @param recordID
 * @param targetLanguage : the language to translate to
 * @param recordTypeString : the record type
 * @param originalFieldNameOne : the name of the field we want to translate
 * @param originalFieldNameTwo : the name of the field we want to translate
 * @return True if translation succeeded , false if translation did not happen (may be because there's no need to translate)
 */
    public static String doTranslationHelper(String recordID, String targetLanguage, String recordTypeString, String originalFieldNameOne, String originalFieldNameTwo) {

        SObject record = Database.query('SELECT Id, ' + originalFieldNameOne + ',' + originalFieldNameTwo + ' FROM ' + recordTypeString + ' WHERE Id=\'' + recordID + '\' LIMIT 1');
        String stringToTranslate = (String) record.get(originalFieldNameOne) + TLOrgConstants.SEPARATOR + (String) record.get(originalFieldNameTwo);
        if (stringToTranslate == null) return null;
        trac_TranslateCallout translation = new trac_TranslateCallout();
        trac_TranslationParser parsedTranslation = translation.translateLanguage(stringToTranslate, targetLanguage);
        String translatedText = parsedTranslation.data.translations[0].translatedText;
        return translatedText;
    }


}