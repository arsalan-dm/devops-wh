trigger AbsBatchTrigger on FundingBatch__c (after update) {
    if (Trigger.isAfter && Trigger.isUpdate){
        AbsBatchTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}