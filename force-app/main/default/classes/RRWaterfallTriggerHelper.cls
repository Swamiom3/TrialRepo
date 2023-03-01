/**
 * Helper class for RRWaterfall object.
 * adding withouth sharing as it should be executed in the system mode.
 */
public without sharing class RRWaterfallTriggerHelper {
    
    public static void updateRevenueContract(List<RightRev__Revenue_Contract_Waterfall__c> records) {
        String rcId;
        for(RightRev__Revenue_Contract_Waterfall__c waterfall:records){
            rcId = waterfall.RightRev__Revenue_Contract_GUID__c;
        }

        RightRev__Revenue_Contract__c revenueContract = [SELECT Id, Name, RightRev__Legal_Entity__c FROM RightRev__Revenue_Contract__c WHERE Id =:rcId];
        RightRev__Accounting_Period__c openPeriod = [SELECT Id, RightRev__Status__c, RightRev__Current_Open_Period__r.RightRev__Year__c,
                                                            RightRev__Current_Open_Period__r.RightRev__Legal_Entity__c, RightRev__Current_Open_Period__r.RightRev__Start_Date__c,
                                                            RightRev__Current_Open_Period__r.RightRev__Period_Number__c
                                                    FROM RightRev__CALENDAR_STATUSES__c 
                                                    WHERE RightRev__Status__c = 'Open' 
                                                        AND RightRev__Legal_Entity__r.Name = :revenueContract.RightRev__Legal_Entity__c]?.RightRev__Current_Open_Period__r;
        Decimal shortTermWaterfall = 0.0;
        Decimal longTermWaterfall = 0.0;
        Date periodEndDate = openPeriod.RightRev__Start_Date__c.addYears(1).addDays(1);
        for (RightRev__Revenue_Contract_Waterfall__c waterfallRecord : [SELECT Name, RightRev__Transaction_Amount__c, RightRev__Accounting_Period__r.RightRev__Period_Number__c,
                                                                               RightRev__Accounting_Period__r.RightRev__End_Date__c, RightRev__Accounting_Period__r.RightRev__Start_Date__c
                                                                        FROM RightRev__Revenue_Contract_Waterfall__c 
                                                                        WHERE RightRev__Accounting_Period__r.RightRev__Start_Date__c > :openPeriod.RightRev__Start_Date__c 
                                                                            AND RightRev__Revenue_Contract_GUID__c=:rcId 
                                                                            AND RightRev__Accounting_Period__r.RightRev__Legal_Entity__c=:openPeriod.RightRev__Legal_Entity__c
                                                                            AND RightRev__Transaction_Amount__c != null 
                                                                        WITH SECURITY_ENFORCED 
                                                                        ORDER BY RightRev__Accounting_Period__r.RightRev__Start_Date__c ASC]) {
            if(waterfallRecord.RightRev__Accounting_Period__r.RightRev__Start_Date__c < periodEndDate){
                shortTermWaterfall+=waterfallRecord.RightRev__Transaction_Amount__c;
            } else {
                longTermWaterfall+=waterfallRecord.RightRev__Transaction_Amount__c;
            }
        }

        revenueContract.Short_Term_Waterfall__c = shortTermWaterfall;
        revenueContract.Long_Term_Waterfall__c = longTermWaterfall;

        Decimal stBillings = 0.0;
        Decimal ltBillings = 0.0;
        
        for (RightRev__Revenue_Contract_Line__c rcLineRecord : [SELECT RightRev__Total_Sell_Price__c, RightRev__End_Date__c, RightRev__Start_Date__c 
                                                                FROM RightRev__Revenue_Contract_Line__c 
                                                                WHERE RightRev__Revenue_Contract_id__c = :rcId 
                                                                    AND RightRev__Start_Date__c > :openPeriod.RightRev__Start_Date__c 
                                                                    AND RightRev__Total_Sell_Price__c != null
                                                                WITH SECURITY_ENFORCED 
                                                                ORDER BY RightRev__Start_Date__c ASC]) {

            if(rcLineRecord.RightRev__Start_Date__c < periodEndDate){
                stBillings+= rcLineRecord.RightRev__Total_Sell_Price__c;
            } else {
                ltBillings+= rcLineRecord.RightRev__Total_Sell_Price__c;
            }
        }
        
        revenueContract.ST_Billings__c = stBillings;
        revenueContract.LT_Billings__c = ltBillings;
        update revenueContract;
    }
}