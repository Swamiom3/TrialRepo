/**
* @author Shubham Jain, Traction on Demand
* @date 2019-10-09
*/

public with sharing class trac_TranslateCallout {

    static Global__c globalCustomSetting = Global__c.getOrgDefaults();
    String endPoint = globalCustomSetting.Translation_End_Point__c;
    String placeHolderAPI = globalCustomSetting.Translation_API_Key__c;

    public trac_TranslationParser translateLanguage(String stringToTranslate, String languageCode) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endPoint + '?key=' + placeHolderAPI + '&target=' + languageCode + '&q=' + EncodingUtil.urlEncode(stringToTranslate, 'UTF-8'));
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {
            // If the request is successful, parse the JSON response
            return trac_TranslationParser.parse(response.getBody());
        } else {
            return null;
        }
    }

}