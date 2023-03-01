/************************************************************************************************************************************
    Author      :   Vaishnavi Khandar 
    Description :   This class contains all the reusable methods related to update REAP integration.
    History     :
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     Date                AUTHOR                  DETAIL
    1           12 November 2021    Vaishnavi Khandar       Initial Developement
**************************************************************************************************************************************/
public class REAPIntegrationUtils {    
    /****************************************************************************************************************************
        Author              : Vaishnavi Khandar
        Description         : This method is used to make callout to REAP Integration api and map the fetched result on Builing Lease and Building Lease Financial Details.
        Created Date        : 12 November 2021
    *****************************************************************************************************************************/
    public static Map<String, Object> makeCalloutForREAPIntegration(List<Building__c> buildingsToCallout, Boolean quickAction) {
        Map<String, Object> reapIntegrationResult = new Map<String, Object>();
        List<Building__c> buildingRecordsToUpdate = new List<Building__c>();
        List<Building_Lease__c> buildingLeaseRecordsToUpsert = new List<Building_Lease__c>();
        List<Building_Lease_Financial_Details__c> buildingLeaseFinancialSecurityDetails = new List<Building_Lease_Financial_Details__c>();
        List<Building_Lease_Financial_Details__c> buildingLeaseFinancialDetailsToUpsert = new List<Building_Lease_Financial_Details__c>();
        Map<String, Building_Lease__c> existingBuildingLeaseRecordDetails = new Map<String, Building_Lease__c>();
        Map<String, Building_Lease__c> existingBuildingLeaseDetailsByLeaseUUID = new Map<String, Building_Lease__c>();
        Map<String, Building_Lease_Financial_Details__c> existingBuildingLeaseFinancialRecordDetails = new Map<String, Building_Lease_Financial_Details__c>();
        for(Building__c buildingRecord : buildingsToCallout){
            if(!buildingRecord.Building_Lease__r.isEmpty()){
                for(Building_Lease__c buidlingLeaserecord : buildingRecord.Building_Lease__r){
                    existingBuildingLeaseRecordDetails.put(buidlingLeaserecord.Area_UUID__c, buidlingLeaserecord);
                    existingBuildingLeaseDetailsByLeaseUUID.put(buidlingLeaserecord.Lease_UUID__c, buidlingLeaserecord);
                }
            }
            if(!buildingRecord.Building_Lease_Financial_Details__r.isEmpty()){
                for(Building_Lease_Financial_Details__c buidlingLeaseFinancialRecord : buildingRecord.Building_Lease_Financial_Details__r){
                    existingBuildingLeaseFinancialRecordDetails.put(buidlingLeaseFinancialRecord.Lease_financial_security_UUID__c, buidlingLeaseFinancialRecord);  
                }
            }
        }
        Date last7Days = Date.today().addDays(-7);
        try{
            for(Building__c building : buildingsToCallout){
                if(quickAction || (building.Building_Lease__r.isEmpty() || (!building.Building_Lease__r.isEmpty() && building.Building_Lease__r[0].LastModifiedDate < last7Days)) || Test.isRunningTest()){
                    String endPoint = APIConnection.getEndPointWithEnv('REAPIntegrationAPI');
                    APIConnection request = new APIConnection(endPoint);
                    request.setEndPointParams(new List<String>{building.UUID__c});
                    HttpResponse response = request.sendRequest('');
                    if(response != null){
                        Map<String, Object> jsonResponse = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                        if(response.getStatusCode() == 200){
                            reapIntegrationResult.put('Status', response.getStatus());
                            reapIntegrationResult.put('Message',jsonResponse.get('Message'));
                            REAPIntegrationUtils.updateREAPDetailsOnLeaseObject(jsonResponse, building, buildingLeaseRecordsToUpsert, buildingLeaseFinancialSecurityDetails, buildingRecordsToUpdate, existingBuildingLeaseRecordDetails, existingBuildingLeaseDetailsByLeaseUUID, existingBuildingLeaseFinancialRecordDetails);
                        } else {
                            reapIntegrationResult.put('Success', false);
                            reapIntegrationResult.put('Message', jsonResponse.get('Message'));
                        }
                    }
                }
            }
            //insert and update the building lease records
            if(!buildingLeaseRecordsToUpsert.isEmpty()){
                upsert buildingLeaseRecordsToUpsert;
                reapIntegrationResult.put('Success', true);
            }
            
            //update the Builing Lease Lookups on the Building Financial Securities
            if(!buildingLeaseFinancialSecurityDetails.isEmpty()){
               REAPIntegrationUtils.updateBuildingLeaseOnFinancialDetails(buildingLeaseFinancialSecurityDetails, buildingLeaseRecordsToUpsert, buildingLeaseFinancialDetailsToUpsert);
            }
            
            //insert and update the building lease financial securities details 
            if(!buildingLeaseFinancialDetailsToUpsert.isEmpty()){ 
                upsert buildingLeaseFinancialDetailsToUpsert;
            }
            
            //update the Measurement unit and Date of original lease agreement on Building
            if(!buildingRecordsToUpdate.isEmpty()){ 
                update buildingRecordsToUpdate;
            }
        } catch (Exception pEx) {
            ApexDebugLog.logException(pEx,JSON.serialize(buildingsToCallout),'REAPIntegrationUtils', 'makeCalloutForREAPIntegration');            
        }
        return reapIntegrationResult;
    }
    
