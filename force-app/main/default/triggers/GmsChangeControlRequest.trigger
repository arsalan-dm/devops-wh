trigger GmsChangeControlRequest on FundingAwardAmendment (after update) {
    if (Trigger.isAfter){
        if(Trigger.isUpdate){
            GmsCcrTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}