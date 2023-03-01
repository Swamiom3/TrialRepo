/*************************************************************************************************************************************
    Author      :   Pawel Biszczak
    Description :   This class provides sufficient test coverage for CalculateUnitsService class
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR            DETAIL
    1          10 Mar, 2022    Pawel Biszczak    Initial Development
**************************************************************************************************************************************/
@isTest
public with sharing class CalculateUnitsServiceTest {

    @IsTest
    public static void shouldGetUsfFromUSF() {
        Decimal usf;

        Test.startTest();
        CalculateUnitsService calculateService = new CalculateUnitsService(1, GlobalConstants.OPPORTUNITY_CREATION_SOURCE_VTS);
        usf = calculateService.getUsf();
        Test.stopTest();

        System.assertEquals(1, usf, 'Single VTS desk quantity should be equal to VTS multiplier');
    }

    @IsTest
    public static void shouldGetDesksFromVtsQuantity() {
        Integer desks;

        Test.startTest();
        CalculateUnitsService calculateService = new CalculateUnitsService(CalculateUnitsService.USF_IN_DESK,
                                                                           GlobalConstants.OPPORTUNITY_CREATION_SOURCE_VTS);
        desks = calculateService.getDesks();
        Test.stopTest();

        System.assertEquals(1, desks, 'Single VTS desk quantity should be equal to VTS multiplier');
    }

    @IsTest
    public static void shouldGetDesksFromDefaultSource() {
        Integer desks;

        Test.startTest();
        CalculateUnitsService calculateService = new CalculateUnitsService(CalculateUnitsService.USF_IN_DESK,
                                                                           'Test');
        desks = calculateService.getDesks();
        Test.stopTest();

        System.assertEquals(Integer.valueOf(Math.ceil(CalculateUnitsService.USF_IN_DESK)), desks,
                            'Desk quantity should be equal to the ceil of VTS multiplier');
    }

    @isTest
    public static void shouldCalculateUsfToUsm() {
        String uom = CalculateUnitsService.USF;
        Integer quantity = 100;
        Decimal quantityForUsm;

        Test.startTest();
        CalculateUnitsService service = new CalculateUnitsService(quantity, uom);
        quantityForUsm = service.getUsm();
        Test.stopTest();

        System.assertEquals(100 * CalculateUnitsService.USM_IN_USF, quantityForUsm);
    }

    @isTest
    public static void shouldCalculateDeskToUsm() {
        String uom = CalculateUnitsService.DESKS;
        Integer quantity = 100;
        Decimal quantityForUsm;

        Test.startTest();
        CalculateUnitsService service = new CalculateUnitsService(quantity, uom);
        quantityForUsm = service.getUsm();
        Test.stopTest();

        System.assertEquals(100 * CalculateUnitsService.USM_IN_DESK, quantityForUsm);
    }

}