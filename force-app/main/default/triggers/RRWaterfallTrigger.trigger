trigger RRWaterfallTrigger on RightRev__Revenue_Contract_Waterfall__c (after insert, after update) {
    new MetadataDrivenTriggerHandler().run();
}