trigger GmsMilestoneTrigger on Funding_Award_Milestone__c (after insert) {
    if (Trigger.isAfter){
        if (Trigger.isInsert){
            GmsMilestoneTriggerHandler.onAfterInsert(Trigger.new);
        }
    }
}