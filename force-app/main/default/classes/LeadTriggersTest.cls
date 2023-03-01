/*************************************************************************************************************************************
    Author      :   Sunil Bhosale
    Description :   This class provides sufficient test coverage for Lead triggers.
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR            DETAIL
    1          4 Nov, 2019     Sunil Bhosale     Modification according to new test structure
    2          10 Feb, 2021    Mikołaj Juras     Remove Building_Iteresrs__c logic
    3          18 Jan, 2022    Pawel Biszczak    Small refactor
**************************************************************************************************************************************/
@isTest
public class LeadTriggersTest {
    public static List<CI_Company__c> companyTestRecords = new List<CI_Company__c>();
    
    @testSetup
    static void setup(){
        TestingUtility.getTerritoryStructure();
        List<sObject> recordsToInsert = new List<sObject>();
        getRawTestReferralRecords();
        recordsToInsert.addAll(getRawTestLeadRecords());
        recordsToInsert.addAll(getRawTestAccountRecords());

        Test.startTest();
        if(!recordsToInsert.isEmpty()){
            insert recordsToInsert;
        }
        Test.stopTest();
    }
    
    @isTest
    public static void LeadTriggerHandlerTest1(){
        Map<String, Lead> leadsEmailsToLeadsMap = new Map<String, Lead>();//This map is used to mantain the Lead.
        List<Lead> leads = getAllLeadRecords();

        Test.startTest();
        /*------Insert trigger assert--------*/
        updateActiveReferrerOnLead(leads);
        updateLeadSourceAndLeadSourceDetail(leads);
        updateRecordType(leads);

        /*------Update Values For Bulk Update--------*/
        updateValuesForUpdateLeadOwner(leads, leadsEmailsToLeadsMap);
        updateValuesForPopulateOrganization(leads, leadsEmailsToLeadsMap);
        updateValuesForConvertLeadsToJourneys(leads, leadsEmailsToLeadsMap);
        updateValuesForUpdateJourneyPrimaryContact(leads);
        updateValuesForRestartJourney(leads, leadsEmailsToLeadsMap);
        
        /*------Update the records--------*/
        if(!leadsEmailsToLeadsMap.keySet().isEmpty()){
            MetadataDrivenTriggerHandler.clearLoopCount();
            update leadsEmailsToLeadsMap.values();
        }
        List<Lead> updatedLeads = getAllLeadRecords();
        for(Lead lead : updatedLeads){
            leadsEmailsToLeadsMap.put(lead.Email, lead);
        }
        /*------Update trigger assert--------*/
        testRestartJourney(leadsEmailsToLeadsMap);
        Test.stopTest();
    }

    @isTest
    public static void LeadTriggerHandlerTest2(){
        try{
            delete [SELECT Id FROM Lead
                    WHERE Email =:'lead1@example.com'];
        }catch(Exception ex ){
            
        }
    } 
    
    public static void LeadTriggerHandlerTest3(){
        try{
            List<Lead> leads = new List<Lead>();
            leads.addAll((List<Lead>)TestingUtility.getRecords(
                    new Map<String, Object>{
                            'doInsert' => 'false',
                            'objName' => 'Lead',
                            'numberOfRecords' => '1',
                            'mapFieldValues' => new Map<String, List<Object>>{
                                    'Company' => new List<Object>{
                                            'Company1'
                                    },
                                    'LastName' => new List<Object>{
                                            'LastName1'
                                    },
                                    'LeadSource' => new List<Object>{
                                            'WeWork.com'
                                    },
                                    'Lead_Source_Detail__c' => new List<Object>{
                                            'Book a Tour Form'
                                    },
                                    'Locations_Interested__c' => new List<Object>{
                                            'AMS-Metropool'
                                    }
                            }
                    }));
            insert leads;
        } catch (Exception exp){
            
        }
    }
    
