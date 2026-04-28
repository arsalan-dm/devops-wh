trigger MessagingSnapshotChildTrigger on Messaging_Snapshot_Child__c (after insert, after update) {
    if (Trigger.isAfter){
        if(Trigger.isInsert){
            MessagingSnapshotChildTriggerHander.onAfterInsert(Trigger.new);
        }
        if (Trigger.isUpdate){
            MessagingSnapshotChildTriggerHander.onAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}