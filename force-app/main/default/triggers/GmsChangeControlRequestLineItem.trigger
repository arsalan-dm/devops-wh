trigger GmsChangeControlRequestLineItem on Change_Control_Request_Line_Item__c (after insert, after update, after delete) {
    if (Trigger.isAfter){
        if (Trigger.isInsert){
            GmsCcrLineItemTriggerHandler.onAfterInsert(Trigger.new);
        }
        if (Trigger.isUpdate){
            GmsCcrLineItemTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isDelete){
            GmsCcrLineItemTriggerHandler.onAfterDelete(Trigger.oldMap);
        }
    }
}