/************************************************************************************************************************************
    Author         : Krishana Tupe
    Description    : This class will contains the logic of Opportunity Workflows/Process Builder that will updates a fields.
                     This trigger will called in Before/After Insert and Update context
     
    History:
----------------------------------------------------------------------------------------------------------------------------------
    VERSION           DATE                    AUTHOR                    DETAIL                              ISSUE
    1                 Feb 17 2020             Krishana Tupe             Initial Developement              ST-5715
    2                 2 September 2020        Maciej Miłosz             Trigger Redesign
**************************************************************************************************************************************/
//TODO: refactor class
public class TrOpportunityFlowToTriggers extends SObjectTriggerHandler {

    /*
    *   Trigger context variables
    *   note: create only the ones required by business logic
    */
    @testVisible
    private List<Opportunity> newOpportunities;
    @testVisible
    private Map<Id, Opportunity> oldOpportunitiesMap;
    @TestVisible
    private AccountSelector accountSelector = new AccountSelector();

    private Boolean isUpdate = false; 
    private Set<Id> bypassedSysAdminProfiles = new Set<Id>();   
    private static Map<Id, Account> accountsMap = new Map<Id, Account>();
    private Map<Id, Account> accountsToUpdate;
    private Map<Id, Opportunity> mapOldOpportunitys;
    private Boolean isTestContext = false; 
    private Set<Id> oppChangedReferrerIds = new Set<Id>();
    private Set<Id> accountIds = new Set<Id>();
    private List<SObject> recordsToUpdate;
    private Map<Id, Opportunity> opportunitiesWithToursMap;
    private Set<Id> closeLostOpportunityIds = new Set<Id>(); 
    private Set<Id> stageChangedOppIdsForUpdateRelateCase = new Set<Id>();

    private final Set<String> OPPORTUNITY_MANUAL_FLOW_CREATION_SOURCES = new Set<String> {'From Add Opportunity', 'From Create Opportunity'};
    private final Set<String> OPPORTUNITY_AUTOMATIC_FLOW_CREATION_SOURCES_TO_EXCLUDE = new Set<String> {'VTS'};

    /*
    *   Constructors
    *   note: constructors should have only required trigger context variables
    */
    public TrOpportunityFlowToTriggers(){
        this((List<Opportunity>) Trigger.new,
             (Map<Id, Opportunity>)Trigger.oldMap);
    }
    @testVisible
    private TrOpportunityFlowToTriggers(List<Opportunity> newOpportunities,
                                      Map<Id, Opportunity> oldOpportunitiesMap){
        this.newOpportunities = newOpportunities;
        this.oldOpportunitiesMap = oldOpportunitiesMap;
        isTestContext = Test.isRunningTest();
        recordsToUpdate = new List<SObject>();
    }

    public override void beforeInsert(){
        isUpdate = false;
        callOpprtunityBeforeTriggersLogic();
    }

    public override void beforeUpdate(){
        isUpdate = true;
        callOpprtunityBeforeTriggersLogic();
    }

    public override void afterInsert(){
        isUpdate = false;
        callOpprtunityAfterTriggersLogic();
        List<SObject> sobjectsToUpdate = recordsToUpdate;
        if(sobjectsToUpdate.isEmpty()){
            return;
        }
        MetadataDrivenTriggerHandler.clearLoopCount('TrOpportunityFlowToTriggers');
        recordsToUpdate = new List<SObject>();
        Database.update(sobjectsToUpdate) ;
    }
    
    public override void afterUpdate(){
        isUpdate = true;
        callOpprtunityAfterTriggersLogic();
        List<SObject> sobjectsToUpdate = recordsToUpdate;
        if(sobjectsToUpdate.isEmpty()){
            return;
        }
        MetadataDrivenTriggerHandler.clearLoopCount('TrOpportunityFlowToTriggers');
        recordsToUpdate = new List<SObject>();
        Database.update(sobjectsToUpdate) ;
    }
    
