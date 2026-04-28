trigger MessageEventTrigger on Message_Event__e (after insert) {
    if (Trigger.isAfter){
        if (Trigger.isInsert){
            MessageEventTriggerHandler.onAfterInsert(Trigger.new);
        }
    }
}