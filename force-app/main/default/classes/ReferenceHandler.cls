/*************************************************************************************************************************************
    Author      :   Anant Kumar
    Description :   This class is used to manage References
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR             DETAIL
    1          15 Jun, 2016    Anant Kumar        Initial Deployment
    2          13 Jan, 2022    Pawel Biszczak     Refactor
**************************************************************************************************************************************/
public class ReferenceHandler {
    public static ReferenceSettings settingsReference;
    private static ReferralSelector referralSelector = new ReferralSelector();
    static Set<String> alreadyQueriedEmails = new Set<String>();
    @TestVisible
    static Map<String, Id> activeReferenceMap = new Map<String, Id>();
    static {
        settingsReference = (ReferenceSettings) Settings.get('ReferenceSettings', ReferenceSettings.class);
        if (settingsReference == null) {
            throw new ReferenceHandlerException('Unable to find a metadata setting named \'ReferenceSettings\'');
        }
    }

    public static void extendReference(Set<String> emails) {
        List<Referral__c> references = referralSelector.getReferralsByReferralEmail(emails);
        for (Referral__c reference : references) {
            reference.Expires_On__c = System.today().addDays(settingsReference.expireAfter);
        }
        update references;
    }

    public static void clearAlreadyQueriedEmailsForTest() {
        if (Test.isRunningTest()) {
            alreadyQueriedEmails.clear();
        }
    }

    public static Map<String, Id> getActiveReference(Set<String> emails) {
        if (alreadyQueriedEmails.containsAll(emails)) {
            return activeReferenceMap;
        }
        List<Referral__c> referrals = referralSelector.getReferralsByReferralEmails(emails);
        for (Referral__c reference : referrals) {
            if (reference.Referrer__c != null
                && (!String.isBlank(reference.Referral_Email__c)
                    && !activeReferenceMap.containsKey(reference.Referral_Email__c))) {
                    activeReferenceMap.put(reference.Referral_Email__c.toLowerCase(), reference.Referrer__c);
            }
        }
        alreadyQueriedEmails.addAll(emails);
        return activeReferenceMap;
    }

    public static Id getActiveReference(String email) {
        Referral__c[] reference = referralSelector.getReferralsByReferralEmail(email);
        if (reference.isEmpty()) {
            return null;
        }
        return reference[0].Referrer__c;
    }

    public static SaveResult ExtendReference(Id recordId, Date startDate, Date referredDate) {
        try {
            SaveResult referenceResult;
            Referral__c reference = referralSelector.getReferralByRecordId(recordId);
            if (reference != null) {
                reference.Expires_On__c = startDate.addDays(settingsReference.expireAfter);
                reference.Start_Date__c = startDate;
                reference.Referred_Date__c = referredDate;
                reference.IsActive__c = !(startDate < System.today().addDays(-settingsReference.expireAfter));
                referenceResult = new SaveResult(Database.update(reference));
            }
            return referenceResult;
        } catch (Exception ex) {
            SaveResult referenceResult = new SaveResult();
            referenceResult.IsSuccess = false;
            return referenceResult;
        }
    }

    public class ReferenceSettings {
        public Integer expireAfter { get; set; }
    }

    public class ReferenceHandlerException extends Exception {
    }
}