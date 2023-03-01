/************************************************************************************************************************************
	Author		: 	Nikhil Mehta
	Description	: 	This class handle Geography insertion using google api.
	----------------------------------------------------------------------------------------------------------------------------------
	VERSION		DATE	        	AUTHOR                     DETAIL
    1           4 December 2018     Nikhil Mehta            Initial Developement
    2           3 August 2021       Krasko Oleg             Refactoring
**************************************************************************************************************************************/
public class GeographyHandler {
    private final String GOOGLE_ID = 'AIzaSyD-Ahtqw-AUvIG3EAUa4wNIGI_4_gyRWiQ';
    private final String setTimeOutLabel = Label.Google_Geolocation_API_SetTimeOut;
    private String baseGoogleGeolocationURL = 'callout:Google_Geolocation_API/geocode/json?address={0}&key={1}';
    @TestVisible
    private static final GeographySelector geographySelector = new GeographySelector();

    /************************************************************************************************************************************
        Author              :   Nikhil Mehta
        Description         :   This method returns map id with geographies for addressses.
        Created Date  		:   04 December 2018
		Issue No.			:	ST-3200
    **************************************************************************************************************************************/
    public Map<Id, Id> getGeographies(Map<Id, Map<String, String>> inputGeographyData){
        Map<Id, String> geographyIdToPlaceId = new Map<Id, String>();
        if(inputGeographyData?.isEmpty() != false){
            return geographyIdToPlaceId;
        }
        Map<String, Geography__c> placeIdToGeographyMap = new Map<String, Geography__c>();
        for(Id recordId : inputGeographyData.keySet()){
            try{ // handle exception - Unable to tunnel through proxy. Proxy returns "HTTP/1.1 503 Service Unavailable"
                Geography__c geographyRec = getGeography(inputGeographyData.get(recordId));
                if(geographyRec == null){
                    continue;
                }
                geographyIdToPlaceId.put(recordId, geographyRec.Place_ID__c);
                placeIdToGeographyMap.put(geographyRec.Place_ID__c, geographyRec);
            }catch(Exception e){
                ApexDebugLog.logException(e, recordId, 'GeographyHandler', 'getGeographies');
            }
        }
        if(placeIdToGeographyMap.isEmpty()){
            return geographyIdToPlaceId;
        }
        Database.upsert(placeIdToGeographyMap.values(), false);
        for(Id recordId : inputGeographyData.keySet()){
            geographyIdToPlaceId.put(recordId, placeIdToGeographyMap.get(geographyIdToPlaceId.get(recordId))?.Id);
        }
        return geographyIdToPlaceId;
    }

    /************************************************************************************************************************************
        Author              :   Nikhil Mehta
        Description         :   This method hit google api and insert geography .
        Created Date  		:   04 December 2018
		Issue No.			:	ST-3200
    **************************************************************************************************************************************/
    public Geography__c getGeography(Map<String, String> inputAddress){
        if(inputAddress?.isEmpty() != false){
            return null;
        }
        HttpRequest httpReq = prepareCallout(inputAddress);
        HTTPResponse httpResp = Test.isRunningTest() ? new QueueInsertGeoForBuildingMockRes().respond(httpReq) :
                new Http().send(httpReq);
        if(String.isBlank(httpResp?.getBody())){
            return null;
        }
        return parseResponse(httpResp);
    }


    /************************************************************************************************************************************
        Author              :   Nikhil Mehta
        Description         :   This method return end point url using google api setting.
        Created Date  		:   04 December 2018
    **************************************************************************************************************************************/
    private String getEndPointURL(String address, String city, String state, String country, String zip){
        String urlAddress = '' + address + ' ' + city + ' ' + state + ' ' + country + ' ' + (String.isNotBlank(zip) ? zip : '') ;
        urlAddress = EncodingUtil.urlEncode(urlAddress, 'UTF-8').replaceAll('\\+','%20');
        return String.format(baseGoogleGeolocationURL, new List<Object>{urlAddress, GOOGLE_ID});
    }