    /****************************************************************************************************************************
        Author              : Vaishnavi Khandar
        Description         : This method is used to update the Building Lease Lookup field on Building Lease Financial Detail.
        Created Date        : 15 November 2021
    *****************************************************************************************************************************/    
    public static void updateBuildingLeaseOnFinancialDetails(List<Building_Lease_Financial_Details__c> buildingLeaseFinancialSecurityDetails, List<Building_Lease__c> buildingLeaseRecordsToUpsert, List<Building_Lease_Financial_Details__c> buildingLeaseFinancialDetailsToUpsert){ 
        Map<String, Building_Lease__c> buildingLeaseRecordDetails = new Map<String, Building_Lease__c>();
        for(Building_Lease__c buidlingLease : buildingLeaseRecordsToUpsert) {
            buildingLeaseRecordDetails.put(buidlingLease.Lease_UUID__c, buidlingLease);  
        }
        for(Building_Lease_Financial_Details__c buildingLeaseFinancialRecordDetail : buildingLeaseFinancialSecurityDetails) {
            if(String.isBlank(buildingLeaseFinancialRecordDetail.Name)) {
                buildingLeaseFinancialRecordDetail.Name = 'Security Details '+buildingLeaseRecordDetails.get(buildingLeaseFinancialRecordDetail.Lease_UUID__c).Name;
            }
            if((String.isBlank(buildingLeaseFinancialRecordDetail.Building_Lease__c) || buildingLeaseFinancialRecordDetail.Building_Lease__c == null) && buildingLeaseFinancialRecordDetail.Name.Contains(buildingLeaseRecordDetails.get(buildingLeaseFinancialRecordDetail.Lease_UUID__c).Name)) {
                buildingLeaseFinancialRecordDetail.Building_Lease__c = buildingLeaseRecordDetails.get(buildingLeaseFinancialRecordDetail.Lease_UUID__c).Id;
            }
            buildingLeaseFinancialDetailsToUpsert.add(buildingLeaseFinancialRecordDetail);
        }
    }
    /****************************************************************************************************************************
        Author              : Vaishnavi Khandar
        Description         : This method is used to update the payload details on Building Lease and Building Lease Financial Detail.
        Created Date        : 15 November 2021
    *****************************************************************************************************************************/  
    
