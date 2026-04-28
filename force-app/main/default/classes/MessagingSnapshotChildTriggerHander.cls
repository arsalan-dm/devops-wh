public with sharing class MessagingSnapshotChildTriggerHander {
    
    public static List<Messaging_Snapshot_Child__c> onAfterInsert(
        List<Messaging_Snapshot_Child__c> newSnapshots
    ){
        aggregateChildSnapshots(newSnapshots);
        return newSnapshots;
    }

    public static List<Messaging_Snapshot_Child__c> onAfterUpdate(
        List<Messaging_Snapshot_Child__c> newSnapshots, 
        Map<Id, Messaging_Snapshot_Child__c> oldSnapshots
    ){
        aggregateChildSnapshots(newSnapshots);
        return newSnapshots;
    }

    public static void aggregateChildSnapshots(List<Messaging_Snapshot_Child__c> snapshots){
        Set<Id> snapshotIds = new Set<Id>();
        for (Messaging_Snapshot_Child__c snapshot : snapshots){
            snapshotIds.add(snapshot.Messaging_Snapshot__c);
        }
        Map<String, Object> bindParams = new Map<String, Object>{'snapshotIds'=>snapshotIds}; 
        List<String> snapshotFields = new List<String>(Schema.Messaging_Snapshot__c.SObjectType.getDescribe().fields.getMap().keySet());
        List<String> snapshotChildFields = new List<String>(Schema.Messaging_Snapshot_Child__c.SObjectType.getDescribe().fields.getMap().keySet());
        String snapshotQuery = 'SELECT ' + String.join(snapshotFields, ',') + 
        ', (SELECT ' + String.join(snapshotChildFields, ',') + ' FROM Messaging_Snapshot_Children__r)'
        + 'FROM Messaging_Snapshot__c WHERE Id IN :snapshotIds';
        List<Messaging_Snapshot__c> snapshotParents = Database.queryWithBinds(
                snapshotQuery, 
                bindParams, 
                AccessLevel.SYSTEM_MODE
            );

        for (Messaging_Snapshot__c snapshotParent : snapshotParents){
            snapshotParent.Number_Of_Messages__c = 0;
            snapshotParent.Number_Of_Unresponded_Messages_By_DP__c = 0;
            snapshotParent.Number_Of_Unread_Messages_By_DP__c = 0;

            Decimal totalResponseTime = 0;
            Decimal totalNumberOfMessagesRespondedTo = 0;
            Decimal totalReadTime = 0;
            Decimal totalNumberOfMessagesRead = 0;
            for (Messaging_Snapshot_Child__c childSnapshot : snapshotParent.Messaging_Snapshot_Children__r){
                snapshotParent.Number_Of_Messages__c += (childSnapshot.Number_Of_Messages__c ?? 0);
                snapshotParent.Number_Of_Unresponded_Messages_By_DP__c += (childSnapshot.Number_Of_Unresponded_Messages_By_DP__c ?? 0);
                snapshotParent.Number_Of_Unread_Messages_By_DP__c += (childSnapshot.Number_Of_Unread_Messages_By_DP__c ?? 0);

                totalNumberOfMessagesRespondedTo += (childSnapshot.Number_Of_Messages_Responded_To_By_DP__c ?? 0);
                totalResponseTime += (childSnapshot.Number_Of_Messages_Responded_To_By_DP__c ?? 0) * (childSnapshot.Average_Response_Time_By_DP__c ?? 0);
                totalNumberOfMessagesRead += (childSnapshot.Number_Of_Messages_Read_By_DP__c ?? 0);
                totalReadTime += (childSnapshot.Number_Of_Messages_Read_By_DP__c ?? 0) * (childSnapshot.Average_Read_Time_By_DP__c ?? 0);

            }
            if (totalNumberOfMessagesRespondedTo != 0){
                snapshotParent.Average_Response_Time_By_DP__c = totalResponseTime / totalNumberOfMessagesRespondedTo;
            }
            if (totalNumberOfMessagesRead != 0){
                snapshotParent.Average_Read_Time_By_DP__c = totalReadTime / totalNumberOfMessagesRead;
            }
            snapshotParent.Number_Of_Threads__c = (snapshotParent?.Messaging_Snapshot_Children__r?.size() ?? 0);

        }
        update snapshotParents;
    }
}