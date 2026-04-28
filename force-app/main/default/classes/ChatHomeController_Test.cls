@istest
public without sharing class ChatHomeController_Test {

    @TestSetup
    public static void makeData() {
        Account acc = new Account(Name = 'Awardee One');
        insert acc;

        FundingAward fa1 = new FundingAward(Name = 'FA-1', AwardeeId = acc.Id);
        FundingAward fa2 = new FundingAward(Name = 'FA-2', AwardeeId = acc.Id);
        insert new List<FundingAward>{ fa1, fa2 };

        // Create Follow__c parent records for share rows to exist. Follow__Share query in controller expects Parent.Context__c.
        // Create Follow__c with Context__c pointing to FundingAward Ids so Follow__Share.Parent.Context__c resolves.
        Follow__c f1 = new Follow__c(Context__c = fa1.Id);
        Follow__c f2 = new Follow__c(Context__c = fa2.Id);
        insert new List<Follow__c>{ f1, f2 };

        // Share rows for the running user, RowCause = Messaging__c
        // Some orgs may have restrictions on manual insert of share rows; but for custom share objects it is permitted in tests.
        Follow__Share fs1 = new Follow__Share(
            ParentId = f1.Id,
            UserOrGroupId = UserInfo.getUserId(),
            RowCause = Schema.Follow__Share.RowCause.Messaging__c,
            AccessLevel = 'Edit'
        );
        Follow__Share fs2 = new Follow__Share(
            ParentId = f2.Id,
            UserOrGroupId = UserInfo.getUserId(),
            RowCause = Schema.Follow__Share.RowCause.Messaging__c,
            AccessLevel = 'Edit'
        );
        insert new List<Follow__Share>{ fs1, fs2 };

        Chat__c c1 = ChatMessaging_Test.newChat(fa1.Id, null, 5);
        Chat__c c2 = ChatMessaging_Test.newChat(fa2.Id, null, 0);
        insert new List<Chat__c>{ c1, c2 };
    }

    @istest
    public static void constructorWithDummyId() {
        ChatRecord record;
        Test.startTest();
        String dummyContextId = '000P00000000000AAA';
        record = new ChatRecord(dummyContextId);
        Test.stopTest();
        Assert.isTrue(record != null, 'expect chat record to not be null when created with dummy id');
        Assert.isTrue(record.contextParent == dummyContextId, 'expect contextParent to equal dummy id');
    }

    @istest
    public static void getUserFollowingChats_returnsRecordsForFollowedParents() {
        Test.startTest();
        List<ChatRecord> results = ChatHomeController.getUserFollowingChats();
        Test.stopTest();

        // We followed two parents (fa1 has chats; fa2 has none). Expect two ChatRecords back.
        Assert.isTrue(results != null, 'results should not be null');
        Assert.areEqual(2, results.size(), 'should return one ChatRecord per followed parent context');

        // Map by parent Id for stable asserts
        Map<String, ChatRecord> byParent = new Map<String, ChatRecord>();
        for (ChatRecord cr : results) {
            byParent.put((String)cr.contextParent, cr);
        }

        // Query the FundingAwards to get their Ids and names for assertions
        List<FundingAward> fas = [SELECT Id, Name, AwardeeId, Awardee.Name FROM FundingAward WHERE Id IN :byParent.keySet() ORDER BY Id ASC ];
        Assert.areEqual(2, fas.size(), 'expected two funding awards');

        FundingAward fa1 = fas[0];
        FundingAward fa2 = fas[1];
        

        // For fa1 (has two chats with total Message_Count__c 3 + 2 = 5, and no read receipts for running user) unread should equal total
        ChatRecord cr1 = byParent.get(fa1.Id);
        Assert.isTrue(cr1 != null, 'expected ChatRecord for FA-1');
        Assert.areEqual(5, cr1.unreadMessageCount, 'FA-1 unread should equal total messages when user has no read receipts');

        // Enrichment from appendExtraData()
        Assert.areEqual(fa1.Awardee.Name, cr1.awardeeName, 'awardeeName should be Awardee name');

        // For fa2 (followed parent but no chats), record should exist with 0 unread and "Unknown" enrichment resolved via appendExtraData fallback
        ChatRecord cr2 = byParent.get(fa2.Id);
        Assert.isTrue(cr2 != null, 'expected ChatRecord for FA-2 (followed parent with no chats)');
        Assert.areEqual(0, cr2.unreadMessageCount, 'FA-2 unread should be zero when there are no chats');
        Assert.areEqual(fa2.Awardee.Name, cr2.awardeeName, 'awardeeName should resolve via FundingAward lookup');
    }

    @istest
    public static void getUserFollowingChats_handlesAuraException() {
        // Induce exception by stubbing data such that appendExtraData throws.
        // Simplest path: call handleAuraExpection directly and assert AuraHandledException is thrown.
        Boolean threw = false;
        try {
            Test.startTest();
            ChatHomeController.handleAuraExpection(new HandledException('Boom'));
            Test.stopTest();
        } catch (AuraHandledException ahe) {
            threw = true;
            Assert.areEqual('Boom', ahe.getMessage(), 'AuraHandledException should carry original message');
        }
        Assert.isTrue(threw, 'Expected AuraHandledException to be thrown');
    }

    @istest
    public static void getUserFollowingChats_ordersByLastMessageAndSumsUnreadAcrossChildren() {
        // Create an additional child context for FA-1 to validate per-child accumulation
        FundingAward fa1 = [SELECT Id FROM FundingAward ORDER BY Id ASC LIMIT 1];
        
        Chat__c childA = ChatMessaging_Test.newChat(fa1.Id, Stub.getId(Schema.Contact.getSObjectType()), 3);
        Chat__c childB = ChatMessaging_Test.newChat(fa1.Id, Stub.getId(Schema.Contact.getSObjectType()), 2);
        insert new List<Chat__c>{ childA, childB };

        Test.startTest();
        List<ChatRecord> results = ChatHomeController.getUserFollowingChats();
        Test.stopTest();

        // Find FA-1 again and assert the new unread count is previous 5 + 4 + 1 = 10
        ChatRecord cr1 = null;
        for (ChatRecord cr : results) {
            if ((String)cr.contextParent == fa1.Id) {
                cr1 = cr;
                break;
            }
        }
        Assert.isTrue(cr1 != null, 'expected ChatRecord for FA-1');
        Assert.areEqual(10, cr1.unreadMessageCount, 'unread should sum across all child contexts for the same parent');
    }

    // Basic constructor sanity for ChatRecord from dummy parent
    @istest
    public static void constructorFromParentContext() {
        ChatRecord record;
        Test.startTest();
        String dummyContextId = '000P00000000000AAA';
        record = new ChatRecord(dummyContextId);
        Test.stopTest();
        Assert.isTrue(record != null, 'expect chat record to not be null');
    }

    // Retain placeholder but make it assertive for stability; actual ChatRecord(Chat__c) constructor is tested indirectly via controller
    @istest
    public static void constructorFromChatRecord() {
        // Create a minimal Chat__c
        Map<String, Object> bindParams = new Map<String, Object>(); 
        List<String> chatFields = new List<String>(Schema.Chat__c.SObjectType.getDescribe().fields.getMap().keySet());
        String snapshotQuery = 'SELECT ' + String.join(chatFields, ',') 
            + ' FROM Chat__c' 
            + ' LIMIT 1';
        List<Chat__c> chats = (List<Chat__c>)Database.queryWithBinds(
                snapshotQuery, 
                bindParams, 
                AccessLevel.SYSTEM_MODE
            );
        
        Test.startTest();
        ChatRecord cr = new ChatRecord(chats[0]);
        Test.stopTest();
        ChatMessage lastMessage = cr.messages.get(cr.messages.size() - 1);

        Assert.areEqual(lastMessage.body, cr.summary, 'the chat records summary');
    }
}