    private Map<Id,Account> getOppAccounts() {
        if (!accountIds.isEmpty()) {
            return new Map<Id,Account>(accountSelector.getSalesAccountsById(accountIds));    
        }
        return new Map<Id,Account>();
    }
    
/************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method will called in before insert and before update trigger context.
        Created Date        :   Feb 17 2020             
**************************************************************************************************************************************/    
    private void callOpprtunityBeforeTriggersLogic() { 
        if(isUpdate){
            Map<String, Id> mapByPassedSysAdminProfiles = (Map<String, Id>)JSON.deserialize(Label.ByPassSystemAdminProfiles.trim(), Map<String, Id>.class);
            if(mapByPassedSysAdminProfiles != null && !mapByPassedSysAdminProfiles.isEmpty()){
                bypassedSysAdminProfiles = new Set<Id>(mapByPassedSysAdminProfiles.values());   
            }
        }
        Set<Id> setOldOppIds = new Set<Id>();        
        for(Opportunity objNewOpp : newOpportunities) {
            if(String.isNotBlank(objNewOpp.AccountId)){
                accountIds.add(objNewOpp.AccountId);  
            }   
        }
        mapOldOpportunitys = new Map<Id, Opportunity>();
        if(!setOldOppIds.isEmpty()){
            mapOldOpportunitys = new Map<Id, Opportunity>([SELECT Id, Building__c FROM Opportunity WHERE Id IN : setOldOppIds]);   
        }          
        if(!accountIds.isEmpty() && accountsMap.isEmpty()){              
            accountsMap = getOppAccounts();
        } 
        //-V- TODO: is it needed?
        Set<Id> setOppIdsToUpdateReferral = new Set<Id>(); 
        List<Opportunity> lstNewOpportunities = new List<Opportunity>();
        for (Opportunity objOpportunity : newOpportunities) {
            Opportunity objOldOpp = isUpdate ? oldOpportunitiesMap.get(objOpportunity.Id) : null;
            if(isUpdate){
                if(isTestContext || Settings.getFlowToTriggersSettings('updateOpportunityUpdatedFromClosedWon__UPDATE', 'Opportunity')){
                    updateOpportunityUpdatedFromClosedWon(objOpportunity, objOldOpp);
                }
                if(isTestContext || Settings.getFlowToTriggersSettings('updateOpportunityCloseDateOnClosedLost__UPDATE', 'Opportunity')){
                    updateOpportunityCloseDateOnClosedLost(objOpportunity, objOldOpp);
                }
                if(isTestContext || Settings.getFlowToTriggersSettings('updateOpportunityUpdatedCloseDate__UPDATE', 'Opportunity')){
                    updateOpportunityUpdatedCloseDate(objOpportunity, objOldOpp);
                }

                if(isTestContext || Settings.getFlowToTriggersSettings('updateOpportunityBuildingEmail__UPDATE', 'Opportunity')){
                    updateOpportunityBuildingEmail(objOpportunity, objOldOpp); 
                }
                if(isTestContext || Settings.getFlowToTriggersSettings('updatePrimaryMemeberOnOpportunity__UPDATE', 'Opportunity')){
                    updatePrimaryMemeberOnOpportunity(objOpportunity, objOldOpp); 
                }
                if(isTestContext || Settings.getFlowToTriggersSettings('updateOpportunityReferralsFlow__UPDATE', 'Opportunity')){
                    updateOpportunityReferralsFlow(objOpportunity, objOldOpp, setOppIdsToUpdateReferral, lstNewOpportunities);
                }
            }else{
                if(isTestContext || Settings.getFlowToTriggersSettings('updateOpportunityUpdatedFromClosedWon__INSERT', 'Opportunity')){
                    updateOpportunityUpdatedFromClosedWon(objOpportunity, objOldOpp);
                }
                if(isTestContext || Settings.getFlowToTriggersSettings('updateOpportunityCloseDateOnClosedLost__INSERT', 'Opportunity')){
                    updateOpportunityCloseDateOnClosedLost(objOpportunity, objOldOpp);
                }
                if(isTestContext || Settings.getFlowToTriggersSettings('updateOpportunityUpdatedCloseDate__INSERT', 'Opportunity')){
                    updateOpportunityUpdatedCloseDate(objOpportunity, objOldOpp);
                }
                if(isTestContext || Settings.getFlowToTriggersSettings('updateOpportunityBuildingEmail__INSERT', 'Opportunity')){
                    updateOpportunityBuildingEmail(objOpportunity, objOldOpp); 
                }
                if(isTestContext || Settings.getFlowToTriggersSettings('updatePrimaryMemeberOnOpportunity__INSERT', 'Opportunity')){
                    updatePrimaryMemeberOnOpportunity(objOpportunity, objOldOpp); 
                }
                if(isTestContext || Settings.getFlowToTriggersSettings('updateOpportunityReferralsFlow__INSERT', 'Opportunity')){
                    updateOpportunityReferralsFlow(objOpportunity, objOldOpp, setOppIdsToUpdateReferral, lstNewOpportunities);
                }
                if(isTestContext || Settings.getFlowToTriggersSettings('updateOpportunityCloseDate__INSERT', 'Opportunity')){
                    updateOpportunityCloseDate(objOpportunity);
                }
            }
        }

        if(lstNewOpportunities.isEmpty()){
            return;
        }
        Map<Id, Contact> mapReferrers = new Map<Id, Contact>();
        if(!oppChangedReferrerIds.isEmpty()){
            mapReferrers = getOpportunityReferrers(oppChangedReferrerIds);                
        } 
        updateReferrerContactOnOpportunity(lstNewOpportunities, mapReferrers);
    }
    
/************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method will called in After insert and After update trigger context.
        Created Date        :   Feb 17 2020             
**************************************************************************************************************************************/    
    private void callOpprtunityAfterTriggersLogic() {
        if(accountIds.isEmpty()){
            //for get opportunity accountId
            for(Opportunity objNewOpp : newOpportunities) {
                if(String.isNotBlank(objNewOpp.AccountId)){
                    accountIds.add(objNewOpp.AccountId);                
                }            
            } 
        }
        opportunitiesWithToursMap = new Map<Id, Opportunity>([SELECT Id FROM Opportunity WHERE Id IN : newOpportunities]);
        Set<Id> setOppIdsToUpdateReferral = new Set<Id>(); 
        List<Opportunity> lstNewOpportunities = new List<Opportunity>();
        Map<Id, Set<Id>> mapOppAccountId;   
        Set<Id> setOppIdsToUpdateRelateCase = new Set<Id>();
        if(accountIds.isEmpty()){
            return;
        }
        if(accountsMap.isEmpty()){
            accountsMap = getOppAccounts(); 
        }
        if(accountsMap.isEmpty()){
            return;
        }
        accountsToUpdate = new Map<Id, Account>();
        mapOppAccountId = new Map<Id, Set<Id>>();
        for(Opportunity objNewOpp : (List<Opportunity>)newOpportunities) {
            Opportunity objOldOpp = isUpdate ? (Opportunity)oldOpportunitiesMap.get(objNewOpp.Id) : null;
            Account objOppAccount = accountsMap.get(objNewOpp.AccountId);
            if(isUpdate){
                if(isTestContext || Settings.getFlowToTriggersSettings('updateAccountDateofFirstBusiness__UPDATE', 'Opportunity')){
                    updateAccountDateofFirstBusiness(objNewOpp, objOldOpp, objOppAccount);
                }
                if(isTestContext || Settings.getFlowToTriggersSettings('updateOpportunityCasesAsClosed__UPDATE', 'Opportunity')){
                    updateOpportunityCasesAsClosed(objNewOpp, objOldOpp);
                }
                if(isTestContext || Settings.getFlowToTriggersSettings('updateAccountLeadSource__UPDATE', 'Opportunity')){
                    updateAccountLeadSource(objNewOpp, objOppAccount);
                }
                if(isTestContext || Settings.getFlowToTriggersSettings('updateOpportunityReferralsFlow__UPDATE', 'Opportunity')){
                    updateOpportunityReferralsFlow(objNewOpp, objOldOpp, setOppIdsToUpdateReferral, lstNewOpportunities); 
                }
            } else {
                if(isTestContext || Settings.getFlowToTriggersSettings('updateAccountLeadSource__INSERT', 'Opportunity')){
                    updateAccountLeadSource(objNewOpp, objOppAccount);
                }
                if(isTestContext || Settings.getFlowToTriggersSettings('updateOpportunityFlowForPartnersOwners__INSERT', 'Opportunity')){

                }
                if(isTestContext ||Settings.getFlowToTriggersSettings('updateOpportunityReferralsFlow__INSERT', 'Opportunity') ){
                    updateOpportunityReferralsFlow(objNewOpp, objOldOpp, setOppIdsToUpdateReferral, lstNewOpportunities); 
                }
            }
        } 
        setOppIdsToUpdateRelateCase.addAll(closeLostOpportunityIds);
        setOppIdsToUpdateRelateCase.addAll(stageChangedOppIdsForUpdateRelateCase);  
        setOppIdsToUpdateRelateCase.remove(null);
        recordsToUpdate.addAll(accountsToUpdate.values());
        updateOpportunityRelatedREACasesToClosedLost(setOppIdsToUpdateRelateCase);
        updateOpportunityRelatedReferrals(setOppIdsToUpdateReferral);
    } 
    
