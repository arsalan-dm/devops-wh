@IsTest
public with sharing class MessageEventTriggerHandler_Test {


    @TestSetup
    static void setupData() {
        Profile internal = [SELECT Id, Name FROM Profile WHERE Profile.UserLicense.LicenseDefinitionKey = 'SFDC' LIMIT 1];

        Profile external = [SELECT Id, Name FROM Profile WHERE Profile.UserLicense.LicenseDefinitionKey != 'SFDC' LIMIT 1];

        // Create two distinct users. getEventType determines Internal vs External by UserLicense map
        // populated from UserLicense with key 'SFDC'. In tests, we'll create users and rely on handler logic
        // to treat one as Internal via presence in queried licenses (best-effort in test context).
        User internalUser = new User(
            Alias = 'intusr',
            Email = 'internal@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Internal',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Europe/London',
            Username = 'internal' + System.now().getTime() + '@example.com',
            ProfileId = internal.Id
        );
        User externalUser = new User(
            Alias = 'extusr',
            Email = 'external@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'External',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Europe/London',
            Username = 'external' + System.now().getTime() + '@example.com',
            ProfileId = external.Id
        );
        insert new List<User>{ internalUser, externalUser };

        FundingAward fa1 = new FundingAward(Name = 'Funding Award 1');
        FundingAward fa2 = new FundingAward(Name = 'Funding Award 2');
        insert new List<FundingAward>{ fa1, fa2 };

        Contact cc1 = new Contact(LastName = 'Child 1');
        Contact cc2 = new Contact(LastName = 'Child 2');
        insert new List<Contact>{ cc1, cc2 };

        // Do not persist IDs in static variables. Each test will query required IDs explicitly.
    }

    // Helper to fabricate platform event sObject instances for direct handler invocation
    private static Message_Event__e makeEvent(Id authorId, Id parentId, Id childId, String messageId, Datetime whenDt, String body, Id caseId) {
        Message_Event__e evt = new Message_Event__e();
        evt.Author__c = authorId;
        evt.Context_Parent__c = parentId;
        evt.Context_Child__c = childId;
        evt.Message_Id__c = messageId;
        evt.When__c = whenDt;
        evt.Message__c = body;
        evt.Escalation__c = caseId;
        return evt;
    }

    @IsTest
    static void test_onAfterInsert_createsSnapshots_and_Message_forExternal() {
        Datetime t0 = Datetime.now().addMinutes(-10);
        // Query fresh IDs needed for this test
        Id externalUserId = [SELECT Id FROM User WHERE Email = 'external@example.com' LIMIT 1].Id;
        Id fundingAward1Id = [SELECT Id FROM FundingAward LIMIT 1].Id;
        Id contextChild1Id = [SELECT Id FROM Contact WHERE LastName = 'Child 1' LIMIT 1].Id;

        Message_Event__e externalMsg = makeEvent(
            externalUserId, fundingAward1Id, contextChild1Id, 'mid-EXT-1', t0, 'Hello from external', null
        );

        Test.startTest();
        List<Message_Event__e> returned = MessageEventTriggerHandler.onAfterInsert(new List<Message_Event__e>{ externalMsg });
        Test.stopTest();

        Assert.areEqual(1, returned.size(), 'Handler should return the same number of events');

        Date snapshotStart = Date.newInstance(Date.today().year(), Date.today().month(), 1);

        List<Messaging_Snapshot__c> parentSnaps = [
            SELECT Id, Funding_Award__c, Start__c, Status__c
            FROM Messaging_Snapshot__c
            WHERE Funding_Award__c = :fundingAward1Id AND Start__c = :snapshotStart
        ];
        Assert.areEqual(1, parentSnaps.size(), 'Parent snapshot should be created');
        Messaging_Snapshot__c ps = parentSnaps[0];
        Assert.areEqual('Current', ps.Status__c, 'Parent snapshot status');

        List<Messaging_Snapshot_Child__c> childSnaps = [
            SELECT Id, Funding_Award__c, Start__c, Status__c, Number_Of_Messages__c,
                   Number_Of_Unresponded_Messages_By_DP__c, Messaging_Snapshot__c, Context_Child__c
            FROM Messaging_Snapshot_Child__c
            WHERE Context_Child__c = :contextChild1Id AND Start__c = :snapshotStart
        ];
        Assert.areEqual(1, childSnaps.size(), 'Child snapshot should be created');
        Messaging_Snapshot_Child__c cs = childSnaps[0];
        Assert.areEqual(ps.Id, cs.Messaging_Snapshot__c, 'Child snapshot should link to parent snapshot');
        Assert.areEqual(1, cs.Number_Of_Messages__c, 'First message counted on child snapshot');
        Assert.areEqual(1, (Integer)cs.Number_Of_Unresponded_Messages_By_DP__c, 'Unresponded increments for external message');

        List<Message__c> messages = [
            SELECT Id, Author__c, Type__c, Case__c, Funding_Award__c, Message__c, When__c,
                   Messaging_Snapshot__c, Messaging_Snapshot_Child__c, Message_Id__c,
                   Is_Responded__c, Time_to_Respond__c
            FROM Message__c
            WHERE Message_Id__c = 'mid-EXT-1'
        ];
        Assert.areEqual(1, messages.size(), 'Message__c should be created');
        Message__c m = messages[0];
        Assert.areEqual('External', m.Type__c, 'External user should create External message');
        Assert.areEqual(ps.Id, m.Messaging_Snapshot__c, 'Message links to parent snapshot');
        Assert.areEqual(cs.Id, m.Messaging_Snapshot_Child__c, 'Message links to child snapshot');
        Assert.isTrue(m.Is_Responded__c == false, 'Message initially not responded');
        Assert.areEqual(null, m.Time_to_Respond__c, 'No response time until reply');
    }

    @IsTest
    static void test_onAfterInsert_internalReply_updatesRespondedFlags_andAverages() {
        Datetime tExt = Datetime.now().addMinutes(-30);
        Datetime tInt = Datetime.now().addMinutes(-5);

        Id externalUserId = [SELECT Id FROM User WHERE Email = 'external@example.com' LIMIT 1].Id;
        Id internalUserId = [SELECT Id FROM User WHERE Email = 'internal@example.com' LIMIT 1].Id;
        Id fundingAward1Id = [SELECT Id FROM FundingAward LIMIT 1].Id;
        Id contextChild1Id = [SELECT Id FROM Contact WHERE LastName = 'Child 1' LIMIT 1].Id;

        Message_Event__e externalMsg = makeEvent(
            externalUserId, fundingAward1Id, contextChild1Id, 'mid-PAIR-EXT', tExt, 'External message', null
        );
        Message_Event__e internalReply = makeEvent(
            internalUserId, fundingAward1Id, contextChild1Id, 'mid-PAIR-INT', tInt, 'Internal reply', null
        );

        Test.startTest();
        MessageEventTriggerHandler.onAfterInsert(new List<Message_Event__e>{ externalMsg });
        MessageEventTriggerHandler.onAfterInsert(new List<Message_Event__e>{ internalReply });
        Test.stopTest();

        Message__c ext = [
            SELECT Id, Is_Responded__c, Time_to_Respond__c, When__c, Type__c
            FROM Message__c
            WHERE Message_Id__c = 'mid-PAIR-EXT'
            LIMIT 1
        ];
        Assert.areEqual('External', ext.Type__c, 'Sanity check message type');
        Assert.isTrue(ext.Is_Responded__c == true, 'External message should be marked responded');

        Decimal expected = ((tInt.getTime() - tExt.getTime()) / 1000);
        Assert.isTrue(ext.Time_to_Respond__c != null, 'Response time should be set');
        Assert.isTrue(Math.abs((Decimal)ext.Time_to_Respond__c - expected) <= 2, 'Response time should be within tolerance');

        Date snapshotStart = Date.newInstance(Date.today().year(), Date.today().month(), 1);
        Messaging_Snapshot_Child__c cs = [
            SELECT Id, Number_Of_Messages__c, Number_Of_Unresponded_Messages_By_DP__c,
                   Number_Of_Messages_Responded_To_By_DP__c, Average_Response_Time_By_DP__c
            FROM Messaging_Snapshot_Child__c
            WHERE Context_Child__c = :contextChild1Id AND Start__c = :snapshotStart
            LIMIT 1
        ];
        Assert.areEqual(2, cs.Number_Of_Messages__c, 'Two messages after reply');
        Assert.areEqual(0, (Integer)cs.Number_Of_Unresponded_Messages_By_DP__c, 'Unresponded resets on internal reply');
        Assert.areEqual(1, (Integer)cs.Number_Of_Messages_Responded_To_By_DP__c, 'One external message responded');
        Assert.isTrue(Math.abs((Decimal)cs.Average_Response_Time_By_DP__c - expected) <= 2, 'Average response time updated');
    }

    @IsTest
    static void test_onAfterInsert_bulk_multipleContexts_andIdempotentUpserts() {
        Datetime t1 = Datetime.now().addMinutes(-20);
        Datetime t2 = Datetime.now().addMinutes(-10);

        Id externalUserId = [SELECT Id FROM User WHERE Email = 'external@example.com' LIMIT 1].Id;
        Id internalUserId = [SELECT Id FROM User WHERE Email = 'internal@example.com' LIMIT 1].Id;
        Id fundingAward1Id = [SELECT Id FROM FundingAward LIMIT 1].Id;
        Id fundingAward2Id = [SELECT Id FROM FundingAward WHERE Id != :fundingAward1Id LIMIT 1].Id;
        Id contextChild1Id = [SELECT Id FROM Contact WHERE LastName = 'Child 1' LIMIT 1].Id;
        Id contextChild2Id = [SELECT Id FROM Contact WHERE LastName = 'Child 2' LIMIT 1].Id;

        List<Message_Event__e> batch1 = new List<Message_Event__e>{
            makeEvent(externalUserId, fundingAward1Id, contextChild1Id, 'mid-B1-1', t1, 'ext1', null),
            makeEvent(externalUserId, fundingAward2Id, contextChild2Id, 'mid-B1-2', t1, 'ext2', null)
        };
        List<Message_Event__e> batch2 = new List<Message_Event__e>{
            makeEvent(internalUserId, fundingAward1Id, contextChild1Id, 'mid-B1-3', t2, 'int1', null),
            // duplicate id to verify upsert idempotency
            makeEvent(externalUserId, fundingAward2Id, contextChild2Id, 'mid-B1-2', t1, 'ext2-dup', null)
        };

        Test.startTest();
        MessageEventTriggerHandler.onAfterInsert(batch1);
        MessageEventTriggerHandler.onAfterInsert(batch2);
        Test.stopTest();

        Date snapshotStart = Date.newInstance(Date.today().year(), Date.today().month(), 1);

        Integer parentSnapCount = [
            SELECT COUNT()
            FROM Messaging_Snapshot__c
            WHERE Start__c = :snapshotStart AND Funding_Award__c IN :new Set<Id>{ fundingAward1Id, fundingAward2Id }
        ];
        Assert.areEqual(2, parentSnapCount, 'Two parent snapshots expected');

        Integer childSnapCount = [
            SELECT COUNT()
            FROM Messaging_Snapshot_Child__c
            WHERE Start__c = :snapshotStart AND Funding_Award__c IN :new Set<Id>{ fundingAward1Id, fundingAward2Id }
        ];
        Assert.areEqual(2, childSnapCount, 'Two child snapshots expected');

        Map<String, Integer> countsById = new Map<String, Integer>();
        for (AggregateResult ar : [
            SELECT Message_Id__c mid, COUNT(Id) cnt
            FROM Message__c
            WHERE Message_Id__c IN ('mid-B1-1','mid-B1-2','mid-B1-3')
            GROUP BY Message_Id__c
        ]) {
            countsById.put((String)ar.get('mid'), (Integer)ar.get('cnt'));
        }
        Assert.areEqual(1, countsById.get('mid-B1-1'), 'Unique message persisted once');
        Assert.areEqual(1, countsById.get('mid-B1-2'), 'Upsert idempotent on duplicate');
        Assert.areEqual(1, countsById.get('mid-B1-3'), 'Unique message persisted once');

        Message__c ext1 = [SELECT Id, Is_Responded__c FROM Message__c WHERE Message_Id__c = 'mid-B1-1' LIMIT 1];
        Assert.isTrue(ext1.Is_Responded__c == true, 'External message in context1 responded by internal follow-up');
    }

    @IsTest
    static void test_getEventType_internal_vs_external() {
        Datetime t0 = Datetime.now().addMinutes(-1);
        Id externalUserId = [SELECT Id FROM User WHERE Email = 'external@example.com' LIMIT 1].Id;
        Id internalUserId = [SELECT Id FROM User WHERE Email = 'internal@example.com' LIMIT 1].Id;
        Id fundingAward1Id = [SELECT Id FROM FundingAward LIMIT 1].Id;
        Id contextChild1Id = [SELECT Id FROM Contact WHERE LastName = 'Child 1' LIMIT 1].Id;

        List<Message_Event__e> events = new List<Message_Event__e>{
            makeEvent(internalUserId, fundingAward1Id, contextChild1Id, 'mid-TYPE-INT', t0, 'int', null),
            makeEvent(externalUserId, fundingAward1Id, contextChild1Id, 'mid-TYPE-EXT', t0, 'ext', null)
        };

        Test.startTest();
        MessageEventTriggerHandler.onAfterInsert(events);
        Test.stopTest();

        Message__c internalMessage = [SELECT Id , Type__c FROM Message__c WHERE Message_Id__c = 'mid-TYPE-INT' LIMIT 1];
        Message__c externalMessage = [SELECT Id , Type__c FROM Message__c WHERE Message_Id__c = 'mid-TYPE-EXT' LIMIT 1];
        Assert.areEqual('Internal', internalMessage.Type__c, 'Internal user should produce Internal type');
        Assert.areEqual('External', externalMessage.Type__c, 'External user should produce External type');
    }

    @IsTest
    static void test_sortReadMessages_marks_messages_read_and_updates_child_snapshot_average() {
        // Arrange: create an External message, then a read event by Internal on same child context
        Datetime tExt = Datetime.now().addMinutes(-25);
        Datetime tRead = Datetime.now().addMinutes(-5);

        Id externalUserId = [SELECT Id FROM User WHERE Email = 'external@example.com' LIMIT 1].Id;
        Id internalUserId = [SELECT Id FROM User WHERE Email = 'internal@example.com' LIMIT 1].Id;
        Id fundingAward1Id = [SELECT Id FROM FundingAward LIMIT 1].Id;
        Id contextChild1Id = [SELECT Id FROM Contact WHERE LastName = 'Child 1' LIMIT 1].Id;

        // First insert external message (unread)
        Message_Event__e externalMsg = makeEvent(
            externalUserId, fundingAward1Id, contextChild1Id, 'mid-READ-1', tExt, 'External message before read', null
        );

        // Create a "read" event for same child context; Is_Read__c=true is what onAfterInsert uses to route to sortReadMessages
        Message_Event__e readEvt = new Message_Event__e();
        readEvt.Author__c = internalUserId; // internal reading external message
        readEvt.Context_Parent__c = fundingAward1Id;
        readEvt.Context_Child__c = contextChild1Id;
        readEvt.Message_Id__c = 'mid-READ-ACK';
        readEvt.When__c = tRead;
        readEvt.Message__c = 'read';
        readEvt.Is_Read__c = true;

        Test.startTest();
        // Insert initial message (unread path -> creates Message__c and child snapshot)
        MessageEventTriggerHandler.onAfterInsert(new List<Message_Event__e>{ externalMsg });
        // Now send read event (read path -> invokes sortReadMessages)
        MessageEventTriggerHandler.onAfterInsert(new List<Message_Event__e>{ readEvt });
        Test.stopTest();

        // Assert: the external message should be marked read with correct time to read and child snapshot averages updated
        Message__c ext = [
            SELECT Id, Is_Read__c, Time_to_Read__c, When__c, Type__c, Messaging_Snapshot_Child__c
            FROM Message__c
            WHERE Message_Id__c = 'mid-READ-1'
            LIMIT 1
        ];
        Assert.areEqual('External', ext.Type__c, 'Sanity check type of created message');
        Assert.isTrue(ext.Is_Read__c, 'Message should be marked as read after read event');

        Decimal expectedSecs = (tRead.getTime() - tExt.getTime()) / 1000;
        Assert.isTrue(ext.Time_to_Read__c != null, 'Time_to_Read__c should be set');
        Assert.isTrue(Math.abs((Decimal)ext.Time_to_Read__c - expectedSecs) <= 2, 'Time_to_Read__c should be within tolerance');

        Date snapshotStart = Date.newInstance(Date.today().year(), Date.today().month(), 1);
        Messaging_Snapshot_Child__c cs = [
            SELECT Id, Average_Read_Time_By_DP__c, Number_Of_Messages_Read_By_DP__c, Start__c, Context_Child__c
            FROM Messaging_Snapshot_Child__c
            WHERE Id = :ext.Messaging_Snapshot_Child__c AND Start__c = :snapshotStart
            LIMIT 1
        ];
        Assert.areEqual(1, (Integer)cs.Number_Of_Messages_Read_By_DP__c, 'One external message read by DP should be counted');
        Assert.isTrue(Math.abs((Decimal)cs.Average_Read_Time_By_DP__c - expectedSecs) <= 2, 'Average read time should reflect read event');
    }

    @IsTest
    static void test_sortReadMessages_multiple_messages_accumulate_average() {
        // Arrange: two external messages then one internal read event. Only External messages contribute to averages.
        Datetime tExt1 = Datetime.now().addMinutes(-40);
        Datetime tExt2 = Datetime.now().addMinutes(-35);
        Datetime tRead = Datetime.now().addMinutes(-10);

        Id externalUserId = [SELECT Id FROM User WHERE Email = 'external@example.com' LIMIT 1].Id;
        Id internalUserId = [SELECT Id FROM User WHERE Email = 'internal@example.com' LIMIT 1].Id;
        Id fundingAward1Id = [SELECT Id FROM FundingAward LIMIT 1].Id;
        Id contextChild1Id = [SELECT Id FROM Contact WHERE LastName = 'Child 1' LIMIT 1].Id;

        // Insert two external messages
        List<Message_Event__e> extBatch = new List<Message_Event__e>{
            makeEvent(externalUserId, fundingAward1Id, contextChild1Id, 'mid-READ-2A', tExt1, 'extA', null),
            makeEvent(externalUserId, fundingAward1Id, contextChild1Id, 'mid-READ-2B', tExt2, 'extB', null)
        };

        // Read event from internal for same child
        Message_Event__e readEvt = new Message_Event__e();
        readEvt.Author__c = internalUserId;
        readEvt.Context_Parent__c = fundingAward1Id;
        readEvt.Context_Child__c = contextChild1Id;
        readEvt.Message_Id__c = 'mid-READ-ACK2';
        readEvt.When__c = tRead;
        readEvt.Message__c = 'read';
        readEvt.Is_Read__c = true;

        Test.startTest();
        MessageEventTriggerHandler.onAfterInsert(extBatch);
        MessageEventTriggerHandler.onAfterInsert(new List<Message_Event__e>{ readEvt });
        Test.stopTest();

        // Assert: both external messages should be marked read and average computed across both
        Map<String, Message__c> messages = new Map<String, Message__c>();
        for (Message__c m : [
            SELECT Id, Message_Id__c, Is_Read__c, Time_to_Read__c, Type__c, Messaging_Snapshot_Child__c
            FROM Message__c
            WHERE Message_Id__c IN ('mid-READ-2A','mid-READ-2B')
        ]) {
            messages.put(m.Message_Id__c, m);
        }
        Assert.isTrue(messages.get('mid-READ-2A').Is_Read__c, 'First message marked read');
        Assert.isTrue(messages.get('mid-READ-2B').Is_Read__c, 'Second message marked read');

        Decimal expected1 = (tRead.getTime() - tExt1.getTime()) / 1000;
        Decimal expected2 = (tRead.getTime() - tExt2.getTime()) / 1000;
        Decimal avg = (expected1 + expected2) / 2;

        Date snapshotStart = Date.newInstance(Date.today().year(), Date.today().month(), 1);
        Messaging_Snapshot_Child__c cs = [
            SELECT Id, Average_Read_Time_By_DP__c, Number_Of_Messages_Read_By_DP__c
            FROM Messaging_Snapshot_Child__c
            WHERE Id = :messages.get('mid-READ-2A').Messaging_Snapshot_Child__c AND Start__c = :snapshotStart
            LIMIT 1
        ];
        Assert.areEqual(2, (Integer)cs.Number_Of_Messages_Read_By_DP__c, 'Two external messages read by DP should be counted');
        Assert.isTrue(Math.abs((Decimal)cs.Average_Read_Time_By_DP__c - avg) <= 2, 'Average read time should reflect both messages');
    }

    @IsTest
    static void test_sortReadMessages_ignores_internal_messages_for_average() {
        // Arrange: internal message then internal read event; internal messages do not contribute to Average_Read_Time_By_DP__c
        Datetime tInt = Datetime.now().addMinutes(-20);
        Datetime tRead = Datetime.now().addMinutes(-5);

        Id internalUserId = [SELECT Id FROM User WHERE Email = 'internal@example.com' LIMIT 1].Id;
        Id externalUserId = [SELECT Id FROM User WHERE Email = 'external@example.com' LIMIT 1].Id;
        Id fundingAward1Id = [SELECT Id FROM FundingAward LIMIT 1].Id;
        Id contextChild1Id = [SELECT Id FROM Contact WHERE LastName = 'Child 1' LIMIT 1].Id;

        // Create an internal message (author internal)
        Message_Event__e intMsg = makeEvent(internalUserId, fundingAward1Id, contextChild1Id, 'mid-READ-INT', tInt, 'internal', null);

        // Read event authored by external user (reading internal message)
        Message_Event__e readEvt = new Message_Event__e();
        readEvt.Author__c = externalUserId; // external reading internal message
        readEvt.Context_Parent__c = fundingAward1Id;
        readEvt.Context_Child__c = contextChild1Id;
        readEvt.Message_Id__c = 'mid-READ-ACK3';
        readEvt.When__c = tRead;
        readEvt.Message__c = 'read';
        readEvt.Is_Read__c = true;

        Test.startTest();
        MessageEventTriggerHandler.onAfterInsert(new List<Message_Event__e>{ intMsg });
        MessageEventTriggerHandler.onAfterInsert(new List<Message_Event__e>{ readEvt });
        Test.stopTest();

        // Internal message is marked read but should not affect DP average metrics
        Message__c internalMessage = [
            SELECT Id, Is_Read__c, Time_to_Read__c, Type__c, Messaging_Snapshot_Child__c
            FROM Message__c
            WHERE Message_Id__c = 'mid-READ-INT'
            LIMIT 1
        ];
        Assert.areEqual('Internal', internalMessage.Type__c, 'Sanity check type internal');
        Assert.isTrue(internalMessage.Is_Read__c, 'Internal message should be marked read');

        Date snapshotStart = Date.newInstance(Date.today().year(), Date.today().month(), 1);
        Messaging_Snapshot_Child__c cs = [
            SELECT Id, Average_Read_Time_By_DP__c, Number_Of_Messages_Read_By_DP__c
            FROM Messaging_Snapshot_Child__c
            WHERE Id = :internalMessage.Messaging_Snapshot_Child__c AND Start__c = :snapshotStart
            LIMIT 1
        ];
        // Because only External messages contribute to DP average in handler
        Assert.isTrue((cs.Number_Of_Messages_Read_By_DP__c == null) || (Integer)cs.Number_Of_Messages_Read_By_DP__c == 0,
            'No DP read count should be recorded for internal message reads');
        Assert.isTrue((cs.Average_Read_Time_By_DP__c == null) || (Decimal)cs.Average_Read_Time_By_DP__c == 0,
            'No DP average should be recorded for internal message reads');
    }
}
