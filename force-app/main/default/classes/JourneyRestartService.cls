public inherited sharing class JourneyRestartService {

    private DmlConsolidator dml;

    public JourneyRestartService setDmlConsolidator(DmlConsolidator dml) {
        this.dml = dml;
        return this;
    }

    public void restartJourneyForLead(Set<Id> restartJourneyLeadIds){
        Settings.FieldMappings leadToJourneyFieldMapping = Settings.getFieldMappings('LeadToJourney');
        if (leadToJourneyFieldMapping == null){
            return;
        }
        List<SObject> recordsForUpsert = prepareRecordsForUpsert(generateQuery(leadToJourneyFieldMapping.mappings.values()), leadToJourneyFieldMapping, restartJourneyLeadIds);
        if(!recordsForUpsert.isEmpty()){
            if (dml != null) {
                dml.add(recordsForUpsert, DmlConsolidator.Operation.FOR_UPSERT);
            } else {
                upsert recordsForUpsert;
            }
        }
    }

    private List<SObject> prepareRecordsForUpsert(String query, Settings.FieldMappings leadToJourneyFieldMapping, Set<Id> restartJournetyLeadIds){
        List<SObject> leadsToUpdate = new List<SObject>();
        List<SObject> journeyToUpsert = new List<SObject>();
        for(Lead leadRecord : Database.Query(query)){
            if(leadRecord.Journeys__r == null || leadRecord.Journeys__r.isEmpty()){// No Started Journey is present on Lead
                journeyToUpsert.add(createJourneyForLead(leadRecord, leadToJourneyFieldMapping));
            }else{
                for(Journey__c journeyRec : leadRecord.Journeys__r){
                    journeyRec.NMD_Next_Contact_Date__c = Date.today();
                    journeyToUpsert.add(journeyRec);
                }
            }
            leadRecord.Restart_Journey__c = false;
            leadsToUpdate.add(leadRecord);
        }
        List<SObject> recordsForUpsert = new List<SObject>();
        recordsForUpsert.addAll(leadsToUpdate);
        recordsForUpsert.addAll(journeyToUpsert);
        return recordsForUpsert;
    }

    public String generateQuery(List<Settings.MappedField> fieldMappings){
        String query = 'SELECT Name, LeadSource, OwnerId,';
        for(Settings.MappedField field : fieldMappings){
            if(!query.contains(field.fieldname)){
                query += field.fieldname + ',';
            }
        }
        query = query.removeEnd(',');
        query += ' , Building_Interested_In__r.City__c, (SELECT Id, NMD_Next_Contact_Date__c FROM Journeys__r';
        query += ' WHERE Status__c = \'Known\' ORDER BY LastModifiedDate DESC LIMIT 1) FROM Lead WHERE Id IN :restartJournetyLeadIds';
        return query;
    }

    private Journey__c createJourneyForLead(Lead leadRecord, Settings.FieldMappings leadToJourneyFieldMapping){
        Journey__c journey = new Journey__c();
        journey.NMD_Next_Contact_Date__c = Date.today();
        journey.Primary_Lead__c = leadRecord.Id;
        journey.OwnerId = leadRecord.OwnerId;
        journey.Status__c = 'Known';
        for(String strKey : leadToJourneyFieldMapping.mappings.keySet()){
            journey.put(strKey, leadRecord.get(leadToJourneyFieldMapping.mappings.get(strKey).fieldname));
        }
        if(lead.Building_Interested_In__c != null && String.isNotBlank(leadRecord.Building_Interested_In__r.City__c) ){
            journey.Name = journey.Name +'-'+leadRecord.Building_Interested_In__r.City__c ;
        }
        if(String.isNotBlank(leadRecord.LeadSource)){
            journey.Name = journey.Name +'-'+leadRecord.LeadSource;
        }
        return journey;
    }


    public void restartJourneyForContact(Set<Id> contactIds) {
        Set<Id> contactToRestartJourney = new Set<Id>();
        List<Sobject> sObjectsToUpdate = new List<Sobject>();
        List<Journey__c> journeyToUpdate = new List<Journey__c>();
        List<Contact> contactToUpdate = new List<Contact>();
        List<Journey__c> journeyToInsert = new List<Journey__c>();
        Settings.FieldMappings contactToJourney = Settings.getFieldMappings('ContactToJourney');
        String query = 'SELECT Name, LeadSource,';
        if (contactToJourney != null) {
            for (Settings.MappedField field : contactToJourney.mappings.values()) {
                if (!query.contains(field.fieldname)) {
                    query += field.fieldname + ',';
                }
            }
        }
        query = query.removeEnd(',');
        query += ' , Location__r.City__c, (SELECT Status__c, NMD_Next_Contact_Date__c, Building_Interested_In__c, Building_Interested_In__r.City__c '
                    + 'FROM Journeys__r WHERE Status__c = \'Known\' ORDER BY LastModifiedDate DESC LIMIT 1) '
                + 'FROM Contact c WHERE Id IN :contactIds';
        for (Contact contact : Database.Query(query)) {
            contact.Restart_Journey__c = false;
            contactToUpdate.add(contact);
            if (!contact.Journeys__r.isEmpty()) {// started journey is present so update existing journey.
                Journey__c journeyRec = contact.Journeys__r;
                Journey__c journey = new Journey__c();
                journey.Id = journeyRec.Id;
                journey.NMD_Next_Contact_Date__c = Date.Today();
                journeyToUpdate.add(journey);
            } else {//no started journey is present so create new journey.
                Journey__c journey = new Journey__c();
                if (contactToJourney != null) {
                    for (String strKey : contactToJourney.mappings.keySet()) {
                        journey.put(strKey, contact.get(contactToJourney.mappings.get(strKey).fieldname));
                    }
                }
                journey.NMD_Next_Contact_Date__c = Date.Today();
                journey.Primary_Contact__c = contact.Id;
                journey.Status__c = GlobalConstants.JOURNEY_STATUS_KNOWN;
                if (contact.Location__c != null && String.isNotBlank(contact.Location__r.City__c)) {
                    journey.Name = journey.Name + '-' + contact.Location__r.City__c;
                }
                if (String.isNotBlank(contact.LeadSource)) {
                    journey.Name = journey.Name + '-' + contact.LeadSource;
                }
                journeyToInsert.add(journey);
            }
        }
        sObjectsToUpdate.addAll((List<sObject>)contactToUpdate);
        sObjectsToUpdate.addAll((List<sObject>)journeyToUpdate);
        if (!journeyToInsert.isEmpty()) {
            if (dml != null) {
                dml.add(journeyToInsert, DmlConsolidator.Operation.FOR_INSERT);
            } else {
                insert journeyToInsert;
            }
        }
        if (!sObjectsToUpdate.isEmpty()) {
            if (dml != null) {
                dml.add(sObjectsToUpdate, DmlConsolidator.Operation.FOR_UPDATE);
            } else {
                update sObjectsToUpdate;
            }
        }
    }
}