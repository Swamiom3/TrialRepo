/*****************************************************************************************************************************
  Yet to do
  1. Modularize the code into multiple method calls.
  2. Put comments for each method call to establish references.
  3. Get it reviewed from the peer team.
  4. The class has some Q2C comments
******************************************************************************************************************************
    Author      :  Krishana Tupe  
    Description :  This class contains the business logic of Journey creation
                    
    History     :  --
    
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION                 DATE            ISSUE       AUTHOR                          DETAIL
    1                       26 Nov 2018      -          Krishana Tupe                   Initial Developement    
******************************************************************************************************************************/
public class JourneyHelper {
    @TestVisible
    private static JourneySelector journeySelector = new JourneySelector();
    
    public static void createJourney(Map<String,sObject> objParent){
        createJourney(new List<Map<String,sObject>>{objParent},null); 
    }
    
    public static void createJourney(List<Map<String,sObject>> lstParents, List<Id> lstLeadsToBeDeleted){  
        JourneyHelperUtility.createJourney(lstParents, lstLeadsToBeDeleted); 
    }
    
    public static Set<Journey__c> setJourneysToCreate = new Set<Journey__c>();
    public static void createJourneyWithAssignment(Map<Id,Map<String,sObject>> mapParents, Map<Id,Journey__c> mapJourneysToUpsert, Map<Id,Id> mapAssignments, Map<Id,sObject> mapJourneys){       
        Map<String,String> mapAPIUserInfo = (Map<String,String>)JSON.deserialize(Settings.get('APIUserContactInfo').Data__c, Map<String,String>.class);
        Map<Id,Journey__c> mapJourneyWithLeadOrContact = new Map<Id,Journey__c>();
        Map<Id,Id> mapJourneyWithLeadOrContactIds = new Map<Id,Id>(); 
        for(Map<String,sObject> mapParent : mapParents.values()){ 
            sObject objParent = mapParent.containsKey('contact') ? mapParent.get('contact') : mapParent.containsKey('lead') ? mapParent.get('lead') : null;
            sObject objNewParent = mapParent.containsKey('newlead') ? mapParent.get('newlead') : mapParent.get('lead');
            Journey__c objJourney = (Journey__c)mapJourneys.get(String.valueOf(objNewParent.Id));           
            objJourney = getDefaultMappings(mapParent, objJourney);
            Journey__c objNewJourney = objJourney.clone(false, false, false, false);
            objNewJourney.Lead_Id__c = null;            
            if(setJourneysToCreate == null || (setJourneysToCreate != null && !setJourneysToCreate.contains(objNewJourney))){
                setJourneysToCreate.add(objNewJourney);               
                if((String.valueOf(objParent.get('OwnerId')).toLowerCase().startsWith('00g')) || (UserUtility.getUserActive(Id.valueOf(String.valueOf(objParent.get('OwnerId')))))){                
                    if(objNewParent != null && objNewParent.get('OwnerId') != null && (UserUtility.getUserActive(Id.valueOf(String.valueOf(objNewParent.get('OwnerId')))) || String.valueOf(objNewParent.get('OwnerId')).toLowerCase().startsWith('00g'))){
                        objJourney.OwnerId = (Id)objNewParent.get('OwnerId');
                    }else if(System.isBatch()){
                        objJourney.OwnerId = UserInfo.getUserId();
                    }
                }else if(objNewParent != null && objNewParent.get('OwnerId') != null && (UserUtility.getUserActive(Id.valueOf(String.valueOf(objNewParent.get('OwnerId')))) || String.valueOf(objNewParent.get('OwnerId')).toLowerCase().startsWith('00g'))){
                    objJourney.OwnerId = (Id)objNewParent.get('OwnerId');
                }else if(!UserUtility.getUserActive(String.valueOf(objParent.get('OwnerId')))){
                    objJourney.OwnerId = Id.valueOf(mapAPIUserInfo.get('UserId'));
                }else{
                    objJourney.OwnerId = String.valueOf(objParent.get('OwnerId'));  
                }
               if((System.isBatch() && String.valueOf(objJourney.OwnerId).startsWith('005') && !LeadConverterHelper.leadIds.contains(String.valueOf(objNewParent.get('Id')))) || String.valueOf(objJourney.OwnerId).startsWith('005')){
                    objJourney.Status__c = 'Accepted'; 
                }               
                mapJourneyWithLeadOrContact.put(Id.valueOf(String.valueOf(objNewParent.get('Id'))), objJourney);
                mapJourneyWithLeadOrContactIds.put(Id.valueOf(String.valueOf(objNewParent.get('Id'))),null);
            }
            if(objParent != null && objParent.get('OwnerId') != null && objNewParent != null &&  objParent.get('Id') != objNewParent.get('Id') && (objParent.get('OwnerId') == Id.valueOf(mapAPIUserInfo.get('UserId')) || (!UserUtility.getUserActive(Id.valueOf(String.valueOf(objParent.get('OwnerId')))) && !String.valueOf(objParent.get('OwnerId')).toLowerCase().startsWith('00g')))){
                mapJourneyWithLeadOrContactIds.put(Id.valueOf(String.valueOf(objParent.get('Id'))),Id.valueOf(String.valueOf(objNewParent.get('Id'))));
            }
        }
        if(mapJourneyWithLeadOrContact.size() > 0){
            mapJourneysToUpsert.putAll(mapJourneyWithLeadOrContact);
            mapAssignments.putAll(mapJourneyWithLeadOrContactIds);
        }
    }
    
