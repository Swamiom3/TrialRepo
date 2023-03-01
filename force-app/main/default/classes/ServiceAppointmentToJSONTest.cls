@isTest

public with sharing class ServiceAppointmentToJSONTest {

    @isTest
    public static void testServiceAppointmentToJSON() {
    
        ServiceAppointmentToJSON satj = new ServiceAppointmentToJSON();

        ServiceAppointmentToJSON.SAInput input = new ServiceAppointmentToJSON.SAInput();
        input.City = 'testCity';

        List<ServiceAppointmentToJSON.SAOutput> output = ServiceAppointmentToJSON.convertSAtoJSON(new List<ServiceAppointmentToJSON.SAInput>{input});
        System.assert(String.isNotEmpty(output[0].serviceAppointmentFields), 'Input was serialized');
    }

}