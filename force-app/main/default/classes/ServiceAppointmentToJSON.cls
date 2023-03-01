/**********************************************************************************************************
Author        :  Salesforce
Description   :  This class is used in Salesforce Scheduler flows to get ServiceAppointment fields into JSON format.
-----------------------------------------------------------------------------------------------------------
VERSION        DATE            AUTHOR           DETAIL
1              03-Sep-2021     Salesforce       
**********************************************************************************************************/
global class ServiceAppointmentToJSON {
  
    @InvocableMethod(label='Service Appointment to JSON' description='')
    public static List<SAOutput> convertSAtoJSON(List<SAInput> sa) {
        List<SAOutput> resp = new List<SAOutput>();  
        SAOutput sao = new SAOutput();
        sao.serviceAppointmentFields = JSON.serializePretty(sa[0]);      
        resp.add(sao);  
        return resp;
    }
  
    global class SAInput {
        @InvocableVariable
        global String AdditionalInformation;
        @InvocableVariable
        global String AppointmentType;
        @InvocableVariable
        global String AccountId;
        @InvocableVariable
        global String ContactId;
        @InvocableVariable
        global String OpportunityId;
        @InvocableVariable
        global String Status;
        @InvocableVariable
        global String Comments;
        @InvocableVariable
        global String ParentRecordId;
        @InvocableVariable
        global String ServiceTerritoryId;
        @InvocableVariable
        global String ServiceResources;
        @InvocableVariable
        global String ServiceResourceId;
        @InvocableVariable
        global String Street;
        @InvocableVariable
        global String City;
        @InvocableVariable
        global String Country;
        @InvocableVariable
        global String Manufacturer;
        @InvocableVariable
        global String PostalCode;
        @InvocableVariable
        global DateTime SchedStartTime;
        @InvocableVariable
        global DateTime SchedEndTime;
        @InvocableVariable
        global String Description;
        @InvocableVariable
        global String Subject;
        @InvocableVariable
        global String Phone;
        @InvocableVariable
        global String Email;
        @InvocableVariable
        global String WorkTypeGroupId;
        @InvocableVariable
        global String WorkTypeId;
        @InvocableVariable
        global Boolean isSlotChanged = false;
        @InvocableVariable
        global String schedulingPolicyId;
    }
  
    global class SAOutput {
        @InvocableVariable(required=true)
        global String serviceAppointmentFields;
    }  
}