public without sharing class ChatController {
    
    public static ChatMessaging messaging = new ChatMessaging(); // this is injectable
    public static ChatAccessController chatAccessController = new ChatAccessController();
    public static ChatReadReceiptService readReceiptService = new ChatReadReceiptService();

    @AuraEnabled
    public static List<ChatMessage> getMessages(String contextParent, String contextChild){
        try {
            // check current user is apart of the contextParent funding award 
            chatAccessController.checkCurrentUserAccess(contextParent);

            List<ChatMessage> chatMessages = messaging.get(contextParent, contextChild);
            if (chatMessages.size() > 0){
                messaging.appendExtraData(chatMessages);
                chatMessages.sort();
            }
            return chatMessages;
        } catch (Exception e) {
            return (List<ChatMessage>)handleAuraExpection(e);
        }
    }

    @AuraEnabled
    public static String oldestMessage(String contextParent, String contextChild){
        try {
            chatAccessController.checkCurrentUserAccess(contextParent);

            Map<String, Object> bindParams = new Map<String, Object>{
                'contextParent' => contextParent,
                'contextChild' => contextChild
            };
            String query;
            query = 'SELECT Id, Context_Parent__c, Context_Child__c, Messages__c, CreatedDate, Read_Receipts__c, Last_Message__c, First_Message__c, Previous_Chat__c FROM Chat__c WHERE Context_Parent__c = :contextParent';
            if (!String.isBlank(contextChild)){
                query += ' AND Context_Child__c = :contextChild' ;
            }
            query += ' ORDER BY First_Message__c ASC LIMIT 1';
            Chat__c chat = Database.queryWithBinds(query, bindParams, AccessLevel.SYSTEM_MODE); // running this in user mode enforces sharing
            return chat?.First_Message__c?.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        } catch (Exception e) {
            return (String)handleAuraExpection(e);
        }
    }

    @AuraEnabled
    public static List<ChatMessage> getMessagesDateRange(
        String contextParent, 
        String contextChild, 
        Date startDate, 
        Date endDate
    ){
        try {
            chatAccessController.checkCurrentUserAccess(contextParent);
            List<ChatMessage> chatMessages = messaging.get(contextParent, contextChild, startDate, endDate);
            if (chatMessages.size() > 0){
                messaging.appendExtraData(chatMessages);
                chatMessages.sort();
                // TODO - generalise this filtering enable it to not filter, it also only works for asc
                if (startDate != null){
                    Boolean withinFilter = false;
                    ChatMessage lastMessage;
                    while (!withinFilter && chatMessages.size() > 0){
                        lastMessage = chatMessages.remove(chatMessages.size() - 1);
                        if (lastMessage.created > startDate){ // if new last message is after the start date add it back on, and stop removing messages
                            chatMessages.add(lastMessage);
                            withinFilter = true;
                        }
                    } 
                }
                if (endDate != null){
                    Boolean withinFilter = false;
                    ChatMessage firstMessage;
                    while (!withinFilter && chatMessages.size() > 0){
                        firstMessage = chatMessages.remove(0);
                        if (firstMessage.created < endDate){ // if new first message is after the start date add it back on, and stop removing messages
                            List<ChatMessage> newMessages = new List<ChatMessage>{firstMessage};
                            newMessages.addAll(chatMessages);
                            chatMessages = newMessages;
                            withinFilter = true;
                        }
                    } 
                }
            }
            return chatMessages;
        } catch (Exception e) {
            return (List<ChatMessage>)handleAuraExpection(e);
        }
    }

    @AuraEnabled
    public static ChatMessage createMessage(ChatMessage message){
        try {
            // check current user is apart of the contextParent funding award 
            chatAccessController.checkCurrentUserAccess(message.contextParent);
            message.authorId = UserInfo.getUserId();
            String now =  JSON.serialize(Datetime.now());
            message.createdDatetime = now.removeStart('"').removeEnd('"');
            Chat__c chat = messaging.add(message);
            List<ChatMessage> messagesCreated = messaging.send();
            messaging.appendExtraData(messagesCreated);
            return messagesCreated.get(0);
        } catch (Exception e) {
            return (ChatMessage)handleAuraExpection(e);
        }
    }

    @AuraEnabled
    public static ChatMessage editMessage(ChatMessage message){
        try {
            // check current user is apart of the contextParent funding award 
            chatAccessController.checkCurrentUserAccess(message.contextParent);
            chatAccessController.checkCurrentUserEdit(message, messaging);
            
            Chat__c chat = messaging.edit(message);
            List<ChatMessage> messagesUpdated = messaging.send();
            return messagesUpdated.get(0);
        } catch (Exception e) {
            return (ChatMessage)handleAuraExpection(e);
        }
    }

    @AuraEnabled
    public static List<ChatMessage> editMessages(List<ChatMessage> messages){
        try {
            // check current user is apart of the contextParent funding award 
            chatAccessController.checkCurrentUserAccess(messages.get(0).contextParent);
            chatAccessController.checkCurrentUserEdit(messages.get(0), messaging);
            System.debug(messages);
            for (ChatMessage message : messages){
                messaging.edit(message);
            }
            return messaging.send();
        } catch (Exception e) {
            return (List<ChatMessage>)handleAuraExpection(e);
        }
    }

    public static Object handleAuraExpection(Exception e){ // this is to help with getting better code coverage %, without going full mocking 
        String message = 'Bad Request';
        AuraHandledException ahe = new AuraHandledException(message);
        ahe.setMessage(message);
        throw ahe;
    }

    @AuraEnabled
    public static String setReadReceipt(String messageKey){
        try {
            List<Chat__c> chats = [SELECT Id, Read_Receipts__c, Context_Parent__c, Context_Child__c FROM Chat__c WHERE Id = :messageKey.left(18) WITH SECURITY_ENFORCED];
            if(chats.size() > 0){
                Chat__c chat = chats.get(0);
                chatAccessController.checkCurrentUserAccess(chat.Context_Parent__c); // check access availability 

                String messageId = messageKey;
                readReceiptService
                    .add(messageId.removeStart(chat.Id), chat)
                    .apply();
                
            } else {
                throw new HandledException('Message not found');
            }
            return '{"success":true}';
        } catch (Exception e) {
            return (String)handleAuraExpection(e);
        }
    }
}