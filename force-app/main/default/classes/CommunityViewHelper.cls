/************************************************************************************************************************************
    Author 		: Milanjeet Singh
    Description : This class will have all the logics for Community View Page
    This class contains commented code for Q2C Org Consolidation
--------------------------------------------------------------------------------------------------------------------------------------
    VERSION					DATE					AUTHOR							DETAIL
    1					    23 July, 2018		    Milanjeet Singh               	Initial Developement
	2 						31 August, 2018			Prashant Mane					Added Method.
*************************************************************************************************************************************/
public without sharing class CommunityViewHelper {
    public static Boolean isInvoker = false;
    public static Savepoint sp {get;set;}
    @TestVisible
    private static BuildingSelector buildingSelector = new BuildingSelector();
    private static final String BILLING_ACCOUNT_RECORD_TYPE = 'Billing Account';
    static {
        isInvoker = ApexDebugLog.registerRootInvoker(ApexDebugLog.InvokerType.AURA, 'CommunityViewHelper' + 'getsObjectPrefix', ApexDebugLog.InvokerType.AURA);
    }
/************************************************************************************************************************************
    Author          : Prashant Mane.
    Description     : This method is used to get data for Community View page
    Issue No        : ST-2383
    Created Date    : 18 May 2018
**************************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getOnLoadCommunityViewData(Map<String, String> intialParameters){
        try{
            CommunityViewOnloadWrapper objCommunityViewOnloadWrapper = new CommunityViewOnloadWrapper();
            objCommunityViewOnloadWrapper.ServerDates = new CommunityViewServerDates();
            objCommunityViewOnloadWrapper.BuildingInfo = getBuildingRelatedData(intialParameters.get('buildingId'));
            objCommunityViewOnloadWrapper.BillingAccount = getBillingAccountData(intialParameters.get('billingAccountId'));
            objCommunityViewOnloadWrapper.HoldBackQueueMetaData = LeadConverterHelper.getHoldBackQueueId();
            objCommunityViewOnloadWrapper.AllWeWorkBuildings = buildingSelector.getAllBuildingsWithTourSchedules();
            if(objCommunityViewOnloadWrapper.BuildingInfo.size() > 0){
                Building__c buildingInfo = objCommunityViewOnloadWrapper.BuildingInfo[0];
                //objCommunityViewOnloadWrapper.TodayTours = getTourRelatedData(intialParameters);
                if(buildingInfo.GMT_Offset__c != null){
                    objCommunityViewOnloadWrapper.ServerDates.BuildingTimeZoneDate =  Datetime.now().addhours(Integer.valueOf(buildingInfo.GMT_Offset__c));
                }else{
                   objCommunityViewOnloadWrapper.ServerDates.BuildingTimeZoneDate = system.now();
                }
            }
            objCommunityViewOnloadWrapper.CommunityViewAPISetting = SalesConsoleSettings.get('CommunityViewAPISetting');
            objCommunityViewOnloadWrapper.loggedInUserInfo = new Map<String,Object>();
            objCommunityViewOnloadWrapper.loggedInUserInfo.put('sessionId',userInfo.getSessionId());
            objCommunityViewOnloadWrapper.loggedInUserInfo.put('Email',userInfo.getUserEmail());
            objCommunityViewOnloadWrapper.loggedInUserInfo.put('UserId',userInfo.getUserId());

            List<Contact> lstContact = [SELECT Id, Name FROM Contact WHERE Email =: UserInfo.getUserEmail()];
            if(lstContact.size() > 0){
                objCommunityViewOnloadWrapper.loggedInUserInfo.put('Contact',lstContact[0]);
            }else {
                objCommunityViewOnloadWrapper.loggedInUserInfo.put('Contact',lstContact);
            }
            Date objDate = System.today();

            objCommunityViewOnloadWrapper.ServerDates.YesterdaysDate = objDate.addDays(-1);
            objCommunityViewOnloadWrapper.ServerDates.TodaysDate = objDate;
            objCommunityViewOnloadWrapper.ServerDates.TomorrowDate = objDate.addDays(1);
            Map<String,Date> mapThisWeekDates = calculateThisWeekEndDate(objDate);
            objCommunityViewOnloadWrapper.ServerDates.ThisWeekStartDate = mapThisWeekDates.get('ThisWeekStartDate');
            objCommunityViewOnloadWrapper.ServerDates.ThisWeekEndDate = mapThisWeekDates.get('ThisWeekEndDate');

            return new DatabaseResult(JSON.serialize(objCommunityViewOnloadWrapper));
        } catch(Exception pEx){
            ApexDebugLog.logException(pEx, ' intialParameters ==>' +intialParameters, 'CommunityViewHelper', 'getOnLoadCommunityViewData');
            return (new DatabaseResult(pEx));
        }
    }
/************************************************************************************************************************************
        Author              : Prashant Mane.
        Description         : This method is used to get Service Appointment related data for Community View page
        Issue No            : ST-2383
        Created Date        : 18 May 2018
--------------------------------------------------------------------------------------------------------------------------------------
        Last Modified By    : Rupesh Patil
        Last Modified date  : 30 May 2018
**************************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getServiceAppointmentRelatedData(Map<String, String> intialParameters){
        String startDate = intialParameters.get('startDate');
        String endDate = intialParameters.get('endDate');
        String selectedStatus = intialParameters.get('selectedStatus');
        String bookedBy = intialParameters.get('bookedBy');
        String assignHost = intialParameters.get('assignHost');
        String tourFormat = intialParameters.get('tourFormat');
        String locationId = intialParameters.get('buildingId');
        String companyName = intialParameters.get('companyName');
        try{
            List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
            Date startselectedDate ;
            Date endselectedDate;
			if(locationId !=null){
                string query = 'Select '+ String.join(getServiceAppointmentFields(), ',') +' From ServiceAppointment where ';
                List<string> lstOfConditions = new List<String>();
                if( String.isNotBlank(startDate)){
                    startselectedDate = Date.valueOf(startDate.split(' ')[0].trim());
                    lstOfConditions.add(' Scheduled_Start_Date__c >=:startselectedDate ');
                }else{
                    lstOfConditions.add(' Scheduled_Start_Date__c =TODAY ');
                }
                if(String.isNotBlank(endDate)){
                    endselectedDate   = Date.valueOf(endDate.split(' ')[0].trim());
                    lstOfConditions.add(' Scheduled_Start_Date__c <=:endselectedDate ');
                }
                if(String.isNotBlank(bookedBy)) {
                    lstOfConditions.add(' createdby.id =:bookedBy');
                }
                if(String.isNotBlank(assignHost)) {
                    lstOfConditions.add(' ownerid =:assignHost');
                }
                if(String.isNotBlank(tourFormat)) {
                    lstOfConditions.add(' Tour_Format__c =:tourFormat');
                }

                if(String.isNotBlank(selectedStatus)) {
                    lstOfConditions.add(' status =:selectedStatus');
                }
                if(String.isNotBlank(companyName)) {
                    lstOfConditions.add(' AccountId=:companyName');
                }
                lstOfConditions.add(' Building_Id__c =:locationId');
                //query += String.join(lstOfConditions, ' AND ')+' ORDER BY Tour_Date_Time__c ASC LIMIT 2001';
                query += String.join(lstOfConditions, ' AND ')+' ORDER BY SchedStartTime ASC LIMIT 2001';
                serviceAppointments = Database.query(query);
            }
            return new DatabaseResult(JSON.serialize(serviceAppointments));
        }catch(Exception pEx){
            ApexDebugLog.logException(pEx, ' startDate ==>' +startDate+ ' endDate==>'+ endDate+' selectedStatus==>'+ selectedStatus+' assignHost==>'+assignHost+' locationId==>'+locationId+' companyName==>'+companyName, 'CommunityViewHelper', 'getUserAndBuildingForManageTours');
            return (new DatabaseResult(pEx));
        }
    }

/************************************************************************************************************************************
        Author         	: Shobhit Gahlot
        Description     : This method is used to get fields for Tour.
    	Issue No      	: STL-127
        Created Date    : 4 Feb 2019
**************************************************************************************************************************************/
   /*public static List<String> getTourFields(){
        Set<String> tourFields = new Set<String>();
        tourFields.add('Id');
        tourFields.add('Name');
        tourFields.add('booked_by_contact_id__c');
        tourFields.add('Opportunity_Stage_for_Tour__c');
        tourFields.add('Primary_Member__r.Name');
        tourFields.add('Interested_in_Number_of_Desks__c');
        tourFields.add('Primary_Member__r.UUId__c');
        tourFields.add('Primary_Member__r.Account.UUID__c');
        tourFields.add('Primary_Member__r.Account.Name');
        tourFields.add('Primary_Member__c');
        tourFields.add('Primary_Member__r.Account.Primary_Member__c');
        tourFields.add('Primary_Member__r.AccountId');
        tourFields.add('Primary_Member__r.Total_Number_Of_Tours__c');
        tourFields.add('Tour_Date__c');
        tourFields.add('Primary_Member_Email__c');
        tourFields.add('Primary_Member_Phone_Number__c');
        tourFields.add('Product_Line__c');
        tourFields.add('Tour_Date_Time__c');
        tourFields.add('Building_Email__c');
        tourFields.add('Company_Name__c');
        tourFields.add('Status__c');
        tourFields.add('Start_Time__c');
        tourFields.add('Assigned_Host__c');
        tourFields.add('Assigned_Host__r.Name');
        tourFields.add('booked_by_contact_id__r.Name');
        tourFields.add('UUID__c');
        tourFields.add('Location__r.Name');
        tourFields.add('Location__c');
        tourFields.add('Location__r.UUID__c');
        tourFields.add('End_Time__c');
        tourFields.add('Tour_Scheduled_With_Email__c');
        tourFields.add('Booked_By_User_Role__c');
        tourFields.add('Opportunity__r.Name');
        tourFields.add('Opportunity__c');
        tourFields.add('Opportunity__r.Building__c');
        tourFields.add('Opportunity__r.Building__r.Name');
        tourFields.add('Opportunity__r.Owner.Name');
        tourFields.add('Opportunity__r.Quantity__c');
        tourFields.add('Opportunity__r.Account.Primary_Member__r.Email');
        tourFields.add('Tour_Outcome__c');
        tourFields.add('Opportunity__r.Interested_in_Number_of_Desks__c');
        tourFields.add('Opportunity__r.Account.Primary_Member__r.Name');
        tourFields.add('Opportunity_Contract_Stage_for_Tour__c');
        tourFields.add('Tours_Visited__c');
        tourFields.add('New_Tour_Notes__c');
        tourFields.add('Opportunity__r.RecordType.Name');
        tourFields.add('Opportunity__r.AccountId');
        tourFields.add('Opportunity__r.Owner.Profile.Name');
        tourFields.add('Opportunity__r.Owner.UserRole.Name');
        tourFields.add('Tour_Format__c');
        List<String> lstFields = new List<string>();
        lstFields.addAll(tourFields);
        return lstFields;
    }*/
    public static List<String> getServiceAppointmentFields(){
        Set<String> appointmentFields = new Set<String>();
        appointmentFields.add('Id');
        appointmentFields.add('AppointmentNumber');
        appointmentFields.add('ownerId');
        appointmentFields.add('SchedStartTime');
        appointmentFields.add('Tour_Format__c');
        appointmentFields.add('status');
        appointmentFields.add('AccountId');
        appointmentFields.add('ContactId');
        appointmentFields.add('Building_Id__c');
        appointmentFields.add('Contact.AccountId');
        appointmentFields.add('Contact.Name');
        appointmentFields.add('Contact.Phone');
        appointmentFields.add('Contact.Email');
        appointmentFields.add('Contact.Total_Number_Of_Tours__c');
        appointmentFields.add('Account.Name');
        appointmentFields.add('Opportunity_Id__r.Interested_in_Number_of_Desks__c');
        appointmentFields.add('Owner.Name');
        appointmentFields.add('Tour_Notes__c');
        appointmentFields.add('Opportunity_Id__c');
        appointmentFields.add('Opportunity_Id__r.Name');
        appointmentFields.add('Opportunity_Id__r.Owner.Name');
        appointmentFields.add('Opportunity_Id__r.RecordType.Name');
        appointmentFields.add('Scheduled_Start_Date__c');
        appointmentFields.add('Scheduled_Start_Time__c');
        appointmentFields.add('CreatedBy.Id');
        appointmentFields.add('CreatedBy.Name');
        appointmentFields.add('Tours_Visited__c');
        appointmentFields.add('Product_Interests__c');
        return new List<String>(appointmentFields);

    }

    private static List<String> getbuildingfieldsForCommunityView(){
        List<String> lstQueryfield = new List<String>{'Id', 'Name', 'Address__c', 'Gate__c', 'Responsible_CM__c', 'City__c', 'UUID__c', 'Time_Zone__c', 'GMT_Offset__c'
        };
            return lstQueryfield;
    }

/************************************************************************************************************************************
        Author         	: Shobhit Gahlot
        Description     : This method is used create query with fields for Tour.
    	Issue No      	: STL-127
        Created Date    : 4 Feb 2019
**************************************************************************************************************************************/
    /*@AuraEnabled
    public static DatabaseResult communityViewSOQL(string soqlLabel, Map<String, Object> mapData){
        List<sObject> lstobjects = new List<sObject>();
        string query;
        switch on soqlLabel {
            when 'label1' {
                query = 'Select '+ String.join(getTourFields(), ',') +' From Tour_Outcome__c where UUID__c = \'' + mapData.get('UUID__c') +'\'';
            }
        }
        return new DatabaseResult(Database.query(query));
    }*/
    /************************************************************************************************************************************
        Author              : Prashant Mane.
        Description         : This method is used to get Tour related data for Community View page
        Issue No            : ST-2383
        Created Date        : 18 May 2018
--------------------------------------------------------------------------------------------------------------------------------------
        Last Modified By    : Samadhan Kadam
        Last Modified date  : 17 Jan 2019
		Issue No			: STL-129,STL-130
**************************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getSelectedBuildingTourRelatedDataAndUpdateUser(String locationId){
        try{
            sp = Database.setSavepoint();
            CommunityViewOnloadWrapper objCommunityViewOnloadWrapper = new CommunityViewOnloadWrapper();
            objCommunityViewOnloadWrapper.BuildingInfo = getBuildingRelatedData(locationId);
            if(objCommunityViewOnloadWrapper.BuildingInfo.size() > 0){
                User objUser = new User(Id =userInfo.getUserId() , Community_View_Building__c=locationId);
                update objUser;
                Map<String, String> mapIntialParameters = new Map<String, String>{
                    'buildingId' => objCommunityViewOnloadWrapper.BuildingInfo[0].Id
                };
                //objCommunityViewOnloadWrapper.TodayTours = getTourRelatedData(mapIntialParameters);
            }
            return new DatabaseResult(JSON.serialize(objCommunityViewOnloadWrapper));
        }catch(Exception pEx){
            LightningComponentController.rollbackTransaction(sp);
            ApexDebugLog.logException(pEx,'locationId==>'+locationId, 'CommunityViewHelper', 'getSelectedBuildingTourRelatedDataAndUpdateUser');
            return (new DatabaseResult(pEx));
        }
    }

/************************************************************************************************************************************
        Author         		: Prashant Mane
        Description    		: This method is used to Convert Lead to an Existing or an Selected Account after salesAccount Salector.
        Issue No      		: ST-2722
        Created Date    	: 31 Aug 2018
		Last Modified By    : Samadhan Kadam
		Last Modified date  : 22 Jan 2019
		Issue No			: STL-129,STL-130
**************************************************************************************************************************************/
    @AuraEnabled
    public static List<Building__c> getBuildingRelatedData(String buildingId){
        try{
            Boolean isBuildingId = false;
            List<Building__c> lstBuildings;
            if(String.isNotBlank(buildingId)){
                try {
                    buildingId = Id.valueOf(buildingId);
                    isBuildingId = true;
                } catch(Exception ex) {
                }
                lstBuildings =  isBuildingId ? buildingSelector.getBuildingsByIdWithTourSchedules(buildingId)
                    : buildingSelector.getBuildingsByUuidWithTourSchedules(buildingId);
            } else {
                Id userId = UserInfo.getUserId();
                lstBuildings = buildingSelector.getBuildingByCommunityManagerWithTourSchedules(userId);
                if(lstBuildings.isEmpty()){
                    Id objBuildingId =  getLoggedInUsersBuildingId();
                    if(String.isNotBlank(objBuildingId)){
                        lstBuildings = buildingSelector.getBuildingsByIdWithTourSchedules(objBuildingId);
                    }
                }
            }
            return lstBuildings;
        } catch(Exception pEx) {
            ApexDebugLog.logException(pEx,'buildingId==>'+ buildingId, 'CommunityViewHelper', 'getBuildingRelatedData');
            return null;
        }
    }

    /************************************************************************************************************************************
        Author         	: Samadhan Kadam
        Description     : This method used to return community view building from user object which is used to prepopulate building on
        				  community view page.
        Issue No      	: STL-128,129
        Created Date    : 17 Jan 2019
	**************************************************************************************************************************************/
    public static Id getLoggedInUsersBuildingId(){
        User userData = [SELECT Id, Community_View_Building__c FROM User WHERE Id =: userInfo.getUserId()];
        if(String.isNotBlank(userData.Community_View_Building__c)){
            return userData.Community_View_Building__c;
        }
        return null;
    }

	/************************************************************************************************************************************
        Author         	: Prashant Mane.
        Description     : This method is used to calculate end date for current week
    	Issue No      	: ST-2383
        Created Date    : 18 May 2018
	**************************************************************************************************************************************/
   public static Map<String,Date> calculateThisWeekEndDate(Date todaysDate){
        Map<String, Date> mapThisWeekDates = new Map<String,Date>();
        datetime objDate = datetime.newInstance(todaysDate.year(), todaysDate.month(), todaysDate.day());
        String day = objDate.format('EEEE');
        if(day == 'Monday'){
            mapThisWeekDates.put('ThisWeekStartDate',todaysDate);
            mapThisWeekDates.put('ThisWeekEndDate',todaysDate.addDays(6));
        }else if(day == 'Tuesday'){
            mapThisWeekDates.put('ThisWeekStartDate',todaysDate.addDays(-1));
            mapThisWeekDates.put('ThisWeekEndDate',todaysDate.addDays(5));
        }else if(day == 'Wednesday'){
            mapThisWeekDates.put('ThisWeekStartDate',todaysDate.addDays(-2));
            mapThisWeekDates.put('ThisWeekEndDate',todaysDate.addDays(4));
        }else if(day == 'Thursday'){
            mapThisWeekDates.put('ThisWeekStartDate',todaysDate.addDays(-3));
            mapThisWeekDates.put('ThisWeekEndDate',todaysDate.addDays(3));
        }else if(day == 'Friday'){
            mapThisWeekDates.put('ThisWeekStartDate',todaysDate.addDays(-4));
            mapThisWeekDates.put('ThisWeekEndDate',todaysDate.addDays(2));
        }else if(day == 'Saturday'){
            mapThisWeekDates.put('ThisWeekStartDate',todaysDate.addDays(-5));
            mapThisWeekDates.put('ThisWeekEndDate',todaysDate.addDays(1));
        }else if(day == 'Sunday'){
            mapThisWeekDates.put('ThisWeekStartDate',todaysDate.addDays(-6));
            mapThisWeekDates.put('ThisWeekEndDate',todaysDate);
        }
        return mapThisWeekDates;
    }
/************************************************************************************************************************************
        Author          	: Rupesh Patil
        Description     	: This method is used to create Opportunity in the Community View page
        Issue No      		: ST-2385
        Created Date    	: 19 May 2018
		Last Modified By    : Pragalbha Mahajan
        Last Modified Date  : 15 October 2018
**************************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult createOpportunityForCommunityView(Id contactId,object noOfDesks,Id buildingID){
        try{
            sp = Database.setSavepoint();
            Opportunity obOpportunity = OpportunityHelper.createOpportunity(contactId, noOfDesks, buildingID);
            return new DatabaseResult(JSON.serialize([Select Id,Name,Building__c,Building__r.Name,Owner.Name,Account.Primary_Member__r.Name,Billing_Account__c,CloseDate,Account.Interested_in_Number_of_Desks__c,Quantity__c,StageName,Account.Primary_Member__r.Email,Account.Name from Opportunity Where Id=:obOpportunity.Id]));
        }catch(Exception pEx){
            LightningComponentController.rollbackTransaction(sp);
            ApexDebugLog.logException(pEx,'contactId==>'+contactId+' noOfDesks==>'+noOfDesks+' buildingID==>'+buildingID, 'CommunityViewHelper', 'createOpportunityForCommunityView');
            return (new DatabaseResult(pEx));
        }
    }

/************************************************************************************************************************************
        Author              :   Rohit Nimase
        Description         :   This method is used to get or create Opportunity Record.
        Issue No.           :   STL-127
        Last Modified Date  :   6 Feb 2019
**************************************************************************************************************************************/
    /*@AuraEnabled
    public static DatabaseResult getOpportunityRecord(Map<String, Id> mapRecordData, Id buildingID){
        Opportunity objOpportunity = getOppRelatedToAccountOrCreate(mapRecordData, buildingID);
        Map<String, Object> mapData = new Map<String, Object>();
        mapData.put('opportunity', objOpportunity);
        mapData.put('contact', [SELECT Id, Name, Email, Phone, Account.Name, Account.UUID__c, UUID__c FROM Contact WHERE Id =: mapRecordData.get('contactId')]);
        return new DatabaseResult(mapData);
    }*/

/************************************************************************************************************************************
        Author              :   Rohit Nimase
        Description         :   This method is used to get or create Opportunity Record.
        Issue No.           :   STL-127
        Last Modified Date  :   6 Feb 2019
**************************************************************************************************************************************/
    /*public static opportunity getOppRelatedToAccountOrCreate(Map<String, Id> mapRecordData, Id buildingID){
        Sales_Console_Setting__mdt communityViewApiSetting = SalesConsoleSettings.get('CommunityViewAPISetting');

            if(communityViewApiSetting != null){
                Map<String,Object> mapData = (Map<String,Object>)JSON.deserializeUntyped(communityViewApiSetting.Data__c);
                set<String> oppStageName = (Set<String>)JSON.deserialize(JSON.serialize(mapData.get('OppCloseStages')), Set<String>.class);
                set<String> closedContractStageName = (Set<String>)JSON.deserialize(JSON.serialize(mapData.get('OppCloseContractStage')), Set<String>.class);
                if(mapRecordData.get('accountId') != null){
                    List<Opportunity> lstOpportunity = [SELECT Id ,StageName ,Contract_Stage__c ,Building__c FROM Opportunity WHERE AccountID =: mapRecordData.get('accountId') AND StageName NOT IN:oppStageName AND Contract_Stage__c NOT IN:closedContractStageName ORDER BY CreatedDate Desc ];
                    if(lstOpportunity != null && lstOpportunity.size()>0){
                        for(Opportunity opp : lstOpportunity){
                            if(buildingId == opp.Building__c){
                               return opp;
                            }
                        }
                        return lstOpportunity[0];
                    }else{
                        return OpportunityHelper.createOpportunity(mapRecordData.get('contactId'), 1, buildingId);
                    }
                }
            }
        return null;
    }*/
/************************************************************************************************************************************
        Author         	: Rupesh Patil
        Description     : This method is used to insert new contact, account and opportunity in the Community View page
        Issue No      	: ST-2385
        Created Date    : 19 May 2018
**************************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult createAccountOppContactCommunityView(Map<String,Object> recordsToCreate){
        try{
            sp = Database.setSavepoint();
            Map<String,Object> response;
            if(recordsToCreate!=null && !recordsToCreate.isEmpty()){

                Contact objContact = new Contact(FirstName= String.valueOf(recordsToCreate.get('FirstName')) !=null ? String.valueOf(recordsToCreate.get('FirstName')):null,LastName=String.valueOf(recordsToCreate.get('LastName')),Email=String.valueOf(recordsToCreate.get('Email')),Phone=String.valueOf(recordsToCreate.get('Phone'))!=null ? String.valueOf(recordsToCreate.get('Phone')):null,UUID__c=String.valueOf(recordsToCreate.get('user_uuid')),LeadSource='Walk In',Lead_Source_Detail__c='Community Registration');
                insert objContact;
                List<Contact> lstContact = [SELECT Id,Name,Account_Name__c,AccountId,Account.Parent_Org_Id__c,Account.Name,Account.Account_Type__c,UUID__c,Email,Email_Domain_Text__c,Company__c,Cleansed_Company_Name__c,Unomy_Company_ID_Formula__c,FirstName,LastName,Phone,Type__c,LeadSource,Lead_Source_Detail__c,utm_campaign__c,utm_content__c,utm_medium__c,utm_source__c,utm_term__c,Locale__c,Country_Code__c FROM Contact WHERE Id=:objContact.Id];
                lstContact[0].AccountId = OrganizationHelper.findOrCreateRelatedOrg(lstContact[0]);
                update lstContact[0];

                Id buildingID;
                if(String.valueOf(recordsToCreate.get('buildingId')) != null)
                    buildingID = String.valueOf(recordsToCreate.get('buildingId'));

                response = new Map<String,Object>();
                response.put('contact',lstContact[0]);
                response.put('account',lstContact[0].AccountId);
            }
            return new DatabaseResult(JSON.serialize(response));
        }catch(Exception pEx){
            LightningComponentController.rollbackTransaction(sp);
            ApexDebugLog.logException(pEx,'recordsToCreate==>'+recordsToCreate, 'CommunityViewHelper', 'createAccountOppContactCommunityView');
            return (new DatabaseResult(pEx));
        }
    }

/************************************************************************************************************************************
        Author         	: Prashant Mane
        Description     : This method is used to Convert Lead to create Contact Account and Opportunity.
        Issue No      	: CSI-1105
        Created Date    : 10 Aug 2018
**************************************************************************************************************************************/
    /*private static Map<String,Map<String,Id>> mapConvertedLead;
    public static opportunity convertLeadForSendPaperWork(Id leadId , Id buildingId){
        List<Lead> lstleadData = [SELECT Id, FirstName, Interested_in_Number_of_Desks_Min__c, Interested_in_Number_of_Desks__c, LastName, Name, OwnerId, Email_Domain_Text__c, Company, Account__c, Account__r.Account_Type__c, Referrer__c, Cleansed_Unomy_Company_Name__c, Cleansed_Company_Name__c, Email, LeadSource, Lead_Source_Detail__c, Generate_Journey__c, By_Pass_Journey_Creation_Criteria__c, Campaign_Id__c, Building_Interested_In__c, Building_Interested_In__r.City__c, Locations_Interested__c, Number_of_Full_Time_Employees__c FROM Lead WHERE Id=:leadId AND IsConverted=false];
        if(lstleadData.size() > 0){
            mapConvertedLead  =  LeadConverterHelper.convertLeadWithTour(lstleadData[0]);
            Map<String,Id> mapLeadData = mapConvertedLead.get(lstleadData[0].email);
           // Opportunity objOpportunity = getOppRelatedToAccountOrCreate(mapLeadData, buildingId);
            return objOpportunity;
        }
        return null;
    }*/

/************************************************************************************************************************************
        Author         	: Prashant Mane
        Description     : This method is used to Convert Lead to an Existing or an Selected Account after salesAccount Salector.
        Issue No      	: ST-2722
        Created Date    : 31 Aug 2018
**************************************************************************************************************************************/
    /*@AuraEnabled
    public static DatabaseResult convertLeadsToExistingAccountandOpportunity(Lead objLead,Id buildingId){
        try{
            sp = Database.setSavepoint();
            if(string.isNotBlank(objLead.Email)){
                List<Lead> lstLeadToUpdate = [SELECT Id FROM Lead WHERE Email =: objLead.Email AND IsConverted=false ORDER BY CreatedDate ASC];
                if(!lstLeadToUpdate.isEmpty()){
                  objLead.Id = lstLeadToUpdate[0].Id;
                }
            }
            update objLead;
            LightningComponentController.checkChangeInLeadForFTE(objLead);
            Opportunity objOpportunity = CommunityViewHelper.convertLeadForSendPaperWork(objLead.Id,buildingId);
            Map<String, Object> mapData = new Map<String, Object>();
            mapData.put('opportunity', objOpportunity);
            if(mapConvertedLead != null){
                Map<String, Id> mapOfconvertedData = mapConvertedLead.get(objLead.Email);
                if(mapOfconvertedData != null && mapOfconvertedData.get('contactId') != null){
                    mapData.put('contact', [SELECT Id, Name, Email, Phone, Account.Name, UUID__c FROM Contact WHERE Id =: mapOfconvertedData.get('contactId')]);
                }
            }
            return new DatabaseResult(mapData);
        } catch(Exception pEx){
            LightningComponentController.rollbackTransaction(sp);
            ApexDebugLog.logException(pEx,'objLead==>'+objLead+' buildingId==>'+buildingId, 'CommunityViewHelper', 'convertLeadsToExistingAccountandOpportunity');
            return (new DatabaseResult(pEx));
        }
    }*/

    /**
    * @author Gad Sharon
    * @date 10/02/19
    * @description Update SAPI with new assigned host for tour.
    * @param string uuid - The UUID of the tour with the new assigned host.
			 string id - The SF contact id of the new assigned host. .
    * @return DatabaseResult - Object with info on success/failure.
    */

    @AuraEnabled
    public static DatabaseResult updateSapiWithNewAssignedHost(string uuid, string contactSfId)
    {
        try
        {
            //Call SAPI and communicate the new assigned host.
            APIConnection req = new APIConnection('SAPI_Assign_Host_to_Tour');
            req.setEndPointParams(new list <String>{uuid});
            HttpResponse resp = req.sendRequest('{"sf_user_id": "' + contactSfId + '"}');

            //Return null if the process completed successfully.
            if(resp.getStatusCode() == 200)
                return new DatabaseResult(true, null, null);

            //SAPI returned an error. We return this error so we can display it to the user.
			Map<String, Object> jsonResponse = (Map<String, Object>)JSON.deserializeUntyped(resp.getBody());
	        return new DatabaseResult(false, null, String.valueOf(jsonResponse.get('error')));
        }
		catch (Exception ex)
        {
            return new DatabaseResult(false, null, 'An error occurred. Please contact support.');
        }
    }

/************************************************************************************************************************************
    Author         : Aaditya Bansal.
    Description    : This method is used to identify if the id is uuid query on billing account
    Issue No       : TWSPG-4297
    Created Date   : 6 June 2020
**************************************************************************************************************************************/
    public static List<Account> getBillingAccountData(String billingAccountId) {
        if (String.isBlank(billingAccountId)) {
            return null;
        }
        String recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(BILLING_ACCOUNT_RECORD_TYPE).getRecordTypeId();

        String query = 'SELECT Id, Name, UUID__c, ID_Status__c, (SELECT Id, Contact.Name, Contact.Email FROM AccountContactRelations WHERE Roles = \'Primary Member\'), Ultimate_Parent_Org__r.Primary_Member__c, Ultimate_Parent_Org__r.Primary_Member__r.Location__c, Ultimate_Parent_Org__r.Primary_Member__r.Email, Ultimate_Parent_Org__c FROM Account WHERE recordTypeId = :recordTypeId AND ';
        if (Pattern.matches('[a-zA-Z0-9]{18}|[a-zA-Z0-9]{15}', billingAccountId)) {
            query += 'Id =: billingAccountId';
        } else {
            query += 'UUID__c =: billingAccountId';
        }
        return Database.query(query);
    }

/************************************************************************************************************************************
    Author         : Prashant Mane.
    Description    : This is wrapper class for getOnLoadCommunityViewData method
    Issue No       : ST-2383
    Created Date   : 18 May 2018
**************************************************************************************************************************************/
    class CommunityViewOnloadWrapper{
        Sales_Console_Setting__mdt CommunityViewAPISetting {get;set;}
        DatabaseResult TodayTours {get;set;}
        List<Building__c> BuildingInfo {get;set;}
        CommunityViewServerDates ServerDates {get;set;}
        Map<String,Object> loggedInUserInfo {get;set;}
        List<Building__c> AllWeWorkBuildings {get;set;}
        List<Account> BillingAccount {get;set;}
        String HoldBackQueueMetaData {get;set;}
    }
/************************************************************************************************************************************
	Author              : Prashant Mane.
	Description         : This is wrapper class for getOnLoadCommunityViewData method
	Issue No            : ST-2383,CSI-883
	Created Date        : 18 May 2018
	Last Modified By    : Jitesh Adwani.
	Last Modified Date  : 29 May 2018
**************************************************************************************************************************************/
    class CommunityViewServerDates{
        Date YesterdaysDate;
        Date TodaysDate;
        Date TomorrowDate;
        Date ThisWeekStartDate;
        Date ThisWeekEndDate;
        DateTime BuildingTimeZoneDate;
    }
}