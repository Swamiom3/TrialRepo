/************************************************************************************************************************************
Author      :   Salesforce
Description :   This class is used to manage the Work Types and related configuration for Salesforce Scheduler per building.
----------------------------------------------------------------------------------------------------------------------------------
VERSION     DATE                AUTHOR                DETAIL
1           01 Aug 2021         Salesforce            Initial Developement
**************************************************************************************************************************************/
public with sharing class BuildingWorkTypesController {
    
    @TestVisible
    private static final String CUTOFF_NEXT_DAY_TOUR = 'Cutoff Next Day Tour';
    
    @TestVisible
    private static final String BLOCK_SAME_DAY_TOUR = 'Block Same Day Tour';
    
    @TestVisible
    private static final String ALLOW_SAME_DAY_TOUR = 'Allow Same Day Tour';

    @TestVisible
    private static final String DURATION_TYPE = 'Minutes';

    @TestVisible
    private static final String CUTOFF = 'Cutoff';

    @TestVisible
    private static final String DUPLICATE_WORKTYPE_MESSAGE = 'The Work Type with this Tour Format is already exists. Please select another Tour Format and try again.';
    
    @TestVisible
    private static BuildingSelector buildSelector = new BuildingSelector();
    
    @AuraEnabled
    public static String getBuildingWorkTypes(String buildingId){        
        Map<String, Object> buildingWorkTypesData = new Map<String, Object>();
        buildingWorkTypesData.put('buildingData', buildSelector.getBuildingTourabilityById(buildingId));
        List<BuildingWorkTypeWrapper> buildingWorkTypes = new List<BuildingWorkTypeWrapper>();
        for(WorkType workTypeRec : [SELECT Id, Name, Building_Id__c, Building_Id__r.Name, Tour_Format__c, EstimatedDuration, BlockTimeBeforeAppointment, BlockTimeAfterAppointment, TimeframeStart, Block_Same_Day_Touring__c, Next_Day_Touring_Cutoff__c 
                                    FROM WorkType
                                    WHERE Parent_Id__c = null 
                                        AND Building_Id__c =:buildingId]){

            buildingWorkTypes.add(new BuildingWorkTypeWrapper(workTypeRec));
        }
        buildingWorkTypesData.put('workTypesData', buildingWorkTypes);        
        return JSON.serialize(buildingWorkTypesData);
    }

    @AuraEnabled
    public static DatabaseResult saveWorkType(String buildingWorkTypeRecordJSON){
        List<WorkType> workTypeRecords = new List<WorkType>();
        BuildingWorkTypeWrapper buildingWorkTypeRecord = (BuildingWorkTypeWrapper) JSON.deserialize(buildingWorkTypeRecordJSON, BuildingWorkTypeWrapper.class);
        
        if(checkIfDuplicateWorkTypeExists(buildingWorkTypeRecord)){
            return new DatabaseResult(false, null, DUPLICATE_WORKTYPE_MESSAGE);
        }
        
        WorkType workTypeRecord = createOrUpdateWorkType(buildingWorkTypeRecord);        
        workTypeRecords.add(workTypeRecord);

        if(String.isNotBlank(buildingWorkTypeRecord.nextDayTouringCutoff)){
            workTypeRecords.add(createChildWorkTypes(workTypeRecord, buildingWorkTypeRecord));
        }
        // Create Work Type and Work Group Member relationship records
        createWorkTypeGroupMember(workTypeRecords);
        
        // Create WorkType and ServiceTerritory relationship records
        createServiceTerritoryWorkTypes(workTypeRecords);

        return new DatabaseResult(workTypeRecord.Id);
    }

    private static Boolean checkIfDuplicateWorkTypeExists(BuildingWorkTypeWrapper buildingWorkTypeRecord){
        List<WorkType> existingWorkTypes = new List<WorkType>();
        if(String.isNotBlank(buildingWorkTypeRecord.uniqueId) && !buildingWorkTypeRecord.uniqueId.startsWith('New')){
            existingWorkTypes = [SELECT Id, Tour_Format__c
                                 FROM WorkType 
                                 WHERE Id =: buildingWorkTypeRecord.uniqueId];           
            return (!existingWorkTypes.isEmpty() && existingWorkTypes[0].Tour_Format__c != buildingWorkTypeRecord.tourFormat);
        } else {
            existingWorkTypes = [SELECT Id 
                                 FROM WorkType 
                                 WHERE Building_Id__c =: buildingWorkTypeRecord.buildingId 
                                     AND Tour_Format__c =: buildingWorkTypeRecord.tourFormat
                                     AND Parent_Id__c = null 
                                 LIMIT 1];
            return !existingWorkTypes.isEmpty();
        }
    }

    private static WorkType createOrUpdateWorkType (BuildingWorkTypeWrapper buildingWorkTypeRecord){
        WorkType workTypeRecord = new WorkType();
        List<OperatingHours> buildingOperatingHours = [SELECT Id 
                                                       FROM OperatingHours 
                                                       WHERE Building_Id__c =:buildingWorkTypeRecord.buildingId 
                                                           AND Host_Id__c = null
                                                       LIMIT 1];
        if(String.isNotBlank(buildingWorkTypeRecord.uniqueId) && !buildingWorkTypeRecord.uniqueId.startsWith('New')){
            workTypeRecord.Id = buildingWorkTypeRecord.uniqueId;
        }
        workTypeRecord.Block_Same_Day_Touring__c = buildingWorkTypeRecord.blockSameDayTouring;
        workTypeRecord.Next_Day_Touring_Cutoff__c = buildingWorkTypeRecord.nextDayTouringCutoff;
        workTypeRecord.Building_Id__c = buildingWorkTypeRecord.buildingId;
        workTypeRecord.Tour_Format__c = buildingWorkTypeRecord.tourFormat;
        workTypeRecord.EstimatedDuration = Decimal.valueOf(buildingWorkTypeRecord.estimatedDuration);
        workTypeRecord.DurationType = DURATION_TYPE;
        workTypeRecord.BlockTimeBeforeAppointment = Integer.valueOf(buildingWorkTypeRecord.blockTimeBeforeAppointment);
        workTypeRecord.BlockTimeAfterAppointment = Integer.valueOf(buildingWorkTypeRecord.blockTimeAfterAppointment);
        workTypeRecord.OperatingHoursId = ((buildingOperatingHours != null && !buildingOperatingHours.isEmpty())?buildingOperatingHours[0].Id:null);
        if(String.isNotBlank(buildingWorkTypeRecord.nextDayTouringCutoff)){
            workTypeRecord.Name = generateWorkTypeName(buildingWorkTypeRecord, CUTOFF_NEXT_DAY_TOUR);
            workTypeRecord.timeframeStart = 2;
        } else if(String.isBlank(buildingWorkTypeRecord.nextDayTouringCutoff) && buildingWorkTypeRecord.blockSameDayTouring){
            workTypeRecord.Name = generateWorkTypeName(buildingWorkTypeRecord, BLOCK_SAME_DAY_TOUR);
            workTypeRecord.timeframeStart = 1;
        } else {
            workTypeRecord.Name = generateWorkTypeName(buildingWorkTypeRecord, ALLOW_SAME_DAY_TOUR);
            workTypeRecord.timeframeStart = 0;
        }
        upsert workTypeRecord;
        return workTypeRecord;
    }

    private static WorkType createChildWorkTypes(WorkType parentWorkType, BuildingWorkTypeWrapper buildingWorkTypeRecord){
        List<WorkType> existingWorkTypes = [SELECT Id 
                                            FROM WorkType 
                                            WHERE Parent_Id__c=: parentWorkType.Id];
        WorkType childWokType = parentWorkType.clone(false, true, false, false);
        if(String.isNotBlank(parentWorkType.Next_Day_Touring_Cutoff__c) && parentWorkType.Block_Same_Day_Touring__c){
            childWokType.Name = generateWorkTypeName(buildingWorkTypeRecord, BLOCK_SAME_DAY_TOUR);
            childWokType.timeframeStart = 1;
        } else {
            childWokType.Name = generateWorkTypeName(buildingWorkTypeRecord, ALLOW_SAME_DAY_TOUR);
            childWokType.timeframeStart = 0;
        }
        childWokType.Next_Day_Touring_Cutoff__c = '';
        childWokType.Parent_Id__c = parentWorkType.Id;
        if(existingWorkTypes != null && !existingWorkTypes.isEmpty()){
            childWokType.Id = existingWorkTypes[0].Id;
        }
        upsert childWokType;
        return childWokType;
    }

    @TestVisible
    private static String generateWorkTypeName(BuildingWorkTypeWrapper buildingWorkTypeRecord, String nameType){
        return buildingWorkTypeRecord.buildingName + ' - ' 
               + buildingWorkTypeRecord.tourFormat + ' - ' 
               + nameType + ' - ' 
               + buildingWorkTypeRecord.estimatedDuration + ' Min - '
               + buildingWorkTypeRecord.blockTimeBeforeAppointment  + ' Buffer Before - '
               + buildingWorkTypeRecord.blockTimeAfterAppointment  + ' Buffer After';
    }

    @TestVisible
    private static void createWorkTypeGroupMember(List<WorkType> workTypeRecords){
        List<WorkTypeGroup> workTypeGroupRecords = [SELECT Id, Name
                                             FROM WorkTypeGroup
                                             WHERE Name LIKE:workTypeRecords[0].Tour_Format__c + '%' 
                                             LIMIT 2];
        Map<String, Id> workTypeGroupToId = new Map<String, Id>();
        for(WorkTypeGroup workTypeGroupRecord: workTypeGroupRecords){
            if(workTypeGroupRecord.Name.contains(CUTOFF)){
                workTypeGroupToId.put('withCutoff', workTypeGroupRecord.Id);
            } else {
                workTypeGroupToId.put('withoutCutoff', workTypeGroupRecord.Id);
            }
        }

        delete [SELECT Id FROM WorkTypeGroupMember WHERE WorkTypeId IN: workTypeRecords];
        List<WorkTypeGroupMember> workTypeGroupMemberToInsert = new List<WorkTypeGroupMember>();
        for(WorkType workTypeRecord: workTypeRecords){
            WorkTypeGroupMember workTypeGroupMemberRecord = new WorkTypeGroupMember(
                WorkTypeId = workTypeRecord.Id,
                WorkTypeGroupId = (String.isBlank(workTypeRecord.Next_Day_Touring_Cutoff__c))? workTypeGroupToId.get('withoutCutoff'):workTypeGroupToId.get('withCutoff')
            );
            workTypeGroupMemberToInsert.add(workTypeGroupMemberRecord);
        }        
        insert workTypeGroupMemberToInsert;
    }

    @TestVisible
    private static void createServiceTerritoryWorkTypes(List<WorkType> workTypeRecords){
        Id serviceTerritoryId = [SELECT Id 
                                 FROM ServiceTerritory 
                                 WHERE Building_Id__c =: workTypeRecords[0].Building_Id__c LIMIT 1]?.Id;

        delete [SELECT Id FROM ServiceTerritoryWorkType WHERE WorkTypeId IN: workTypeRecords AND ServiceTerritoryId =: serviceTerritoryId];
        List<ServiceTerritoryWorkType> serviceTerritoryWorkTypeToInsert = new List<ServiceTerritoryWorkType>();
        for(WorkType workTypeRecord: workTypeRecords){
            ServiceTerritoryWorkType serviceTerritoryWorkTypeRecord = new ServiceTerritoryWorkType(
                WorkTypeId = workTypeRecord.Id,
                ServiceTerritoryId = serviceTerritoryId
            );
            serviceTerritoryWorkTypeToInsert.add(serviceTerritoryWorkTypeRecord);
        }
        insert serviceTerritoryWorkTypeToInsert;
    }

    @AuraEnabled
    public static void deleteWorkType(Id workTypeId){
        delete [SELECT Id 
                FROM WorkType
                WHERE Id=: workTypeId 
                    OR Parent_Id__c=: workTypeId];
    }
    
    public class BuildingWorkTypeWrapper {
        @AuraEnabled 
        public String uniqueId;
        @AuraEnabled 
        public String name;
        @AuraEnabled
        public String tourFormat;
        @AuraEnabled
        public String estimatedDuration;
        @AuraEnabled
        public String blockTimeBeforeAppointment;
        @AuraEnabled
        public String blockTimeAfterAppointment;
        @AuraEnabled
        public String timeframeStart;
        @AuraEnabled
        public Boolean blockSameDayTouring;
        @AuraEnabled
        public String nextDayTouringCutoff;
        @AuraEnabled
        public String buildingId;
        @AuraEnabled
        public String buildingName;
        @AuraEnabled
        public Boolean isEditable;

        BuildingWorkTypeWrapper (WorkType workTypeRecord){
            this.uniqueId = workTypeRecord.Id;
            this.name = workTypeRecord.Name;
            this.tourFormat = workTypeRecord.Tour_Format__c;
            this.estimatedDuration = String.valueOf(workTypeRecord.EstimatedDuration);
            this.blockTimeBeforeAppointment = String.valueOf(workTypeRecord.BlockTimeBeforeAppointment);
            this.blockTimeAfterAppointment = String.valueOf(workTypeRecord.BlockTimeAfterAppointment);
            this.blockSameDayTouring = workTypeRecord.Block_Same_Day_Touring__c;
            this.nextDayTouringCutoff = workTypeRecord.Next_Day_Touring_Cutoff__c;
            this.buildingId = workTypeRecord.Building_Id__c;
            this.buildingName = workTypeRecord.Building_Id__r.Name;
            this.isEditable = false;
        }
    }
}