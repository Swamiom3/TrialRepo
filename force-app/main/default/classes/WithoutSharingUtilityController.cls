/************************************************************************************************************************************
    Author      :   ---
    Description :   This class contain methods to run buisness logic in system mode.

    History:
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           22 January 2016     ---                     Initial Developement
**************************************************************************************************************************************/
public without sharing class WithoutSharingUtilityController {
    private static final List<String> ACCOUNT_CHILD_OBJECT_NAMES = new List<String>{'Contacts', 'Opportunities', 'childAccounts'};
    private static final Set<String> OPEN_OPP_STAGES = new Set<String>{'Qualifying', 'Selling', 'Negotiating'};
    private static final Schema.DescribeSObjectResult ACCOUNT_DESCRIBE_RESULT = Schema.SObjectType.Account;
    private static final Map<Id, RecordTypeInfo> ALLOWED_ACC_REC_TYPES_BY_ID = ACCOUNT_DESCRIBE_RESULT.getRecordTypeInfosById();
    private static final Map<String, RecordTypeInfo> ALLOWED_CON_REC_TYPES_BY_NAME = Schema.SObjectType.Contact.getRecordTypeInfosByName();
    private static final Map<String, RecordTypeInfo> ALLOWED_OPP_REC_TYPES_BY_NAME = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
    @TestVisible
    private static final Map<String, RecordTypeInfo> ALLOWED_ACC_REC_TYPES_BY_NAME = ACCOUNT_DESCRIBE_RESULT.getRecordTypeInfosByName();
    private static final String OPP_OWNER_CHAGE_EMAIL_SUBJECT = 'Opportunity Owner has been Changed';
    @TestVisible
    private static final String USER_ROLES_ENTERPRISE_SOLUTION = 'enterprise solutions';
    @TestVisible
    private static final String USER_ROLES_KEY_SALES = 'key sales';
    private static final String USER_ROLES_LEAD_PREFIX = 'lead -';
    private static final String TEAM_MEMBER_ROLE_SPLIT_REP = 'split rep';
    private static final String LEAD_SOURCE_OUTBOUND_EMAIL_COLD_CALL = 'outbound email/cold call';
    
    /************************************************************************************************************************************
        Author              :   ---
        Description         :   This method is invoked from updateRecordType to get lower size from company size range.
        Created Date        :   11 June 2017
  **************************************************************************************************************************************/
    public static Integer getLowerSize(String size){
        return AccountAssignmentHelper.getLowerSize(size);
    }
    
    public static OpportunityTeamMember helperCreateOpportunityTeamMember(User userDetails, Opportunity opportunityRecord, String teamMemberRole){
        OpportunityTeamMember objOpportunityTeamMember = new OpportunityTeamMember();
        objOpportunityTeamMember.UserId = userDetails.Id;
        objOpportunityTeamMember.TeamMemberRole = teamMemberRole;
        objOpportunityTeamMember.OpportunityId = opportunityRecord.Id;
        objOpportunityTeamMember.TeamMemberCreationSource__c = 'TourOutcomeForm';
        return objOpportunityTeamMember;
    }
    
    public static OpportunityTeamMember helperCreateORUpdateOpportunityTeamMember(User tourCompletedUser, Opportunity oppRecord, String teamMemberRole){
        set<Id> opportunityTeamMemberIds = new set<Id>();
        for(OpportunityTeamMember oppTeamMember : oppRecord.OpportunityTeamMembers ){
            if(oppTeamMember.UserId == null){
                continue;  
            }
            opportunityTeamMemberIds.add(oppTeamMember.UserId);
        }
        if(opportunityTeamMemberIds.isEmpty()){
            return null;
        }
        if(opportunityTeamMemberIds.contains(tourCompletedUser.Id)){//If User is allready present as member then update its Role as Assist
            for(OpportunityTeamMember oppTeamMember : oppRecord.OpportunityTeamMembers ){
                if(oppTeamMember.UserId == tourCompletedUser.Id){
                    oppTeamMember.TeamMemberRole = Settings.getTeamRoleConfigSettings('WithoutSharingUtilityController#1');
                    oppTeamMember.TeamMemberCreationSource__c = 'TourOutcomeForm';
                    return oppTeamMember;
                }
            }
        }else {//If user is not a member then add user as Team member
            return helperCreateOpportunityTeamMember(tourCompletedUser, oppRecord, teamMemberRole);
        }
        return null;
    }
    
   /************************************************************************************************************************************
        Author              :  ---
        Description         :  This method is used to update tour completed by field on tour.
        Created Date        :  11 June 2017
        LastModified By   	:  Sunil Bhosale
        LastModified Date  	:  6 Dec 2018
        Issue No      		:  ST-3197
    **************************************************************************************************************************************/
    /*public static void updateTourCompletedBy(List<Tour_Outcome__c> lstNewTours, Map<Id, Tour_Outcome__c> mapOldTours){
        set<String> setTourCompletedByUUIDs = new set<String>();
        set<String> setOpportunityIds = new set<String>();
        Map<String, Set<string>> mapExcludedProfiles = new Map<String, Set<string>>();
        MetadataSetting__mdt objMeataData = Settings.getMetadataSetting('RestrictTeamMemberProfiles');
        if(objMeataData != NULL && String.isNotBlank(objMeataData.Data__c)){
            mapExcludedProfiles = (Map<String,Set<String>>)JSON.deserialize(objMeataData.Data__c, Map<String,Set<String>>.class);
        }
        for(Tour_Outcome__c objTour :  lstNewTours){
            if(String.isNotBlank(objTour.Tour_Completed_By_Contact_UUID__c) && mapOldTours.get(objTour.Id).Tour_Completed_By_Contact_UUID__c != objTour.Tour_Completed_By_Contact_UUID__c){
                setTourCompletedByUUIDs.add(objTour.Tour_Completed_By_Contact_UUID__c);
            }
            if(String.isNotBlank(objTour.Opportunity__c)){
                setOpportunityIds.add(objTour.Opportunity__c);
            }
        }
        Map<String, Contact> mapContacts = new Map<String, Contact>();
        Map<Id, Opportunity> mapRealetedOpp = new Map<Id, Opportunity>();
        if(!setTourCompletedByUUIDs.isEmpty()){
            for(Contact contact: [SELECT id, Email, UUID__c FROM Contact WHERE UUID__c In : setTourCompletedByUUIDs]){
                mapContacts.put(contact.UUID__c, contact);
            }
        }
        if(!setOpportunityIds.isEmpty()){
            mapRealetedOpp = new Map<Id, Opportunity>([SELECT Id, (SELECT Id,TeamMemberRole,OpportunityId,UserId FROM OpportunityTeamMembers ) FROM Opportunity WHERE Id IN :setOpportunityIds]);
        }
        Set<OpportunityTeamMember> setOppTeamMember = new Set<OpportunityTeamMember>();
        for(Tour_Outcome__c objTour :  lstNewTours){
            if(String.isNotBlank(objTour.Tour_Completed_By_Contact_UUID__c) && mapContacts.get(objTour.Tour_Completed_By_Contact_UUID__c) != null){
                Contact objContact = mapContacts.get(objTour.Tour_Completed_By_Contact_UUID__c);
                objTour.Tour_Completed_By__c = objContact.Id;
            }
            User objUser = getValideUserForOpportunityTeamMember(objTour.Tour_Completed_By_SFID__c, mapExcludedProfiles);
            if(objUser != null && String.isNotBlank(objTour.Opportunity__c) && mapRealetedOpp.get(objTour.Opportunity__c) != null){
                setOppTeamMember.add(helperCreateORUpdateOpportunityTeamMember(objUser, mapRealetedOpp.get(objTour.Opportunity__c), Settings.getTeamRoleConfigSettings('WithoutSharingUtilityController#2')));
            }
            if(String.isNotBlank(objTour.Tour_Completed_By_SFID__c) && mapOldTours.get(objTour.Id).Tour_Completed_By_SFID__c != objTour.Tour_Completed_By_SFID__c){
                objTour.OwnerId = (Id)objTour.Tour_Completed_By_SFID__c;
            }
        }
        List<OpportunityTeamMember> lstOppTeamMemberToUpsert = new List<OpportunityTeamMember>();
        lstOppTeamMemberToUpsert.addAll(setOppTeamMember);
        if(!lstOppTeamMemberToUpsert.isEmpty()){
            if(OpportunityHelper.lstOpportunityTeamMembers == null){
                OpportunityHelper.lstOpportunityTeamMembers = new List<OpportunityTeamMember>();
            }
            OpportunityHelper.lstOpportunityTeamMembers.addAll(lstOppTeamMemberToUpsert);
        }
        else if(!lstOppTeamMemberToUpsert.isEmpty()){
            upsert lstOppTeamMemberToUpsert;
        }
    }
    
    private static User getValideUserForOpportunityTeamMember(Id userId, Map<String, Set<String>> mapExcludedProfiles){
        if(String.isNotBlank(userId) && UserUtility.getUserActive(userId)){
            User objUser = UserUtility.getUserById(userId);
            if(mapExcludedProfiles != NULL && !mapExcludedProfiles.isEmpty() &&
               mapExcludedProfiles.get('RestrictProfilesForRoleAssist') != NULL &&
               !mapExcludedProfiles.get('RestrictProfilesForRoleAssist').contains(String.valueOf(objUser.ProfileId)) &&
               !mapExcludedProfiles.get('RestrictProfilesForRoleAssist').contains(String.valueOf(objUser.ProfileId).substring(0, 15)) &&
               !AccountAssignmentHelper.isApiUser('UserId', objUser.Id)){
                   return objUser;
               }
        }
        return NULL;
    }
    **/
    /****************************************************************************************************************************
        Author              : Amol Darekar
        Description         : This method is invoked from OpportunityTeamMember on before insert and before Update.
        Summary             : This Method is used to Update the Split percentage according to sales console setting creiterias on OpportunityTeam Member records.
        Created Date        : 05 July 2016
        Last Modified By    : Krishana Tupe
        Last Modified Date  : 05 February 2018
    *****************************************************************************************************************************/
    public static void updateSplitPercentage(List<OpportunityTeamMember> newTeamMembers,Map<Id, OpportunityTeamMember> mapNewItems) {
        Set<Id> setOpportunityIds = new Set<Id>();
        Set<Id> setUserIds = new Set<Id>();
        for(OpportunityTeamMember opportunityTeamRecord :  newTeamMembers){
            setOpportunityIds.add(opportunityTeamRecord.OpportunityId);
            setUserIds.add(opportunityTeamRecord.UserId);
        }
        Map<Id,Opportunity> mapOpportunity = new Map<Id,Opportunity>([Select Id,Owner.UserRole.Name,LeadSource From Opportunity Where Id IN:setOpportunityIds]);
        
        UserUtility.fetchUsers();
        Map<Id, User> userSfdcRoleMap = UserUtility.idToUser;
        //Map<Id,User> userSfdcRoleMap = new Map<Id,User>([Select Id,UserRole.Name from User Where Id IN:setUserIds]);
        
        for(OpportunityTeamMember opportunityTeamRecord :  newTeamMembers){
            if(!(WeworkEngine.hasSObjectField('Split_Rep_Percentage__c',opportunityTeamRecord)) && opportunityTeamRecord.Split_Rep_Percentage__c==null){
                Opportunity opportunityRecord = mapOpportunity.get(opportunityTeamRecord.OpportunityId);
                if(opportunityRecord.Owner.UserRole != null
                   && (opportunityRecord.Owner.UserRole.Name.toLowerCase().contains(USER_ROLES_KEY_SALES)
                         || opportunityRecord.Owner.UserRole.Name.toLowerCase().contains(USER_ROLES_LEAD_PREFIX))
                   && opportunityTeamRecord.TeamMemberRole.toLowerCase()==(TEAM_MEMBER_ROLE_SPLIT_REP)){
                    setRepPercentageForOtherRoles(opportunityTeamRecord, userSfdcRoleMap, opportunityRecord);
                }
                else if(opportunityRecord.Owner.UserRole != null
                        && opportunityRecord.Owner.UserRole.Name.toLowerCase().contains(USER_ROLES_ENTERPRISE_SOLUTION)){
                    setRepPercentageForEnterpriseSolutionsRole(opportunityTeamRecord, userSfdcRoleMap);
                }
                else{
                    opportunityTeamRecord.Split_Rep_Percentage__c = 0;
                }
            }
        }
    }

    @TestVisible
    private static void setRepPercentageForEnterpriseSolutionsRole(OpportunityTeamMember opportunityTeamRecord, Map<Id, User> userSfdcRoleMap){
        if(userSfdcRoleMap.get(opportunityTeamRecord.UserId) == null) {
            return;
        }
        if (userSfdcRoleMap.get(opportunityTeamRecord.UserId).UserRole.Name.toLowerCase().contains(USER_ROLES_ENTERPRISE_SOLUTION)) {
            opportunityTeamRecord.Split_Rep_Percentage__c = 100.00;
        } else if (userSfdcRoleMap.get(opportunityTeamRecord.UserId).UserRole.Name.toLowerCase().contains(USER_ROLES_KEY_SALES) || userSfdcRoleMap.get(opportunityTeamRecord.UserId).UserRole.Name.toLowerCase().contains(USER_ROLES_LEAD_PREFIX)) {
            opportunityTeamRecord.Split_Rep_Percentage__c = 50.00;
        } else {
            opportunityTeamRecord.Split_Rep_Percentage__c = 0;
        }
    }

    @TestVisible
    private static void setRepPercentageForOtherRoles(OpportunityTeamMember opportunityTeamRecord, Map<Id, User> userSfdcRoleMap, Opportunity opportunityRecord){
        if(userSfdcRoleMap.get(opportunityTeamRecord.UserId) == null) {
            return;
        }
        if ((userSfdcRoleMap.get(opportunityTeamRecord.UserId).UserRole.Name.toLowerCase().contains(USER_ROLES_KEY_SALES) 
               || userSfdcRoleMap.get(opportunityTeamRecord.UserId).UserRole.Name.toLowerCase().contains(USER_ROLES_LEAD_PREFIX)) 
            && (opportunityRecord.LeadSource != null && opportunityRecord.LeadSource.toLowerCase() == LEAD_SOURCE_OUTBOUND_EMAIL_COLD_CALL)) {
            opportunityTeamRecord.Split_Rep_Percentage__c = 100.00;
        } else if ((userSfdcRoleMap.get(opportunityTeamRecord.UserId).UserRole.Name.toLowerCase().contains(USER_ROLES_ENTERPRISE_SOLUTION) 
                      || userSfdcRoleMap.get(opportunityTeamRecord.UserId).UserRole.Name.toLowerCase().contains(USER_ROLES_KEY_SALES) 
                      || userSfdcRoleMap.get(opportunityTeamRecord.UserId).UserRole.Name.toLowerCase().contains(USER_ROLES_LEAD_PREFIX)) 
                   && (opportunityRecord.LeadSource != null && opportunityRecord.LeadSource.toLowerCase() == LEAD_SOURCE_OUTBOUND_EMAIL_COLD_CALL)) {
            opportunityTeamRecord.Split_Rep_Percentage__c = 50.00;
        } else {
            opportunityTeamRecord.Split_Rep_Percentage__c = 0;
        }
    }
}