    @isTest
    public static void LeadTriggerHandlerTest4(){
        Test.startTest();
        RESTInboundLeadAPIHelper.isLeadFromWeb = true;
        Integer index = 0;
        List<Lead> leadsToUpdate = new List<Lead>();
        List<Lead> leadsToInsert = UtilLead.getNewLeads(11, false);
        for(Lead leadRecord : leadsToInsert){
            leadRecord.Email ='test'+index+'@exmaple.com';
            leadRecord.Generate_Journey__c = true;
            index++;
        }
        insert leadsToInsert;
        RESTInboundLeadAPIHelper.isLeadFromWeb = false;
        index = 0;
        List<Lead> secondLeadsToInsert = UtilLead.getNewLeads(11, false);
        for(Lead leadRecord : secondLeadsToInsert){
            leadRecord.Email ='test'+index+'@exmaple.com';
            leadRecord.Generate_Journey__c = true;
            index++;
        }
        insert secondLeadsToInsert;
        for(Lead leadRecord :  [SELECT Id, Restart_Journey__c, Locations_Interested__c, Email FROM lead WHERE Email LIKE 'test%']){
            leadRecord.Restart_Journey__c = true;
            leadRecord.Locations_Interested__c = 'AMS-Metropool';
            leadsToUpdate.add(leadRecord);
        }
        update leadsToUpdate;
        Test.stopTest();
        /*------Update trigger asert--------*/
        testRestartJourneyQueueable();
        
    } 
    
    @isTest
    public static void LeadTriggerNewStructureTest1(){
        List<Lead> leads = getAllLeadRecords();
        Map<String, Lead> recordsForUpdateMap = new Map<String, Lead>();
        Test.startTest();
        TestManager.handleTestProcess('Lead', leads, null,
                                      'LeadTriggerNewStructureTest1', TestManager.insertAssertEvent);
        TestManager.handleTestProcess('Lead', leads, recordsForUpdateMap,
                                      'LeadTriggerNewStructureTest1', TestManager.updateValuesEvent);
        if(!recordsForUpdateMap.values().isEmpty()){
            update recordsForUpdateMap.values();
        }
        TestManager.handleTestProcess('Lead',  getAllLeadRecords(), null, 'LeadTriggerNewStructureTest1', TestManager.updateAssertEvent);
        Test.stopTest();
    }
    
    @isTest
    public static void LeadTriggerNewStructureTest2(){
        Test.startTest();
        List<Lead> leads = getAllLeadRecords();
        Map<String, Lead> recordsForUpdateMap = new Map<String, Lead>();
        TestManager.handleTestProcess('Lead', leads, recordsForUpdateMap, 'LeadTriggerNewStructureTest2', TestManager.updateValuesEvent);
        if(!recordsForUpdateMap.values().isEmpty()){
            update recordsForUpdateMap.values();
        }
        TestManager.handleTestProcess('Lead', leads, null, 'LeadTriggerNewStructureTest2', TestManager.updateAssertEvent);
        Test.stopTest();
    }

    @isTest
    public static void prepareRecordsForUpsertTest() {
        Settings.FieldMappings mappings = Settings.getFieldMappings('LeadToJourney');
        List<String> fieldsToQuery = new List<String>();
        for (Settings.MappedField item : mappings.mappings.values()){
            fieldsToQuery.add(item.fieldname);
        }
        fieldsToQuery.add('OwnerId');
        fieldsToQuery.add('Building_Interested_In__r.City__c');
        List<Lead> leads = getAllLeadRecords();
        Set<Id> leadIds = new Set<Id>();

        for (Lead item : leads) {
            leadIds.add(item.Id);
        }
        String query = 'SELECT ' + String.join(fieldsToQuery,',') + ' FROM Lead';

        Test.startTest();
        List<sObject> records = LeadTriggerHandler.prepareRecordsForUpsert(query, mappings, leadIds);
        Test.stopTest();

        System.assertEquals(leads.size() * 2, records.size(), 'for every lead journey should be created');
    }