    //@future
    public static void updateJourneyOwner(String strJourneysWithContactOrLead,String strSobjectTODelete){
        Map<Id,Id> mapJourneysWithContactOrLead = (Map<Id,Id>)JSON.deserialize(strJourneysWithContactOrLead, Map<Id,Id>.class);
        List<Id> lstSObjectToDelete;
        if(String.isNotBlank(strSobjectTODelete)){
            lstSObjectToDelete = (List<Id>)JSON.deserialize(strSobjectTODelete, List<Id>.class);
        }
        updateJourneyOwner(mapJourneysWithContactOrLead, lstSObjectToDelete);
    }
        
 
    public static void updateJourneyOwner(Map<Id,Id> mapJourneysWithContactOrLead, List<Id> lstSObjectToDelete){
        Map<String,String> mapAPIUserInfo = (Map<String,String>)JSON.deserialize(Settings.get('APIUserContactInfo').Data__c, Map<String,String>.class);
        MetadataSetting__mdt metadataRecord = Settings.getMetadataSettingByDevName('Unassigned_NMD_US_Queue');
        String unassignedQueueId = String.valueOf(metadataRecord.Data__c);
        Id strHoldBackQueueId =  (Id)LeadConverterHelper.getHoldBackQueueId();
        Set<Id> setJourneyIds = new Set<Id>();
        Set<Id> setContactIds = new Set<Id>();
        Set<Id> setLeadIds = new Set<Id>();
        Map<Id,sObject> mapRecords = new Map<Id,sObject>();
        Map<Id, sObject> mapSObjectsToUpdate = new  Map<Id,sObject>();
        for(Id sourceId : mapJourneysWithContactOrLead.keySet()){
            if(String.valueOf(sourceId).toLowerCase().startsWith('00q')){
                setLeadIds.add(sourceId);
            }else if(String.valueOf(sourceId).toLowerCase().startsWith('003')){
                setContactIds.add(sourceId);
            }
            if(mapJourneysWithContactOrLead.get(sourceId) != null){
                if(String.valueOf(mapJourneysWithContactOrLead.get(sourceId)).toLowerCase().startsWith('00q')){
                    setLeadIds.add(mapJourneysWithContactOrLead.get(sourceId));
                }else if(String.valueOf(mapJourneysWithContactOrLead.get(sourceId)).toLowerCase().startsWith('003')){
                    setContactIds.add(mapJourneysWithContactOrLead.get(sourceId));
                }else if(String.valueOf(mapJourneysWithContactOrLead.get(sourceId)).toLowerCase().startsWith('a0j')){
                    setJourneyIds.add(mapJourneysWithContactOrLead.get(sourceId));
                }    
            }                       
        }       
        if(setLeadIds.size() > 0){
            mapRecords.putAll(new Map<Id,sObject>([SELECT Id, OwnerId, Email, Lead_Assignment_Stage__c, Routing_Qualification_Result__c FROM Lead WHERE Id IN :setLeadIds]));
        }
        if(setContactIds.size() > 0){
            mapRecords.putAll(new Map<Id,sObject>([SELECT Id, OwnerId FROM Contact WHERE Id IN :setContactIds]));
        }
        Map<Id, Journey__c> mapJourneys = new Map<Id, Journey__c>();
         if(setJourneyIds.size() > 0){
            mapJourneys.putAll(new Map<Id, Journey__c>(journeySelector.getJourneysWithAdditionalFieldsByIds(new List<Id>(setJourneyIds))));    
        }    
        for(Id sourceId : mapRecords.keySet()){
            if(mapJourneysWithContactOrLead.containsKey(sourceId) && String.isNotBlank(mapJourneysWithContactOrLead.get(sourceId))){
                Id destinationId = mapJourneysWithContactOrLead.get(sourceId);                
                if(String.valueOf(destinationId).toLowerCase().startsWith('00q')){
                    if(UserUtility.getUserActive(String.valueOf(mapRecords.get(sourceId).get('OwnerId')))){
                        if(Id.valueOf(String.valueOf(mapRecords.get(sourceId).get('OwnerId'))) == Id.valueOf(String.valueOf(mapAPIUserInfo.get('UserId')))){
                            if(String.valueOf(sourceId).toLowerCase().startsWith('00q')){
                                if(Id.valueOf(String.valueOf(mapRecords.get(destinationId).get('OwnerId'))) != Id.valueOf(String.valueOf(mapAPIUserInfo.get('UserId')))){                                   
                                    Lead objExistingLead = new Lead(Id = sourceId, OwnerId = String.valueOf(mapRecords.get(destinationId).get('OwnerId')));
                                    if(strHoldBackQueueId == objExistingLead.ownerId && objExistingLead.Lead_Assignment_Stage__c != '6'){
                                        objExistingLead.Lead_Assignment_Stage__c = '6';   
                                    } 
                                    mapSObjectsToUpdate.put(sourceId, objExistingLead); 
                                }else{
                                    mapSObjectsToUpdate.put(sourceId, new Lead(Id = sourceId, OwnerId = unassignedQueueId));
                                }
                            }else{
                                if(String.valueOf(mapRecords.get(destinationId).get('OwnerId')).toLowerCase().startsWith('00g')){
                                    mapSObjectsToUpdate.put(sourceId, new Contact(Id = sourceId, OwnerId = Id.valueOf(String.valueOf(mapAPIUserInfo.get('UserId')))));
                                }else{
                                    mapSObjectsToUpdate.put(sourceId, new Contact(Id = sourceId, OwnerId = String.valueOf(mapRecords.get(destinationId).get('OwnerId'))));
                                }
                            }
                        }
                    }else{
                        if(String.valueOf(sourceId).toLowerCase().startsWith('00q')){
                            mapSObjectsToUpdate.put(sourceId, new Lead(Id = sourceId, OwnerId = String.valueOf(mapRecords.get(destinationId).get('OwnerId'))));
                        }else{
                            if(String.valueOf(mapRecords.get(destinationId).get('OwnerId')).toLowerCase().startsWith('00g')){
                                mapSObjectsToUpdate.put(sourceId, new Contact(Id = sourceId, OwnerId = Id.valueOf(String.valueOf(mapAPIUserInfo.get('UserId')))));
                            }else{
                                mapSObjectsToUpdate.put(sourceId, new Contact(Id = sourceId, OwnerId = String.valueOf(mapRecords.get(destinationId).get('OwnerId'))));
                            }
                        }
                    }
                }else{                    
                    if(Id.valueOf(String.valueOf(mapRecords.get(sourceId).get('OwnerId'))) != Id.valueOf(String.valueOf(mapAPIUserInfo.get('UserId')))){                        
                        if(mapJourneys.containsKey(destinationId) && mapJourneys.get(destinationId).Lead_Id__c == mapRecords.get(sourceId).get('Id')){
                           //org consoli Journey__c objJourney = new Journey__c(Id = destinationId, Routing_Qualification_Result__c = (String)mapRecords.get(sourceId).get('Routing_Qualification_Result__c'), OwnerId = String.valueOf(mapRecords.get(sourceId).get('OwnerId')));
                            Journey__c objJourney = new Journey__c(Id = destinationId, OwnerId = String.valueOf(mapRecords.get(sourceId).get('OwnerId')));

                            Set<String> setJourneyClosedStages  = LeadRoutingHelper.getJourneyClosedStages(); 
                           
                            if(String.valueOf(objJourney.OwnerId).startsWith('005') && (setJourneyClosedStages == null || (setJourneyClosedStages != null && !setJourneyClosedStages.contains(mapJourneys.get(destinationId).Status__c)))){
                                objJourney.Status__c = 'Accepted';
                            }
                            mapSObjectsToUpdate.put(objJourney.Id, objJourney);
                        }                   
                    }else{     
                                        
                        /*if(mapJourneys.get(destinationId) != NULL && (String.valueOf(mapJourneys.get(destinationId).OwnerId).startsWith('005') && !UserUtility.getUserActive(mapJourneys.get(destinationId).OwnerId) || mapJourneys.get(destinationId).OwnerId == (String.isNotBlank(mapAPIUserInfo.get('userId')) ? Id.valueOf(mapAPIUserInfo.get('userId')):  Id.valueOf('005F0000003Kmbw')))){
                            mapSObjectsToUpdate.put(destinationId, new Journey__c(Id = destinationId, Secondary_Lead_Demographic_Score__c = getDecimalValue(mapRecords.get(sourceId).get('Lead_Demographic_Score__c')), SecondaryLead_Demographic_Score_DateTime__c = getDateTimeValue(mapRecords.get(sourceId).get('Lead_Demographic_Score_DateTime__c')), OwnerId = unassignedQueueId, Routing_Qualification_Result__c = (String)mapRecords.get(sourceId).get('Routing_Qualification_Result__c')));    
                        }  */                     
                    }
                }
            }
        }            
         
        if(!mapSObjectsToUpdate.isEmpty() && mapSObjectsToUpdate.size() > 0){
            update mapSObjectsToUpdate.values();
        }
        
        if(lstSObjectToDelete != null && lstSObjectToDelete.size() > 0){
            Database.delete(lstSObjectToDelete, false);
        }
    }
       
