/************************************************************************************************************************************
Author         :     Pragalbha Mahajan
Description    :     This class contains the business logic of Creating Opportunity Team Member.
History        :
----------------------------------------------------------------------------------------------------------------------------------
VERSION        DATE                AUTHOR                    DETAIL
1              08 Jan 2019         Pragalbha Mahajan         Initial Development
2              12 April 2019       Rupesh Patil              Changes for ST-3730
3              24 Mar 2020         Jake Flynt                Changes for ST-5939
4              01 Sep 2020         Maciej Miłosz             Trigger Redesign
5              09 Nov 2020         Liubomyr Mishchykha       ST-7110 & refactoring
6              05 Nov 2021         Oleksandr Liesnik         ST-9428 & refactoring
**************************************************************************************************************************************/
public without sharing class OpportunityCreateOppTeamMemberTrH extends SObjectTriggerHandler {

    @TestVisible
    private AccountTeamMemberSelector accTeamMemberSelector = new AccountTeamMemberSelector();
    @TestVisible
    private ContactSelector contactSelector = new ContactSelector();
    @TestVisible
    private OpportunitySelector opportunitySelector = new OpportunitySelector();
    @TestVisible
    private OpportunityTeamMemberSelector oppTeamMemberSelector = new OpportunityTeamMemberSelector();
    @TestVisible
    private List<Opportunity> newOpportunities;
    @TestVisible
    private Map<Id, Opportunity> oldOpportunitiesMap;
    @TestVisible
    private List<OpportunityTeamMember> opportunityTeamMembersToInsert;
    @TestVisible
    private List<OpportunityTeamMember> opportunityTeamMembersToUpdate;
    
    private Set<Id> closedWonOpportunityIds;

    private Set<Id> oppIdOfApiUser;
    @TestVisible
    private Map<Id, User> contactIdsToUsers;

    private Map<String, String> profileNameToRole;

    private Map<String, String> profileNameToAccess;

    private static Map<Id, List<OpportunityTeamMember>> opportunityIdsToRelatedTeamMembers;

    public OpportunityCreateOppTeamMemberTrH() {
        this((List<Opportunity>) Trigger.new, (Map<Id, Opportunity>) Trigger.oldMap);
    }
    @TestVisible
    private OpportunityCreateOppTeamMemberTrH(List<Opportunity> newOpportunities,
                                              Map<Id, Opportunity> oldOpportunitiesMap) {
        this.newOpportunities = newOpportunities;
        this.oldOpportunitiesMap = oldOpportunitiesMap;
        opportunityTeamMembersToInsert = new List<OpportunityTeamMember>();
        opportunityTeamMembersToUpdate = new List<OpportunityTeamMember>();
        closedWonOpportunityIds = new Set<Id>();
        oppIdOfApiUser = new Set<Id>();
        contactIdsToUsers = new Map<Id, User>();
        profileNameToRole = new Map<String, String>();
        profileNameToAccess = new Map<String, String>();
    }

    @TestVisible
    public override void afterInsert() {
        addCoOwnersOnNamedAccountSegmentOpportunity();
        createOpportunityTeamMember();
        insertTeamMembers();
    }

    public override void beforeUpdate() {
        getChildOpportunityTeamMembers();
    }
    
    public override void afterUpdate() {
        createOpportunityTeamMember();
        insertTeamMembers();
    }

    @TestVisible
    private void createOpportunityTeamMember() {
        if (oldOpportunitiesMap == null) {
            mapContactIdsToUsers();
        }
        OpportunityTeamMemberCreation memberCreationSetting = getOppTeamMemberCreationSetting();
        Map<String, Set<String>> restrictedTeamMemberProfiles = getRestrictTeamMemberProfiles();
        if (memberCreationSetting != null) {
            for (AllowedProfiles allowedProfiles : memberCreationSetting.allowedProfiles) {
                profileNameToRole.put(allowedProfiles.profile.toLowerCase(), allowedProfiles.role);
                profileNameToAccess.put(allowedProfiles.profile.toLowerCase(), allowedProfiles.access);
            }
        }
        createTeamMemberOnOpportunityOwnerChange(memberCreationSetting);
        if (OpportunityHelper.lstOpportunityTeamMembers == null || OpportunityHelper.lstOpportunityTeamMembers.isEmpty()) {
            return;
        }
        List<OpportunityTeamMember> oppTeamMembersWithoutExcludedProfiles = getTeamMembersWithoutExcludedProfiles(restrictedTeamMemberProfiles);
        OpportunityHelper.lstOpportunityTeamMembers.clear();
        opportunityTeamMembersToInsert.addAll(oppTeamMembersWithoutExcludedProfiles);
    }

    @TestVisible
    private void mapContactIdsToUsers() {
        for (Opportunity newOpportunity : newOpportunities) {
            if (String.isNotBlank(newOpportunity.Tour_Booked_By__c) && newOpportunity.CreatedById == ApiUsersUtils.apiUserId) {
                oppIdOfApiUser.add(newOpportunity.Id);
                contactIdsToUsers.put(newOpportunity.Tour_Booked_By__c, null);
            }
        }
        if (!contactIdsToUsers.isEmpty()) {
            for (Contact con : getContactsByIds(contactIdsToUsers.keySet())) {
                contactIdsToUsers.put(con.Id, UserUtility.getUserByEmail(con.Email));
            }
        }
    }

    private List<Contact> getContactsByIds(Set<Id> contactIds) {
        return contactSelector.getContactsByIds(contactIds);
    }

    private void createTeamMemberOnOpportunityOwnerChange(OpportunityTeamMemberCreation memberCreationSetting){
        Set<Id> existingOpportunityTeamMemberIds;
        if (this.context == TriggerContext.AFTER_UPDATE) {
            existingOpportunityTeamMemberIds = new Map<Id, OpportunityTeamMember>(getExistingOpportunityTeamMemberIds()).keySet();
        }
        for (Opportunity newOpportunity : newOpportunities) {
            Opportunity oldOpportunity = oldOpportunitiesMap?.get(newOpportunity.Id);
            User teamMemberUser = oppIdOfApiUser.contains(newOpportunity.Id) && contactIdsToUsers.get(newOpportunity.Tour_Booked_By__c) != null 
                                                ? contactIdsToUsers.get(newOpportunity.Tour_Booked_By__c) 
                                                : UserUtility.getUserById(newOpportunity.OwnerId);
            if (oldOpportunitiesMap == null || (oldOpportunity != null && TriggerUtility.isFieldValueChanged(newOpportunity, oldOpportunity, GlobalConstants.OWNER_API_NAME))) {
                if (this.context == TriggerContext.AFTER_UPDATE && opportunityIdsToRelatedTeamMembers?.get(newOpportunity.Id) != null) {
                    for (OpportunityTeamMember childOppTeamMember : opportunityIdsToRelatedTeamMembers.get(newOpportunity.Id)) {
                        if (!Test.isRunningTest() && existingOpportunityTeamMemberIds.contains(childOppTeamMember.Id)) {
                            continue;
                        }
                        OpportunityTeamMember newTeamMember = childOppTeamMember.clone(false, true, false, false);
                        newTeamMember.TeamMemberCreationSource__c = 'OnOpportunityOwnerChange';
                        if (UserUtility.getUserActive(newTeamMember.UserId)) {
                            opportunityTeamMembersToInsert.add(newTeamMember);
                        }
                    }
                }
                if(teamMemberUser != null) {
                    createTeamMemberWithotProfile(teamMemberUser, memberCreationSetting, oldOpportunity, newOpportunity);
                }
            }
            if (oldOpportunity != null && newOpportunity.StageName == GlobalConstants.OPP_CLOSED_WON_STAGE_NAME 
                && TriggerUtility.isFieldValueChanged(newOpportunity, oldOpportunity, GlobalConstants.OPPORTUNITY_STAGE_API_NAME)) {
                closedWonOpportunityIds.add(newOpportunity.Id);
            }
        }
    }

    private void createTeamMemberWithotProfile(User teamMemberUser, OpportunityTeamMemberCreation memberCreationSetting,Opportunity oldOpportunity, Opportunity newOpportunity) {
        String profileName;
        String role;
        String access;
        if (UserUtility.getUserActive(teamMemberUser.Id) && String.isNotBlank(teamMemberUser.Profile.Name)
            && (memberCreationSetting.excludedProfiles == null || !memberCreationSetting.excludedProfiles.contains(teamMemberUser.Profile.Name))) {
                    profileName = teamMemberUser.Profile.Name.toLowerCase();
                    role = profileNameToRole.get(profileName) != null ? profileNameToRole.get(profileName) : memberCreationSetting.defaultRole;
                    access = profileNameToAccess.get(profileName) != null ? profileNameToAccess.get(profileName) : memberCreationSetting.defaultAccess;
                    if ((oldOpportunitiesMap == null || oldOpportunitiesMap.isEmpty()) 
                         || !(oldOpportunity != null && (memberCreationSetting.nmdProfiles != null 
                         && memberCreationSetting.nmdProfiles.contains(teamMemberUser.Profile.Name)))) {
                        opportunityTeamMembersToInsert.add(new OpportunityTeamMember(OpportunityId = newOpportunity.Id, TeamMemberRole = role, UserId = teamMemberUser.Id, OpportunityAccessLevel = access));
                    }
                }
    }

    private List<OpportunityTeamMember> getExistingOpportunityTeamMemberIds() {
        return oppTeamMemberSelector.getExistingOpportunityTeamMemberIds(new Map<Id, Opportunity>(newOpportunities).keySet());
    }

    private List<OpportunityTeamMember> getTeamMembersWithoutExcludedProfiles(Map<String, Set<String>> restrictedTeamMemberProfiles) {
        List<OpportunityTeamMember> opportunityTeamMembers = new List<OpportunityTeamMember>();
        if (restrictedTeamMemberProfiles != null) {
            Set<String> excludedProfilesForTeamMemberCreation = restrictedTeamMemberProfiles.get('Excluded Profiles');
            for (OpportunityTeamMember oppTeamMember : OpportunityHelper.lstOpportunityTeamMembers) { 
                if (oppTeamMember?.userId == null) {
                    continue;
                }
                User teamMemberUser = UserUtility.getUserById(oppTeamMember.UserId);
                if (!excludedProfilesForTeamMemberCreation.contains(teamMemberUser.Profile.Name.toLowerCase())) {
                    opportunityTeamMembers.add(oppTeamMember);
                }
            }
        } else {
            opportunityTeamMembers.addAll(OpportunityHelper.lstOpportunityTeamMembers);
        }
        return opportunityTeamMembers;
    }

    public static OpportunityTeamMemberCreation getOppTeamMemberCreationSetting() {
        MetadataSetting__mdt metadataRecord = Settings.getMetadataSettingByDevName('ManageOppTeamMemberCreation');
        if (metadataRecord?.Data__c != null) {
            return (OpportunityTeamMemberCreation) JSON.deserialize(metadataRecord.Data__c, OpportunityTeamMemberCreation.class);
        }
        return null;
    }

    private Map<String, Set<String>> getRestrictTeamMemberProfiles() {
        MetadataSetting__mdt metadataRecord = Settings.getMetadataSettingByDevName('RestrictTeamMemberProfiles');
        if (metadataRecord != null && metadataRecord.Data__c != null) {
            Map<String, Set<String>> restrictedProfiles = (Map<String, Set<String>>) JSON.deserialize(metadataRecord.Data__c, Map<String, Set<String>>.class);
            return restrictedProfiles;
        }
        return null;
    }

    @TestVisible
    private void addCoOwnersOnNamedAccountSegmentOpportunity() {
        List<Opportunity> globalOpportunities = new List<Opportunity>();
        List<Opportunity> nonGlobalOpportunities = new List<Opportunity>();
        Set<Id> globalAccountIds = new Set<Id>();
        Id renewalRecTypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Renewal').getRecordTypeId();
        for (Opportunity newOpportunity : newOpportunities) {
            if (newOpportunity.RecordTypeId != renewalRecTypeId && String.isNotBlank(newOpportunity.Named_Account_Segment__c) && newOpportunity.AccountId != null) {
                if (newOpportunity.Named_Account_Segment__c == 'Global Account') {
                    globalAccountIds.add(newOpportunity.AccountId);
                    globalOpportunities.add(newOpportunity);
                } else {
                    nonGlobalOpportunities.add(newOpportunity);
                }
            }
            if (newOpportunity.RecordTypeId == renewalRecTypeId && newOpportunity.Interested_in_Number_of_Desks__c >= 10
                    && (String.isBlank(newOpportunity.Named_Account_Segment__c) || newOpportunity.Named_Account_Segment__c == 'Community Account')) {
                nonGlobalOpportunities.add(newOpportunity);
            }
        }
        
        if (!globalOpportunities.isEmpty()) {
            createGlobalAccountsOpportunityTeamMembers(globalOpportunities, globalAccountIds);
        }
        if (!nonGlobalOpportunities.isEmpty()) {
            createNonGlobalAccountsOpportunityTeamMembers(nonGlobalOpportunities);
        }
    }

    @TestVisible
    private void createGlobalAccountsOpportunityTeamMembers(List<Opportunity> globalOpportunities, Set<Id> globalAccountIds) {
        Map<Id, Id> accountIdToTeamMemberId = new Map<Id, Id>();
        String teamMemberRole = Settings.getTeamRoleConfigSettings('OpportunityCreateOppTeamMemberTrH#5');
        for (AccountTeamMember accountTeamMember : getAccountTeamMembersWithGlobalAccount(globalAccountIds, teamMemberRole)) {
            accountIdToTeamMemberId.put(accountTeamMember.AccountId, accountTeamMember.UserId);
        }
        for (Opportunity globalOpportunity : globalOpportunities) {
            Id accountDirUserId = accountIdToTeamMemberId.get(globalOpportunity.AccountId);
            if (accountDirUserId != null && UserUtility.getUserActive(accountDirUserId)) {
                opportunityTeamMembersToInsert.add(new OpportunityTeamMember(OpportunityId = globalOpportunity.Id, TeamMemberRole = Settings.getTeamRoleConfigSettings('OpportunityCreateOppTeamMemberTrH#6'), UserId = accountDirUserId));
            }
        }
    }

    private List<AccountTeamMember> getAccountTeamMembersWithGlobalAccount(Set<Id> globalAccountIds, String teamMemberRole) {
        return accTeamMemberSelector.getAccountTeamMembersWithGlobalAccount(globalAccountIds, teamMemberRole);
    }

    @TestVisible
    private void createNonGlobalAccountsOpportunityTeamMembers(List<Opportunity> nonGlobalOpportunities) {
        for (Opportunity nonGlobalOpportunity : nonGlobalOpportunities) {
            Id oppAccountOwnerId;
            if (nonGlobalOpportunity.Account_Owner__c.startsWith('_')
                && String.isNotBlank(nonGlobalOpportunity.Account_Owner__c.split('_')[3])) {
                    oppAccountOwnerId = (Id) nonGlobalOpportunity.Account_Owner__c.split('_')[3]; // if formula field value is encoded
            } else if (nonGlobalOpportunity.Account_Owner__c.startsWith('<')
                       && String.isNotBlank(nonGlobalOpportunity.Account_Owner__c.split('"')[1])) {
                          oppAccountOwnerId = (Id) nonGlobalOpportunity.Account_Owner__c.split('"')[1]; // if formula field value is not encoded
            } else {
                continue;
            }
            if (oppAccountOwnerId != ApiUsersUtils.apiUserId && UserUtility.getUserActive(oppAccountOwnerId)) {
                opportunityTeamMembersToInsert.add(new OpportunityTeamMember(OpportunityId = nonGlobalOpportunity.Id, TeamMemberRole = Settings.getTeamRoleConfigSettings('OpportunityCreateOppTeamMemberTrH#7'), UserId = oppAccountOwnerId));
            }
        }
    }

    private void insertTeamMembers() {
        if (opportunityTeamMembersToInsert.isEmpty()) {
            return;
        }
        new OppTeamMemberUpdateUserAttributeHelper().updateUserAttribute(opportunityTeamMembersToInsert, false);
        dml.add(opportunityTeamMembersToInsert, DmlConsolidator.Operation.FOR_INSERT);
    }

    private List<Opportunity> getOpportunitiesWithTeamMembers() {
        return opportunitySelector.getOpportunitiesWithTeamMembers(new Map<Id, Opportunity>(newOpportunities).keySet());
    }

    @TestVisible
    private void getChildOpportunityTeamMembers() {
        opportunityIdsToRelatedTeamMembers = new Map<Id, List<OpportunityTeamMember>>();
        List<Opportunity> opportunitiesWithTeamMembers = getOpportunitiesWithTeamMembers();
        for (Opportunity opportunityWithTeamMembers : opportunitiesWithTeamMembers) {
            if (opportunityWithTeamMembers.OpportunityTeamMembers != null && opportunityWithTeamMembers.OpportunityTeamMembers.size() > 0) {
                opportunityIdsToRelatedTeamMembers.put(opportunityWithTeamMembers.Id, opportunityWithTeamMembers.OpportunityTeamMembers);
            }
        }
    }
  
    public class AllowedProfiles {
        public String role { get; set; }
        public String profile { get; set; }
        public String access { get; set; }
    }

    public class OpportunityTeamMemberCreation {
        public List<AllowedProfiles> allowedProfiles { get; set; }
        public String defaultRole { get; set; }
        public String defaultAccess { get; set; }
        public String errorForSecondNMD { get; set; }
        public List<String> teamMemberRoles { get; set; }
        public Set<String> excludedProfiles { get; set; }
        public Set<String> nmdProfiles { get; set; }
        public Set<Id> excludedProfilesForNMDValidation { get; set; }
    }
}