    public static void updateREAPDetailsOnLeaseObject(Map<String, Object> jsonResponse, Building__c building, List<Building_Lease__c> buildingLeaseRecordsToUpsert, 
                                                    List<Building_Lease_Financial_Details__c> buildingLeaseFinancialSecurityDetails, List<Building__c> buildingRecordsToUpdate, 
                                                    Map<String, Building_Lease__c> existingBuildingLeaseRecordDetails, Map<String, Building_Lease__c> existingBuildingLeaseDetailsByLeaseUUID, 
                                                    Map<String, Building_Lease_Financial_Details__c> existingBuildingLeaseFinancialRecordDetails){
        List<Object> propertyDetails = (List<Object>)jsonResponse.get('properties');
        Map<String,Object> propertyDetail = new Map<String,Object>();
        Map<String,Object> buildingLeaseDetail = new Map<String,Object>();
        if(propertyDetails == null  || propertyDetails.isEmpty()) {
            return;
        }
        for(Object objPropertyDetail : propertyDetails){
            propertyDetail = (Map<String,Object>)objPropertyDetail;
            List<Object> buildingLeaseDetails = (List<Object>)propertyDetail.get('leases');
            for(Object leaseDetail : buildingLeaseDetails){
                buildingLeaseDetail = (Map<String,Object>)leaseDetail;
                List<Object> leaseAreaDetails = (List<Object>)buildingLeaseDetail.get('areas');
                if(leaseAreaDetails != null && !leaseAreaDetails.isEmpty()){
                    for(Object areaDetail : leaseAreaDetails){
                        Building_Lease__c buildingLease = new Building_Lease__c();
                        Map<String,Object> buildingAreaDetail = (Map<String,Object>) areaDetail;
                        if(existingBuildingLeaseRecordDetails.containsKey((String)buildingAreaDetail.get('area_uuid'))) {
                            Building_Lease__c buildingLeaseRecordDetail = existingBuildingLeaseRecordDetails.get((String)buildingAreaDetail.get('area_uuid'));
                            REAPIntegrationUtils.insertAndUpdateBuildingLeaseOnBuilding(building, buildingLeaseRecordDetail, propertyDetail, buildingLeaseDetail, buildingAreaDetail, buildingLeaseRecordsToUpsert, buildingRecordsToUpdate);
                        } else {
                            REAPIntegrationUtils.insertAndUpdateBuildingLeaseOnBuilding(building, buildingLease, propertyDetail, buildingLeaseDetail, buildingAreaDetail, buildingLeaseRecordsToUpsert, buildingRecordsToUpdate);
                        }
                    }
                } else {
                    Building_Lease__c buildingLease = new Building_Lease__c();
                    if(existingBuildingLeaseDetailsByLeaseUUID.containsKey((String)buildingLeaseDetail.get('lease_uuid'))) {
                        Building_Lease__c buildingLeaseRecordDetail = existingBuildingLeaseDetailsByLeaseUUID.get((String)buildingLeaseDetail.get('lease_uuid'));
                        REAPIntegrationUtils.insertAndUpdateBuildingLeaseOnBuilding(building, buildingLeaseRecordDetail, propertyDetail, buildingLeaseDetail, null, buildingLeaseRecordsToUpsert, buildingRecordsToUpdate);
                    } else {
                        REAPIntegrationUtils.insertAndUpdateBuildingLeaseOnBuilding(building, buildingLease, propertyDetail, buildingLeaseDetail, null, buildingLeaseRecordsToUpsert, buildingRecordsToUpdate);
                    }
                }
                List<Object> leaseFinancialDetails = (List<Object>)buildingLeaseDetail.get('lease_financial_securites');
                if(!leaseFinancialDetails.isEmpty()){
                    for(Object leaseFinancialDetail : leaseFinancialDetails){
                        Building_Lease_Financial_Details__c buildingLeaseFinancial = new  Building_Lease_Financial_Details__c();
                        Map<String,Object> buildingLeaseFinancialRecord = (Map<String,Object>)leaseFinancialDetail;
                        if(existingBuildingLeaseFinancialRecordDetails.containsKey((String)buildingLeaseFinancialRecord.get('lease_financial_security_uuid'))){
                            Building_Lease_Financial_Details__c buildingLeaseFinancialDetail = existingBuildingLeaseFinancialRecordDetails.get((String)buildingLeaseFinancialRecord.get('lease_financial_security_uuid'));
                            REAPIntegrationUtils.insertAndUpdateBuildingLeaseFinancialDetails(building, buildingLeaseFinancialDetail, buildingLeaseFinancialRecord, buildingLeaseDetail, buildingLeaseFinancialSecurityDetails, buildingRecordsToUpdate);
                        } else {
                            REAPIntegrationUtils.insertAndUpdateBuildingLeaseFinancialDetails(building, buildingLeaseFinancial, buildingLeaseFinancialRecord, buildingLeaseDetail, buildingLeaseFinancialSecurityDetails, buildingRecordsToUpdate);
                        }
                    } 
                }
            }
        }
    }
    