 /************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method is used to update Opportunity Updated_from_Closed_Won__c as TRUE when StageName changed to 'Closed Won'.
        Created Date          :   Feb 18 2020             
**************************************************************************************************************************************/    
    private void updateOpportunityUpdatedFromClosedWon(Opportunity objNewOpp, Opportunity objOldOpp){
        if(!objNewOpp.Updated_from_Closed_Won__c && isUpdate 
        && TriggerUtility.isFieldValueChanged(objNewOpp, objOldOpp, 'StageName')
        && objOldOpp.StageName == GlobalConstants.OPP_CLOSED_WON_STAGE_NAME){ 
            objNewOpp.Updated_from_Closed_Won__c = TRUE;
        }        
    }    
    
    //only Insert context
/************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method is used to update Opportunity CloseDate for insert context only.
                                CloseDate = Today() + 1 month when StageName different than 'Closed Won' and Opportunity created from Automated flow.
                                For inserted 'Closed Won' Opportunities CloseDate = today()
                                VTS automatic flow is excluded from closeDate update
        Created Date        :   Feb 18 2020             
        Updated date        :   Jan 19 2021 Mikolaj Juras
        Updated date        :   Mar 2  2021 Mikolaj Juras
**************************************************************************************************************************************/    
        @TestVisible
        private void updateOpportunityCloseDate(Opportunity objNewOpp){

        if (isUpdate) {
            return;
        }
        
        if (objNewOpp.StageName == GlobalConstants.OPP_CLOSED_WON_STAGE_NAME) {
            objNewOpp.CloseDate = System.today();
        } else if (!OPPORTUNITY_MANUAL_FLOW_CREATION_SOURCES.contains(objNewOpp.Opportunity_Creation_Source__c) 
                    && !OPPORTUNITY_AUTOMATIC_FLOW_CREATION_SOURCES_TO_EXCLUDE.contains(objNewOpp.Opportunity_Creation_Source__c)) {
            objNewOpp.CloseDate = System.today().addMonths(1);

        } 
    }
    
