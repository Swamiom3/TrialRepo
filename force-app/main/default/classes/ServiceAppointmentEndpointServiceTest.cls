@isTest
public with sharing class ServiceAppointmentEndpointServiceTest {
    @isTest
    static void testServiceAppointmentEndpointService() {
        ServiceAppointmentEndpointService saes = new ServiceAppointmentEndpointService();
        Id fakeHostId = TestUtility.getFakeId(ServiceResource.SObjectType);
        saes.setServiceResource(fakeHostId);
        System.assert(!saes.ssar.assignedResources.isEmpty(), 'Host list must not be empty');
        System.assert(saes.ssar.assignedResources[0].isPrimaryResource, 'Tour Host added should be set as promary');
        System.assertEquals(fakeHostId, saes.ssar.assignedResources[0].serviceResourceId, 'Host Id is not set correctly');
        saes.setSAField('Field__c', 'Value');
        System.assertEquals(1, saes.ssar.serviceAppointment.extendedFields.size(), 'One field must be added to service appointment payload');
    }
}