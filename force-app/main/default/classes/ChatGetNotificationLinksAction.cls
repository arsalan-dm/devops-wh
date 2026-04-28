public with sharing class ChatGetNotificationLinksAction {
    public static ChatMessaging chatMessaging = new ChatMessaging();
    
    @invocableMethod(label='Get Notification Links')
    public static List<Links> getNotificationLinks(List<List<Chat__c>> chatsWrapper){
        List<Chat__c> chats = chatsWrapper.get(0);
        List<String> tableRows = new List<String>();
        Set<Id> parentContexts = new Set<Id>();
        for (Chat__c chat : chats){
            if (chat.Context_Child__c == null){
                parentContexts.add(chat.Context_Parent__c);
            }
        }
        Map<Id, FundingAward> fas;
        if (parentContexts.size() > 0){
            fas = new Map<Id, FundingAward>([SELECT Id, Name FROM FundingAward]);
        }

        List<ChatMessage> messages = chatMessaging.get(chats);
        chatMessaging.appendExtraData(messages);
        messages.sort();
        Map<Id, ChatMessage> uniqueChatMessages = new Map<Id, ChatMessage>();

        for (ChatMessage message : messages){
            Id context = message.contextChild;
            if (message.contextChild == null){
                context = message.contextParent;
            }
            if (uniqueChatMessages.get(context) == null){
                uniqueChatMessages.put(context, message);
            }
        }

        for (Id contextId : uniqueChatMessages.keySet()){
            ChatMessage message = uniqueChatMessages.get(contextId);
            String objectLabel = contextId.getSObjectType().getDescribe().getLabel();
            String recordName = message.contextChildName ?? fas?.get(message.contextParent)?.Name;
            String aTag = '<a target="_blank" href="/' + contextId + '">' + recordName + '</a>';
            String tableRow = '<tr><td>' + objectLabel + '</td><td>' + message.body + '</td><td>' + aTag + '</td></tr>';
            tableRows.add(tableRow);
        }
        List<Links> links = new List<Links>{new Links(tableRows)};
        return links;
    }

    public class Links{
        @invocableVariable
        public List<String> tableRows;
        Links(List<String> tableRows){
            this.tableRows = tableRows;
        }
    }
}