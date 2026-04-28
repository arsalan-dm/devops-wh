@istest
public with sharing class ChatController_Test {

    public static final String protectedErrorMessage = 'Bad Request';

    @istest
    public static void getMessages_SuccessNoMessages(){
        ChatController.chatAccessController = (ChatAccessController)Stub.builder().create(ChatAccessController.class);
        ChatController.messaging = (ChatMessaging)Stub.builder()
            .handleMethod('get').with(new List<ChatMessage>())
            .create(ChatMessaging.class);

        Test.startTest();
        List<ChatMessage> messages = ChatController.getMessages(null, null);
        Test.stopTest();

        Assert.areEqual(0,messages.size(),'number of messages returnedq');
    }

    @istest
    public static void getMessages_SuccessMessagesSorted(){
        ChatController.chatAccessController = (ChatAccessController)Stub.builder().create(ChatAccessController.class);
        Id accountId = Stub.getId(Schema.Chat__c.getSObjectType());
        ChatMessage m2 = newMessage(Stub.getId(Schema.Chat__c.getSObjectType()), accountId, System.now());
        ChatMessage m1 = newMessage(Stub.getId(Schema.Chat__c.getSObjectType()), accountId, System.now().addDays(-1));
        ChatMessage m3 = newMessage(Stub.getId(Schema.Chat__c.getSObjectType()), accountId, System.now().addDays(1));
        List<ChatMessage> messages = new List<ChatMessage>{m1, m2, m3};

        ChatController.messaging = (ChatMessaging)Stub.builder()
            .handleMethod('get').with(messages)
            .create(ChatMessaging.class);

        Test.startTest();
        List<ChatMessage> receivedMessages = ChatController.getMessages(accountId, null);
        Test.stopTest();
        
        // assert they've been sorted by date
        for (Integer i = 0; i < receivedMessages.size() - 1; i += 1){
            Assert.isTrue(receivedMessages.get(i).created >= receivedMessages.get(i + 1).created, 'Expect the be in date descending order');
        }
    }

    @istest
    public static void getMessages_Failure(){
        ChatController.chatAccessController = (ChatAccessController)Stub.builder()
            .handleMethod('checkCurrentUserAccess').with(new HandledException('error message'))
            .create(ChatAccessController.class);
        String errorMessage = '';
        Test.startTest();
        try{
            List<ChatMessage> messages = ChatController.getMessages(null, null);
        }catch(Exception e){
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.areEqual(protectedErrorMessage, errorMessage, 'error message received from the method');
    }

    @istest
    public static void getMessagesDateRange_success(){
        ChatController.chatAccessController = (ChatAccessController)Stub.builder().create(ChatAccessController.class);
        Id accountId = Stub.getId(Schema.Chat__c.getSObjectType());
        ChatMessage m2 = newMessage(Stub.getId(Schema.Chat__c.getSObjectType()), accountId, System.now());
        ChatMessage m1 = newMessage(Stub.getId(Schema.Chat__c.getSObjectType()), accountId, System.now().addDays(-1));
        ChatMessage m3 = newMessage(Stub.getId(Schema.Chat__c.getSObjectType()), accountId, System.now().addDays(1));
        ChatMessage m4 = newMessage(Stub.getId(Schema.Chat__c.getSObjectType()), accountId, System.now().addDays(2));
        List<ChatMessage> messages = new List<ChatMessage>{m1, m2, m3, m4};

        ChatController.messaging = (ChatMessaging)Stub.builder()
            .handleMethod('get').with(messages)
            .create(ChatMessaging.class);

        Test.startTest();
        List<ChatMessage> messagesReceived = ChatController.getMessagesDateRange(accountId, null, System.today(), System.today().addDays(2));
        Test.stopTest();
        Assert.areEqual(2,messagesReceived.size(), 'number of messages returned');
    }

    @istest
    public static void getMessagesDateRange_Failure(){
        ChatController.chatAccessController = (ChatAccessController)Stub.builder()
            .handleMethod('checkCurrentUserAccess').with(new HandledException('error message'))
            .create(ChatAccessController.class);
        String errorMessage = '';
        Test.startTest();
        try{
            List<ChatMessage> messages = ChatController.getMessagesDateRange(null, null, null, null);
        }catch(Exception e){
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.areEqual(protectedErrorMessage, errorMessage, 'error message received from the method');
    }

    @istest
    public static void createMessage_success(){
        ChatController.chatAccessController = (ChatAccessController)Stub.builder().create(ChatAccessController.class);
        
        ChatMessage message1 = newMessage(
            Stub.getId(Schema.Chat__c.getSObjectType()), 
            Stub.getId(Schema.Account.getSObjectType()), 
            System.now().addDays(-1));
        
        message1.authorId = Stub.getId(Schema.User.getSObjectType());

        ChatController.messaging = (ChatMessaging)Stub.builder()
            .handleMethod('send').with(new List<ChatMessage>{message1})
            .create(ChatMessaging.class);
        
        ChatMessage beforeMessageDatetimeTest = newMessage(null, null, System.now());
        Test.startTest();
        ChatMessage messageResponse = ChatController.createMessage(message1);
        Test.stopTest();
        ChatMessage afterMessageDatetimeTest = newMessage(null, null, System.now());


        // check it has set it to the current user 
        Assert.areEqual(UserInfo.getUserId(), messageResponse.authorId, 'author of the message');
        // check the datetime is correct on the message
        Assert.isTrue(beforeMessageDatetimeTest.created <= messageResponse.created, 'expect the message\'s created date to be the equal or greater than \'' +beforeMessageDatetimeTest.createdDatetime+ '\'');
        Assert.isTrue(messageResponse.created <= afterMessageDatetimeTest.created, 'expect the message\'s created date to be equal or before \'' +afterMessageDatetimeTest.createdDatetime+ '\'');
        // body the same as the submitted message 
        Assert.areEqual(message1.body, messageResponse.body, 'message body text');
    }       

    @istest
    public static void createMessage_failure(){
        ChatController.chatAccessController = (ChatAccessController)Stub.builder()
            .handleMethod('checkCurrentUserAccess').with(new HandledException('error message'))
            .create(ChatAccessController.class);
        String errorMessage = '';
        Test.startTest();
        try{
            ChatMessage messages = ChatController.createMessage(null);
        }catch(Exception e){
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.areEqual(protectedErrorMessage, errorMessage, 'error message received from the method');
    }

    @istest
    public static void editMessage_success(){
        ChatController.chatAccessController = (ChatAccessController)Stub.builder().create(ChatAccessController.class);
        
        ChatMessage message1 = newMessage(
            Stub.getId(Schema.Chat__c.getSObjectType()), 
            Stub.getId(Schema.Account.getSObjectType()), 
            System.now());
        message1.escalationId = Stub.getId(Schema.Case.getSObjectType());
        ChatController.messaging = (ChatMessaging)Stub.builder()
            .handleMethod('send').with(new List<ChatMessage>{message1})
            .create(ChatMessaging.class);

        Test.startTest();
        ChatMessage messageResponse = ChatController.editMessage(message1);
        Test.stopTest();
        Assert.areEqual(message1.body, messageResponse.body, 'message body text');
        Assert.areEqual(message1.escalationId, messageResponse.escalationId, 'message escalation Id');
    }

    @istest
    public static void editMessage_failure(){
        ChatController.chatAccessController = (ChatAccessController)Stub.builder()
            .handleMethod('checkCurrentUserAccess').with(new HandledException('error message'))
            .create(ChatAccessController.class);
        String errorMessage = '';
        Test.startTest();
        try{
            ChatMessage messages = ChatController.editMessage(null);
        }catch(Exception e){
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.areEqual(protectedErrorMessage, errorMessage, 'error message received from the method');
    }

    @istest
    public static void editMessages_success(){
        ChatController.chatAccessController = (ChatAccessController)Stub.builder().create(ChatAccessController.class);
        
        ChatMessage message1 = newMessage(
            Stub.getId(Schema.Chat__c.getSObjectType()), 
            Stub.getId(Schema.Account.getSObjectType()), 
            System.now());
        message1.escalationId = Stub.getId(Schema.Case.getSObjectType());
        List<ChatMessage> messages = new List<ChatMessage>{message1};
        ChatController.messaging = (ChatMessaging)Stub.builder()
            .handleMethod('send').with(messages)
            .create(ChatMessaging.class);

        Test.startTest();
        List<ChatMessage> messagesResponse = ChatController.editMessages(messages);
        Test.stopTest();
        ChatMessage messageResponse = messagesResponse.get(0);
        Assert.areEqual(message1.body, messageResponse.body, 'message body text');
        Assert.areEqual(message1.escalationId, messageResponse.escalationId, 'message escalation Id');
    }


    @istest
    public static void editMessages_failure(){
        ChatController.chatAccessController = (ChatAccessController)Stub.builder()
            .handleMethod('checkCurrentUserAccess').with(new HandledException('error message'))
            .create(ChatAccessController.class);
        String errorMessage = '';
        Test.startTest();
        try{
            List<ChatMessage> messages = ChatController.editMessages(null);
        }catch(Exception e){
            errorMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.areEqual(protectedErrorMessage, errorMessage, 'error message received from the method');
    }

    public static ChatMessage newMessage(String chatId, String parentContext, Datetime created){
        ChatMessage cm = new ChatMessage();
        cm.body = 'test message 1';
        cm.contextParent = parentContext;
        cm.contextChild = Stub.getId(Schema.Contact.getSObjectType());
        cm.chatId = chatId;
        cm.key = chatId+'1';
        cm.createdDatetime = created.toString();
        return cm;
    }

    @IsTest
    public static void oldestMessage(){
        Id parentContext = Stub.getId(Account.getSObjectType());
        Id childContext = Stub.getId(Contact.getSObjectType());

        Chat__c chat1 = new Chat__c();
        chat1.Context_Parent__c = parentContext;
        chat1.Context_Child__c = childContext;
        chat1.First_Message__c = System.now().addDays(-10);

        Chat__c chat2 = new Chat__c();
        chat2.Context_Parent__c = parentContext;
        chat2.Context_Child__c = childContext;
        chat2.First_Message__c = System.now().addDays(-20);
        insert new List<Chat__c>{chat1, chat2};

        Test.startTest();
        String firstMessageIsoDateTime = ChatController.oldestMessage(parentContext, childContext);
        Test.stopTest();
        Assert.areEqual(chat2.First_Message__c.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.000\'Z\''), firstMessageIsoDateTime, 'first message iso datetime');
    }
}