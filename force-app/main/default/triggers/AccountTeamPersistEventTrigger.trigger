trigger AccountTeamPersistEventTrigger on Account_Team_Persistence__e (after insert){
    new MetadataDrivenTriggerHandler().run();
}