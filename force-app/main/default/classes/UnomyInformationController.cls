/************************************************************************************************************************************
    Author      :   Jitesh Adwani
    Description :   This class will contain Logic of UnomyInformationController.
	Issue No    : 	ST-3523
    History		:
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR                  DETAIL
    1          4 Mar 2019		    Jitesh             Initial Developement
**************************************************************************************************************************************/
public class UnomyInformationController {
    public class  UnomyInformationControllerException extends Exception{}
    public static Boolean isInvoker = false;
    public static Savepoint objSavePoint {get; set;}

    static {
        isInvoker = ApexDebugLog.registerRootInvoker(ApexDebugLog.InvokerType.AURA, 'UnomyInformationController' + 'getsObjectPrefix', ApexDebugLog.InvokerType.AURA);
    }

    /************************************************************************************************************************************
        Author         : Jitesh Adwani
        Description    : This method returns the map which contains information of record and metadata setting.
        Created Date   : 5 Mar 2019
        Issue No       : ST-3523
    **************************************************************************************************************************************/
    @AuraEnabled
    public static DatabaseResult getUnomyInformation(Id recordId) {
        try {
            Id CICompanyId = getUnomyCompanyId(recordId);
            Map<String, Object> mapUnomyInformation = new Map<String, Object>();
            Map<String, String> mapMetaDataSetting = (Map<String, String>)JSON.deserialize(Settings.getMetadataSettingByDevName('UnomyInformation').Data__c, Map<String, String>.class);
            mapUnomyInformation.put('MetaDataSetting', mapMetaDataSetting);
            if(CICompanyId != null){
                List<CI_Company__c> lstUnomyCompany = new List<CI_Company__c>([SELECT Id, Name, CurrencyIsoCode, Company_Name__c, Size__c, Industry__c, Location_Country__c, Location_City__c, Location_State__c, Revenue__c, Location_Address__c, Website__c, Updated_DateTime__c, Company_Logo__c, Company_Trend__c, Override_Estimated_Headcount__c, Override_Address__c, Override_Country__c, Override_State__c, Override_City__c FROM CI_Company__c WHERE Id =: CICompanyId]);
                mapUnomyInformation.put('UnomyCompanyRecord', lstUnomyCompany[0]);
            }
            mapUnomyInformation.put('TimeZone', String.valueOf(UserInfo.getTimeZone()));
            return new DatabaseResult(mapUnomyInformation);
        } catch(Exception pEx) {
            ApexDebugLog.logException(pEx, recordId, 'UnomyInformationController', 'getUnomyInformatio');
            return new DatabaseResult(pEx);
        }
    }

    /************************************************************************************************************************************
        Author         : Jitesh Adwani
        Description    : This method returns the record Id of UnomyCompany.
        Created Date   : 4 Mar 2019
        Issue No       : ST-3523
    **************************************************************************************************************************************/
    public static String getUnomyCompanyId(Id recordId) {
        String strObjectType = recordId.getSObjectType().getDescribe().getName();
        String strQuery = 'SELECT Id, CI_Company__c FROM ' + strObjectType + ' WHERE Id = \'' + recordId + '\'';
        List<SObject> lstSoject = Database.query(strQuery);
        if(lstSoject != NULL && !lstSoject.isEmpty()){
            return (String)lstSoject[0].get('CI_Company__c');
        }
        return NULL;
    }
}