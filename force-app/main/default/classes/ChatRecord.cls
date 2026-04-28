public without sharing class ChatRecord {
    
    public static ChatMessaging messaging = new ChatMessaging(); // this is injectable

    @AuraEnabled
    public String summary {get; set;}

    @AuraEnabled
    public String chatId {get; set;}

    @AuraEnabled
    public String messagesJSON {get; set;}

    @AuraEnabled
    public List<ChatMessage> messages {get; set;}

    @AuraEnabled
    public DateTime lastMessage {get; set;}

    @AuraEnabled
    public String contextParent {get; set;}

    @AuraEnabled
    public String contextChild {get; set;}

    @AuraEnabled
    public String contextParentName {get; set;}

    @AuraEnabled
    public String awardeeName {get; set;}

    @AuraEnabled
    public Integer unreadMessageCount {get; set;}


    private Integer sortDirection = 1; // 1 is earliest at top, -1 earliest at bottom

    public ChatRecord(Chat__c chat){
        this.chatId = chat.Id;
        this.contextParent = chat.Context_Parent__c;
        this.messagesJSON = chat.Messages__c; 
        this.messages = messaging.get(chat);
        this.summary = createChatSummary(this.messages); 
        this.lastMessage =  chat.Last_Message__c; 
        this.contextChild = chat.Context_Child__c;
        //this.unreadMessageCount = 
    }

    public ChatRecord(String contextParent){
        this.chatId = null;
        this.contextParent = contextParent;
        this.summary = 'No Messages'; 
        this.lastMessage =  null; 
    }

    @testvisible
    private String isoToJavaDateString(String isoDateTime){
        return isoDateTime.left(10) + ' ' + isoDateTime.mid(11, 8);
    }

    private String createChatSummary(List<ChatMessage> messages){
        
        if(messages.size() >0){
            String summary = messages[messages.size() - 1].body; 
            return summary;
        }
        else{
            return 'No Messages';
        }
        
    }

}