    public static void updateActiveReferrerOnLead(List<Lead> leads){
        for(Lead lead : leads){
            if(lead.Email != null && (lead.Email== 'Lead1@example.com' || lead.Email== 'Lead2@example.com')){
                System.assert(lead.Referrer__c != null, 'Referrers are not updated on lead');
                System.assert(lead.Building_Interested_In__c != null, 'Building_Interested_In__c is not updated on lead');// assert for updateBuildingInterestOnLead trigger
                
            }
            if(lead.Building_Interested_In__c != null) {
                System.assertEquals(lead.Portfolio_Interested_In__c, lead.Building_Interested_In__r.Market__c);
                System.assertEquals(lead.Territory_Name__c, lead.Building_Interested_In__r.Territory_Name__c);
            }
            if(lead.Portfolio_Interested_In__c != null) {
                System.assertEquals(lead.Territory_Name__c, lead.Portfolio_Interested_In__r.Territory__c);
            }
        }
    }

    public static void updateLeadSourceAndLeadSourceDetail(List<Lead> leads){
        for(Lead lead : leads){
            if(lead.Email != null && (lead.Email== 'Lead3@example.com')){
                System.assertEquals('Partner Referral', lead.LeadSource, 'Lead source is not updated according to unomy data on lead');
                System.assertEquals('test', lead.Lead_Source_Detail__c,'Lead sourceDetail is not updated according to unomy data on lead');
            }
        }
    }
    
    public static void updateRecordType(List<Lead> leads){
        for(Lead lead : leads){
            if(lead.Email != null && lead.Email== 'Lead3@example.com'){
                System.assertEquals('Lead Record Type', lead.recordType.Name, 'Record Type is not updated.');
            }else if(lead.Email != null && lead.Email== 'Lead4@example.com'){
                System.assertEquals('Lead Record Type', lead.recordType.Name, 'Record Type is not updated.');
                
            }
        }
    }
    
    public static void updateValuesForUpdateLeadOwner(List<Lead> leads, Map<String, Lead> leadsEmailsToLeadsMap){
        MetadataSetting__mdt metadataRecord = Settings.getMetadataSettingByDevName('Unassigned_NMD_US_Queue');

        for(Lead lead : leads){
            if(lead.Email == 'lead1@example.com' || lead.Email == 'lead2@example.com'){
                lead.OwnerId = Id.valueOf(metadataRecord.Data__c);//Assign lead to referral queue.
                leadsEmailsToLeadsMap.put(lead.Email,lead);
            }
        } 
    }

    public static void updateValuesForPopulateOrganization(List<Lead> leads, Map<String, Lead> leadsEmailsToLeadsMap){
        for(Lead lead : leads){
            if(lead.Email == 'lead1@example.com' || lead.Email == 'lead2@example.com'){
                lead.CI_Updated_DateTime__c = Datetime.now();
                leadsEmailsToLeadsMap.put(lead.Email,lead);
            } 
        } 
    }

    public static void updateValuesForConvertLeadsToJourneys(List<Lead> leads, Map<String, Lead> leadsEmailsToLeadsMap){
        for(Lead lead : leads){
            if(lead.Email == 'lead3@example.com' ){
                lead.Email = 'lead3@changeEmailexample.com';
                leadsEmailsToLeadsMap.put(lead.Email,lead);
            } 
        } 
    }

    public static void updateValuesForUpdateJourneyPrimaryContact(List<Lead> leads){
        List<Lead> leadsToConvert = new List<Lead>();
        for(Lead leadRecord : leads){
            if(leadRecord.Email == 'lead7@example.com'){
                leadsToConvert.add(leadRecord);
                break;
            }
        }
        if(leadsToConvert.isEmpty()) {
            return;
        }
        List<Lead> leadsAfterConvert = [ SELECT Id,
                                                (SELECT Id
                                                 FROM Journeys__r
                                                 ORDER BY LastModifiedDate DESC)
                                         FROM Lead
                                         WHERE Id = :leadsToConvert[0].Id ];
        Id journeyId = leadsAfterConvert[0].Journeys__r.size() > 0 ? leadsAfterConvert[0].Journeys__r[0].Id : null;
        Database.LeadConvert leadConvertRecord = new Database.LeadConvert();
        LeadStatus convertStatus = [ SELECT Id, MasterLabel
                                     FROM LeadStatus
                                     WHERE IsConverted = true 
                                     LIMIT 1 ];
        leadConvertRecord.setLeadId(leadsToConvert[0].Id);
        leadConvertRecord.setConvertedStatus(convertStatus.MasterLabel);
        SObjectTriggerHandler.bypass('OpportunityContactRoleTrH');
        Database.convertLead(leadConvertRecord);
        SObjectTriggerHandler.clearAllBypasses();
        leadConvertRecord.setConvertedStatus(convertStatus.MasterLabel);
        List<Journey__c> journeyAfterUpdate = [ SELECT Id, Primary_Lead__c, Primary_Contact__c
                                                FROM Journey__c
                                                WHERE Id = :journeyId ];
        System.assert(journeyAfterUpdate[0].Primary_Lead__c == null);
        System.assert(journeyAfterUpdate[0].Primary_Contact__c != null);
            
        
    }

