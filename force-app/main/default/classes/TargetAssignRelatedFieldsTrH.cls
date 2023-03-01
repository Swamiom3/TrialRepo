/************************************************************************************************************************************
Author      :    Krishna Somwanshi
Description :    This trigger has logic to auto popualate fields on target records.
History:
----------------------------------------------------------------------------------------------------------------------------------
VERSION    DATE            AUTHOR               Issue No      DETAIL
1          23 Sept 2021    Krishna Somwanshi    ST-9152       Refactor
**************************************************************************************************************************************/
public with sharing class TargetAssignRelatedFieldsTrH extends SObjectTriggerHandler {
    private List<Targets__c> newTargets;
    private Map<Id, Targets__c> oldTargetsMap;
    private Map<Id, String> targetRecordTypesWithName = UtilRecordType.GetSobjectActiveRecordTypesByLabelNotLowerById('Targets__c');
    private static Map<String, String> targetsMetadata = getTargetMetadata();
    private Map<String, List<String>> criteriaToRecordTypeMaps = getValidRecordType();
    PeriodSelector periodSelector = new PeriodSelector();
    @TestVisible
    private AccountSelector accountSelector = new AccountSelector();
    
    public TargetAssignRelatedFieldsTrH() {
        this(
            (List<Targets__c>) Trigger.new,
            (Map<Id, Targets__c>) Trigger.oldMap
        );
    }
    
    private TargetAssignRelatedFieldsTrH(List<Targets__c> newTargets, Map<Id, Targets__c> oldTargetsMap) {
        this.newTargets = newTargets;
        this.oldTargetsMap = oldTargetsMap;
    }
    
    public override void beforeInsert() {
        assignRelatedFields();
    }

    public override void beforeUpdate() {
        assignRelatedFields();
    }
    
    private void assignRelatedFields() {
        if(targetsMetadata.isEmpty() || criteriaToRecordTypeMaps.isEmpty()) {
            return;
        }
        setGlobalSalesForecast(newTargets, oldTargetsMap);
        setBuildingGoals(newTargets, oldTargetsMap);
        setAccountGoals(newTargets, oldTargetsMap);
        setRepGoals(newTargets, oldTargetsMap);
    }

    void setRepGoals(List<Targets__c> newTargets, Map<Id, Targets__c> oldTargetsMap) {
        Set<Date> startDates = new Set<Date>();
        Set<Date> endDates = new Set<Date>();
        Set<String> periodTypes = new Set<String>();
        Set<Id> userIds = new Set<Id>();
        Set<Targets__c> targetForUsers = new Set<Targets__c>();
        Set<Targets__c> targetForPeriods = new Set<Targets__c>();
        Boolean isUpdate = oldTargetsMap != null;
        for(Targets__c target : newTargets) {
            Targets__c oldTarget = oldTargetsMap?.get(target.Id);
            if(checkValidToUpdate('valid_rectype_for_user_update', target)
               && ((!isUpdate && String.isNotBlank(target.User__c))
               || (isUpdate && TriggerUtility.isFieldValueChanged(target, oldTarget, 'User__c')))) {
               if(isUpdate && String.isBlank(target.User__c)) {
                   emptyUserFields(target);
                }else {
                    userIds.add(target.User__c);
                    targetForUsers.add(target);
                }
            }
            if(!isUpdate|| (isUpdate && TriggerUtility.isFieldValueChanged(target, oldTarget, 'Target_Period_Type__c')
               ||TriggerUtility.isFieldValueChanged(target, oldTarget, 'Target_Period_Date__c')
               ||TriggerUtility.isFieldValueChanged(target, oldTarget, 'Period__c'))) {
                Map<String, Date> startAndEndDateMaps = getStartAndEndDate(target);
                if(startAndEndDateMaps.get('startDate') != null) {
                    startDates.add(startAndEndDateMaps.get('startDate'));
                    endDates.add(startAndEndDateMaps.get('endDate'));
                    periodTypes.add(target.Target_Period_Type__c);
                    targetForPeriods.add(target);
                } else {
                    target.Period__c = null;
                }
            }
        }
        if(!targetForPeriods.isEmpty()) {
            populatePeriodLookup(targetForPeriods, startDates, periodTypes, endDates);
        }
        if(!userIds.isEmpty()) {
            populateUserFields(userIds, targetForUsers);
        }
    }
    
    void setAccountGoals (List<Targets__c> newTargets, Map<Id, Targets__c> oldTargetsMap) {
        Set<Id> accountIds = new Set<Id>();
        Set<Targets__c> targetForAccounts = new Set<Targets__c>();
        Boolean isUpdate = oldTargetsMap != null;
        for(Targets__c target : newTargets) {
            Targets__c oldTarget = oldTargetsMap?.get(target.Id);
            if(checkValidToUpdate('valid_rectype_for_account_update', target)
               &&((!isUpdate && String.isNotBlank(target.Account__c))
               ||(isUpdate && TriggerUtility.isFieldValueChanged(target, oldTarget, 'Account__c')))) {
                if(isUpdate && String.isBlank(target.Account__c)) {
                    target.Account_Owner__c = null;
                }else {
                    accountIds.add(target.Account__c);
                    targetForAccounts.add(target);
                }
            }
        }
        if(!accountIds.isEmpty()) {
            populateAccountOwner(accountIds, targetForAccounts);
        }
    }

    void setBuildingGoals(List<Targets__c> newTargets, Map<Id, Targets__c> oldTargetsMap) {
        Boolean isUpdate = oldTargetsMap != null;
        for(Targets__c target : newTargets) {
            Targets__c oldTarget = oldTargetsMap?.get(target.Id);
            if(checkValidToUpdate('valid_rectype_for_building_update', target)
               &&((!isUpdate && String.isNotBlank(target.Building__c))
               ||(isUpdate && TriggerUtility.isFieldValueChanged(target, oldTarget, 'Building__c')))) {
                if(isUpdate  && String.isBlank(target.Building__c)) {
                    emptyBuildingFields(target);
                }else {
                    populateBuildingFields(target);
                }
            }
        }
    }

    void setGlobalSalesForecast(List<Targets__c> newTargets, Map<Id, Targets__c> oldTargetsMap) {
        for(Targets__c target : newTargets) {
            Targets__c oldTarget = oldTargetsMap?.get(target.Id);
            Boolean isUpdate = oldTargetsMap != null;   
            Boolean invalidRecordTypeForUpdate = !checkValidToUpdate('valid_rectype_for_unitsacv_update', target);
            if(!invalidRecordTypeForUpdate) {
                return;
            }
            if((!isUpdate && target.Units__c != null && target.Units_High__c == null && target.Units_Low__c == null)
               ||(isUpdate && TriggerUtility.isFieldValueChanged(target, oldTarget, 'Units__c'))) {
                target.Units_High__c = target.Units__c;
                target.Units_Low__c = target.Units__c;
            } else if(((!isUpdate && ((target.Units_High__c != null) || (target.Units_Low__c != null)))
               ||(isUpdate && (TriggerUtility.isFieldValueChanged(target, oldTarget, 'Units_High__c')
               ||TriggerUtility.isFieldValueChanged(target, oldTarget, 'Units_Low__c'))))) {
                if(targetsMetadata?.get('units_update_error') != null) {
                    target.addError((String)targetsMetadata?.get('units_update_error'));
                    continue;
                }
            }
            if((!isUpdate && target.ACV__c != null && target.ACV_High__c == null && target.ACV_Low__c == null)
               ||(isUpdate && TriggerUtility.isFieldValueChanged(target, oldTarget, 'ACV__c'))) {
                target.ACV_High__c = target.ACV__c;
                target.ACV_Low__c = target.ACV__c;
            }else if(((!isUpdate && ((target.ACV_High__c != null) || (target.ACV_Low__c != null)))
               ||(isUpdate && (TriggerUtility.isFieldValueChanged(target, oldTarget, 'ACV_High__c')
               ||(target.ACV_Low__c != oldTarget?.ACV_Low__c))))) {
                if(targetsMetadata?.get('acv_update_error') != null) {
                    target.addError((String)targetsMetadata?.get('acv_update_error'));
                    continue;
                }
            }
        }
    }

    void populateUserFields(Set<Id> userIds, Set<Targets__c> targetForUsers) {
        Map<Id, User_Attribute__c> userAttributes = new Map<Id, User_Attribute__c>();
        for(User_Attribute__c userAttribute : [SELECT User__c, User__r.Name, Portfolio__c, Portfolio__r.Name, Region__c,
                                               Territory__c, Sales_Function__c, Manager__c, Manager__r.Name 
                                               FROM User_Attribute__c 
                                               WHERE User__c IN :userIds AND Is_Active__c = TRUE 
                                               AND RecordType.Name = 'User History']) {
            userAttributes.put(userAttribute.User__c, userAttribute);
        }
        for(Targets__c target : targetForUsers) {
            User_Attribute__c userAttribute = userAttributes.get(target.User__c);
            if(userAttribute != null) {
                target.Portfolio__c = userAttribute?.Portfolio__r?.Name;
                target.Region_derived__c = userAttribute?.Region__c;
                target.Territory__c = userAttribute?.Territory__c;
                target.Sales_Function__c = userAttribute?.Sales_Function__c;
                target.Manager__c = String.isNotBlank(userAttribute.Manager__c) ? userAttribute?.Manager__r?.Name : '';
            }else {
                if(targetsMetadata != null && targetsMetadata?.get('user_attri_not_present_error') != null) {
                    target.addError((String)targetsMetadata?.get('user_attri_not_present_error'));
                }
            }
        }
    }
    
    void populateAccountOwner(Set<Id> accountIds, Set<Targets__c> Targets) {
        Map<Id, Account> targetToAccounts = new Map<Id, Account>();
        targetToAccounts = new Map<Id, Account>(accountSelector.getAccountsById(new List<Id>(accountIds)));
        for (Targets__c target : Targets) {
            target.Account_Owner__c = targetToAccounts.get(target.Account__c).Owner.Name;
        }
    }
    
    void populateBuildingFields(Targets__c target) {
        if(BuildingUtility.idToBuilding.isEmpty()) {
            BuildingUtility.fetchBuildings(); 
        }
        if(BuildingUtility.idToBuilding?.get(target.Building__c) == null) {
            return;
       }    
        Building__c building = BuildingUtility.idToBuilding?.get(target.Building__c);
        target.Region_derived__c = building?.Region_Name__c;
        target.Territory__c = building?.Territory_Name__c;
        target.Sub_territory__c = building?.Sub_Territory__r?.Name;
        target.Portfolio__c = building?.Portfolio_Name__c;
        target.Cluster__c = building?.Cluster_Name__c;
        target.Small_Market_Manager__c = building?.Associate_Director_Market_Sales__r?.Name;
        target.Small_Market_Salesperson__c = building?.Senior_Associate_Market_Sales__r?.Name;
        target.Large_Portfolio_Director__c = building?.Director_Portfolio_Sales__r?.Name;
        target.Large_Portfolio_Salesperson__c = building?.Associate_Director_Portfolio_Sales__r?.Name;
    }
    void populatePeriodLookup(Set<Targets__c> setTargets,Set<Date> startDates, Set<String> periodTypes, Set<Date> endDates) {
        Map<String, Id> periodKeyAndIds = new Map<String, Id>();
        Map<Id, Period__c> targetToPeriods = new Map<Id, Period__c>();
        targetToPeriods = new Map<Id, Period__c>(periodSelector.getPeriodsByRecordTypeNameStartDateEndDate(startDates, periodTypes, endDates));
        for(Period__c period: targetToPeriods.values()) {
            String periodKey = String.valueOf(period.Start_Date__c) + String.valueOf(period.End_Date__c)
                             + period.RecordType.Name.toLowerCase();
            periodKeyAndIds.put(periodKey, period.Id);
        }
        for(Targets__c target: setTargets) {
            Map<String, Date> startAndEndDateMaps = getStartAndEndDate(target);
            String objTargetKey = String.valueOf(startAndEndDateMaps.get('startDate')) + 
            String.valueOf(startAndEndDateMaps.get('endDate')) + 
            target.Target_Period_Type__c.toLowerCase();
            target.Period__c = periodKeyAndIds.get(objTargetKey);
        }          
    }
    
    static Map<String, Date> getStartAndEndDate(Targets__c targetForStartDate) {
        Map<String, Date> startAndEndDateMaps = new Map<String, Date>();
        if(String.isBlank(targetForStartDate.Target_Period_Type__c) && targetForStartDate.Target_Period_Date__c == null) {
            return new Map<String, Date>();
        }
        Date targetDate = targetForStartDate.Target_Period_Date__c;
        Date startDate;
        Date endDate;
        switch on targetForStartDate.Target_Period_Type__c.toLowerCase() {
            when 'weekly' {
                Integer dayOfWeek = Math.mod(Date.newInstance(1900, 1, 7).daysBetween(targetDate),7);
                startDate = targetDate.addDays(-dayOfWeek);
                endDate = startDate.addDays(6);
            }
            when 'monthly' {
                startDate = targetDate.toStartOfMonth();
                endDate = Date.newInstance(startDate.year(), startDate.month(), date.daysInMonth(startDate.year(), startDate.month()));
            }
            when 'quarterly' {
                Integer quarterNumber = (Integer)Math.ceil(targetDate.month()/3.0);
                Integer quarterMonth = (1 + (quarterNumber - 1)*3);
                startDate = Date.newInstance(targetDate.year(),quarterMonth , 01);
                endDate = Date.newInstance(startDate.year(), startDate.month()+2, date.daysInMonth(startDate.year(), startDate.month()+2));
            }
            when 'annually' {
                startDate = Date.newInstance(targetDate.year(), 01, 01);
                endDate = Date.newInstance(startDate.year(), 12, 31);
            }
        }
        startAndEndDateMaps.put('startDate', startDate);
        startAndEndDateMaps.put('endDate', endDate);
        return startAndEndDateMaps;
    }
    
    boolean checkValidToUpdate(String featureName, Targets__c target) {
        return ((!(criteriaToRecordTypeMaps.get(featureName)).isEmpty())
                && ((criteriaToRecordTypeMaps.get(featureName)).contains(targetRecordTypesWithName.get(target.RecordTypeId).toLowerCase())));
    }
    
    public static void emptyUserFields(Targets__c target) {
        target.Portfolio__c = null;
        target.Region_derived__c = null;
        target.Territory__c = null;
        target.Sales_Function__c = null; 
        target.Manager__c = null; 
    }
    
    public static void emptyBuildingFields(Targets__c target) {
        target.Region_derived__c = null;
        target.Territory__c = null;
        target.Sub_territory__c = null;
        target.Portfolio__c = null;
        target.Cluster__c = null;
        target.Small_Market_Manager__c = null;
        target.Small_Market_Salesperson__c = null;
        target.Large_Portfolio_Director__c = null;
        target.Large_Portfolio_Salesperson__c = null;
    }
    
    public static Map<String, String> getTargetMetadata() {
        if(targetsMetadata == null || targetsMetadata.isEmpty()) {
            MetadataSetting__mdt targetMetadataSetting = Settings.getMetadataSetting('TargetsTriggerMetadata');
            if(targetMetadataSetting != null && String.isNotBlank(targetMetadataSetting.Data__c)){
                targetsMetadata = (Map<String, String>)JSON.deserialize(targetMetadataSetting.Data__c, Map<String, String>.class);
            }
        }
        return targetsMetadata;
    } 
    
    // As suggested by Maciej Milosz in PR #4130 we have hardcoded this in class(removed from metadata)
    private Map<String, List<String>> getValidRecordType() {
        Map<String, List<String>> criteriaToRecordTypeMaps = new Map<String, List<String>>();
        criteriaToRecordTypeMaps.put('valid_rectype_for_unitsacv_update', new List<String>{'global sales forecast'});
        criteriaToRecordTypeMaps.put('valid_rectype_for_building_update', new List<String>{'building goals'});
        criteriaToRecordTypeMaps.put('valid_rectype_for_user_update', new List<String>{'rep goals'});
        criteriaToRecordTypeMaps.put('valid_rectype_for_account_update', new List<String>{'account goals'});
        return criteriaToRecordTypeMaps;     
    }
}