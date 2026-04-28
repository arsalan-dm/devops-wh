public without sharing class ChatMessaging {
    @testvisible
    private List<Chat__c> chatsToCreate = new List<Chat__c>();
    @testvisible
    private Map<Id, Chat__c> chatsToUpdate = new Map<Id, Chat__c>();
    @testvisible
    private Map<Id, Chat__c> initialChats = new Map<Id, Chat__c>();

    public List<ChatMessage> newMessages = new List<ChatMessage>();
    public ChatReadReceiptService readReceiptService = new ChatReadReceiptService();

    // adding chat messages breaks at about 150 messages in one Apex transaction 
    // due to CPU time when doing the send method
    public Set<Chat__c> add(List<ChatMessage> messages){
        Set<Id> chatIds = new Set<Id>();
        for (ChatMessage message : messages){
            chatIds.add(message.chatId);
        }
        this.newMessages.addAll(messages);
        Map<Id, Chat__c> chats = new Map<Id, Chat__c>([SELECT Id, OwnerId, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, Context_Parent__c, Context_Child__c, Messages__c, Previous_Chat__c, Read_Receipts__c, First_Message__c, Last_Message__c, Message_Count__c FROM Chat__c WHERE Id IN :chatIds WITH SECURITY_ENFORCED]);
        Map<String, Chat__c> amendedChats = new Map<String, Chat__c>();
        Set<Chat__c> responseChats = new Set<Chat__c>();
        for (ChatMessage message : messages){
            Chat__c currentChat = amendedChats.get(message.specificContext()) ?? chats.get(message.chatId);
            Chat__c reponseChat = add(message, currentChat);
            amendedChats.put(message.specificContext(), reponseChat);
            responseChats.add(reponseChat);
        }
        return responseChats;
    }

    public Chat__c add(ChatMessage message){
        List<Chat__c> chats = [SELECT Id, OwnerId, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, Context_Parent__c, Context_Child__c, Messages__c, Previous_Chat__c, Read_Receipts__c, First_Message__c, Last_Message__c, Message_Count__c FROM Chat__c WHERE Id = :message.chatId WITH SECURITY_ENFORCED LIMIT 1];
        Chat__c chat;
        if (chats.size() == 0){
            return add(message, null);
        }else{  
            chat = chats.get(0);
            if (chat.Context_Parent__c != message.contextParent){
                throw new HandledException('chat does not belong to the context parent');
            }
            return add(message, chats.get(0));
        }
    }

    public Chat__c add(ChatMessage message, Chat__c chat){
        JsonUtil jsonUtil = new JsonUtil(false, true); // outerarray and not pretty
        List<Message> messages = new List<Message>();
        this.newMessages.add(message);
        if (chat == null){
            chat = new Chat__c();
            chat.Context_Parent__c = message.contextParent;
            chat.Context_Child__c = message.contextChild;
            chat.First_Message__c = System.now();
            chat.Last_Message__c = System.now();
            chat.Message_Count__c = 1;
            //chat.Read_Receipts__c = UserInfo.getUserId(); // reset read receipts field
            chatsToCreate.add(chat);
        }else{
            Chat__c initialChat = chat.clone(true, true, true, true);
            initialChats.put(initialChat.Id, initialChat);
            //sendEmailNotifications(message, initialChat);
            chat.Last_Message__c = System.now();
            chat.Message_Count__c = (chat.Message_Count__c ?? 0) + 1;
            //chat.Read_Receipts__c = UserInfo.getUserId(); // reset read receipts field
            if(chatsToUpdate.get(chat.Id) == null){
                chatsToUpdate.put(chat.Id, chat);
            }else{
                chat = chatsToUpdate.get(chat.Id); 
            }

            messages = (List<Message>)JSON.deserialize(chat.Messages__c, List<Message>.class);
        }

        readReceiptService.add(String.valueOf(chat.Message_Count__c), chat);
        message.messageNumber = (Integer)chat.Message_Count__c;
        messages.add(new Message(message));
        
        return newMessageCharacterLimitCheck(chat, messages, message);
    }

    // I've taken out some tech debt and not bulkified this
    public Chat__c edit(ChatMessage message){
        
        Chat__c chat;
        if(chatsToUpdate.get(message.chatId) == null){
            chat = [SELECT Id, OwnerId, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, Context_Parent__c, Context_Child__c, Messages__c, Previous_Chat__c, Read_Receipts__c, First_Message__c, Last_Message__c, Message_Count__c FROM Chat__c WHERE Id = :message.chatId WITH SECURITY_ENFORCED];
            chatsToUpdate.put(chat.Id, chat);
            Chat__c initialChat = chat.clone(true, true, true, true);
            initialChats.put(initialChat.Id, initialChat);
        }else{
            chat = chatsToUpdate.get(message.chatId);
        }

        // loop here instead of passing the count of each message to the client and back
        Map<String,Message> messages = new Map<String, Message>();
        for (Message currentMessage : (List<Message>)JSON.deserialize(chat.Messages__c, List<Message>.class)){
            messages.put(currentMessage.i, currentMessage);
        }
        messages.put(String.valueOf(message.messageNumber), new Message(message));
        
        return editMessageCharacterLimitCheck(chat, messages.values(), message);
    }

    public List<ChatMessage> send(){
        // returns a list of new messages
        if (chatsToCreate != null){
            insert chatsToCreate;
        }
        if (chatsToUpdate != null){
            update chatsToUpdate.values();
        }
        // loop over newMessages and publish events for them 
        List<Message_Event__e> events = new List<Message_Event__e>();
        for (ChatMessage message : newMessages){
            if (message.chatId != null){
                events.add(createEventMessage(message));
            }
        }
        for (ChatMessage message : get(chatsToCreate)){
            events.add(createEventMessage(message));
        }
        EventBus.publish(events);
        return newMessages;
    }

    public Message_Event__e createEventMessage(ChatMessage message){
        Message_Event__e event = new Message_Event__e();
        event.Author__c = message.authorId;
        event.Chat__c = message.chatId;
        event.Context_Child__c = message.contextChild;
        if (message.contextChild == null){ // makes reporting around number of unresponded messages easier
            event.Context_Child__c = message.contextParent;
        }
        event.Context_Parent__c = message.contextParent;
        event.Escalation__c = message.escalationId;
        event.Message__c = message.body;
        event.When__c = message.created;
        event.Message_Id__c = message.chatId + String.valueOf(message.messageNumber);
        return event;
    }

    public ChatMessage get(String key){
        Id chatId = key.left(18);
        List<Chat__c> chats = [SELECT Id, OwnerId, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, Context_Parent__c, Context_Child__c, Messages__c, Previous_Chat__c, Read_Receipts__c, First_Message__c, Last_Message__c, Message_Count__c FROM Chat__c WHERE Id = :chatId LIMIT 1];
        List<ChatMessage> messages = get(chats);
        Integer messageIndex = Integer.valueOf(key.mid(18, key.length() - 18));
        return messages.get(messageIndex);
    }

    public List<ChatMessage> get(String contextParent, String contextChild){
        Map<String, Object> bindParams = new Map<String, Object>{
            'contextParent' => contextParent,
            'contextChild' => contextChild
        };
        String query;
        query = 'SELECT Id, Context_Parent__c, Context_Child__c, Messages__c, CreatedDate, Read_Receipts__c, Last_Message__c, First_Message__c, Previous_Chat__c FROM Chat__c WHERE Context_Parent__c = :contextParent';
        if (!String.isBlank(contextChild)){
            query += ' AND Context_Child__c = :contextChild';
        }
        query += ' ORDER BY CreatedDate DESC';
        List<Chat__c> chats = Database.queryWithBinds(query, bindParams, AccessLevel.SYSTEM_MODE); // running this in user mode enforces sharing
        return get(chats);
    }

    public List<ChatMessage> get(String contextParent, String contextChild, Date startDate, Date endDate){
        Map<String, Object> bindParams = new Map<String, Object>{
            'contextParent' => contextParent,
            'contextChild' => contextChild,
            'startDate' => startDate,
            'endDate' => endDate
        };
        String query;
        query = 'SELECT Id, Context_Parent__c, Context_Child__c, Messages__c, CreatedDate, Read_Receipts__c, Last_Message__c, First_Message__c, Previous_Chat__c FROM Chat__c WHERE Context_Parent__c = :contextParent';
        if (!String.isBlank(contextChild)){
            query += ' AND Context_Child__c = :contextChild' ;
        }
        if (startDate != null){
            query += ' AND Last_Message__c >= :startDate';
        }
        if (endDate != null){
            query += ' AND First_Message__c <= :endDate'; // in using created date here and not having a first message sent date it's been assumed messages won't get created in retrospect
        }
        query += ' ORDER BY CreatedDate DESC';
        List<Chat__c> chats = Database.queryWithBinds(query, bindParams, AccessLevel.SYSTEM_MODE); // running this in user mode enforces sharing
        return get(chats);
    }

    public List<ChatMessage> get(Chat__c chat){
        List<ChatMessage> messages = new List<ChatMessage>();
        List<Object> jsonChatMessages = (List<Object>)JSON.deserializeUntyped(chat.Messages__c);
        for (Object jsonChatMessage : jsonChatMessages){
            Map<String, Object> messageJson = (Map<String, Object>)jsonChatMessage;
            messages.add(new ChatMessage(chat, messageJson));
        }
        return messages;
    }

    public List<ChatMessage> get(List<Chat__c> chats){
        List<ChatMessage> messages = new List<ChatMessage>();
        for (Chat__c chat : chats){
            messages.addAll(get(chat));
        }
        return messages;
    }

    public List<ChatMessage> appendExtraData(List<ChatMessage> chatMessages){
        // author name, escalation record name, and context child names
        // get ids of records we need to lookup
        Set<Id> userIds = new Set<Id>();
        Map<String, Set<Id>> dynamicIdSets = new Map<String,Set<Id>>();
        for (ChatMessage chatMessage : chatMessages){
            userIds.add(chatMessage.authorId);
            if (!String.isBlank(chatMessage.escalationId)){
                Id escalation = (Id)chatMessage.escalationId;
                String objectName = escalation.getSObjectType().getDescribe().getName();
                chatMessage.escalationRecordName = objectName;
                Set<Id> objectIds = dynamicIdSets.get(objectName) ?? new Set<Id>();
                objectIds.add(escalation);
                dynamicIdSets.put(objectName, objectIds);
            }
            if (!String.isBlank(chatMessage.contextChild)){
                Id contextChild = (Id)chatMessage.contextChild;
                String objectName = contextChild.getSObjectType().getDescribe().getName();
                chatMessage.contextChildName = objectName;
                Set<Id> objectIds = dynamicIdSets.get(objectName) ?? new Set<Id>();
                objectIds.add(contextChild);
                dynamicIdSets.put(objectName, objectIds);
            }
        }

        // lookup records 
        Map<Id, User> userData = new Map<Id, User>([SELECT Id, FirstName, LastName FROM User WHERE Id IN :userIds]);
        Map<String, Map<Id, SObject>> records = new Map<String, Map<Id, SObject>>();
        // do bulkified selects in a loop - this is pretty nuts even for me 
        for (String objectName : dynamicIdSets.keySet()){
            Map<Id, SObject> objectRecords;
            Map<String, Object> bindParams = new Map<String, Object>{objectName+'bind' => dynamicIdSets.get(objectName)};
            if (objectName == 'Case'){
                String query = 'SELECT Id, CaseNumber FROM ' + objectName + ' WHERE Id IN :'+objectName+'bind ';
                objectRecords = new Map<Id, SObject>(Database.queryWithBinds(query, bindParams, AccessLevel.SYSTEM_MODE));
            }else{
                String query = 'SELECT Id, Name FROM ' + objectName + ' WHERE Id IN :'+objectName+'bind ';
                objectRecords = new Map<Id, SObject>(Database.queryWithBinds(query, bindParams, AccessLevel.SYSTEM_MODE));
            }
            records.put(objectName, objectRecords);
        }
        
        // populate the messages with the extra data
        for (ChatMessage chatMessage : chatMessages){
            User authorUser = userData.get(chatMessage.authorId) ?? new User(FirstName = 'user', LastName = 'not found');
            chatMessage.author = authorUser.FirstName + ' ' + authorUser.LastName;
            if (!String.isBlank(chatMessage.escalationId)){
                Id escalation = (Id)chatMessage.escalationId;
                SObject record = records?.get(chatMessage.escalationRecordName)?.get(escalation);
                if (record != null){
                    Map<String, Object> populatedFields = record.getPopulatedFieldsAsMap();
                    chatMessage.escalationRecordName = (String)populatedFields.get('Name') ?? (String)populatedFields.get('CaseNumber');
                }
            }

            if (!String.isBlank(chatMessage.contextChild)){
                Id context = (Id)chatMessage.contextChild;
                SObject record = records?.get(chatMessage.contextChildName)?.get(context);
                if (record != null){
                    Map<String, Object> populatedFields = record.getPopulatedFieldsAsMap();
                    chatMessage.contextChildName = (String)populatedFields.get('Name') ?? (String)populatedFields.get('CaseNumber');
                }
            }
        }
        return chatMessages;
    }

    private Chat__c newMessageCharacterLimitCheck(Chat__c chat, List<Message> messages, ChatMessage message){
        String jsonMessages = JSON.serialize(messages);
        if (jsonMessages.length() > 131072){ // this should only be possible on an update 
            // limit character length on inputs
            chatsToUpdate.remove(chat.Id);
            chat = new Chat__c();
            chat.Context_Parent__c = message.contextParent;
            chat.Context_Child__c = message.contextChild;
            //chat.Read_Receipts__c = UserInfo.getUserId();
            chat.First_Message__c = System.now();
            chat.Last_Message__c = System.now();
            Message newMessage = new Message(message);
            chat.Messages__c = JSON.serialize(newMessage);
            chatsToCreate.add(chat);
        }else{
            chat.Messages__c = jsonMessages;
        }
        return chat;
    }

    private Chat__c editMessageCharacterLimitCheck(Chat__c chat, List<Message> messages, ChatMessage message){
        String jsonMessages = JSON.serialize(messages);
        if (jsonMessages.length() > 131072){ 
            Chat__c newChat = chat.clone(false, true, false, false);
            chatsToCreate.add(newChat);
            newChat.Messages__c = null;
            List<Message> newChatMessages = new List<Message>();
            while (jsonMessages.length() > 131072){
                Message lastMessage = messages.remove(messages.size()-1);
                newChatMessages.add(lastMessage);
                jsonMessages = JSON.serialize(messages);
            }
            newChat.Messages__c = JSON.serialize(newChatMessages);
            // bump the end messages off the end of the current chat onto a new one until the current chat is below the limit 
        }else{
            chat.Messages__c = jsonMessages;
        }
        return chat;
    }

    /*public void sendEmailNotifications(ChatMessage message, Chat__c initialChat){
        Map<Id, Follow__c> follows = new Map<Id, Follow__c>([SELECT Id FROM Follow__c WHERE Context__c = :message.contextParent WITH SECURITY_ENFORCED]);
        List<Follow__Share> followShares = [SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause FROM Follow__Share WHERE RowCause = 'Chat__c' AND ParentID IN :follows.keySet() WITH SECURITY_ENFORCED];
        Set<Id> followerIds = new Set<Id>();
        for (Follow__Share followShare : followShares){
            followerIds.add(followShare.UserOrGroupId);
        }
        List<User> followers = [SELECT Id, Email FROM User WHERE Email != null AND Id IN :followerIds WITH SECURITY_ENFORCED];
        ChatMessagingNotifications messagingNofications = new ChatMessagingNotifications(message, initialChat, followers);
        messagingNofications.enqueue();        
    }*/
    
    class Message{
        String m;
        String e;
        String a;
        String t;
        String i;

        Message(ChatMessage message){
            this.m = message.body;
            this.e = message.escalationId;
            this.a = message.authorId;
            this.t = message.createdDatetime;
            this.i = message.messageNumber.toString();
        }
    }
}