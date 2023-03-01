/*********************************************************************************************************
    Author        :  Krishna Somwanshi
    Description   :  This class has logic to extract Contacts from OD Accounts.
    Issue No.     :  
    History       :
-----------------------------------------------------------------------------------------------------------
    VERSION        DATE            AUTHOR             DETAIL
    1          11-Jan-2023     Krishna Somwanshi     Initial Development
**********************************************************************************************************/
public class TransferContactController {
    
    @AuraEnabled(cacheable=false)
    public static list<contact> getContactList(string searchKey) {
        string searchKeyword = '%' + searchKey + '%';
        list<Contact> contacts = new list<Contact>();
        for(Contact contact : [Select id,Name,Email,FirstName,LastName,Account.Name
                              From Contact WHERE Name LIKE : searchKeyword OR Email LIKE : searchKeyword]){
            contacts.add(contact);
        }
         if(contacts.size() == 0){
            throw new AuraHandledException('No Record Found..'); 
         }
        return contacts;
    }

    @AuraEnabled(cacheable=false)
    public static list<account> getAccountList(string searchKey) {
        string searchKeyword = '%' + searchKey + '%';
        list<Account> accounts = new list<Account>();
        for(Account account : [Select Id,Name 
                              From Account WHERE Name Like : searchKeyword AND (NOT Name LIKE :'On Demand') ]){
            accounts.add(account);
        }
         if(accounts.size() == 0){
            throw new AuraHandledException('No Record Found..'); 
         }
        return accounts;
    }
    
    @AuraEnabled(cacheable=false)
    public static void updateContact(Id contact, Id account){
        Id contactsId = contact;
        Id accountsId = account;
        List<Contact> contactsToUpdate = new List<Contact>();
        for(Contact contactToUpdate : [Select Id, AccountId From Contact WHERE Id =: contactsId LIMIT 1]){
            contactToUpdate.Id = contactsId;
            contactToUpdate.AccountId = accountsId;
            contactsToUpdate.add(contactToUpdate);
        }
        Database.update(contactsToUpdate);
    }

    @AuraEnabled(cacheable=false)
    public static void updateOpportunity(Id contact, Id account){
        Id contactsId = contact;
        Id accountsId = account;
        List<Opportunity> opportunitysToUpdate = new List<Opportunity>();
        for(Opportunity opportunity : [Select Id, Primary_Member__c, AccountId, Decision_Maker__c From Opportunity WHERE Primary_Member__c =: contactsId LIMIT 1]){
            opportunity.AccountId = accountsId;
            opportunitysToUpdate.add(opportunity);
        }
        Database.update(opportunitysToUpdate);
    }
}