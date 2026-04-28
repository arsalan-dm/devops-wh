public without sharing class ChatMessage implements Comparable{

    @AuraEnabled
    public String body {get; set;}

    @AuraEnabled
    public String escalationId {get; set;}

    @AuraEnabled
    public String escalationRecordName {get; set;}

    @AuraEnabled
    public String key {get; set;}

    @AuraEnabled
    public String chatId {get; set;}

    @AuraEnabled
    public String authorId {get; set;}

    @AuraEnabled
    public String author {get; set;}

    @AuraEnabled
    public String createdDatetime {get; set;}

    @AuraEnabled
    public String contextParent {get; set;}

    @AuraEnabled
    public String contextChild {get; set;}

    @AuraEnabled
    public String contextChildName {get;set;}

    public Integer messageNumber {
        get{
            if (messageNumber == null){
                messageNumber = Integer.valueOf(key?.removeStart(chatId) ?? '0');
            }
            return messageNumber;
        }set{
            messageNumber = value;
        }
    }

    private Integer sortDirection = 1; // 1 is earliest at top, -1 earliest at bottom

    public DateTime created {
        get {
            if (created == null){
                created = Datetime.valueOf(isoToJavaDateString(createdDatetime));
            }
            return created;
        }
        set {
            created = value;
        }
    }

    public ChatMessage(){

    }

    public ChatMessage(Chat__c chat, Object messageObj){
        Map<String, Object> jsonObj = (Map<String, Object>) messageObj;
        this.messageNumber = Integer.valueOf((String)jsonObj.get('i'));
        this.key = chat.Id + ((String)jsonObj.get('i'));
        this.escalationId = (String)jsonObj.get('e');
        this.chatId = chat.Id;
        this.authorId = (String)jsonObj.get('a');
        this.createdDatetime = (String)jsonObj.get('t');
        this.body = (String)jsonObj.get('m');
        this.contextParent = chat.Context_Parent__c;
        this.contextChild = chat.Context_Child__c;
    }

    public Integer compareTo(Object compareTo) {
        ChatMessage compareToMessage = (ChatMessage)compareTo;
        // Your code here
        if (compareToMessage.created == this.created) return 0;
        if (compareToMessage.created > this.created) return 1*sortDirection;
        return -1*sortDirection;
    }

    @testvisible
    private String isoToJavaDateString(String isoDateTime){
        return isoDateTime.left(10) + ' ' + isoDateTime.mid(11, 8);
    }

    public String specificContext(){
        return this.contextChild ?? this.contextParent;
    }
}