    public static void updateValuesForRestartJourney(List<Lead> leads, Map<String, Lead> leadsEmailsToLeadsMap){
        for(Lead lead : leads){
            if(lead.Email == 'lead4@example.com' || lead.Email == 'lead5@example.com'){
                lead.Restart_Journey__c = true;
                leadsEmailsToLeadsMap.put(lead.Email,lead);
            }
        }
    }
    
    public static void testRestartJourney(Map<String, Lead> leadsEmailsToLeadsMap){
        Set<Id> leadsIds = new Set<Id>();
        leadsIds.add(leadsEmailsToLeadsMap.get('lead4@example.com').Id);
        leadsIds.add(leadsEmailsToLeadsMap.get('lead5@example.com').Id);
        for (Lead lead : [ SELECT Id, 
                                  (SELECT Id
                                   FROM Journeys__r)
                           FROM Lead
                           WHERE Id IN :leadsIds ]) {
            System.assert(lead.Journeys__r.size() > 0, 'Journey is not restarted');
        }
    }
    
    public static void testRestartJourneyQueueable(){
        for(Lead leadRecord : [ SELECT Id, Email, 
                                       (SELECT  Id, Primary_Email__c 
                                        FROM Journeys__r
                                        WHERE Status__c IN ('Known','Started')) 
                                FROM Lead 
                                WHERE Email LIKE 'test%' 
                                      AND Generate_Journey__c = true ]){
            System.assert(!leadRecord.Journeys__r.isEmpty(), 'Journey not inserted');
        }
    }                 

