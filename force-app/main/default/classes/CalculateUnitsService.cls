/*************************************************************************************************************************************
    Author      :   ---
    Description :   This class is handling units calculation
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR            DETAIL
    2          10 Mar, 2022    Pawel Biszczak    Refactor
**************************************************************************************************************************************/
public with sharing class CalculateUnitsService {
    public static final String DESKS = 'Desks';
    public static final String USM = 'USM';
    public static final String USF = 'USF';
    public static final String VTS = 'VTS';
    public static final Double USM_IN_DESK = 5.0818; // updated to the new value as per user story ST-7883. Prev value - 2.6626
    public static final Double USM_IN_USF = 0.092903;
    public static final Double USF_IN_USM = 10.7639;
    public static final Double USF_IN_DESK = 54.7; // updated to the new value as per user story ST-7883. Prev value - 28.66
    public static final Double DESK_IN_USF = 0.01828; // updated to the new value as per user story ST-7883. Prev value - 0.03489
    public static final Double DESK_IN_USM = 0.19678;// updated to the new value as per user story ST-7883. Prev value - 0.37557

    private Decimal quantity;
    private String uom;

    public CalculateUnitsService(Decimal quantity, String uom) {
        this.quantity = quantity;
        this.uom = uom;
    }
    public Decimal getUsf() {
        if (DESKS == uom) {
            return quantity * USF_IN_DESK;
        }
        if (USM == uom) {
            return quantity * USF_IN_USM;
        }

        return quantity;
    }

    public Decimal getUsm() {
        if (DESKS == uom) {
            return quantity * USM_IN_DESK;
        }
        if (USF == uom || VTS == uom) {
            return quantity * USM_IN_USF;
        }
        return quantity;
    }

    public Integer getDesks() {
        if (USM == uom) {
            return Integer.valueOf(Math.ceil(quantity * DESK_IN_USM));
        }
        if (USF == uom || VTS == uom) {
            return Integer.valueOf(Math.ceil(quantity * DESK_IN_USF));
        }
        return Integer.valueOf(Math.ceil(quantity));
    }
}