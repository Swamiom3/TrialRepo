/************************************************************************************************************************************
    Author      :   Mikolaj Juras
    Description :   This class should contain Case specific constants that are not related to any business domain 
----------------------------------------------------------------------------------------------------------------------------------   
**************************************************************************************************************************************/
public with sharing class CaseConstants {
    public static final Set<String> CASE_SALES_RECORD_TYPE = new Set<String>{'REA', 'Enterprise Finance & Strategy', 'Support - Sales', 'Support - Unomy','Support Request'};
}