    /****************************************************************************************************************************
        Author              : Vaishnavi Khandar
        Description         : This method is used to insert and update payload details on Building Lease.
        Created Date        : 15 November 2021
    *****************************************************************************************************************/
    
    public static void insertAndUpdateBuildingLeaseOnBuilding(Building__c building, Building_Lease__c buildingLease, 
                                                              Map<String,Object> propertyDetail, Map<String,Object> buildingLeaseDetail, 
                                                              Map<String,Object> buildingAreaDetail, List<Building_Lease__c> buildingLeaseRecordsToUpsert, 
                                                              List<Building__c> buildingRecordsToUpdate) {
        buildingLease.Location_UUID__c = (String)propertyDetail.get('location_uuid');
        buildingLease.Property_UUID__c = (String)propertyDetail.get('property_uuid');
        buildingLease.Measurement_Unit__c = (String)propertyDetail.get('measure_unit');
        buildingLease.Lease_UUID__c = (String)buildingLeaseDetail.get('lease_uuid');
        if(buildingLease.Location__c == null) {
            buildingLease.Location__c = building.Id;
        }
        if(buildingLeaseDetail.get('possession_date') != null){
           buildingLease.Possession_Date__c = Date.valueOf((String)buildingLeaseDetail.get('possession_date'));
        }                                                          
        buildingLease.Type_of_Lease__c = (String)buildingLeaseDetail.get('type');
        if(buildingLeaseDetail.get('lease_expiration_date') != null){
           buildingLease.Lease_Expiration_Date__c = Date.valueOf((String)buildingLeaseDetail.get('lease_expiration_date'));
        }
        if(buildingLeaseDetail.get('date_of_lease_agreement') != null){
           buildingLease.Date_of_lease_agreement__c = Date.valueOf((String)buildingLeaseDetail.get('date_of_lease_agreement'));
        }
        if(buildingLeaseDetail.get('lease_commencement_date') != null){
           buildingLease.Lease_Commencement__c = Date.valueOf((String)buildingLeaseDetail.get('lease_commencement_date'));
        }
        if(buildingAreaDetail != null){
           buildingLease.Area_UUID__c = (String)buildingAreaDetail.get('area_uuid');
           buildingLease.Rentable_Area__c = (Decimal)buildingAreaDetail.get('rsf');
           buildingLease.Floors__c  = (String)buildingAreaDetail.get('area_description');
           buildingLease.Name = building.Name + '  ' + (String) buildingAreaDetail.get('area_description');                                                       
        }else{
            buildingLease.Name = building.Name;
        }
        
        
        if(!buildingLeaseRecordsToUpsert.contains(buildingLease)){
            buildingLeaseRecordsToUpsert.add(buildingLease);
        }        
        //Set the Date of original lease agreement and Measurement Unit on the building
        if(String.isBlank(building.Measurement_Unit__c) || building.Measurement_Unit__c == null || building.Measurement_Unit__c != (String)propertyDetail.get('measure_unit')){
            building.Measurement_Unit__c =(String)propertyDetail.get('measure_unit');
        }
        if(buildingLeaseDetail.get('date_of_lease_agreement') != null && (building.Date_of_original_lease_agreement__c == null || building.Date_of_original_lease_agreement__c > Date.valueOf((String)buildingLeaseDetail.get('date_of_lease_agreement')))){
            building.Date_of_original_lease_agreement__c = Date.valueOf((String)buildingLeaseDetail.get('date_of_lease_agreement'));
        }
        if(buildingLeaseDetail.get('lease_expiration_date') != null && (building.Expiration_Date__c == null || building.Expiration_Date__c > Date.valueOf((String)buildingLeaseDetail.get('lease_expiration_date')))){
            building.Expiration_Date__c = Date.valueOf((String)buildingLeaseDetail.get('lease_expiration_date'));
        }                                                         
        if(!buildingRecordsToUpdate.contains(building)) {
            buildingRecordsToUpdate.add(building);
        }
    }
    
    /****************************************************************************************************************************
        Author              : Vaishnavi Khandar
        Description         : This method is used to insert and update payload details on Building Lease Financial detail.
        Created Date        : 15 November 2021
    *****************************************************************************************************************************/
    
