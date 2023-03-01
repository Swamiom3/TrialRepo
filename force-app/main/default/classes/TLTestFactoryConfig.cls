/**
 * Configuration class for TLTestFactory
 * Defines FieldDefaults providers for different types of SObject
 * @author Grant Adamson, Traction on Demand
 * @date 2018-03-12
 * @group TLTestFactory
 */
@IsTest
public class TLTestFactoryConfig implements TLTestFactory.Configuration {

    public Map<SObjectType, Type> getValuesProviders() {
        return new Map<SObjectType, Type>{
                Lead.SObjectType => TLTestFactoryConfig.LeadDefaults.class,
                Account.SObjectType => TLTestFactoryConfig.AccountDefaults.class,
                Asset.SObjectType => TLTestFactoryConfig.AssetDefaults.class,
                Case.SObjectType => TLTestFactoryConfig.CaseDefaults.class,
                Contact.SObjectType=> TLTestFactoryConfig.ContactDefaults.class,
                EmailMessage.SObjectType=> TLTestFactoryConfig.EmailMessageDefaults.class,
                Group.SObjectType=> TLTestFactoryConfig.GroupDefaults.class,
                GroupMember.SObjectType=> TLTestFactoryConfig.GroupMemberDefaults.class,
                Building__c.SObjectType => TLTestFactoryConfig.BuildingDefaults.class,
                Opportunity.SObjectType => TLTestFactoryConfig.OpportunityDefaults.class,
                User.SObjectType => TLTestFactoryConfig.UserDefaults.class
        };
    }

    /**
     * Standard ValuesProvider implementations for common objects
     * For real use, these should be top level classes for each SObject where test data is needed, and then added to
     * the map above
     */
    public class LeadDefaults implements TLTestFactory.ValuesProvider {
        public Map<Schema.SObjectField, Object> getFieldValues() {
            return new Map<Schema.SObjectField, Object> {
                    Lead.LastName => 'Test Lead',
                    Lead.Company => 'Test Company'
            };
        }
        public Schema.SObjectField getNameField() {
            return Lead.Name;
        }
    }


    public class AccountDefaults implements TLTestFactory.ValuesProvider {
        public Map<Schema.SObjectField, Object> getFieldValues() {
            return new Map<Schema.SObjectField, Object> {
                    Account.Name => 'Test Account'
            };
        }
        public Schema.SObjectField getNameField() {
            return Account.Name;
        }
    }


    public class AssetDefaults implements TLTestFactory.ValuesProvider {
        public Map<Schema.SObjectField, Object> getFieldValues() {
            return new Map<Schema.SObjectField, Object> {
                    Asset.Name => 'Test Asset'
            };
        }
        public Schema.SObjectField getNameField() {
            return Asset.Name;
        }
    }


    public class CaseDefaults implements TLTestFactory.ValuesProvider {
        public Map<Schema.SObjectField, Object> getFieldValues() {
            return new Map<Schema.SObjectField, Object> {
                    Case.Subject => 'Test Case'
            };
        }
        public Schema.SObjectField getNameField() {
            return Case.Subject;
        }
    }


    public class ContactDefaults implements TLTestFactory.ValuesProvider {
        public Map<Schema.SObjectField, Object> getFieldValues() {
            return new Map<Schema.SObjectField, Object> {
                    Contact.FirstName => 'First',
                    Contact.LastName => 'Last',
                    Contact.Member_Type__c => TLPicklist.getPicklistValues('Contact','Member_Type__c')[0],
                    Contact.Member_Role__c => TLPicklist.getPicklistValues('Contact','Member_Role__c')[0]
            };
        }
        public Schema.SObjectField getNameField() {
            return Contact.LastName;
        }
    }


    public class EmailMessageDefaults implements TLTestFactory.ValuesProvider {
        public Map<Schema.SObjectField, Object> getFieldValues() {
            return new Map<Schema.SObjectField, Object> {
                    EmailMessage.Subject => 'Test Subject'
            };
        }
        public Schema.SObjectField getNameField() {
            return EmailMessage.MessageIdentifier;
        }
    }


    public class GroupDefaults implements TLTestFactory.ValuesProvider {
        public Map<Schema.SObjectField, Object> getFieldValues() {
            return new Map<Schema.SObjectField, Object> {
                    Group.Name => 'My Queue',
                    Group.Type => 'Queue'
            };
        }
        public Schema.SObjectField getNameField() {
            return Group.Name;
        }
    }


    public class GroupMemberDefaults implements TLTestFactory.ValuesProvider {
        public Map<Schema.SObjectField, Object> getFieldValues() {
            return new Map<Schema.SObjectField, Object> {};
        }
        public Schema.SObjectField getNameField() {
            return null;
        }
    }

    public class BuildingDefaults implements TLTestFactory.ValuesProvider {
        public Map<Schema.SObjectField, Object> getFieldValues() {
            return new Map<Schema.SObjectField, Object> {
                    Building__c.Name => 'Test Building'
            };
        }
        public Schema.SObjectField getNameField() {
            return Building__c.Name;
        }
    }
    
    public class OpportunityDefaults implements TLTestFactory.ValuesProvider {
        public Map<Schema.SObjectField, Object> getFieldValues() {
            return new Map<Schema.SObjectField, Object> {
                    Opportunity.Name => 'Test Opportunity',
                    Opportunity.StageName => 'Closed Won',
                    Opportunity.CloseDate => System.today()
            };
        }
        public Schema.SObjectField getNameField() {
            return Opportunity.Name;
        }
    }


    public class UserDefaults implements TLTestFactory.ValuesProvider {
        public Map<Schema.SObjectField, Object> getFieldValues() {
            return new Map<Schema.SObjectField, Object> {
                    User.FirstName => 'Uclid',
                    User.LastName => 'Barkley',
                    User.Username => 'ubarkley@my-salesforce-domain.test',
                    User.Email => 'ubarkley@my-salesforce-domain.test',
                    User.Alias => 'ubarkley',
                    User.CommunityNickname => 'ubarkley',
                    User.TimeZoneSidKey => 'America/Los_Angeles',
                    User.LocaleSidKey => 'en_US',
                    User.EmailEncodingKey => 'UTF-8',
                    User.LanguageLocaleKey => 'en_US'
            };
        }
        public Schema.SObjectField getNameField() {
            return User.Name;
        }
    }
}