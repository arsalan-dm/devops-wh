@istest
public without sharing class ChatMessage_Test {

    private static Integer index = 0;

    @istest
    public static void constructor(){
        ChatMessage message;
        Test.startTest();
        message = new ChatMessage();
        Test.stopTest();

        Assert.isTrue(message != null, 'expect message to not be null');
    }

    @istest
    public static void constructorFromChat(){
        String now = System.now().toString();
        JsonUtil jsonUtil = new JsonUtil(true,false);
        jsonUtil.put('m', 'message text');
        jsonUtil.put('a', UserInfo.getUserId());
        jsonUtil.put('t', now);
        jsonUtil.put('s', true);
        jsonUtil.put('i', '1');

        String jsonBody = jsonUtil.getAsString();
        Object jsonObj = (Object)JSON.deserializeUntyped(jsonBody);
        Chat__c chat = new Chat__c();
        Test.startTest();
        ChatMessage message = new ChatMessage(chat,jsonObj);
        Test.stopTest();

        Assert.isTrue(message.createdDatetime == now, 'expect the messages createdDateTime to be \'' + now + '\', but received \'' + message.createdDatetime + '\'');
        Assert.isTrue(message.authorId == UserInfo.getUserId(), 'Expected to receive an authorId of \'' + UserInfo.getUserId() +  '\', but received \''+ message.authorId+ '\'');
    }

    @istest
    public static void comparible(){

        ChatMessage c1 = createMessage(System.now().addDays(-1).toString());
        ChatMessage c2 = createMessage(System.now().addDays(-2).toString());

        List<ChatMessage> messages = new List<ChatMessage>{c2, c1};
        
        Test.startTest();
        messages.sort();
        Test.stopTest();

        Assert.isTrue(messages.get(0).body == '1', 'Expect the first message to be the most recent one');
    }

    @istest
    public static void specificContext(){
        
        ChatMessage message = createMessage(System.now().toString());
        message.contextParent = '000P00000000000AAA';
        Test.startTest();
        String specificContext = message.specificContext();
        Test.stopTest();

        Assert.isTrue(specificContext == message.contextParent, 'Expect the return to be the message contextParent \'' + message.contextParent + '\', but received \'' + specificContext + '\'');
    }

    public static ChatMessage createMessage(String createdDateTime){
        JsonUtil jsonUtil = new JsonUtil(true, false);
        index += 1;
        jsonUtil.put('m', index.toString());
        jsonUtil.put('a', UserInfo.getUserId());
        jsonUtil.put('t', createdDateTime);
        jsonUtil.put('i', String.valueOf(index));

        String jsonBody = jsonUtil.getAsString();
        Object jsonObj = (Object)JSON.deserializeUntyped(jsonBody);
        Chat__c chat = new Chat__c();
        ChatMessage message = new ChatMessage(chat, jsonObj);
        return message;
    }
}