/*************************************************************************************************************************************
    Author      :   Oleg Krasko
    Description :   This class covers SObjectDataConfigTrH
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE           AUTHOR             DETAIL
    1          16 Feb, 2022    Oleg Krasko        Initial Deployment
**************************************************************************************************************************************/
@isTest
private class SObjectDataConfigTrHTest{

    @isTest
    static void trueDMLTest(){
        SObjectDataConfigTrH sObjConfigHandler = new SObjectDataConfigTrH();    
        Map<String, List<SObject>> testData = prepareTestData();

        Test.startTest();
        insert testData.get('sObjects');
        insert testData.get('sObjectsAdditional');
        insert testData.get('sObjectsAutoNumberNames');
        Test.stopTest();

        List<SObject> allSObjects = testData.get('sObjects');
        allSObjects.addAll(testData.get('sObjectsAutoNumberNames'));
        allSObjects.addAll(testData.get('sObjectsAdditional'));
        allSObjects.addAll(testData.get('parentSObjects'));
        for (SObject sObj : allSObjects) {
            String queryString = String.format('SELECT {0} FROM {1}', new List<Object>{
                sObjConfigHandler.EXTERNAL_ID_API_NAME,
                sObj.getSObjectType().getDescribe().getName()
            });
            //this is predefined list of records to loop over and that's why SOQL in loop
            //eventually it would need to make the same number of SOQLs
            SObject sObjectToCheck = Database.query(queryString);//NOPMD
            System.assert(sObjectToCheck.get(sObjConfigHandler.EXTERNAL_ID_API_NAME) != null, 'External ID should be filled in' + sObj.getSObjectType().getDescribe().getName());
        }
    }

