public without sharing class ChatReadReceiptService {

    @testVisible 
    private List<Chat__c> chats = new List<Chat__c>();
    @TestVisible
    private List<Receipt> receipts = new List<Receipt>();

    private Chat__c chat;
    //userId to number of unread messages
    @testVisible
    private Map<String, String> readReceiptsMap = new Map<String, String>();

    public ChatReadReceiptService add(String key, Chat__c chat) {
        if (chat == null){
            throw new HandledException('the chat record is null, require a chat to add read receipts');
        }
        Map<String, Object> readReceipts = (Map<String, Object>)JSON.deserializeUntyped(chat?.Read_Receipts__c ?? '{}');
        if (readReceipts.size() == 0){
            readReceipts = new Map<String, Object>{UserInfo.getUserId() => key};
        }else{
            readReceipts.put(UserInfo.getUserId(), key);
        }
        chat.Read_Receipts__c = JSON.serialize(readReceipts);
        chats.add(chat);
        receipts.add(new Receipt(chat, chat.Id + key, UserInfo.getUserId()));
        return this;
    }

    public void apply(){
        // send a read message event for each chat updated
        update chats;
        List<Message_Event__e> events = new List<Message_Event__e>();
        for (Receipt receipt: receipts){
            Message_Event__e event = new Message_Event__e();
            event.Is_Read__c = true;
            event.Author__c = receipt.userId;
            event.When__c = System.now();
            event.Message_Id__c = receipt.key;
            event.Context_Child__c = receipt?.chat?.Context_Child__c ?? receipt.chat.Context_Parent__c;
            event.Context_Parent__c = receipt.chat.Context_Parent__c;
            events.add(event);
        }
        EventBus.publish(events);
    }

    public Integer getReadReceiptNumber(String readReceiptsJson, Id userId) {
        if (String.isBlank(readReceiptsJson) || userId == null) return null;

        Object raw = JSON.deserializeUntyped(readReceiptsJson);
        if (!(raw instanceof Map<String, Object>)) return null;

        Map<String, Object> m = (Map<String, Object>) raw;
        Object val = m.get((String)userId);
        if (val == null) return null;

        if (val instanceof Integer) return (Integer) val;
        if (val instanceof Long)    return Integer.valueOf(String.valueOf(val));
        if (val instanceof Decimal) return ((Decimal) val).intValue();

        try {
            return Integer.valueOf(String.valueOf(val));
        } catch (Exception e) {
            return null;
        }
    }

    //method to deserialize read reciepts from a chat record. Return an instance of chat read reciept service
    public ChatReadReceiptService deserializeReadReceipts(Chat__c chat){
        if (chat == null) {
            return null;
        }
        this.chat = chat;

        readReceiptsMap = (Map<String, String>)JSON.deserialize(chat.Read_Receipts__c, Map<String, String>.class); //deserialize the read receipts JSON string into a map of string, string
        return this;
    }

    //Another method take in a user and the deserialised chat read receipts. Return a number of unread messags for the user that was passed in. methodName for user
    //if the user ID isn't in the read reciept, then return the total message count. If the user ID is in the read reciepts then return the message count - read reciept sevice.
    public Integer getUnreadMessagesForUser(Id userId){
        if (userId == null) return null;

        Integer unreadNumber = 0;

        if (readReceiptsMap.containsKey(userId)){
            unreadNumber = Integer.valueOf(chat.Message_Count__c) - Integer.valueOf(readReceiptsMap.get(userId));
        } else {
            unreadNumber = Integer.valueOf(chat.Message_Count__c);
        }
        return unreadNumber;
    }

    class Receipt{
        Chat__c chat;
        String key;
        Id userId;
        Receipt(Chat__c chat, String key, Id userId){
            this.chat = chat;
            this.key = key;
            this.userId = userId;
        }
    }
}