@IsTest
public with sharing class ChatReadReceiptService_Test {

    @TestSetup
    public static void makeData(){
        FundingAward fa = new FundingAward();
        insert fa;
        Chat__c chat = ChatMessaging_Test.newChat(fa.Id, null, 2);
        insert chat;
    }

    @IsTest
    public static void add(){
        List<String> chatFields = new List<String>(Schema.Chat__c.SObjectType.getDescribe().fields.getMap().keySet());
        String chatQuery = 'SELECT ' + String.join(chatFields, ',') 
            + ' FROM Chat__c';
        List<Chat__c> chats = (List<Chat__c>)Database.query(
                chatQuery, 
                AccessLevel.SYSTEM_MODE
            );
        Chat__c chat = chats.get(0);
        ChatReadReceiptService crrs = new ChatReadReceiptService();
        Test.startTest();
        crrs.add('2', chat);
        Test.stopTest();
        Assert.areEqual(1,crrs.chats.size(), 'number of chats updated with read receipts'); 

        Object raw = JSON.deserializeUntyped(crrs.chats.get(0).Read_Receipts__c);
        Map<String, Object> m = (Map<String, Object>) raw;
        Integer val = Integer.valueOf(m.get((String)UserInfo.getUserId()));

        Assert.areEqual(2,val, 'update the read receipts to the most recent message on this chat');
    }

    @IsTest
    public static void add_nullChat(){
        String message = 'the chat record is null, require a chat to add read receipts';
        String errorMessage = '';
        ChatReadReceiptService crrs = new ChatReadReceiptService();
        Test.startTest();
        try{
            crrs.add('2', null);
        }catch(Exception e){
            errorMessage = e.getMessage();
        }
        Test.stopTest();
        Assert.areEqual(message, errorMessage, 'message recieved when chat is null'); 
    }

    @IsTest
    public static void add_secondUser(){
        List<String> chatFields = new List<String>(Schema.Chat__c.SObjectType.getDescribe().fields.getMap().keySet());
        String chatQuery = 'SELECT ' + String.join(chatFields, ',') 
            + ' FROM Chat__c';
        List<Chat__c> chats = (List<Chat__c>)Database.query(
                chatQuery, 
                AccessLevel.SYSTEM_MODE
            );
        Chat__c chat = chats.get(0);
        ChatReadReceiptService crrs = new ChatReadReceiptService();
        User runningUser = [SELECT Id FROM User WHERE Id != :UserInfo.getUserId() AND IsActive = true LIMIT 1];
        Test.startTest();
        System.runAs(runningUser){
            crrs.add('2', chat);
        }
        Test.stopTest();
        Assert.areEqual(1,crrs.chats.size(), 'number of chats updated with read receipts'); 

        Object raw = JSON.deserializeUntyped(crrs.chats.get(0).Read_Receipts__c);
        Map<String, Object> m = (Map<String, Object>) raw;
        Integer val = Integer.valueOf(m.get(runningUser.Id));

        Assert.areEqual(2,val, 'update the read receipts for the running user to the most recent message on this chat'); 
    }

    @IsTest
    public static void apply(){
        List<String> chatFields = new List<String>(Schema.Chat__c.SObjectType.getDescribe().fields.getMap().keySet());
        String chatQuery = 'SELECT ' + String.join(chatFields, ',') 
            + ' FROM Chat__c';
        List<Chat__c> chats = (List<Chat__c>)Database.query(
                chatQuery, 
                AccessLevel.SYSTEM_MODE
            );
        Chat__c chat = chats.get(0);
        chat.Read_Receipts__c = '{"'+UserInfo.getUserId() + '":2}';

        ChatReadReceiptService crrs = new ChatReadReceiptService();
        Test.startTest();
        crrs.add('2', chat);
        crrs.apply();
        Test.stopTest();
        Chat__c chatAfter = [SELECT Id, Read_Receipts__c FROM Chat__c WHERE Id = :chat.Id];

        Object raw = JSON.deserializeUntyped(chatAfter.Read_Receipts__c);
        Map<String, Object> m = (Map<String, Object>) raw;
        String val = (String)m.get((String)UserInfo.getUserId());

        Assert.areEqual('2',val, 'read receipt applied to the chat for the current user'); 
    }

    @IsTest
    public static void getReadReceiptNumber_null(){

        ChatReadReceiptService crrs = new ChatReadReceiptService();
        Test.startTest();
        Integer key = crrs.getReadReceiptNumber(null, UserInfo.getUserId());
        Test.stopTest();
        Assert.isNull(key, 'expect the key to be null');
    }

    @IsTest
    public static void getReadReceiptNumber_Array(){

        ChatReadReceiptService crrs = new ChatReadReceiptService();
        Test.startTest();
        Integer key = crrs.getReadReceiptNumber('[]', UserInfo.getUserId());
        Test.stopTest();
        Assert.isNull(key, 'expect the key to be null');
    }

    @IsTest
    public static void getReadReceiptNumber_missingUserID(){

        ChatReadReceiptService crrs = new ChatReadReceiptService();
        Test.startTest();
        Integer key = crrs.getReadReceiptNumber('{}', UserInfo.getUserId());
        Test.stopTest();
        Assert.isNull(key, 'expect the key to be null');
    }
    
    @IsTest
    public static void getReadReceiptNumber_integer(){

        ChatReadReceiptService crrs = new ChatReadReceiptService();
        String jsonStr = '{"'+ UserInfo.getUserId() +'":2}';
        Test.startTest();
        Integer key = crrs.getReadReceiptNumber(jsonStr, UserInfo.getUserId());
        Test.stopTest();
        Assert.areEqual(2, key, 'the key');
    }

    @IsTest
    public static void getReadReceiptNumber_decimal(){

        ChatReadReceiptService crrs = new ChatReadReceiptService();
        String jsonStr = '{"'+ UserInfo.getUserId() +'":2.1}';
        Test.startTest();
        Integer key = crrs.getReadReceiptNumber(jsonStr, UserInfo.getUserId());
        Test.stopTest();
        Assert.areEqual(2, key, 'the key');
    }

    @IsTest
    public static void getReadReceiptNumber_string(){

        ChatReadReceiptService crrs = new ChatReadReceiptService();
        String jsonStr = '{"'+ UserInfo.getUserId() +'":"2"}';
        Test.startTest();
        Integer key = crrs.getReadReceiptNumber(jsonStr, UserInfo.getUserId());
        Test.stopTest();
        Assert.areEqual(2, key, 'the key');
    }

    @isTest
    public static void deserializeReadReceipts(){
        ChatReadReceiptService crrs = new ChatReadReceiptService();
        List<String> chatFields = new List<String>(Chat__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap().keySet());
        String chatQuery = 'SELECT ' + String.join(chatFields, ',') 
            + ' FROM Chat__c';
        List<Chat__c> chats = (List<Chat__c>)Database.query(
                chatQuery, 
                AccessLevel.SYSTEM_MODE
            );
        Chat__c chat = chats.get(0);
        User runningUser = [SELECT Id FROM User WHERE Id != :UserInfo.getUserId() AND IsActive = true LIMIT 1];
        chat.Read_Receipts__c = '{"'+ runningUser.Id +'":1}';
        Test.startTest();
        crrs.deserializeReadReceipts(chat);
        Test.stopTest();
        Assert.areEqual(1, crrs.readReceiptsMap.size(), 'the read receipts map should have one entry for the user id');

        
        Integer unreadMessages = crrs.getUnreadMessagesForUser(runningUser.Id);
        Assert.areEqual(1, unreadMessages, 'the number of unread messages for the user should be 1');

    }

        @isTest
    public static void deserializeReadReceiptsNoUser(){
        ChatReadReceiptService crrs = new ChatReadReceiptService();
        List<String> chatFields = new List<String>(Chat__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap().keySet());
        String chatQuery = 'SELECT ' + String.join(chatFields, ',') 
            + ' FROM Chat__c';
        List<Chat__c> chats = (List<Chat__c>)Database.query(
                chatQuery, 
                AccessLevel.SYSTEM_MODE
            );
        Chat__c chat = chats.get(0);
        User runningUser = [SELECT Id FROM User WHERE Id != :UserInfo.getUserId() AND IsActive = true LIMIT 1];
        chat.Read_Receipts__c = '{}';
        Test.startTest();
        crrs.deserializeReadReceipts(chat);
        Test.stopTest();
        Assert.areEqual(0, crrs.readReceiptsMap.size(), 'the read receipts map should have no entries');

        
        Integer unreadMessages = crrs.getUnreadMessagesForUser(runningUser.Id);
        Assert.areEqual(2, unreadMessages, 'the number of unread messages for the user should be 2');

    }

}