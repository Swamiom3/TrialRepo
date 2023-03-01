/************************************************************************************************************************************
Author      :   Shivprasad Patil
Description :   This class is used to close cases manually of valid user profile.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE              AUTHOR                Issue No            DETAIL
0           1 Feb 2018        Priyanka Ambre        ST-2000,ST-2022
1           5 Sep 2019        Shivprasad Patil      ST-1017             Initial Development
2           15 Jun 2021       Tomasz Sadowski       ST-8436             Migration to new trigger framework
**************************************************************************************************************************************/
public class CaseValidationTrH extends SObjectTriggerHandler{
    @TestVisible
    private List<Case> newCases;
    @TestVisible
    private Map<Id, Case> oldCasesMap;
    
    public CaseValidationTrH() {
        this(
            (List<Case>) Trigger.new,
            (Map<Id, Case>) Trigger.oldMap
        );
    }
    
    @TestVisible
    private CaseValidationTrH(List<Case> newCases, Map<Id, Case> oldCasesMap) {
        this.newCases = this.returnOnlyObjectWithValidRT(Case.SObjectType, 
                                                                           newCases,
                                                                           CaseConstants.CASE_SALES_RECORD_TYPE);
        if (this.context == TriggerContext.AFTER_INSERT
            || this.context == TriggerContext.BEFORE_INSERT) {
            return;
        }
        List<Case> oldCasesLit = this.returnOnlyObjectWithValidRT(Case.SObjectType, 
                                                                   oldCasesMap.values(),
                                                                   CaseConstants.CASE_SALES_RECORD_TYPE);
        this.oldCasesMap = new Map<Id, Case>(oldCasesLit);
    }
    
    public override void beforeUpdate() {
        validateUser();
    }

    public void validateUser() {
        validateUserToCloseCases(prepareCaseActors());
    }

    private List<Case> prepareCaseActors() {
        List<Case> filteredCases = new List<Case>();
        for (Case caseRecord : newCases) {
            Case oldCase = oldCasesMap?.get(caseRecord.Id);
            if (caseRecord.Status != GlobalConstants.CASE_STATUS_CLOSED || !TriggerUtility.isFieldValueChanged(caseRecord, oldCase, 'Status')) {
                continue;
            }
            filteredCases.add(caseRecord);
        }
        return filteredCases;
    }

    public void validateUserToCloseCases(List<Case> filteredCases) {
        if (filteredCases.isEmpty()) {
            return;
        }
        User loggedInUser = UserUtility.getUserById(UserInfo.getUserId());
        Set<String> profiles = new Set<String>();
        MetadataSetting__mdt metadataSetting = Settings.getMetadataSettingByDevName('AllowedProfilesToManageCases');
        AllowedProfilesForManageCases profilesToManageCasesSettings;
        if (metadataSetting != null && metadataSetting.Data__c != null) {
            profilesToManageCasesSettings = (AllowedProfilesForManageCases) JSON.deserialize(String.valueOf(metadataSetting.Data__c), AllowedProfilesForManageCases.class);
            if (profilesToManageCasesSettings != null && profilesToManageCasesSettings.profiles != null) {
                for (String profileName : profilesToManageCasesSettings.profiles) {
                    profiles.add(profileName.toLowerCase());
                }
            }
        }
        Boolean userProfile = false;
        Boolean metadataProfile = false;
        for (Case caseRecord : filteredCases) {
            userProfile = (loggedInUser.Profile.Name).equalsIgnoreCase(caseRecord.User_Profile__c);
            metadataProfile = profiles.contains(loggedInUser.Profile.Name.toLowerCase());
            if ((userProfile || metadataProfile) && String.valueOf(caseRecord.OwnerId).startsWith(GlobalConstants.GROUP_ID_PREFIX)) {
                caseRecord.OwnerId = loggedInUser.Id;
            } else if (!userProfile && !metadataProfile) {
                caseRecord.Status.addError(profilesToManageCasesSettings.errorMessage);
            }
        }
    }

    public class AllowedProfilesForManageCases {
        public List<String> profiles {get;set;}
        public String errorMessage {get;set;}
    } 
}