    public static List<Lead> getRawTestLeadRecords(){
        List<Lead> leads = new List<Lead>();
        leads.addAll((List<Lead>)TestingUtility.getRecords(
                new Map<String, Object>{
                        'doInsert' => 'false',
                        'objName' => 'Lead',
                        'numberOfRecords' => '1',
                        'mapFieldValues' => new Map<String, List<Object>>{
                                'Company' => new List<Object>{
                                        'Company1'
                                },
                                'FirstName' => new List<Object>{
                                        'FirstName1'
                                },
                                'LastName' => new List<Object>{
                                        'LastName1'
                                },
                                'Email' => new List<Object>{
                                        'lead1@example.com'
                                },
                                'LeadSource' => new List<Object>{
                                        'WeWork.com'
                                },
                                'Lead_Source_Detail__c' => new List<Object>{
                                        'Book a Tour Form'
                                },
                                'Locations_Interested__c' => new List<Object>{
                                        'AMS-Metropool'
                                },
                                'HasOptedOutOfEmail' => new List<Object>{
                                        false
                                },
                                'Last_Lead_Processing_Update__c' => new List<Object>{
                                        null
                                }
                        }
                }));// used for updateActiveReferrerOnLead and updateBuildingInterestOnLead triggers.
        leads.addAll((List<Lead>)TestingUtility.getRecords(
                new Map<String, Object>{
                        'doInsert' => 'false',
                        'objName' => 'Lead',
                        'numberOfRecords' => '1',
                        'mapFieldValues' => new Map<String, List<Object>>{
                                'Company' => new List<Object>{
                                        'Company2'
                                },
                                'FirstName' => new List<Object>{
                                        'FirstName2'
                                },
                                'LastName' => new List<Object>{
                                        'LastName2'
                                },
                                'Email' => new List<Object>{
                                        'lead2@example.com'
                                },
                                'LeadSource' => new List<Object>{
                                        'WeWork.com'
                                },
                                'Lead_Source_Detail__c' => new List<Object>{
                                        'Book a Tour Form'
                                },
                                'Locations_Interested__c' => new List<Object>{
                                        'BKN-Brooklyn Heights'
                                },
                                'City' => new List<Object>{
                                        'city1'
                                },
                                'State' => new List<Object>{
                                        'State1'
                                }
                        }
                }));// used for updateActiveReferrerOnLead and updateBuildingInterestOnLead triggers.
        List<CI_Company__c> companyTestRecords  = getCICompanyRecords();
        Integer count = 0;
        for(Lead lead : leads){
            lead.CI_Company__c = companyTestRecords[count].Id;
            count++;
        }
        Map<String, Building__c> uuidsToBuildingsMap = new Map<String, Building__c>();
        for(Building__c buildingRecord : [ SELECT Id, UUID__c
                                           FROM Building__c ]){
            uuidsToBuildingsMap.put(buildingRecord.UUID__c, buildingRecord);
        }
        leads.addAll((List<Lead>)TestingUtility.getRecords(
                new Map<String, Object>{
                        'doInsert' => 'false',
                        'objName' => 'Lead',
                        'numberOfRecords' => '1',
                        'mapFieldValues' => new Map<String, List<Object>>{
                                'Company' => new List<Object>{
                                        'Company3'
                                }, 'FirstName' => new List<Object>{
                                        'FirstName3'
                                }, 'LastName' => new List<Object>{
                                        'LastName3'
                                }, 'Email' => new List<Object>{
                                        'lead3@example.com'
                                }, 'LeadSource' => new List<Object>{
                                        'WeWork.com'
                                }, 'utm_source__c' => new List<Object>{
                                        'PArtner'
                                }, 'utm_medium__c' => new List<Object>{
                                        'test'
                                }, 'Number_of_Full_Time_Employees__c' => new List<Object>{
                                        50
                                }, 'Building_Interested_In__c' => new List<Object>{
                                        uuidsToBuildingsMap.get('testBuilding1').Id
                                }, 'Full_URL__c' => new List<Object>{
                                        'testexample.com?subtrting'
                                }
                        }
                }));// used for updateLeadSourceAndLeadSourceDetail trigger
        leads.addAll((List<Lead>)TestingUtility.getRecords(
                new Map<String, Object>{
                        'doInsert' => 'false',
                        'objName' => 'Lead',
                        'numberOfRecords' => '1',
                        'mapFieldValues' => new Map<String, List<Object>>{
                                'Company' => new List<Object>{
                                        'Company4'
                                }, 'FirstName' => new List<Object>{
                                        'FirstName4'
                                }, 'LastName' => new List<Object>{
                                        'LastName4'
                                }, 'Email' => new List<Object>{
                                        'lead4@example.com'
                                }, 'LeadSource' => new List<Object>{
                                        'WeWork.cn'
                                }, 'Number_of_Full_Time_Employees__c' => new List<Object>{
                                        1550
                                }, 'Marketing_Consent__c' => new List<Object>{
                                        true
                                }, 'Generate_Journey__c' => new List<Object>{
                                        false
                                }, 'Building_Interested_In__c' => new List<Object>{
                                        uuidsToBuildingsMap.get('testBuilding2').Id
                                }, 'Full_URL__c' => new List<Object>{
                                        'testexample.com?subtrting'
                                }
                        }
                }));// used for updateRecordType trigger
        leads.addAll((List<Lead>)TestingUtility.getRecords(
                new Map<String, Object>{
                        'doInsert' => 'false',
                        'objName' => 'Lead',
                        'numberOfRecords' => '1',
                        'mapFieldValues' => new Map<String, List<Object>>{
                                'Company' => new List<Object>{
                                        'Company5'
                                }, 'FirstName' => new List<Object>{
                                        'FirstName5'
                                }, 'LastName' => new List<Object>{
                                        'LastName5'
                                }, 'Email' => new List<Object>{
                                        'lead5@example.com'
                                }, 'LeadSource' => new List<Object>{
                                        'Broker Referral'
                                }, 'Locations_Interested__c' => new List<Object>{
                                        'AMS-Metropool'
                                }, 'Marketing_Consent__c' => new List<Object>{
                                        false
                                }, 'Generate_Journey__c' => new List<Object>{
                                        false
                                }, 'Building_Interested_In__c' => new List<Object>{
                                        uuidsToBuildingsMap.get('testBuilding3').Id
                                }, 'Full_URL__c' => new List<Object>{
                                        'testexample.com?subtrting'
                                }
                        }
                }));// Record is used for TrLeadContactMarketingConsentUpdate trigger.
        leads.addAll((List<Lead>)TestingUtility.getRecords(
                new Map<String, Object>{
                        'doInsert' => 'false',
                        'objName' => 'Lead',
                        'numberOfRecords' => '1',
                        'mapFieldValues' => new Map<String, List<Object>>{
                                'Company' => new List<Object>{
                                        'Company6'
                                }, 'FirstName' => new List<Object>{
                                        'FirstName6'
                                }, 'LastName' => new List<Object>{
                                        'LastName6'
                                }, 'Email' => new List<Object>{
                                        'lead6@example.com'
                                }, 'LeadSource' => new List<Object>{
                                        'Broker Referral'
                                }, 'Locations_Interested__c' => new List<Object>{
                                        'AMS-Metropool'
                                }, 'Building_Interested_In__c' => new List<Object>{
                                        uuidsToBuildingsMap.get('testBuilding4').Id
                                }, 'Full_URL__c' => new List<Object>{
                                        'testexample.com?subtrting'
                                }
                        }
                }));// Record is used for TrLeadContactMarketingConsentUpdate trigger.
        leads.addAll((List<Lead>)TestingUtility.getRecords(
                new Map<String, Object>{
                        'doInsert' => 'false',
                        'objName' => 'Lead',
                        'numberOfRecords' => '1',
                        'mapFieldValues' => new Map<String, List<Object>>{
                                'Company' => new List<Object>{
                                        'Company7'
                                }, 'FirstName' => new List<Object>{
                                        'FirstName7'
                                }, 'LastName' => new List<Object>{
                                        'LastName7'
                                }, 'Email' => new List<Object>{
                                        'lead7@example.com'
                                }, 'LeadSource' => new List<Object>{
                                        'WeWork.com'
                                }, 'Lead_Source_Detail__c' => new List<Object>{
                                        'Book a Tour Form'
                                }, 'Generate_Journey__c' => new List<Object>{
                                        true
                                }, 'Status' => new List<Object>{
                                        'Known'
                                }
                        }
                }));
        leads.addAll((List<Lead>)TestingUtility.getRecords(
                new Map<String, Object>{
                        'doInsert' => 'false',
                        'objName' => 'Lead',
                        'numberOfRecords' => '1',
                        'mapFieldValues' => new Map<String, List<Object>>{
                                'Company' => new List<Object>{
                                        'Company8'
                                }, 'FirstName' => new List<Object>{
                                        'FirstName8'
                                }, 'LastName' => new List<Object>{
                                        'LastName8'
                                }, 'Email' => new List<Object>{
                                        'lead8@example.com'
                                }, 'LeadSource' => new List<Object>{
                                        'WeWork.com'
                                }, 'Lead_Source_Detail__c' => new List<Object>{
                                        'Book A Tour Availability'
                                }, 'Generate_Journey__c' => new List<Object>{
                                        true
                                }, 'CI_Updated_DateTime__c' => new List<Object>{
                                        Datetime.now()
                                }
                        }
                }));
        return leads;
    }

