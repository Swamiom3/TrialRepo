/*************************************************************************************************************************************
 Author      :   Arun
 Description :   This is a wrapper class for TermBasedDiscountController
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               01/25/2021       Arun        Initial Deployment
 **************************************************************************************************************************************/
public class TermCommitmentWrapper {
    @AuraEnabled
    public List<String> commitmentTerms {get;set;}
    @AuraEnabled
    public String commitmentTerm {get; set;}
    public TermCommitmentWrapper(List<String> commitmentTerms, String commitmentTerm) {
        this.commitmentTerms = commitmentTerms;
        this.commitmentTerm = commitmentTerm;
    }
}