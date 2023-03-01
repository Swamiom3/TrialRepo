/************************************************************************************************************************************
    Author      :   Anant Kumar
    Description :   This class will contain buisness logic of opportunity trigger.
    History:
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1           23 February 2016    Anant Kumar             Initial Developement
    2           12 May 2016         Amol Darekar
    3           26 August 2020      Maciej Miłosz           Switching to new trigger framework
    4           10 February 2021    Mikolaj Juras           Remove Building_Interests__c logic
**************************************************************************************************************************************/
global class OpportunityTriggerHandler extends SObjectTriggerHandler {

    @TestVisible
    private List<Opportunity> newOpportunities;
    @TestVisible
    private List<Opportunity> oldOpportunities;
    @TestVisible
    private Map<Id, Opportunity> newOpportunitiesMap;
    @TestVisible
    private Map<Id, Opportunity> oldOpportunitiesMap;
    @TestVisible
    private static Set<Id> usersIdsFromPreviousExecution;
    @TestVisible
    private static Map<Id, List<User_Attribute__c>> userAttributesByUsersIds;

    public OpportunityTriggerHandler(){
        this(
                (List<Opportunity>) Trigger.new,
                (List<Opportunity>) Trigger.old,
                (Map<Id, Opportunity>) Trigger.newMap,
                (Map<Id, Opportunity>) Trigger.oldMap
        );
    }

    @TestVisible
    private OpportunityTriggerHandler(List<Opportunity> newOpportunities, List<Opportunity> oldOpportunities, Map<Id, Opportunity> newOpportunitiesMap, Map<Id, Opportunity> oldOpportunitiesMap){
        this.newOpportunities = newOpportunities;
        this.oldOpportunities = oldOpportunities;
        this.newOpportunitiesMap = newOpportunitiesMap;
        this.oldOpportunitiesMap = oldOpportunitiesMap;
    }
    static Set<Id> setOppIds;
    static Set<Id> setLeadIds;


    static Boolean handleRecursiveFlagForNotifyTeamMemberCwOrCl = true;
    static Boolean handleRecursiveForNotifyEmailOwnership = true;
    static Boolean hasOnceEmailSentForNotifyEmailOwnership = true;
    static Boolean hasOncecloneJourney = true;
    /************************************************************************************************************************************
    Author              :   Anant Kumar
    Description         :   This method overrides before insert method from ITriggerHander which will control the execution flow.
    Created Date        :   23 February 2016
    Last Modified Date  :   12 May 2016
    Last Modified By    :   Amol Darekar
    **************************************************************************************************************************************/
    public override void beforeInsert(){
        handleRecursiveForNotifyEmailOwnership = false;
    }

    /************************************************************************************************************************************
    Author              :   Anant Kumar
    Description         :   This method overrides before update method from ITriggerHander which will control the execution flow.
    Last Modified Date  :   12 May 2016
    Last Modified By    :   Amol Darekar
    **************************************************************************************************************************************/
    public override void beforeUpdate(){
    }

    /************************************************************************************************************************************
    Author              :   Anant Kumar
    Description         :   This method overrides after insert method from ITriggerHander which will control the execution flow.
    Last Modified Date  :   12 May 2016
    Last Modified By    :   Amol Darekar
    **************************************************************************************************************************************/
    public override void afterInsert(){
        handleRecursiveForNotifyEmailOwnership = true;
    }

    /************************************************************************************************************************************
    Author              :   Anant Kumar
    Description         :   This method overrides after update method from ITriggerHander which will control the execution flow.
    Last Modified Date  :   12 May 2016
    Last Modified By    :   Amol Darekar
    **************************************************************************************************************************************/
    public override void afterUpdate(){
    }

    /************************************************************************************************************************************
        Author              :   Amol Darekar
        Description         :   This method used for Change Type and Record type to Residential Space when LeadSource is 'WeLive' or 'WeLive.com' and also if Product Line is 'WeLive'.
        Created Date        :   14 June 2016
        Issue No.           :   ST-412
    **************************************************************************************************************************************/
    @TestVisible
    private void setTypeAndRecordTypeOfOpprtunity(){
        for(Opportunity currentOpprotunity : newOpportunities){
            if(currentOpprotunity.LeadSource == 'WeLive.com' || currentOpprotunity.LeadSource == 'WeLive'){
                currentOpprotunity.Type__c = 'Residential Space';
                currentOpprotunity.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('New Business').getRecordTypeId();
            }
        }
    }

    /************************************************************************************************************************************
        Author              :   Anant Kumar
        Description         :   This method will encode Opportunity Id.
        Created Date        :   21 June 2016
        Issue No.           :   ST-455
    **************************************************************************************************************************************/
    @TestVisible
    private void encodedOpportunityID(){
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        for(Opportunity objOpp : newOpportunities){
            if(objOpp.Encoded_Id__c==null){
                opportunitiesToUpdate.add(new Opportunity(Id = objOpp.Id, Encoded_Id__c = EncodingUtil.base64Encode(Blob.valueOf(objOpp.Id))));
            }
        }
        if(!opportunitiesToUpdate.isEmpty()){
            MetadataDrivenTriggerHandler.disableExecution();
            update opportunitiesToUpdate;
            MetadataDrivenTriggerHandler.enableExecution();
        }
    }

    /************************************************************************************************************************************
        Author              :   Anant Kumar
        Description         :   This method has auto tagging for referral app.
        Created Date        :   20 July 2016
        Issue No.           :   ST-530
    **************************************************************************************************************************************/
    @TestVisible
    private void updateActiveReferrer(){
        Set<String> primaryContactEmails = new Set<String>();
        for(Opportunity opp : newOpportunities){
            if(opp.Primary_Member__c != null && opp.Referrer__c == null && String.isNotBlank(opp.Primary_Member_Email_New__c)){
                primaryContactEmails.add(opp.Primary_Member_Email_New__c);
            }
        }
        if(primaryContactEmails.isEmpty()){
            return;
        }
        Map<String, Id> mapActiveReferences = ReferenceHandler.getActiveReference(primaryContactEmails);
        if(mapActiveReferences == null || mapActiveReferences.isEmpty()){
            return;
        }
        for(Opportunity opp : newOpportunities){
            if(String.isNotBlank(opp.Primary_Member_Email_New__c) && mapActiveReferences.containsKey(opp.Primary_Member_Email_New__c.toLowerCase())){
                opp.Referrer__c = mapActiveReferences.get(opp.Primary_Member_Email_New__c.toLowerCase());
            }
        }
    }

    @TestVisible
    private User getContactUser(Map<Id,Contact> mapContacts, Opportunity oppRec, Map<String,User> mapEmailToUser){
        if(mapContacts.get(oppRec.Send_Paperwork_By__c) != null
                && mapContacts.get(oppRec.Send_Paperwork_By__c).Email != null
                && mapEmailToUser.get(mapContacts.get(oppRec.Send_Paperwork_By__c).Email) != null){
            return mapEmailToUser.get(mapContacts.get(oppRec.Send_Paperwork_By__c).Email);
        }
        return null;
    }

    /*****************************************************************************************************************************************
        Author              :   Pragalbha Mahajan
        Description         :   This method sends email to current and previous owners of opportunity when opportunity owner will be changed.
        Created Date        :   01 October 2018
        Issue No            :   ST-2795
    ******************************************************************************************************************************************/
    @TestVisible
    private void sendEmailOnOwnerChange(){
        Id EntSolutionId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('New Business').getRecordTypeId();
        Set<Id> setOpportunityIds = new Set<Id>();
        Set<Id> setNonEntOpportunities = new Set<Id>();
        Set<Id> setEntOpportunities = new Set<Id>();
        Map<Id, Opportunity> opportunitiesOnAccOwnerChange = AccountStoreRelOppForEmailAlertTrH.accRelatedOpportunityOnAccOwnerChange;
        for(Opportunity objOpp: newOpportunities){
            if(((objOpp.OwnerId != oldOpportunitiesMap.get(objOpp.Id).OwnerId) || (!opportunitiesOnAccOwnerChange.isEmpty() && opportunitiesOnAccOwnerChange.containsKey(objOpp.Id) && objOpp.OwnerId != opportunitiesOnAccOwnerChange.get(objOpp.Id).OwnerId))){
                if((String.valueOf(objOpp.RecordTypeId).equalsIgnoreCase(EntSolutionId) && hasOnceEmailSentForNotifyEmailOwnership)){
                    setEntOpportunities.add(objOpp.Id);
                }else if(!String.valueOf(objOpp.RecordTypeId).equalsIgnoreCase(EntSolutionId) && handleRecursiveForNotifyEmailOwnership){
                    setNonEntOpportunities.add(objOpp.Id);
                }
            }
        }
        if(!setNonEntOpportunities.isEmpty()){
            handleRecursiveForNotifyEmailOwnership = false;
            setOpportunityIds.addAll(setNonEntOpportunities);
        }
        if(!setEntOpportunities.isEmpty()){
            hasOnceEmailSentForNotifyEmailOwnership = false;
            setOpportunityIds.addAll(setEntOpportunities);
        }
        if(!setOpportunityIds.isEmpty()){
            //V TODO refactor: extract to separate class that will send emails on ownership changes for any SObject
            AccountSendEmailToAccountOwnersTrH.sendEmailOnOwnershipChangeForOpportunities(setOpportunityIds, 'Email_on_Opportunity_Owner_Change', newOpportunitiesMap, oldOpportunitiesMap);
        }
    }

    /************************************************************************************************************************************
        Author              : Rohit Nimase
        Description         : This method contains business logic to update opportunity's forecast category.
        Created Date        : 12 Oct 2018
        Issue No.           : ST-2750
    **************************************************************************************************************************************/
    @TestVisible
    private void updateOppForecastCategory(){
        Boolean standardForecastChanged;
        Boolean customForecastChanged;
        for(Opportunity oppRec : newOpportunities){
            customForecastChanged = (oppRec.Forecast_Category__c != null && oldOpportunitiesMap == null) || (oldOpportunitiesMap != null && oldOpportunitiesMap.get(oppRec.Id).Forecast_Category__c != oppRec.Forecast_Category__c);
            standardForecastChanged = (oppRec.ForecastCategoryName != null && oldOpportunitiesMap == null) || (oldOpportunitiesMap != null && oldOpportunitiesMap.get(oppRec.Id).ForecastCategoryName != oppRec.ForecastCategoryName);
            if(oldOpportunitiesMap == null){
                mapForecastCategory(customForecastChanged, standardForecastChanged, oppRec);
            }else{
                if(customForecastChanged || standardForecastChanged){
                    if(oppRec.OwnerId == UserInfo.getUserID()){
                        mapForecastCategory(customForecastChanged, standardForecastChanged, oppRec);
                    }else if(oldOpportunitiesMap.get(oppRec.Id).StageName != oppRec.StageName){
                        mapForecastCategory(false, true, oppRec);
                    }else if(!FeatureManagement.checkPermission('Validation_Bypass_User_Integration')){
                        oppRec.addError('Opportunity Owner can modify custom Forecast Category field for any record type and Director of Sales can modify this field for New Business Opportunity.');
                    }
                }
            }
        }
    }

    /************************************************************************************************************************************
        Author              : Milanjeet Singh
        Description         : This method is a helper method to map forecast category depending on custom forecast and standard forecast field
        Created Date        : 18 Oct 2018
        Issue No.           : ST-2750
    **************************************************************************************************************************************/
    @TestVisible
    private void mapForecastCategory(boolean customForecastChanged, boolean standardForecastChanged, Opportunity opportunityRec){
        if((customForecastChanged && standardForecastChanged) || customForecastChanged){
            opportunityRec.ForecastCategoryName = opportunityRec.Forecast_Category__c;
        }else if(standardForecastChanged){
            opportunityRec.Forecast_Category__c = opportunityRec.ForecastCategoryName;
        }
    }

    /************************************************************************************************************************************
        Author              :   Praveen Kumar Emmadi
        Description         :   This method used to Opportunity Owner Assigned Date.
        Created Date        :   30 Aug 2019
        Issue No            :   ST-4724
        Modified By         :   Praveen Kumar Emmadi
        Last Modified Date  :   30 Aug 2019
        Issue No            :   ST-4724
    **************************************************************************************************************************************/
    @TestVisible
    private void updateOwnerAssDate(){
        for (Opportunity opp : newOpportunities) {
            if (oldOpportunitiesMap == null
                    || hasFieldChanged(oldOpportunitiesMap.get(opp.Id), opp, 'OwnerId')
                    || hasFieldChanged(oldOpportunitiesMap.get(opp.Id), opp, 'StageName')){
                opp.Owner_Assigned_Date__c = System.today();
            }
        }
    }

    private Boolean hasFieldChanged(SObject oldRecord, SObject newRecord, String fieldName){
        return oldRecord.get(fieldName) != newRecord.get(fieldName);
    }
    /************************************************************************************************************************************
        Author              :   Mayuresh Ghodke
        Description         :   This is a wrapper class used in task ray setting wrapper to store opportunity
                                team memeber field values.
        Created Date        :   23 February 2016
    **************************************************************************************************************************************/
    global class OpportunityTeamMemberSet {
        public Set<Id> setUserId;
        public String AssignedTo;
    }

    /************************************************************************************************************************************
        Author              :   Mayuresh Ghodke
        Description         :   This is a wrapper class used in create task ray project method to
                                make list of set of opportunity team memebers.
        Created Date        :   23 February 2016
    **************************************************************************************************************************************/
    global class TaskRaySetting {
        public List<OpportunityTeamMemberSet> OpportunityTeamMemberSet;
    }

    global class SendPaperWorkSetting {
        global List<OpportunityCreationSetting> OpportunityCreationSetting;
        global List<String> ExcludedProfiles;
        global List<String> ExcludedProductTypes;
        global List<String> AllowedEnterpriseProfiles;
        global String URL;
    }

    global class OpportunityCreationSetting {
        global String RecordType;
        global String CompanySize;
    }

}