    public static void getRawTestReferralRecords(){
        List<Referral__c> referralRecords = new List<Referral__c>();
        referralRecords.addAll((List<Referral__c>)TestingUtility.getRecords(
                new Map<String, Object>{
                        'doInsert' => 'true',
                        'objName' => 'referral',
                        'numberOfRecords' => '5',
                        'referralEmails' => new List<String>{
                                'lead1@example.com', 'lead2@example.com',
                                'lead3@example.com', 'lead5@example.com',
                                'lead6@example.com'
                        }
                }));
    }

    public static List<CI_Company__c> getCICompanyRecords(){
        companyTestRecords.addAll((List<CI_Company__c>)TestingUtility.getRecords(
                new Map<String, Object>{
                        'doInsert' => 'false',
                        'objName' => 'unomy',
                        'numberOfRecords' => '1',
                        'mapFieldValues' => new Map<String, List<Object>>{
                                'Location_Address__c' => new List<Object>{
                                        'Address1'
                                }, 'Location_City__c' => new List<Object>{
                                        'City1'
                                }, 'Company_Name__c' => new List<Object>{
                                        'Company1'
                                }, 'Size__c' => new List<Object>{
                                        50
                                }
                        }
                }));
        companyTestRecords.addAll((List<CI_Company__c>)TestingUtility.getRecords(
                new Map<String, Object>{
                        'doInsert' => 'false',
                        'objName' => 'unomy',
                        'numberOfRecords' => '1',
                        'mapFieldValues' => new Map<String, List<Object>>{
                                'Location_Address__c' => new List<Object>{
                                        'Address1'
                                }, 'Location_City__c' => new List<Object>{
                                        'City1'
                                }, 'Company_Name__c' => new List<Object>{
                                        'Company2'
                                }, 'Size__c' => new List<Object>{
                                        1250
                                }
                        }
                }));
        insert companyTestRecords;
        return companyTestRecords;
    }

