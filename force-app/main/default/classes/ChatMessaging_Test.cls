@istest
public without sharing class ChatMessaging_Test {
    
    public static Integer count = 0;

    public static Integer getIndex(){
        Integer index = count;
        count += 1;
        return index;
    }

    @TestSetup
    static void makeData(){
        Account a = new Account();
        a.Name = 'test1';
        Account a1 = new Account();
        a1.Name = 'test2';
        Account a2 = new Account(Name = 'test3');
        Account[] accounts = new Account[]{a, a1, a2};
        insert accounts;

        Contact c = new Contact();
        c.FirstName = 'bob';
        c.LastName = 'Dylan';
        c.AccountId = a.Id;
        Contact[] contacts = new Contact[]{c};
        insert contacts;

        Chat__c c1 = newChat(a.Id, null, 1);
        Chat__c c2 = newChat(a.Id, c.Id, 1);
        Chat__c c3 = newChat(a1.Id, null, 5);
        Chat__c c4 = newChat(a2.Id, null, 10);

        List<Chat__c> chats = new List<Chat__c>{c1, c2, c3, c4};
        insert chats;

        Case cs1 = new Case();
        Case[] cases = new Case[]{cs1};
        insert cases;
    }

    @istest
    public static void addNewChat(){
        ChatMessaging chatMessaging = new ChatMessaging();
        ChatMessage message = newMessage(null, getIndex());
        Test.startTest(); 
        Chat__c chat = chatMessaging.add(message);
        Test.stopTest();
        Assert.isTrue(chatMessaging.chatsToCreate.size() == 1, 'we should have a new chat to create');
        List<ChatMessage> messages = chatMessaging.get(chat);
        Assert.isTrue(messages.get(0).body == message.body, 'the returned chat should have a message that matches the message passed to add');
    }

    @istest
    public static void addChatExists(){
        Chat__c chat = [SELECT Id, Context_Parent__c, Context_Child__c FROM Chat__c LIMIT 1];
        ChatMessaging chatMessaging = new ChatMessaging();
        ChatMessage message = newMessage(chat, getIndex());
        Test.startTest();
        Chat__c returnedChat = chatMessaging.add(message);
        Test.stopTest();
        Assert.isTrue(chatMessaging.chatsToUpdate.size() == 1, 'we should have a new chat to create');
        Assert.isTrue(returnedChat.Id == chat.Id, 'Expect the returned chat to have the same chat Id as the chat passed for when only have 1 message on the original chat');
        List<ChatMessage> messages = chatMessaging.get(returnedChat);
        Assert.isTrue(messages.size() == 2, 'expect the updated chat to have 2 messages');
    }

    @istest
    public static void edit(){
        Account a = [SELECT Id, Name FROM Account WHERE Name = 'test1'];
        Chat__c chat = [SELECT Id, OwnerId, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, Context_Parent__c, Context_Child__c, Messages__c, Previous_Chat__c, Read_Receipts__c, Last_Message__c FROM Chat__c WHERE Context_Parent__c =:a.Id LIMIT 1];
        ChatMessaging chatMessaging = new ChatMessaging();
        List<ChatMessage> messages = chatMessaging.get(chat);
        ChatMessage message = messages.get(0);
        message.escalationId = 'escalation';
        Test.startTest();
        Chat__c returnedChat = chatMessaging.edit(message);
        Test.stopTest();
        List<ChatMessage> initialMessages = chatMessaging.get(chatMessaging.initialChats.values());
        Assert.isTrue(initialMessages.get(0).escalationId == null, 'expect the cached initial messages to all have a null escalation Id');
        Assert.isTrue(chatMessaging.chatsToUpdate.size() == 1, 'expect there to be a chat to update');
        List<ChatMessage> returnedMessages = chatMessaging.get(returnedChat);
        Assert.isTrue(returnedMessages.get(0).escalationId == message.escalationId, 'expect the first message to have an updated escalation Id');
    }   

    @istest
    public static void editMultipleMessages(){
        Account a = [SELECT Id FROM Account WHERE Name = 'test3'];
        Chat__c chat = [SELECT Id, OwnerId, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, Context_Parent__c, Context_Child__c, Messages__c, Previous_Chat__c, Read_Receipts__c, Last_Message__c FROM Chat__c WHERE Context_Parent__c =:a.Id LIMIT 1];
        ChatMessaging chatMessaging = new ChatMessaging();
        List<ChatMessage> messages = chatMessaging.get(chat);
        ChatMessage message1 = messages.get(0);
        message1.escalationId = 'escalation1';
        ChatMessage message2 = messages.get(5);
        message1.escalationId = 'escalation1';
        List<ChatMessage> messagesToUpdate = new List<ChatMessage>{message1, message2};
        
        Test.startTest();
        for (ChatMessage message : messagesToUpdate){
            chatMessaging.edit(message);
        }
        chatMessaging.send();
        Test.stopTest();
        Chat__c chatAfter = [SELECT Id, OwnerId, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, Context_Parent__c, Context_Child__c, Messages__c, Previous_Chat__c, Read_Receipts__c, Last_Message__c FROM Chat__c WHERE Context_Parent__c =:a.Id LIMIT 1];
        List<ChatMessage> messagesAfter = chatMessaging.get(chatAfter);
        ChatMessage messageAfter1 = messagesAfter.get(0);
        Assert.areEqual(message1.escalationId,messageAfter1.escalationId,'escalations Ids are expected to be the same');
        ChatMessage messageAfter2 = messagesAfter.get(5);
        Assert.areEqual(message2.escalationId,messageAfter2.escalationId,'escalations Ids are expected to be the same');
    }

    @istest 
    public static void sendUpdatesEdited(){
        Account a = [SELECT Id, Name FROM Account WHERE Name = 'test1'];
        Chat__c chat = [SELECT Id, OwnerId, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, Context_Parent__c, Context_Child__c, Messages__c, Previous_Chat__c, Read_Receipts__c, Last_Message__c FROM Chat__c WHERE Context_Parent__c =:a.Id LIMIT 1];
        ChatMessaging chatMessaging = new ChatMessaging();
        List<ChatMessage> messages = chatMessaging.get(chat);
        ChatMessage message = messages.get(0);
        message.escalationId = 'escalation2';
        Chat__c returnedChat = chatMessaging.edit(message);
        Test.startTest();
        List<ChatMessage> returnedMessages = chatMessaging.send();
        Test.stopTest();
        Assert.areEqual(1,chatMessaging.chatsToUpdate.size(), 'length of chats to update');
    }

    @istest
    public static void sendUpdatesAdded(){
        Account a = [SELECT Id, Name FROM Account WHERE Name = 'test1'];
        Chat__c chat = [SELECT Id, OwnerId, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, Context_Parent__c, Context_Child__c, Messages__c, Previous_Chat__c, Read_Receipts__c, Last_Message__c, Message_Count__c FROM Chat__c WHERE Context_Parent__c =:a.Id LIMIT 1];
        ChatMessaging chatMessaging = new ChatMessaging();
        List<ChatMessage> messages = chatMessaging.get(chat);
        ChatMessage chatMessage = newMessage(chat, messages.size());
        Chat__c returnedChat = chatMessaging.add(chatMessage);
        Test.startTest();
        List<ChatMessage> returnedMessages = chatMessaging.send();
        Test.stopTest();
        Assert.isTrue(returnedMessages.size() == 1, 'expect the returned list of messages to only include 1 messages, but received \'' + returnedMessages.size().toString() +  '\' messages');
        Assert.isTrue(returnedMessages.get(0).body == chatMessage.body);
    }

    @istest 
    public static void getKey(){
        ChatMessaging messaging = new ChatMessaging();

        Chat__c chat = [SELECT Id, Messages__c FROM Chat__c LIMIT 1];
        String key = chat.Id + '0';
        Test.startTest();
        ChatMessage message = messaging.get(key);
        Test.stopTest();
        List<Object> jsonMessages = (List<Object>)JSON.deserializeUntyped(chat.Messages__c);
        Map<String, Object> jsonMessage = (Map<String, Object>)jsonMessages.get(0);
        String messageBody = (String)jsonMessage.get('m');
        Assert.areEqual(messageBody, message.body, 'Returned chat messages body');
        
    }

    @istest 
    public static void getParentContext(){
        Id contextParent = [SELECT Id FROM Account LIMIT 1].Id;
        ChatMessaging chatMessaging = new ChatMessaging();
        Test.startTest();
        List<ChatMessage> messages = chatMessaging.get(contextParent, null);
        Test.stopTest();
        for (ChatMessage message : messages){
            Assert.isTrue(message.contextParent == contextParent, 'Expect the returned chats parent context to be \'' + contextParent+ '\', but received \'' + message.contextParent + '\'');
        }
    }

    @istest
    public static void getChildContext(){
        Id contextParent = [SELECT Id FROM Account LIMIT 1].Id;
        Id contextChild = [SELECT Id FROM Contact LIMIT 1].Id;
        ChatMessaging chatMessaging = new ChatMessaging();
        Test.startTest();
        List<ChatMessage> messages = chatMessaging.get(contextParent, contextChild);
        Test.stopTest();
        for (ChatMessage message : messages){
            Assert.isTrue(message.contextChild == contextChild, 'Expect the returned chats child context to be \'' + contextChild+ '\', but received \'' + message.contextChild + '\'');
        }
    }

    @istest
    public static void getChildContextWithDateRange(){
        Id contextParent = [SELECT Id FROM Account LIMIT 1].Id;
        Id contextChild = [SELECT Id FROM Contact LIMIT 1].Id;
        ChatMessaging chatMessaging = new ChatMessaging();
        Test.startTest();
        List<ChatMessage> messages = chatMessaging.get(contextParent, contextChild, System.today().addDays(-1), System.today().addDays(1));
        Test.stopTest();
        for (ChatMessage message : messages){
            Assert.isTrue(message.contextChild == contextChild, 'Expect the returned chats child context to be \'' + contextChild+ '\', but received \'' + message.contextChild + '\'');
        }
    }

    @istest
    public static void appendExtraData(){
        Case cs1 = [SELECT Id, CaseNumber FROM Case LIMIT 1];
        Contact c1 = [SELECT Id, Name FROM Contact LIMIT 1];

        Chat__c chat = [SELECT Id, Context_Parent__c, Context_Child__c FROM Chat__c WHERE Context_Child__c = :c1.Id LIMIT 1];

        ChatMessage message1 = newMessage(chat, 1);
        message1.escalationId = cs1.Id;
        message1.contextChild = c1.Id;
        List<ChatMessage> messages = new List<ChatMessage>{message1};

        ChatMessaging messaging = new ChatMessaging();
        Test.startTest();
        messaging.appendExtraData(messages);
        Test.stopTest();
        for (ChatMessage message : messages){
            if (message.escalationId == cs1.Id){
                Assert.isTrue(message.escalationRecordName == cs1.CaseNumber, 'Expect the escalation record name to be \'' + cs1.CaseNumber+'\' where the escalation id is \'' + message.escalationId + '\', but recieved \'' +message.escalationRecordName+ '\'');
            }
            if(message.contextChild == c1.Id){
                Assert.isTrue(message.contextChildName == c1.Name, 'Expect the context child name to be \'' + c1.Name + '\', but where the context child Id is \'' + message.contextChild + '\', but received \'' + message.contextChildName + '\'');
            }
            Assert.isTrue (message.author == UserInfo.getName(), 'Expect the author name to be \'' + UserInfo.getName() + '\', but received \'' + message.author + '\'');
        }  
    }

    public static ChatMessage newMessage(Chat__c chat, Integer messageCount){
        ChatMessage message = new ChatMessage();
        message.contextParent = chat?.Context_Parent__c;
        message.contextChild = chat?.Context_Child__c;
        message.body = 'this is the message body' + messageCount;
        message.authorId = UserInfo.getUserId();
        message.chatId = chat?.Id;
        message.key = chat?.Id + messageCount.toString();
        message.createdDatetime = System.now().toString();
        return message;
    }

    public static Chat__c newChat(String parentContext, String childContext, Integer messageCount){
        Chat__c c = new Chat__c();
        c.Context_Parent__c = parentContext;
        c.Context_Child__c = childContext;
        JSONGenerator jsonGen = JSON.createGenerator(false);
        jsonGen.writeStartArray();
        for (Integer i = 0; i < messageCount; i += 1){
            jsonGen.writeStartObject();
            jsonGen.writeStringField('m', 'message text ' + messageCount.toString());
            jsonGen.writeStringField('a', UserInfo.getUserId());
            jsonGen.writeStringField('t', System.now().toString());
            jsonGen.writeBooleanField('s', true);
            jsonGen.writeStringField('i', String.valueOf(i+1));
            jsonGen.writeEndObject();
        }
        c.Messages__c = jsonGen.getAsString();
        c.Last_Message__c = System.now();
        c.Message_Count__c = messageCount;
        return c;
    }
}