 /************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method is used to update Opportunity CloseDate as Today when StageName changed to 'Closed Lost'.
        Created Date          :   Feb 18 2020             
**************************************************************************************************************************************/    
    private void updateOpportunityCloseDateOnClosedLost(Opportunity objNewOpp, Opportunity objOldOpp){
        if(objNewOpp.StageName == GlobalConstants.OPP_CLOSED_LOST_STAGE_NAME 
        && (!isUpdate || TriggerUtility.isFieldValueChanged(objNewOpp, objOldOpp, 'StageName'))){
            objNewOpp.CloseDate = System.today();
        } 
    }
    
/************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method is used to update Opportunity CloseDate as Today when Stagename gets changed to 'Closed Won' and logged in user should not be System Admin.
        Created Date          :   Feb 18 2020             
**************************************************************************************************************************************/    
    private void updateOpportunityUpdatedCloseDate(Opportunity objNewOpp, Opportunity objOldOpp){
        if(isUpdate && objNewOpp.CloseDate != System.today() 
            && objNewOpp.StageName == GlobalConstants.OPP_CLOSED_WON_STAGE_NAME
            && TriggerUtility.isFieldValueChanged(objNewOpp, objOldOpp, 'StageName')
            && objOldOpp.StageName != GlobalConstants.OPP_CLOSED_WON_STAGE_NAME 
            && !bypassedSysAdminProfiles.contains(UserInfo.getProfileId())) {
            objNewOpp.CloseDate = System.today();
        }        
    } 
    
/************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method is used to update Opportunity Building_Email1__c as Opportunity Building Email when Building__c gets changed.
        Created Date          :   Feb 18 2020             
**************************************************************************************************************************************/    

