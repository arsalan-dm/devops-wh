@istest
public with sharing class ChatGetNotificationLinksAction_Test {
    @istest 
    public static void getNotificationLinks_noChildContext(){
        FundingAward fa = new FundingAward();
        insert fa;

        Chat__c chat = ChatMessaging_Test.newChat(fa.Id, null, 1);
        List<Chat__c> chats = new List<Chat__c>{chat};
        
        ChatMessage message1 = new ChatMessage();
        message1.body = 'message text 1';
        message1.contextParent = fa.Id;
        List<ChatMessage> messages = new List<ChatMessage>{message1};


        ChatGetNotificationLinksAction.chatMessaging = (ChatMessaging)Stub.builder()
            .handleMethod('get').with(messages)
            .create(ChatMessaging.class);

        Test.startTest();
        List<ChatGetNotificationLinksAction.Links> links = ChatGetNotificationLinksAction.getNotificationLinks(new List<List<Chat__c>>{chats});
        Test.stopTest();
        ChatGetNotificationLinksAction.Links firstLinks = links.get(0);
        List<String> tableRows = firstLinks.tableRows;
        Assert.isTrue(tableRows.get(0).contains('href="/' + fa.Id + '"'), 'expect the returned row to contain an a tag with a href of /' + fa.Id);
    }

    @istest
    public static void getNotificationLinks_ChildContextWithMultipleMessages(){
        FundingAward fa = new FundingAward();
        insert fa;

        FundingBaseline__c baseline = new FundingBaseline__c(Status__c = 'Active');
        insert baseline;

        FundingBatch__c fb = new FundingBatch__c(Funding_Award__c = fa.Id, Active_Baseline__c = baseline.Id);
        insert fb;

        Chat__c chat = ChatMessaging_Test.newChat(fa.Id, null, 1);
        List<Chat__c> chats = new List<Chat__c>{chat};
        
        ChatMessage message1 = new ChatMessage();
        message1.body = 'message text 1';
        message1.contextParent = fa.Id;
        message1.contextChild = fb.Id;
        String yesterday =  JSON.serialize(Datetime.now().addDays(-1));
        message1.createdDatetime = yesterday.removeStart('"').removeEnd('"');

        ChatMessage latestMessage = new ChatMessage();
        latestMessage.body = 'latest message';
        latestMessage.contextParent = fa.Id;
        latestMessage.contextChild = fb.Id;
        String now =  JSON.serialize(Datetime.now());
        latestMessage.createdDatetime = now.removeStart('"').removeEnd('"');
        List<ChatMessage> messages = new List<ChatMessage>{message1, latestMessage};


        ChatGetNotificationLinksAction.chatMessaging = (ChatMessaging)Stub.builder()
            .handleMethod('get').with(messages)
            .create(ChatMessaging.class);

        Test.startTest();
        List<ChatGetNotificationLinksAction.Links> links = ChatGetNotificationLinksAction.getNotificationLinks(new List<List<Chat__c>>{chats});
        Test.stopTest();
        ChatGetNotificationLinksAction.Links firstLinks = links.get(0);
        List<String> tableRows = firstLinks.tableRows;
        Assert.isTrue(tableRows.get(0).contains('href="/' + fb.Id + '"'), 'expect the returned row to contain an a tag with a href of /' + fb.Id);
        Assert.isTrue(tableRows.get(0).contains(latestMessage.body), 'expect the returned row to contain the body of the latest message on the child context \'' + latestMessage.body + '\'');
    }
}