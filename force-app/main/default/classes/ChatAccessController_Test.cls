@istest
public with sharing class ChatAccessController_Test {

    @testsetup
    public static void makeData(){
        FundingAward fa = new FundingAward();
        insert fa;

        Profile profile = [SELECT Id FROM Profile WHERE UserLicense.Name = 'Salesforce' LIMIT 1];

        User user2 = new User(LocaleSidKey = 'en_US', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', TimeZoneSidKey='GMT');
        user2.Email = 'test@test.com';
        user2.Username = 'checkCurrentUserAccessChatViewAllSuccess@test.com';
        user2.ProfileId = profile.Id;
        user2.LastName = 'bob';
        user2.Alias = 'bob';

        User user3 = new User(LocaleSidKey = 'en_US', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', TimeZoneSidKey='GMT');
        user3.Email = 'test@test.com';
        user3.Username = 'checkCurrentUserAccessNoChatViewAllFailure@test.com';
        user3.ProfileId = profile.Id;
        user3.LastName = 'bob';
        user3.Alias = 'bob';

        User user4 = new User(LocaleSidKey = 'en_US', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', TimeZoneSidKey='GMT');
        user4.Email = 'test@test.com';
        user4.Username = 'checkCurrentUserEdit_ChatInternalUser@test.com';
        user4.ProfileId = profile.Id;
        user4.LastName = 'bob';
        user4.Alias = 'bob';

        User user5 = new User(LocaleSidKey = 'en_US', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', TimeZoneSidKey='GMT');
        user5.Email = 'test@test.com';
        user5.Username = 'checkCurrentUserEdit_NoPermission@test.com';
        user5.ProfileId = profile.Id;
        user5.LastName = 'bob';
        user5.Alias = 'bob';

        User user6 = new User(LocaleSidKey = 'en_US', EmailEncodingKey = 'ISO-8859-1', LanguageLocaleKey = 'en_US', TimeZoneSidKey='GMT');
        user6.Email = 'test@test.com';
        user6.Username = 'checkCurrentUserEdit_Failure@test.com';
        user6.ProfileId = profile.Id;
        user6.LastName = 'bob';
        user6.Alias = 'bob';

        List<User> users = new List<User>{user2, user3, user4, user5, user6};
        insert users;
    }
    
    @istest
    public static void checkCurrentUserAccessChatViewAllSuccess(){
        User user = [SELECT Id FROM User WHERE Username = 'checkCurrentUserAccessChatViewAllSuccess@test.com'];

        PermissionSet perms = [SELECT Id FROM PermissionSet WHERE Name = 'Chat_User_Internal' LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = user.Id;
        psa.PermissionSetId = perms.Id;
        insert psa;

        Boolean hasAccess = false;
        ChatAccessController cac = new ChatAccessController();
        Test.startTest();
        System.runAs(user){
            hasAccess = cac.checkCurrentUserAccess('000A0000000000');
        }
        Test.stopTest();

        Assert.isTrue(hasAccess, 'Expect the current user to have access to this funding awward');
    }

    @istest
    public static void checkCurrentUserAccessNoChatViewAllFailure(){
        User user = [SELECT Id FROM User WHERE Username = 'checkCurrentUserAccessNoChatViewAllFailure@test.com'];

        String errorMessage = 'no error occurred';
        ChatAccessController cac = new ChatAccessController();
        Test.startTest();
        System.runAs(user){
            try{
                cac.checkCurrentUserAccess('000A0000000000');
            }catch(Exception e){
                errorMessage = e.getMessage();
            }
        }
        Test.stopTest();

        Assert.isTrue(errorMessage == 'User does not have access to this chat', 'expect the error message to be \'' + 'User does not have access to this chat' + '\', but received \'' + errorMessage + '\'');
    }

    @istest
    public static void checkCurrentUserEdit_ChatInternalUser(){
        User user = [SELECT Id FROM User WHERE Username = 'checkCurrentUserEdit_ChatInternalUser@test.com'];
        PermissionSet perms = [SELECT Id FROM PermissionSet WHERE Name = 'Chat_User_Internal' LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = user.Id;
        psa.PermissionSetId = perms.Id;
        insert psa;
        ChatMessaging messaging = new ChatMessaging();
        ChatMessage message = new ChatMessage();
        Boolean response = false;
        ChatAccessController cac = new ChatAccessController();
        Test.startTest();
        System.runAs(user){
            response = cac.checkCurrentUserEdit(message, messaging);
        }
        Test.stopTest();

        Assert.isTrue(response, 'expect the return from \'ChatAccessController.checkCurrentUserEdit\' to be true');
    }

    @istest
    public static void checkCurrentUserEdit_NoPermission(){
        User user = [SELECT Id FROM User WHERE Username = 'checkCurrentUserEdit_NoPermission@test.com'];
        
        Chat__c chat = ChatMessaging_Test.newChat(null, null, 1);
        JsonUtil jsonUtil = new JsonUtil(true, true);
        jsonUtil.startObject();
        jsonUtil.put('m', 'test message');
        jsonUtil.put('a', user.Id);
        jsonUtil.put('t', System.now().toString());
        jsonUtil.put('i', '1');
        chat.Messages__c = jsonUtil.getAsString();
        insert chat;
        
        ChatMessaging messaging = new ChatMessaging();
        ChatMessage message = new ChatMessage();
        message.authorId = user.Id;
        message.body = 'new Message';
        message.chatId = chat.Id;
        message.key = chat.Id + '0';

        Boolean response = false;
        ChatAccessController cac = new ChatAccessController();
        Test.startTest();
        System.runAs(user){
            response = cac.checkCurrentUserEdit(message, messaging);
        }
        Test.stopTest();


        Assert.isTrue(response, 'expect the return from \'ChatAccessController.checkCurrentUserEdit\' to be true');

    }


    @istest
    public static void checkCurrentUserEdit_Failure(){
        User user = [SELECT Id FROM User WHERE Username = 'checkCurrentUserEdit_Failure@test.com'];
        Chat__c chat = ChatMessaging_Test.newChat(null, null, 1);
        insert chat;
        ChatMessaging messaging = new ChatMessaging();
        ChatMessage message = new ChatMessage();
        message.authorId = user.Id;
        message.body = 'new Message';
        message.chatId = chat.Id;
        message.key = chat.Id + '0';

        String errorMessage = '';
        ChatAccessController cac = new ChatAccessController();
        Test.startTest();
        System.runAs(user){
            try{
                Boolean response = cac.checkCurrentUserEdit(message, messaging);
            }catch(Exception e){
                errorMessage = e.getMessage();
            }
        }
        
        Test.stopTest();
        Assert.areEqual('User does not have access to edit this chat', errorMessage, 'caught error message');
    }
}