    private void updateOpportunityBuildingEmail(Opportunity objNewOpp, Opportunity objOldOpp){
        if(String.isNotBlank(objNewOpp.Building__c) && (!isUpdate || (isUpdate && objNewOpp.Building__c != objOldOpp.Building__c))){
            Building__c objBuilding = BuildingUtility.getBuildingById(objNewOpp.Building__c);
            if(objBuilding != null){
                //remove Building_Email1__c as field is marked not to migrate
                objNewOpp.Building_Name__c = objBuilding.Name;
            }          
        } 
    }  
/************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method is used to update Account Date_of_First_Business__c as Opportunity CloseDate when Date_of_First_Business__c = null and Account_Type__c is ORG.
        Created Date          :   Feb 18 2020             
**************************************************************************************************************************************/    
    private void updateAccountDateofFirstBusiness(Opportunity objNewOpp, Opportunity objOldOpp, Account objOppAccount){
        if (String.isNotBlank(objNewOpp.AccountId) 
            && objNewOpp.StageName == GlobalConstants.OPP_CLOSED_WON_STAGE_NAME 
            && objNewOpp.StageName != objOldOpp.StageName) {
            if(objOppAccount != null &&  objOppAccount.Date_of_First_Business__c == null && objOppAccount.Account_Type__c == 'Org'){
                setAccountRecordToUpdate(objOppAccount.Id, 'Date_of_First_Business__c',  objNewOpp.CloseDate);               
            }  
        }
    }
    
    
    //only Insert context
/************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method is used to update Account Lead_Source__c as Opportunity LeadSource when Account Lead_Source__c = null.
        Created Date          :   Feb 18 2020             
**************************************************************************************************************************************/    
    private void updateAccountLeadSource(Opportunity objNewOpp, Account objOppAccount){
        if(objOppAccount != null &&  String.isBlank(objOppAccount.Lead_Source__c) && String.isNotBlank(objNewOpp.LeadSource)){
            setAccountRecordToUpdate(objOppAccount.Id, 'Lead_Source__c', objNewOpp.LeadSource);           
        }
    }
    