    public static List<Account> getRawTestAccountRecords(){
        List<Account> lstAccounts = new List<Account>();
        Map<String, Object> accountValuesMap =
                new Map<String, Object>{
                        'Name' => 'Company1',
                        'Account_Type__c' => 'Org',
                        'CI_Company__c' => companyTestRecords[0].Id,
                        'MSA_Expiration__c' => Date.today().addDays(3),
                        'RecordTypeId' => Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId()
                };
        lstAccounts.addAll(TestingUtility.getAccountsByType(accountValuesMap, 'Org', 1));
        
        Map<String, Object> accountValuesMap1 =
                new Map<String, Object>{
                        'Name' => 'Company2',
                        'Account_Type__c' => 'Org',
                        'CI_Company__c' => companyTestRecords[1].Id,
                        'MSA_Expiration__c' => Date.today().addDays(3),
                        'RecordTypeId' => Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId()
                };
        lstAccounts.addAll(TestingUtility.getAccountsByType(accountValuesMap1, 'Org', 1));
        
        return lstAccounts;
    }

    public static List<Lead> getAllLeadRecords(){
        return(List<Lead>) Database.query('SELECT '+ String.join(getLeadFields(),',') + ' FROM Lead');
    }

    public static List<String> getLeadFields(){
        Set<String> leadFields = new Set<String>{'Id',
                                                 'FirstName',
                                                 'LastName',
                                                 'Name',
                                                 'Email',
                                                 'Referrer__c',
                                                 'LeadSource',
                                                 'Lead_Source_Detail__c',
                                                 'RecordType.Name',
                                                 'SMS_Opt_In__c',
                                                 'Marketing_Consent__c',
                                                 'HasOptedOutOfEmail',
                                                 'Email_Domain_Text__c',
                                                 'Last_Lead_Processing_Update__c',
                                                 'Update_HQ_Market_Status__c',
                                                 'CI_Updated_DateTime__c',
                                                 'Account__c',
                                                 'Processing_Stage__c',
                                                 'Unqualified_Reason__c',
                                                 'CI_Company__c','status',
                                                 'Portfolio_Interested_In__c',
                                                 'Territory_Name__c',
                                                 'Clean_URL__c',
                                                 'Full_URL__c',
                                                 'Contact_Broker__c',
                                                 'DoNotCall',
                                                 'Building_Interested_In__r.Market__c',
                                                 'Building_Interested_In__r.Territory_Name__c',
                                                 'Portfolio_Interested_In__r.Territory__c'
                                                };
        return new List<String>(leadFields);
    }
}