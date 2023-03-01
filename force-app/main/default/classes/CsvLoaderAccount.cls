public inherited sharing class CsvLoaderAccount extends CsvLoader {
    private final List<TriggerHandler> handlers = new List<TriggerHandler> {
        new TriggerHandler(
                'AccountSendEmailToAccountOwnersTrH',
                'Sends emails to both old and new account owners if not an API user',
                'Account',
                null,
                null
        ),
        new TriggerHandler(
                'ContactInheritOrganizationOwnerTrH',
                'Sets owner values of account into related contact',
                'Contact', 
                null,
                null
        ),
        new TriggerHandler(
                'AccountBypassChildUpdateTrH',
                'Used for bypassing the account\'s child owner change depending on the threshold value set in the setting',
                'Account', 
                null,
                null
        ),
        new TriggerHandler(
                'AccountStoreRelOppForEmailAlertTrH',
                'Creates a list of accounts\' child opportunities to be sent to account owners',
                'Account', 
                null,
                null
        ),
        new TriggerHandler(
                'AccountSendEmailToAccountOwnersTrH',
                'Sends emails to previous and new account owners with opportunity information',
                'Account', 
                null,
                null
        )
    };

    public override List<TriggerHandler> getTriggerHandlers() {
        return handlers;
    }
}