    public static void insertAndUpdateBuildingLeaseFinancialDetails(Building__c building, Building_Lease_Financial_Details__c buildingLeaseFinancialDetail, 
                                                                    Map<String,Object> buildingLeaseFinancialRecord, Map<String,Object> buildingLeaseDetail, 
                                                                    List<Building_Lease_Financial_Details__c> buildingLeaseFinancialSecurityDetails, List<Building__c> buildingRecordsToUpdate) {
        buildingLeaseFinancialDetail.Lease_UUID__c = (String)buildingLeaseDetail.get('lease_uuid');
        buildingLeaseFinancialDetail.Lease_financial_security_UUID__c = (String)buildingLeaseFinancialRecord.get('lease_financial_security_uuid');
        if(String.isBlank(buildingLeaseFinancialDetail.Building__c) || buildingLeaseFinancialDetail.Building__c == null){
            buildingLeaseFinancialDetail.Building__c = building.Id;
        }
        if((String)buildingLeaseFinancialRecord.get('type') == 'Letter of Credit'){
            buildingLeaseFinancialDetail.Current_Letter_of_Credit_Amount__c = (Decimal)buildingLeaseFinancialRecord.get('amount');
            buildingLeaseFinancialDetail.Current_Corporate_Guaranty_Amount__c = 0 ;
        }else if((String)buildingLeaseFinancialRecord.get('type') == 'Guarantee'){
            buildingLeaseFinancialDetail.Current_Corporate_Guaranty_Amount__c = (Decimal)buildingLeaseFinancialRecord.get('amount');
            buildingLeaseFinancialDetail.Current_Letter_of_Credit_Amount__c = 0 ;
        }
        if(buildingLeaseFinancialRecord.get('next_burndown_amount') != null){    
            buildingLeaseFinancialDetail.Next_Burndown_Amount__c = (Decimal)(buildingLeaseFinancialRecord.get('next_burndown_amount'));    
        }else{    
            buildingLeaseFinancialDetail.Next_Burndown_Amount__c = 0;                
        }
        if(buildingLeaseFinancialRecord.get('next_burndown_date') != null){
           buildingLeaseFinancialDetail.Next_Burndown_Date__c = Date.valueOf((String)buildingLeaseFinancialRecord.get('next_burndown_date'));
        }
        if(!buildingLeaseFinancialSecurityDetails.contains(buildingLeaseFinancialDetail)){
            buildingLeaseFinancialSecurityDetails.add(buildingLeaseFinancialDetail);
        }
        if(buildingLeaseFinancialRecord.get('next_burndown_date') != null && (building.Next_Burndown_Date__c == null || building.Next_Burndown_Date__c > Date.valueOf((String)buildingLeaseFinancialRecord.get('next_burndown_date')))){
            building.Next_Burndown_Date__c = Date.valueOf((String)buildingLeaseFinancialRecord.get('next_burndown_date'));
        }                                                         
        if(!buildingRecordsToUpdate.contains(building)) {
            buildingRecordsToUpdate.add(building);
        }
    }
    
    /****************************************************************************************************************************
        Author              : Vaishnavi Khandar 
        Description         : Create query for Query Locator 
    *****************************************************************************************************************************/
    
    public static String getQueryBySetting() {
        String query;
        query = 'SELECT Id, Name, UUID__c, Measurement_Unit__c, Date_of_original_lease_agreement__c, Expiration_Date__c, Next_Burndown_Date__c, LastModifiedDate, (SELECT Id, LastModifiedDate, Lease_UUID__c, Area_UUID__c, Location__c, Location_UUID__c, Property_UUID__c, Name, Measurement_Unit__c, Possession_Date__c, Type_of_Lease__c, Lease_Expiration_Date__c, Date_of_lease_agreement__c, Lease_Commencement__c, Rentable_Area__c, Floors__c FROM Building_Lease__r), (SELECT Id, Name, Lease_UUID__c,Lease_financial_security_UUID__c, Building_Lease__c, Building__c, Next_Burndown_Amount__c, Next_Burndown_Date__c, Current_Corporate_Guaranty_Amount__c, Current_Letter_of_Credit_Amount__c FROM Building_Lease_Financial_Details__r) FROM Building__c WHERE UUID__c != null';
        return query;
    }
    
}