trigger ServiceAppointmentTriggers on ServiceAppointment (before insert, before update, after insert, after update) {
    new MetadataDrivenTriggerHandler().run();
}