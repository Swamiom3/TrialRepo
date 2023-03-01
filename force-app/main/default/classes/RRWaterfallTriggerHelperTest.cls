@IsTest
public with sharing class RRWaterfallTriggerHelperTest{
    @TestSetup
    static void setupData(){
        blng__LegalEntity__c legalEntity = new blng__LegalEntity__c(Name = 'TestLegalEntity');
        insert legalEntity;
        List<RightRev__Accounting_Period__c> lstAccountingPeriods = createAccountingPeriod(5);
        lstAccountingPeriods[0].RightRev__Status__c = 'Open';
        Date dateValue = Date.today();
        for (RightRev__Accounting_Period__c accPeriod : lstAccountingPeriods){
            accPeriod.RightRev__Legal_Entity__c = legalEntity.Id;
            accPeriod.RightRev__Start_Date__c = dateValue;
            dateValue = dateValue.addMonths(6);
        }
        insert lstAccountingPeriods;
        List<RightRev__CALENDAR_STATUSES__c> periodOpenClose = createPeriodOpenClose(1);
        periodOpenClose[0].RightRev__Current_Open_Period__c = lstAccountingPeriods[0].Id;
        periodOpenClose[0].RightRev__Legal_Entity__c = legalEntity.Id;
        periodOpenClose[0].RightRev__Unposted_Journal_Entries__c = 'No';
        periodOpenClose[0].RightRev__Holds__c = 'No';
        periodOpenClose[0].RightRev__Status__c = 'Open';
        periodOpenClose[0].RightRev__Transaction_Errors__c = 'No';
        insert periodOpenClose;
        List<RightRev__Revenue_Contract__c> lstRevenueContracts = createRevenueContract(1);
        lstRevenueContracts[0].RightRev__Carves_Currency_Type__c = 'functional_currency';
        lstRevenueContracts[0].RightRev__Legal_Entity__c = legalEntity.Name;
        insert lstRevenueContracts;
        dateValue = Date.today();
        List<RightRev__Revenue_Contract_Line__c> lstRCLines = createRevenueContractLine(5);
        for (RightRev__Revenue_Contract_Line__c rcLine : lstRCLines){
            rcLine.RightRev__Cummulative_Carves_Amount__c = 4444.4;
            rcLine.RightRev__Carves_Eligible__c = true;
            rcLine.RightRev__Total_Revenue_Released_Percent__c = 0;
            rcLine.RightRev__Revenue_Contract_id__c = lstRevenueContracts[0].Id;
            rcLine.RightRev__Total_Sell_Price__c = 100;
            rcLine.RightRev__Start_Date__c = dateValue;
            dateValue = dateValue.addMonths(6);
        }
        insert lstRCLines;
    }

    @IsTest
    static void waterfallTriggerHelperTest(){
        RightRev__Revenue_Contract__c rc = [SELECT Id, Name
                                            FROM RightRev__Revenue_Contract__c
                                            LIMIT 1];
        List<RightRev__Accounting_Period__c> lstAccPeriods = [SELECT Id, Name
                                                              FROM RightRev__Accounting_Period__c
                                                              ORDER BY RightRev__Start_Date__c ASC];
        List<RightRev__Revenue_Contract_Waterfall__c> lstWaterfalls = createWaterfall(5);
        for (RightRev__Revenue_Contract_Waterfall__c waterfall : lstWaterfalls){
            waterfall.RightRev__Revenue_Contract_GUID__c = rc.Id;
            waterfall.RightRev__Transaction_Amount__c = 100;
            waterfall.RightRev__Accounting_Period__c = lstAccPeriods[lstWaterfalls.indexOf(waterfall)].Id;
        }
        Test.startTest();
        insert lstWaterfalls;
        for (RightRev__Revenue_Contract_Waterfall__c waterfall : lstWaterfalls){
            waterfall.RightRev__Transaction_Amount__c = 200;
        }
        update lstWaterfalls;
        Test.stopTest();
        System.assertNotEquals(null, lstWaterfalls[0].Id, 'Waterfall insertion failed');
    }

    /*Method to create Test Revenue Contract Line Data*/
    public static List<RightRev__Revenue_Contract_Line__c> createRevenueContractLine(Integer numRevenueContractLine){
        List<RightRev__Revenue_Contract_Line__c> lstRCLines = new List<RightRev__Revenue_Contract_Line__c>();
        for (Integer i = 0; i < numRevenueContractLine; i++){
            RightRev__Revenue_Contract_Line__c rcl = new RightRev__Revenue_Contract_Line__c(RightRev__Line_Term__c = 3, RightRev__Terms__c = 12);
            lstRCLines.add(rcl);
        }
        return lstRCLines;
    }

    /*Method to create test Revenue Contract Data*/
    public static List<RightRev__Revenue_Contract__c> createRevenueContract(Integer numRevenueContract){
        List<RightRev__Revenue_Contract__c> lstRC = new List<RightRev__Revenue_Contract__c>();
        for (Integer i = 0; i < numRevenueContract; i++){
            lstRC.add(new RightRev__Revenue_Contract__c(Name = 'TestRevenueContract' + i, RightRev__Revenue_Contract_GUID__c = '123'));
        }
        return lstRC;
    }

    /*Method to create Test Accounting Period Data*/
    public static List<RightRev__Accounting_Period__c> createAccountingPeriod(Integer numAccountingPeriod){
        List<RightRev__Accounting_Period__c> lstAccPeriods = new List<RightRev__Accounting_Period__c>();
        for (Integer i = 0; i < numAccountingPeriod; i++){
            lstAccPeriods.add(new RightRev__Accounting_Period__c(RightRev__Is_Valid__c = true, RightRev__Fiscal_Year__c = 'FY-2020', RightRev__Start_Date__c = Date.today(), RightRev__Period_Number__c = 1, RightRev__Quarter_Number__c = 3, RightRev__End_Date__c = Date.today() + 7));
        }
        return lstAccPeriods;
    }

    /*Method to create Test Period Open Close Data*/
    public static List<RightRev__CALENDAR_STATUSES__c> createPeriodOpenClose(Integer numPeriodOpenClose){
        List<RightRev__CALENDAR_STATUSES__c> lstPeriodOpenClose = new List<RightRev__CALENDAR_STATUSES__c>();
        for (Integer i = 0; i < numPeriodOpenClose; i++){
            lstPeriodOpenClose.add(new RightRev__CALENDAR_STATUSES__c(Name = 'Test PeriodOpenClose' + i));
        }
        return lstPeriodOpenClose;
    }

    /*Method to create Test Waterfall Data*/
    public static List<RightRev__Revenue_Contract_Waterfall__c> createWaterfall(Integer numWaterfall){
        List<RightRev__Revenue_Contract_Waterfall__c> lstWaterfalls = new List<RightRev__Revenue_Contract_Waterfall__c>();
        for (Integer i = 0; i < numWaterfall; i++){
            lstWaterfalls.add(new RightRev__Revenue_Contract_Waterfall__c());
        }
        return lstWaterfalls;
    }

}