    private HttpRequest prepareCallout(Map<String, String> inputAddress){
        String address = inputAddress.get('address');
        String city = inputAddress.get('city');
        String state = inputAddress.get('state');
        String country = inputAddress.get('country');
        String zip = inputAddress.get('zip');
        String endPointUrl = getEndPointURL(address, city, state, country, zip);
        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint(endPointUrl);
        httpReq.setMethod('GET');
        httpReq.setHeader('accept', GlobalConstants.ACCEPT_HEADER);
        httpReq.setHeader('accept-encoding', GlobalConstants.ACCEPT_ENCODING_HEADER);
        if(String.isNotBlank(setTimeOutLabel)){
            Map<String, String> configData = (Map<String, String>) JSON.deserialize(setTimeOutLabel, Map<String, String>.class);
            if(!configData.isEmpty()){
                Integer icalloutTimeOut = configData.get('setTimeOut') != null ? Integer.valueOf(configData.get('setTimeOut')) : null;
                Boolean isApplied = configData.get('isApplied') != null ? Boolean.valueOf(configData.get('isApplied')) : false;
                if(isApplied && icalloutTimeOut != null && icalloutTimeOut < 120000){
                    httpReq.setTimeout(icalloutTimeOut);
                }
            }
        }
        return httpReq;
    }

    private Geography__c parseResponse(HttpResponse httpResp){
        GoogleResult googleResult = (GoogleResult) System.JSON.deserialize(httpResp.getBody(), GoogleResult.class);
        if(googleResult.results?.isEmpty() != false){
            return null;
        }
        List<Geography__c> geographies = (geographySelector.getGeographiesByPlaceId(googleResult.results[0].place_id));
        if(!geographies.isEmpty()){
            return geographies[0];
        }
        Result result = googleResult.results[0];
        Geography__c geography = new Geography__c(
                Geocode__Latitude__s = result.geometry.location.lat,
                Geocode__Longitude__s = result.geometry.location.lng,
                Formatted_Address__c = result.formatted_address,
                Place_ID__c = result.place_id,
                JSON__c = System.JSON.serialize(result),
                Location_Type__c = result.geometry.location_type
        );
        if(String.isNotBlank(result.formatted_address)){
            geography.Name = result.formatted_address.split(',')[0].abbreviate(80);
        }
        processAddressComponents(result.address_components, geography);
        return geography;
    }

    private void processAddressComponents(List<Address_components> address_components, Geography__c geography){
        for(Address_components addressComponent : address_components){
            if(addressComponent.types?.isEmpty() != false){
                continue;
            }
            if(addressComponent.types[0].equals('country')){
                geography.Country__c = addressComponent.long_name;
                geography.Country_Code__c = addressComponent.short_name;
            }
            if(addressComponent.types[0].equals('administrative_area_level_1')){
                geography.State__c = addressComponent.long_name;
                geography.Name += ', ' + geography.State__c;
            }
            if(addressComponent.types[0].equals('administrative_area_level_2')){
                geography.District__c = addressComponent.long_name;
            }
            if(addressComponent.types[0].equals('locality')){
                geography.City__c = addressComponent.long_name;
            }
            if(addressComponent.types[0].equals('postal_code')){
                geography.Zip_Postal_Code__c = addressComponent.long_name;
            }
        }
    }

    /********************************************************************************************************************
        Author              : Nikhil Mehta
        Description         : This following classes is used convert googleAPi response JSON data to object
        Created Date        : 14 May, 2018
    	Last Modified By	: Nikhil Mehta
        Last Modified Date  : 7 December 2018
    **********************************************************************************************************************/
    private class Address_components {
        public String long_name;
        public String short_name;
        public List<String> types;
    }
    private class Geometry {
        public Location location;
        public String location_type;
        public Viewport viewport;
    }
    private class GoogleResult {
        public List<Result> results;
        public String status;
    }
    private class Result {
        public List<Address_components> address_components;
        public String formatted_address;
        public Geometry geometry;
        public String place_id;
        public List<String> types;
    }
    private class Viewport {
        public Location northeast;
        public Location southwest;
    }
    private class Location {
        public Double lat;
        public Double lng;
    }

    public class GeographyException extends Exception {}
}