    public static DateTime getDateTimeValue(object objDateTime){
        if(objDateTime != null){
            String strDateTime = String.valueOf(objDateTime);
            if(String.isNotBlank(strDateTime)){
                return ((DateTime)JSON.deserialize(strDateTime, DateTime.class));       
            }    
        }        
        return null;
    }
    
    public static Decimal getDecimalValue(object objDecimal){
        if(objDecimal != null){
            Decimal objDecimalValue = Decimal.valueOf(String.valueOf(objDecimal));       
            return (objDecimalValue > 0.0 ? objDecimalValue : null);  
        }
        return null;
    }
    
    public static String getStringValue(object objString){
        if(objString != null){
            return String.valueOf(objString);
        }
        return null;
    }     
    
    public static Journey__c getDefaultMappings(Map<String,sObject> mapParents,Journey__c objJourney){
        sObject objNewParent = mapParents.containsKey('newlead') ? mapParents.get('newlead'): mapParents.get('lead');
        sObject objParent = mapParents.containsKey('contact') ? mapParents.get('contact') : mapParents.get('lead');
        Set<String> setLocationIntrested =  new Set<String>();
     
        if(objJourney.Id == null){
            if(String.valueOf(objParent.get('Id')).toLowerCase().startsWith('00q')){
                //objJourney.Name = (objParent.get('Name') != null ? objParent.get('Name'): '')+ '-' +((objNewParent.getSobject('building_interested_In__r') == null) ? ((objParent.getSobject('building_interested_In__r') == null) ? '' : (String.isBlank((String)objParent.getSobject('building_interested_In__r').get('city__c')) ? '' : objParent.getSobject('building_interested_In__r').get('city__c') + '-')) : (String.isBlank((String)objNewParent.getSobject('building_interested_In__r').get('city__c')) ? '' : objNewParent.getSobject('building_interested_In__r').get('city__c') + '-'))+''+((objNewParent.get('leadsource') == null) ? ((objParent.get('leadsource') == null) ? '' : objParent.get('leadsource')) : objNewParent.get('leadsource'));
                objJourney.Name = (objNewParent.get('Name') != null ? objNewParent.get('Name') : objParent.get('Name')) + '-' + ((objNewParent.getSobject('building_interested_In__r') == null) ? ((objParent.getSobject('building_interested_In__r') == null) ? '' : (String.isBlank((String)objParent.getSobject('building_interested_In__r').get('city__c')) ? '' : objParent.getSobject('building_interested_In__r').get('city__c') + '-')) : (String.isBlank((String)objNewParent.getSobject('building_interested_In__r').get('city__c')) ? '' : objNewParent.getSobject('building_interested_In__r').get('city__c') + '-')) + '' + ((objNewParent.get('leadsource') == null)?((objParent.get('leadsource') == null) ? '' : objParent.get('leadsource')) : objNewParent.get('leadsource'));
                objJourney.Primary_Lead__c = String.valueOf(objParent.get('Id'));                                
                if(objParent.get('Locations_Interested__c') != null){
                    setLocationIntrested.addAll(String.valueOf(objParent.get('Locations_Interested__c')).split(';'));
                }
            }else{
                objJourney.Name = (objNewParent.get('Name') != null ? objNewParent.get('Name'): objParent.get('Name'))+ '-' +((objNewParent.getSobject('building_interested_In__r') ==null)?((objParent.getSobject('Location__r') ==null)?'':(String.isBlank((String)objParent.getSobject('Location__r').get('city__c'))?'':objParent.getSobject('Location__r').get('city__c') + '-')):(String.isBlank((String)objNewParent.getSobject('building_interested_In__r').get('city__c'))?'':objNewParent.getSobject('building_interested_In__r').get('city__c') + '-'))+''+((objNewParent.get('leadsource') == null)?((objParent.get('leadsource') == null)?'':objParent.get('leadsource')):objNewParent.get('leadsource'));
                objJourney.Primary_Contact__c = String.valueOf(objParent.get('Id'));
                if(objParent.get('Location_Interested__c')!=null){
                    setLocationIntrested.addAll(String.valueOf(objParent.get('Location_Interested__c')).split(';'));
                }
            }            
            if(String.isNotBlank(objJourney.Name) && objJourney.Name.length() > 80){
                objJourney.Name =  objJourney.Name.substring(0, 80);
            } 
            //org consoli objJourney.Stage__c = 'Started'; 
            objJourney.Building_Interested_In__c = getStringValue(objNewParent.get('Building_Interested_In__c')); 
            objJourney.Lead_Source__c = getStringValue(objNewParent.get('LeadSource'));
            objJourney.Lead_Source_Detail__c = getStringValue(objNewParent.get('Lead_Source_Detail__c'));
            //ST-3222, for new journey on existing lead or contact.
            objJourney.LeadSource_Sub_Type__c  = getStringValue(objNewParent.get('LeadSource_Sub_Type__c'));
            if(String.isBlank(objJourney.lead_id__c)){
                objJourney.lead_id__c = getStringValue(objNewParent.get('Id')); 
            }
            if(objNewParent.get('Campaign_Id__c') != null && String.isBlank(objJourney.CampaignId__c)){
                objJourney.CampaignId__c = getStringValue(objNewParent.get('Campaign_Id__c'));
            } 
            string strModeOfAssignment = JourneyHelperUtility.getJourneyModeofAssignment((Lead)objNewParent);
            if(String.isNotBlank(strModeOfAssignment)){
                objJourney.Mode_Of_Assignment__c = strModeOfAssignment;   
            }
            if(objNewParent.get('Routing_Qualification_Result__c') != NULL){
              objJourney.Routing_Qualification_Result__c = (String)objNewParent.get('Routing_Qualification_Result__c'); 
            }
           //org consoli  objJourney.Secondary_Lead_Demographic_Score__c = getDecimalValue(objNewParent.get('Lead_Demographic_Score__c'));
           // objJourney.SecondaryLead_Demographic_Score_DateTime__c = getDateTimeValue(objNewParent.get('Lead_Demographic_Score_DateTime__c'));            
        } 
        if(objNewParent != null){
            if(objNewParent.get('Locations_Interested__c') != null){
                setLocationIntrested.addAll(String.valueOf(objNewParent.get('Locations_Interested__c')).split(';'));
            }
            if(objJourney.Building_Interested_In__c == null){
                objJourney.Building_Interested_In__c = objNewParent.get('Building_Interested_In__c') != null ? (Id)objNewParent.get('Building_Interested_In__c') : null;
            }
        }
        //objJourney.Promo_Code__c = objNewParent.get('Promo_Code__c') != null ? String.valueOf(objNewParent.get('Promo_Code__c')) : String.valueOf(objParent.get('Promo_Code__c')); 
        objJourney.Description__c = objNewParent.get('Description') != null ? String.valueOf(objNewParent.get('Description')) : String.valueOf(objParent.get('Description'));         
        objJourney.NMD_Next_Contact_Date__c = System.today();        
        return objJourney;
    }
        
    
    /************************************************************************************************************************************
      Author              : Praveen Emmadi
      Description         : This method is used to update journey when opportunity is created from journey. 
      Created Date        : 10 Oct 2019 
      Issue No.           : ST-4943
    **************************************************************************************************************************************/
    public static void closeOppRelatedJourney(List<Journey__c> lstJourney){        
        for(Journey__c objJourney : lstJourney){ 
            objJourney.Status__c = 'Converted';
        }
        if(lstJourney.size() > 0){
            Database.update(lstJourney, false);              
        } 
    }
    
