/**
 * @description class for the membership (asset) trigger
 * @name trac_Membership
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-09-04
 */

public with sharing class trac_Membership extends SObjectDomain {
    public List<Asset> memberships;

    public trac_Membership() {
        super();
        this.memberships = (List<Asset>) records;
    }

    public override void onAfterInsert() {
        setAccountMembershipType(this.memberships);
    }

    public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
        setAccountMembershipType(TLTrigger.filterByFieldChanged(this.memberships,existingRecords,Asset.Product2Id));
        findAccountMembershipStatus(this.memberships,(Map<Id,Asset>) existingRecords);
    }

//    public override void onBeforeDelete() { }
    public override void onAfterDelete() {
        findAccountMembershipStatus(TLList.collectStrings(this.memberships,Asset.Member_Name__c));
    }
//    public override void onAfterMergeDelete(List<SObject> mergeLoserRecords) { }
//    public override void onAfterUndelete() { }



    private static void setAccountMembershipType(List<Asset> memberships) {
        Set<String> membershipIds = new Set<String>();
        for(Asset membership: memberships) {
            membershipIds.add(membership.Id);
        }

        List<Asset> membershipsWithProduct = [SELECT Id, Product2.Name, Member_Name__c FROM Asset WHERE Id IN :membershipIds];
        List<Account> accountsToUpdate = new List<Account>();
        for(Asset membership : membershipsWithProduct) {
            if(TLOrgConstants.PRODUCT_NAMES_PHYSICAL.contains(membership.Product2.Name)) {
                accountsToUpdate.add(new Account(Id=membership.Member_Name__c, Membership_Type__c=TLOrgConstants.MEMBERSHIP_TYPE_PHYSICAL));
            } else if(TLOrgConstants.PRODUCT_NAMES_VIRTUAL.contains(membership.Product2.Name)) {
                accountsToUpdate.add(new Account(Id=membership.Member_Name__c, Membership_Type__c=TLOrgConstants.MEMBERSHIP_TYPE_VIRTUAL));
            }
        }

        if(accountsToUpdate.size() > 0) {
            try {
                update accountsToUpdate;
            } catch (Exception e) {
                System.debug('Could not update account Membership Type: ' + e.getMessage());
            }
        }
    }

    public static void findAccountMembershipStatus(List<Asset> memberships, Map<Id,Asset> oldMap) {
        List<Asset> changedAccountMemberships = TLTrigger.filterByFieldChanged(memberships,oldMap,Asset.Member_Name__c);
        Set<String> changedAccountIds = new Set<String>();
        for(Asset a : changedAccountMemberships) {
            changedAccountIds.add(oldMap.get(a.Id).Member_Name__c);
        }
        findAccountMembershipStatus(changedAccountIds);
    }


    public static void findAccountMembershipStatus(Set<String> accountIds) {
        List<Account> accounts = [SELECT Id, (SELECT Id, Product2.Name FROM Memberships__r) FROM Account WHERE Id IN :accountIds];
        for(Account account : accounts) {
            String membershipType = '';
            for(Asset accMem : account.Memberships__r) {
                if(TLOrgConstants.PRODUCT_NAMES_PHYSICAL.contains(accMem.Product2.Name)) {
                    membershipType = TLOrgConstants.MEMBERSHIP_TYPE_PHYSICAL;
                } else if(TLOrgConstants.PRODUCT_NAMES_VIRTUAL.contains(accMem.Product2.Name)) {
                    membershipType = TLOrgConstants.MEMBERSHIP_TYPE_VIRTUAL;
                }
            }
            account.Membership_Type__c = membershipType;
        }
        update accounts;
    }
}