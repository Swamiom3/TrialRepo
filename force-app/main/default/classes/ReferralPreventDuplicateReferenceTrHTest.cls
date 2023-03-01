@isTest
public class ReferralPreventDuplicateReferenceTrHTest {
    private static final String ERROR_MESSAGE = System.Label.Referral_Duplication_Reference_Error;
    
    @isTest
    private static void insertReferralTest(){
        List<Referral__c> mockedReferrals = getFakeReferrals(true);
        mockedReferrals[0].Referral_Email__c = 'referral@gmail.com';
        mockedReferrals[2].Referral_Email__c = 'referral45@gmail.com';
        mockedReferrals[3].Referral_Email__c = 'referral45@gmail.com';
        List<Referral__c> existingReferrals = new List<Referral__c>{
            new Referral__c(Id = TestUtility.getFakeId(Referral__c.getSObjectType()),
                            Name = 'Test Referral Rec',
                            Referral_Email__c = 'referral@gmail.com')
        };
        ReferralPreventDuplicateReferenceTrH referralReference = new ReferralPreventDuplicateReferenceTrH();
        referralReference.newReferrals = mockedReferrals;
        referralReference.referralSelector = (ReferralSelector)
                                           MockService.createMock(ReferralSelector.class,
                                                                  new Map<String, Object>{
                                                                      'getReferralsByReferralEmail' => existingReferrals
                                                                  });
        referralReference.beforeInsert();
        String errorMsg = mockedReferrals[0].getErrors()[0].getMessage();
        String errorMsg1 = mockedReferrals[3].getErrors()[0].getMessage();
        System.assertEquals(ERROR_MESSAGE, errorMsg, 'Duplicate reference'); 
        System.assertEquals(ERROR_MESSAGE, errorMsg1, 'Duplicate reference'); 
    }
    
    static List<Referral__c> getFakeReferrals(Boolean isFakeIds) {
        Map<String, Object> recordsData = new Map<String, Object>();
        recordsData = new Map<String, Object>();
        recordsData.put('objectName', 'Referral__c');
        recordsData.put('numberOfRecords', 5);
        List<Referral__c> referrals = MockTestingUtility.getRecords(recordsData, isFakeIds);
        for (Integer i = 0; i < referrals.size(); i++) {
            Map<String, Object> referralToDeserialize = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(referrals[i]));
            referralToDeserialize.put('CreatedDate', System.today());
            referrals[i] = (Referral__c) JSON.deserialize(JSON.serialize(referralToDeserialize), Referral__c.class);
        }
        return referrals;
    }
}