@isTest
private class TermCommitmentWrapperTest {
    @isTest
    static void testWrapper() {
        List<String> commitmentTerms = new List<String>{'1'};
        String commitmentTerm = '1';
        
        Test.startTest();
        TermCommitmentWrapper termWrapper = new TermCommitmentWrapper(commitmentTerms, commitmentTerm);
        Test.stopTest();
        
        System.assert(termWrapper.commitmentTerms == commitmentTerms, 'Failed to populate the Commitment Terms');
        System.assert(termWrapper.commitmentTerm == commitmentTerm, 'Failed to populate the Commitment Term');
    }
}