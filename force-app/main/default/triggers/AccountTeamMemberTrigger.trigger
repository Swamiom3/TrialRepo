trigger AccountTeamMemberTrigger on AccountTeamMember (before insert, after insert,
                                                        before update, after update,
                                                        after delete, after undelete) {
    new MetadataDrivenTriggerHandler().run();
}