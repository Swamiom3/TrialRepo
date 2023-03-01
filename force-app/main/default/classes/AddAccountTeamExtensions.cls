public class AddAccountTeamExtensions {
    public final Account currentAccount{get; set;}
    @TestVisible
    private AccountSelector accountSelector = new AccountSelector();

    public AddAccountTeamExtensions(ApexPages.StandardController accountController){
        Account account = (Account) accountController.getRecord();
        this.currentAccount = accountSelector.getAccountsById(new List<Id>{account.Id})?.get(0);
    }
}