    private void setAccountRecordToUpdate(Id accountId, String strAccFieldName, object strOppFieldValue){
        Account objTemp;
        if(accountsToUpdate != null && accountsToUpdate.get(accountId) != null){
            objTemp = accountsToUpdate.get(accountId);                      
        }else{
            objTemp = new Account(Id = accountId);  
        }        
        objTemp.put(strAccFieldName, strOppFieldValue);       
        accountsToUpdate.put(accountId, objTemp);
    }
 
/************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method is used to update Opportunity Primary_Member__c as Opportunity AccountId.Primary_Member__c when AccountId gets changed.
        Created Date          :   Feb 19 2020         
**************************************************************************************************************************************/    
    //Process Builder : Map Opportunity Primary Member.   
    private void updatePrimaryMemeberOnOpportunity(Opportunity objNewOpp, Opportunity objOldOpp){
        if( objNewOpp.AccountId != null && String.isBlank(objNewOpp.Primary_Member__c) && accountsMap.get(objNewOpp.AccountId) != null && accountsMap.get(objNewOpp.AccountId).Primary_Member__c != null){
            objNewOpp.Primary_Member__c = accountsMap.get(objNewOpp.AccountId).Primary_Member__c;
        }  
    }
 
/************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method is used to update Opportunity related Opportunity_Cases__r when StageName and Old_Opportunity__c gets changed.
        Created Date          :   Feb 19 2020             
**************************************************************************************************************************************/    
    //Process Builder : Opportunity - REA: Close Cases when Opp Closes.
    private void updateOpportunityCasesAsClosed(Opportunity objNewOpp, Opportunity objOldOpp){
        if(isUpdate){
            if(objNewOpp.StageName != objOldOpp.StageName){
                stageChangedOppIdsForUpdateRelateCase.add(objNewOpp.Id); 
                if (objNewOpp.StageName == GlobalConstants.OPP_CLOSED_LOST_STAGE_NAME) {
                    //add Opportunity Id to update related Opportunity_Cases__r
                    closeLostOpportunityIds.add(objNewOpp.Id);            
                } 
            }
        }              
    } 
    
/************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method is used to update Opportunity related Opportunity Referrals__r when StageName changed to 'Closed Won' and Total_Tours__c gets changed to Total_Tours__c > 0.
                                also updated Referrer_Contact_Type__c on opportunity when opportunity Referrer__c gets changed.
        Created Date          :   Feb 19 2020         
**************************************************************************************************************************************/    
    //Process Builder : Opportunity Referrals Flow.   
    private void updateOpportunityReferralsFlow(Opportunity objNewOpp, Opportunity objOldOpp, Set<Id> setOppIdsToUpdateReferral, List<Opportunity> lstNewOpportunities){
        if((this.context == TriggerContext.AFTER_INSERT || this.context == TriggerContext.AFTER_UPDATE)
           && objNewOpp.Total_Tours__c != null 
           && (isUpdate && ((objNewOpp.StageName == GlobalConstants.OPP_CLOSED_WON_STAGE_NAME 
                             && objNewOpp.StageName != objOldOpp.StageName) 
                            || ( opportunitiesWithToursMap.get(objNewOpp.Id) != null )))){
                                //add Opportunity Id to update related Opportunity Referrals__r
                                setOppIdsToUpdateReferral.add(objNewOpp.Id);
                            }         
           if((this.context == TriggerContext.BEFORE_INSERT || this.context == TriggerContext.BEFORE_UPDATE) 
              && (String.isNotBlank(objNewOpp.Referrer__c) || String.isBlank(objNewOpp.Referrer__c)) 
              && (!isUpdate || (isUpdate && objNewOpp.Referrer__c != objOldOpp.Referrer__c))){
                  lstNewOpportunities.add(objNewOpp);
                  if(objNewOpp.Referrer__c != null){
                      oppChangedReferrerIds.add(objNewOpp.Referrer__c);
                  }
              }
           } 
  
/************************************************************************************************************************************
        Author              :   Krishana Tupe
        Description         :   This method is used to add VC Partner relationship portal owner as a Opportunity team member with 'Opp: Partner BDM' role and Edit access.                                
        Created Date          :   Feb 19 2020             
**************************************************************************************************************************************/    
    //Process Builder : Opportunity flow for Partners owners.   
    private void updateOpportunityFlowForPartnersOwners(Opportunity objNewOpp, Account objOppAccount, Map<Id, Set<Id>> mapOppAccountId){
        if(!isUpdate && objNewOpp.AccountId != null && objOppAccount != null){            
            if(!mapOppAccountId.containsKey(objNewOpp.AccountId)){
                mapOppAccountId.put(objNewOpp.AccountId, new Set<Id>{});
            }
            mapOppAccountId.get(objNewOpp.AccountId).add(objNewOpp.Id);
        }        
    }
    
