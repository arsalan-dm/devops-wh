trigger FundingAwardTrigger on FundingAward (before insert, before update) {
    if (Trigger.isBefore){
        if (Trigger.isInsert){
            FundingAwardTriggerHandler.onBeforeInsert(Trigger.new);
        }
        if (Trigger.isUpdate){
            FundingAwardTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}