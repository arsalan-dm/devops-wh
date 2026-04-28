@istest
public with sharing class MessagingSnapshotChildTH_Test {

    @TestSetup
    public static void makeData(){
        Date snapshotPeriod = Date.newInstance(Date.today().year(), Date.today().month(), 1);
        String period = String.valueOf(snapshotPeriod).split(' ')[0];
        FundingAward fa = new FundingAward();
        insert fa;
        
        Messaging_Snapshot__c ms = new Messaging_Snapshot__c();
        ms.Funding_Award__c = fa.Id;
        ms.Status__c = 'Current';
        ms.Start__c = snapshotPeriod;
        ms.Snapshot_Id__c = fa.Id + period;
        insert ms;

        List<Messaging_Snapshot_Child__c> mscs = new List<Messaging_Snapshot_Child__c>();
        Messaging_Snapshot_Child__c msc = new Messaging_Snapshot_Child__c();
        msc.Funding_Award__c = fa.Id;
        msc.Status__c = 'Current';
        msc.Start__c = snapshotPeriod;
        msc.Snapshot_Id__c = Stub.getId(Schema.Account.getSObjectType()) + period;
        msc.Messaging_Snapshot__c = ms.Id;
        mscs.add(msc);
        insert mscs;
    }

    @istest
    public static void aggregateChildSnapshots_ResponseTime(){
        Date snapshotPeriod = Date.newInstance(Date.today().year(), Date.today().month(), 1);
        String period = String.valueOf(snapshotPeriod).split(' ')[0];
        Messaging_Snapshot__c ms = getMessagingSnapshot();
        Messaging_Snapshot_Child__c snapshot = new Messaging_Snapshot_Child__c();
        snapshot.Messaging_Snapshot__c = ms.Id;
        snapshot.Number_Of_Messages__c = 6;
        snapshot.Number_Of_Messages_Responded_To_By_DP__c = 4;
        snapshot.Average_Response_Time_By_DP__c = 100;
        snapshot.Number_Of_Unresponded_Messages_By_DP__c = 1;
        snapshot.Snapshot_Id__c = Stub.getId(Schema.Opportunity.getSObjectType()) + period;

        Messaging_Snapshot_Child__c snapshot2 = new Messaging_Snapshot_Child__c();
        snapshot2.Messaging_Snapshot__c = ms.Id;
        snapshot2.Number_Of_Messages__c = 7;
        snapshot2.Number_Of_Messages_Responded_To_By_DP__c = 4;
        snapshot2.Average_Response_Time_By_DP__c = 200;
        snapshot2.Number_Of_Unresponded_Messages_By_DP__c = 2;
        snapshot2.Snapshot_Id__c = Stub.getId(Schema.Opportunity.getSObjectType()) + period;

        insert new List<Messaging_Snapshot_Child__c>{snapshot, snapshot2};

        Test.startTest();
        MessagingSnapshotChildTriggerHander.aggregateChildSnapshots(new List<Messaging_Snapshot_Child__c>{snapshot, snapshot2});
        Test.stopTest();
        
        Messaging_Snapshot__c msAfter = getMessagingSnapshot(ms.Id);
        Assert.areEqual(3, msAfter.Number_Of_Unresponded_Messages_By_DP__c, 'parent snapshot number of unresponded messages');
        Assert.areEqual(13, msAfter.Number_Of_Messages__c, 'parent snapshot number of messages');
        Assert.areEqual(150, msAfter.Average_Response_Time_By_DP__c, 'parent snapshot average response time');
    } 

    @istest
    public static void aggregateChildSnapshots_ReadTime(){
        Date snapshotPeriod = Date.newInstance(Date.today().year(), Date.today().month(), 1);
        String period = String.valueOf(snapshotPeriod).split(' ')[0];
        Messaging_Snapshot__c ms = getMessagingSnapshot();
        Messaging_Snapshot_Child__c snapshot = new Messaging_Snapshot_Child__c();
        snapshot.Messaging_Snapshot__c = ms.Id;
        snapshot.Number_Of_Messages__c = 5;
        snapshot.Number_Of_Messages_Read_By_DP__c = 3;
        snapshot.Average_Read_Time_By_DP__c = 100;
        snapshot.Number_Of_Unread_Messages_By_DP__c = 1;
        snapshot.Snapshot_Id__c = Stub.getId(Schema.Asset.getSObjectType()) + period;

        Messaging_Snapshot_Child__c snapshot2 = new Messaging_Snapshot_Child__c();
        snapshot2.Messaging_Snapshot__c = ms.Id;
        snapshot2.Number_Of_Messages__c = 5;
        snapshot2.Number_Of_Messages_Read_By_DP__c = 3;
        snapshot2.Average_Read_Time_By_DP__c = 500;
        snapshot2.Number_Of_Unread_Messages_By_DP__c = 1;
        snapshot2.Snapshot_Id__c = Stub.getId(Schema.Asset.getSObjectType()) + period;

        insert new List<Messaging_Snapshot_Child__c>{snapshot, snapshot2};
        
        Test.startTest();
        MessagingSnapshotChildTriggerHander.aggregateChildSnapshots(new List<Messaging_Snapshot_Child__c>{snapshot, snapshot2});
        Test.stopTest();
        Messaging_Snapshot__c msAfter = getMessagingSnapshot(ms.Id);
        Assert.areEqual(2, msAfter.Number_Of_Unread_Messages_By_DP__c, 'parent snapshot number of unread messages');
        Assert.areEqual(10, msAfter.Number_Of_Messages__c, 'parent snapshot number of messages');
        Assert.areEqual(300, msAfter.Average_Read_Time_By_DP__c, 'parent snapshot average read time');
    } 

    @istest
    public static void onAfterInsert(){
        Date snapshotPeriod = Date.newInstance(Date.today().year(), Date.today().month(), 1);
        String period = String.valueOf(snapshotPeriod).split(' ')[0];
        Messaging_Snapshot__c ms = getMessagingSnapshot();
        Messaging_Snapshot_Child__c snapshot = new Messaging_Snapshot_Child__c();
        snapshot.Messaging_Snapshot__c = ms.Id;
        snapshot.Number_Of_Messages__c = 3;
        snapshot.Number_Of_Messages_Responded_To_By_DP__c = 2;
        snapshot.Average_Response_Time_By_DP__c = 200;
        snapshot.Number_Of_Unresponded_Messages_By_DP__c = 0;
        snapshot.Snapshot_Id__c = Stub.getId(Schema.Contact.getSObjectType()) + period;
        Test.startTest();
        insert snapshot;
        Test.stopTest();
        Messaging_Snapshot__c msAfter = getMessagingSnapshot(ms.Id);

        Assert.areEqual((ms.Number_Of_Threads__c ?? 0) + 1, msAfter.Number_Of_Threads__c, 'the number of threads on the award should have increased by 1 on insert');
    }

    @istest
    public static void onAfterUpdate(){
        Messaging_Snapshot__c ms = [SELECT Id, Number_Of_Threads__c, Number_Of_Messages__c, (SELECT Id, Number_Of_Messages__c FROM Messaging_Snapshot_Children__r) FROM Messaging_Snapshot__c WHERE Id IN (SELECT Messaging_Snapshot__c FROM Messaging_Snapshot_Child__c) LIMIT 1];
        Messaging_Snapshot_Child__c msc = ms.Messaging_Snapshot_Children__r.get(0);
        msc.Number_Of_Messages__c += 1;
        Test.startTest();
        update msc;
        Test.stopTest();
        Messaging_Snapshot__c msAfter = getMessagingSnapshot(ms.Id);
        Assert.areEqual(ms.Number_Of_Threads__c, msAfter.Number_Of_Threads__c, 'the number of threads on the award should not increased by 1 on update');
        Assert.areEqual(ms.Number_Of_Messages__c + 1, msAfter.Number_Of_Messages__c, 'the number of messages the parent snapshot should have after the update');
    }

    public static Messaging_Snapshot__c getMessagingSnapshot(){
        return getMessagingSnapshot(null);
    }

    public static Messaging_Snapshot__c getMessagingSnapshot(Id snapshotId){
        Map<String, Object> bindParams = new Map<String, Object>{'snapshotId'=>snapshotId}; 
        String whereClause = ' WHERE Id = :snapshotId ';
        if (snapshotId == null){
            whereClause = '';
        }
        List<String> snapshotFields = new List<String>(Schema.Messaging_Snapshot__c.SObjectType.getDescribe().fields.getMap().keySet());
        String snapshotQuery = 'SELECT ' + String.join(snapshotFields, ',') + ' FROM Messaging_Snapshot__c ' + whereClause + ' LIMIT 1';
        List<Messaging_Snapshot__c> snapshots =
            (List<Messaging_Snapshot__c>)Database.queryWithBinds(
                snapshotQuery, 
                bindParams, 
                AccessLevel.SYSTEM_MODE
            );
        return snapshots.get(0);
    }
}