    /************************************************************************************************************************************
      Author              : Priyanka Ambre
      Description         : This method is used to update journey when opportunity is created from journey. 
      Created Date        : 27 Jannuary 2017 
      Issue No.           : 1530
    **************************************************************************************************************************************/
    public static void closeOppRelatedJourney(Id journeyId){        
       // org consoli List<Journey__c> lstJourney = [SELECT Id, Name, Stage__c FROM Journey__c  WHERE Id =: journeyId LIMIT 1];
        List<String> fields = new List<String>{'Id', 'Name'};
        List<Journey__c> lstJourney = journeySelector.getJourneysByIds(fields, new List<Id>{journeyId});

        for(Journey__c objJourney : lstJourney){ 
            objJourney.Status__c = 'Converted';
        }
        if(lstJourney.size() > 0){
            Database.update(lstJourney, false);              
        } 
    }
    
    public class LeadSourceDetails{
        public List<LeadSource> LeadSource{get;set;}
        public Set<String> LeadSourceDetails{get;set;}
    }
    
    public class LeadSource{
        public String name{get;set;}
        public Boolean OverrideLeadSoruce{get;set;}
    }
    
    public class JourneyCreationSetting{
        public Integer NextCallInDaysFromLeadCreation{get;set;}
        public Id NoCompanyAccountId{get;set;}
        public Integer NextCallInDaysFromJourneyUpdation{get;set;}
        public Map<String,String> NewLeadActivityFields{get;set;}
        public Map<String,String> NewJourneyFields{get;set;}
        public String ExistingJourneyStage{get;set;}
        public Integer AssignExistingJourneyOwner{get;set;}
        public Integer ExistingJourneyCreatedDateDifference{get;set;}
        public Integer JourneyAssignmentCutOffDays{get;set;}
        public Integer CloseInDaysFromJourneyCreation{get;set;}
        public Set<String> ClosedJourneyStages{get;set;}
    }
    
    /************************************************************************************************************************************
       Author         : Dipak Pawar
       Description    : This method gives the Journey Close Stages configured in "JourneyCloseStages" Sales Console Setting
       Created Date   : 10 January 2019
   **************************************************************************************************************************************/
    public static Set<String> getJourneyCloseStages(){
        Sales_Console_Setting__mdt objSetting = SalesConsoleSettings.get('JourneyCloseStages');

        Set<String> setJourneyCloseStages = new Set<String>();
        if(objSetting != null){
            setJourneyCloseStages = (Set<String>)JSON.deserialize(objSetting.Data__c, Set<String>.class);
        }
        return setJourneyCloseStages;
    }
}