    static Map<String, List<SObject>> prepareTestData(){
        List<SObject> parentSObjects = new List<SObject>();
        ConsumptionSchedule consumpSched = new ConsumptionSchedule(
            Name = 'Test ConsumptionSchedule Name',
            BillingTerm = 1, BillingTermUnit = 'Month',
            Type = 'Range', RatingMethod = 'Tier'
        );
        parentSObjects.add(consumpSched);
        SBQQ__ProductRule__c prodRule = new SBQQ__ProductRule__c(
            Name = 'Test Product Rule Name',
            SBQQ__ErrorMessage__c = 'test error message',
            SBQQ__EvaluationEvent__c = 'Load',
            SBQQ__Scope__c = 'Product',
            SBQQ__Type__c = 'Validation',
            SBQQ__ConditionsMet__c = 'All'
        );
        parentSObjects.add(prodRule);
        SBQQ__PriceRule__c priceRule = new SBQQ__PriceRule__c();
        parentSObjects.add(priceRule);
        sbaa__ApprovalRule__c approvalRule = new sbaa__ApprovalRule__c(
            sbaa__TargetObject__c = 'Opportunity', 
            Name = 'Test Approval Rule Name'
        );
        parentSObjects.add(approvalRule);
        insert parentSObjects;

        List<SObject> sObjects = new List<SObject>();
        List<SObject> sObjectsAdditional = new List<SObject>();
        List<SObject> sObjectsAutoNumberNames = new List<SObject>();
        SObject inputSObject = new sbaa__EmailTemplate__c(Name = 'test Email Template name 0', sbaa__TemplateId__c = 'test template ID');
        sObjects.add(inputSObject);
        inputSObject = new SBQQ__ProductFeature__c(Name = 'test ProductFeature name', SBQQ__Number__c = 1);
        sObjects.add(inputSObject);
        inputSObject = new SFBD__DunningActivity__c(Name = 'test DunningActivity name', Assignee__c = 'Billing Agent', Order__c = 1);
        sObjects.add(inputSObject);
        inputSObject = new SBQQ__ConfigurationRule__c(SBQQ__ProductRule__c = prodRule.Id);
        sObjects.add(inputSObject);
        inputSObject = new SBQQ__CustomAction__c(Name = 'test Custom Action name', SBQQ__DisplayOrder__c = 1);
        sObjects.add(inputSObject);
        inputSObject = new blng__PaymentGateway__c(Name = 'test Payment Gateway name');
        sObjects.add(inputSObject);
        inputSObject = new blng__TaxRule__c(Name = 'test Tax Rule name');
        sObjects.add(inputSObject);
        inputSObject = new blng__RevenueRecognitionRule__c(
            Name = 'test Revenue Recognition name',
            blng__CreateRevenueSchedule__c = 'No'
        );
        sObjects.add(inputSObject);
        inputSObject = new blng__BillingRule__c(
            Name = 'test Billing Rule name',
            blng__GenerateInvoices__c = 'No',
            blng__InitialBillingTrigger__c = 'Order Product Activation Date'
        );
        sObjects.add(inputSObject);

        inputSObject = new Pricebook2(Name = 'test Price Book name');
        sObjectsAdditional.add(inputSObject);
        inputSObject = new sbaa__ApprovalChain__c(Name = 'test Approval Chain name');
        sObjectsAdditional.add(inputSObject);
        inputSObject = new sbaa__ApprovalVariable__c(Name = 'test Approval Variable name');
        sObjectsAdditional.add(inputSObject);
        inputSObject = new sbaa__Approver__c(Name = 'test Approver name');
        sObjectsAdditional.add(inputSObject);
        inputSObject = new SBQQ__CustomScript__c(Name = 'test Custom Script name');
        sObjectsAdditional.add(inputSObject);
        inputSObject = new SBQQ__SummaryVariable__c(Name = 'test Summary Variable name');
        sObjectsAdditional.add(inputSObject);
        inputSObject = new SFBD__DunningMethod__c(Name = 'test Dunning Method name', Dunning_Move_in_Type__c = 'Standard');
        sObjectsAdditional.add(inputSObject);
        inputSObject = new blng__PaymentScheduler__c(
            Name = 'test Payment Scheduler name', 
            blng__Startdateandtime__c = Datetime.now().addDays(5),
            blng__Type__c = 'Once'
        );
        sObjectsAdditional.add(inputSObject);

        inputSObject = new sbaa__ApprovalCondition__c(sbaa__TestedField__c = 'Name', sbaa__ApprovalRule__c = approvalRule.Id);
        sObjectsAutoNumberNames.add(inputSObject);
        inputSObject = new ConsumptionRate(
            ConsumptionScheduleId = consumpSched.Id,
            PricingMethod = 'PerUnit',
            ProcessingOrder = 1,
            Price = 1,
            LowerBound = 1
        );
        sObjectsAutoNumberNames.add(inputSObject);
        inputSObject = new SBQQ__ErrorCondition__c(SBQQ__TestedField__c = 'Group Line Items', SBQQ__Rule__c = prodRule.Id);
        sObjectsAutoNumberNames.add(inputSObject);
        inputSObject = new SBQQ__LookupQuery__c();
        sObjectsAutoNumberNames.add(inputSObject);
        inputSObject = new SBQQ__PriceAction__c(SBQQ__Rule__c = priceRule.Id);
        sObjectsAutoNumberNames.add(inputSObject);
        inputSObject = new SBQQ__PriceCondition__c(SBQQ__Field__c = 'Product Code', SBQQ__Rule__c = priceRule.Id);
        sObjectsAutoNumberNames.add(inputSObject);
        inputSObject = new SBQQ__ProductAction__c(SBQQ__Rule__c = prodRule.Id);
        sObjectsAutoNumberNames.add(inputSObject);
        inputSObject = new Traditional_All_Access_Pricing__c();
        sObjectsAutoNumberNames.add(inputSObject);
        inputSObject = new SBQQ__ProductOption__c(SBQQ__Number__c = 1);
        sObjectsAutoNumberNames.add(inputSObject);
        return new Map<String, List<SObject>>{
            'sObjects' => sObjects,
            'sObjectsAdditional' => sObjectsAdditional,
            'sObjectsAutoNumberNames' => sObjectsAutoNumberNames,
            'parentSObjects' => new List<SObject>{consumpSched, approvalRule, priceRule, prodRule}
        };
    }
}