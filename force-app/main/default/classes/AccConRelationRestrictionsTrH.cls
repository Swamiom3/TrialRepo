/************************************************************************************************************************************
    Author       :  Shubham Nandwana   
    @Description :  Create validation for AccountContactRelation records 
    Issue No     :  TWSPG-3535
    ----------------------------------------------------------------------------------------------------------------------------------
    VERSION     DATE                AUTHOR              ISSUE NO        DETAIL
    1           30 August 2021      Shubham Nandwana    TWSPG-3535      Initial Developement              
**************************************************************************************************************************************/
public class AccConRelationRestrictionsTrH extends SObjectTriggerHandler {
    private Set<Id> accountIdsToBeFiltered = new Set<Id>();
    private Set<String> roleNamesToBeFiltered = new Set<String>();
    @TestVisible
    private Map<String,List<AccountContactRelation>> accountRoleToAccConRelations = new Map<String,List<AccountContactRelation>>();
    
    private Map<String,String> roleSettings = new Map<String,String>();
    private final String SUFFIX_COUNT = '_Count';
    private final String SUFFIX_ERROR = '_Error';
    private final String MULTI_SELECT_PICKLIST_SEPERATOR = ';';
    @TestVisible
    private AccountContactRelationSelector accConRelationSelector = new AccountContactRelationSelector();
    
    @TestVisible
    private Map<Id,AccountContactRelation> oldAccConRelationsMap;
    @TestVisible
    private List<AccountContactRelation> newAccConRelations;
    @TestVisible
    private Boolean isUserToBeBypassed;

    public AccConRelationRestrictionsTrH() {
        this((Map<Id,AccountContactRelation>) Trigger.oldMap, (List<AccountContactRelation>) Trigger.new);
        populateRoleSettingWrapperMap();
        checkIsUserToBeBypassed();
    }
    
    @TestVisible
    private AccConRelationRestrictionsTrH(Map<Id,AccountContactRelation> oldAccConRelationsMap,
                                          List<AccountContactRelation> newAccConRelations){
        this.oldAccConRelationsMap = oldAccConRelationsMap;
        this.newAccConRelations = newAccConRelations;
    }
    
    public override void beforeInsert() {
        if(isUserToBeBypassed){
            return;
        }
        List<AccountContactRelation> accConRelRecords = filterAccountContactRelations();
        populateAccountIdsWithRoles();
        validateRolesAccountConRelations(accConRelRecords);
    }
    
    public override void beforeUpdate() {
        if(isUserToBeBypassed){
            return;
        }
        List<AccountContactRelation> accConRelRecords = filterAccountContactRelations();
        populateAccountIdsWithRoles();
        validateRolesAccountConRelations(accConRelRecords);
    }
    
    private void checkIsUserToBeBypassed(){
        this.isUserToBeBypassed = FeatureManagement.checkPermission('Bypass_Account_Contact_Relationship_Restrictions');
    }
    
    private List<AccountContactRelation> filterAccountContactRelations(){
        List<AccountContactRelation> accConRelRecords = new List<AccountContactRelation>();
        for(AccountContactRelation accConRelation : newAccConRelations){
            if(accConRelation.AccountId == null || accConRelation.Roles == null){
                continue;
            }
            for(String role : accConRelation.Roles.split(MULTI_SELECT_PICKLIST_SEPERATOR)){
                roleNamesToBeFiltered.add(role);
                String key = accConRelation.AccountId + role;
                if(!accountRoleToAccConRelations.containsKey(key)){
                    accountRoleToAccConRelations.put(key, new List<AccountContactRelation>());
                }
                accountRoleToAccConRelations.get(key).add(accConRelation);
            }
            if(oldAccConRelationsMap != null && TriggerUtility.isFieldValueChanged(
                accConRelation, oldAccConRelationsMap.get(accConRelation.id), 'Roles')){
                continue;
            }
            accountIdsToBeFiltered.add(accConRelation.AccountId );
            accConRelRecords.add(accConRelation);
        }
        return accConRelRecords;
    }
    
    private void populateAccountIdsWithRoles(){
        for(AccountContactRelation accConRel : getAccConRelationsByAccIdsAndRoleNames()){
            for(String role : accConRel.Roles.split(MULTI_SELECT_PICKLIST_SEPERATOR)){                                            
                String key = accConRel.AccountId+role;
                if(!accountRoleToAccConRelations.containsKey(key)){
                    accountRoleToAccConRelations.put(key, new List<AccountContactRelation>());
                }
                accountRoleToAccConRelations.get(key).add(accConRel);
            }
        }
    }
    
    private List<AccountContactRelation> getAccConRelationsByAccIdsAndRoleNames(){
        return accConRelationSelector
                .getAccountContactRelationsByAccountIdsAndRoles(new List<Id>(accountIdsToBeFiltered),
                                                                new List<String>(roleNamesToBeFiltered));
    }
    
    private void validateRolesAccountConRelations(List<AccountContactRelation> accConRelRecords){       
        for(AccountContactRelation accountConRel : accConRelRecords){
            for(String role : accountConRel.Roles.split(MULTI_SELECT_PICKLIST_SEPERATOR)){
                if(!isRolePresentInConfiguration(role)){
                    continue;
                }
                String key = accountConRel.accountId + role;
                if(accountRoleToAccConRelations.get(key) != null && 
                   accountRoleToAccConRelations.get(key).size() > Integer.valueOf(roleSettings.get(role+SUFFIX_COUNT))){
                       accountConRel.addError(roleSettings.get(role + SUFFIX_ERROR));
                       break;
                   }
            }
        }
    }
    
    private Boolean isRolePresentInConfiguration(String role){
        return roleSettings.containsKey(role+SUFFIX_COUNT);
    }
    
    public void populateRoleSettingWrapperMap(){
        Map<String, Account_Contact_Relation_Setting__mdt> accConRoleSettings = Account_Contact_Relation_Setting__mdt.getAll();
        for(String roleName : accConRoleSettings.keySet()){
            String key = accConRoleSettings.get(roleName).label;
            roleSettings.put(key+SUFFIX_COUNT, String.valueOf(accConRoleSettings.get(roleName).Count__c));
            roleSettings.put(key+SUFFIX_ERROR, accConRoleSettings.get(roleName).Error_Message__c);
        }
    }
}