    //Written for Opportunity - REA: Close Cases when Opp Closes flow.
    private void updateOpportunityRelatedREACasesToClosedLost(Set<Id> setOppIdsToUpdateRelateCases){
        if(setOppIdsToUpdateRelateCases == null || setOppIdsToUpdateRelateCases.isEmpty()){
            return;
        }
        List<Case> lstCases = [SELECT Id, Status, Opportunity__c, Opportunity__r.StageName FROM Case WHERE Opportunity__c IN : setOppIdsToUpdateRelateCases];
        if(lstCases.isEmpty()){
            return;
        }
        for(Case objCase : lstCases){
            if(closeLostOpportunityIds.contains(objCase.Opportunity__c) && objCase.Status <> GlobalConstants.OPP_CLOSED_LOST_STAGE_NAME){
                objCase.Status = GlobalConstants.OPP_CLOSED_LOST_STAGE_NAME;  
            }
            if(stageChangedOppIdsForUpdateRelateCase.contains(objCase.Opportunity__c)){
                objCase.Opportunity_Stage_Field_Update__c = objCase.Opportunity__r.StageName;
            }                   
        }
        recordsToUpdate.addAll(lstCases);               
    }
    
    //Written for Opportunity Referrals Flow
    private void updateOpportunityRelatedReferrals(Set<Id> setOppIdsToUpdateReferral){
        if(setOppIdsToUpdateReferral.isEmpty()){   
            return;
        }
        Set<String> setReferralPortalEvents = new Set<String>{'Paperwork signed', 'Referral Expired', 'Opportunity Closed Lost'};
        List<Referral__c> lstReferrals = [SELECT Id, Referral_Portal_Event__c, Opportunity__r.StageName FROM Referral__c WHERE Opportunity__c IN : setOppIdsToUpdateReferral AND Referral_Portal_Event__c NOT IN :setReferralPortalEvents];
        if(!lstReferrals.isEmpty()){
            for(Referral__c objReferral : lstReferrals){
                objReferral.Referral_Portal_Event__c = objReferral.Opportunity__r.StageName == GlobalConstants.OPP_CLOSED_WON_STAGE_NAME ? 'Paperwork signed' : 'Tour Completed';
            }
            recordsToUpdate.addAll(lstReferrals);
        }
    }
    
    //Written for Opportunity Referrals Flow
    private Map<Id, Contact> getOpportunityReferrers(Set<Id> setOppReferrerIds){
        if(!setOppReferrerIds.isEmpty()){ 
            return new Map<Id, Contact>([SELECT Id, Type__c FROM Contact WHERE Id IN : setOppReferrerIds AND Type__c <> null]);
        } 
        return new Map<Id, Contact>();
    }
    
    //Written for Opportunity Referrals Flow
    private void updateReferrerContactOnOpportunity(List<Opportunity> lstNewOpportunities, Map<Id, Contact> mapOppReferrers){        
        for(Opportunity objNewOpp : lstNewOpportunities){
            if(objNewOpp.Referrer__c != null){                   
                objNewOpp.Referrer_Contact_Type__c = (mapOppReferrers != null && mapOppReferrers.get(objNewOpp.Referrer__c) != null) ? mapOppReferrers.get(objNewOpp.Referrer__c).Type__c : null;
            }else{
                objNewOpp.Referrer_Contact_Type__c = null;
            }                
        }
    }     
}