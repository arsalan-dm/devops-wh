@isTest
public with sharing class GmsLoginReminderEmailHandler_Test {

    public static List<User> createUser(Integer daysFromToday){
        List<User> users = new List<User>();
         for(Integer i=0; i<20; i++) {
            JsonUtil jsonUtil = new JsonUtil();
            jsonUtil.startObject()
            .put('LastLoginDate', String.valueOf(System.today().addDays(daysFromToday)))
            .put('Id', Stub.getId(User.getSObjectType()))
            .put('Email', 'testuser' + i + '@test.com')
            .put('Last_Login_Reminder_Sent__c', String.valueOf(System.today().addDays(daysFromToday)))
            .put('FirstName', 'John')
            .put('IsActive', true);
            user u = (User)JSON.deserialize(jsonUtil.getAsString(), User.class);
            users.add(u);
        }
        return users;
    } 

    public static List<FundingAwardParticipant> createFundingAwardParticipant(Id userId) {
        FundingAwardParticipant fap = new FundingAwardParticipant();
        fap.ParticipantId = userId;
        fap.FundingAwardId = Stub.getId(FundingAward.getSObjectType());
        return new List<FundingAwardParticipant>{fap};
    }

    public static List<Chat__c> createChats(Id fundingAwardId, Id usrId) {
        List<Chat__c> chats = new List <Chat__c>();
        for(Integer i=0; i<5; i++) {
            Chat__c chat = new Chat__c();
            chat.Context_Parent__c = fundingAwardId;
            chat.Messages__c = 'Test message ' + i;
            chat.Read_Receipts__c = '{"' + usrId + '":"1"}';
            chat.Message_Count__c = 2;
            chat.Id = Stub.getId(Chat__c.getSObjectType());
            chats.add(chat);
        }
        return chats;
    }

    public static List<EmailTemplate> createEmailTemplate() {
        EmailTemplate et = new EmailTemplate();
        et.DeveloperName = 'GMS_Login_Reminder';
        et.Subject = 'You have unread messages in Salesforce';
        et.HtmlValue = 'Hello {FirstName}, you have {UnreadMessages} unread messages in Salesforce.';
        return new  List<EmailTemplate> {et};
    }
    
    public static List<OrgWideEmailAddress> getOrgWideEmail() {
        OrgWideEmailAddress owea = new OrgWideEmailAddress();
        owea.Address = 'sigma.admin@ics.gov.uk';
        owea.DisplayName = 'DESNZ Grants No-reply SIGMA';
        return new List<OrgWideEmailAddress> {owea};
    }
    
    //Positive test, email is sent when users are found
    @isTest
    public static void sendEmailToAllUsers() {
        List<User> users = createUser(-15);
        List<FundingAwardParticipant> fapList = new List<FundingAwardParticipant>();
        for(user u : users) {
            FundingAwardParticipant fap = createFundingAwardParticipant(u.Id)[0];
            fapList.add(fap);
        }
        List<Chat__c> chats = new List<Chat__c>();
        for(FundingAwardParticipant funaps : fapList) {
            Chat__c c = createChats(funaps.FundingAwardId, funaps.ParticipantId)[0];
            chats.add(c);
        }
        List<EmailTemplate> emailTemplate = createEmailTemplate();
        List<OrgWideEmailAddress> oweas = getOrgWideEmail();
        
        //Instantiate the stub classes needed to create the handler.
        ChatReadReceiptService mockReadReceiptService =
            (ChatReadReceiptService)Stub.builder()
            	.handleMethod('getUnreadMessagesForUser').with(2)
                .create(ChatReadReceiptService.class);
        Selector mockSelector = (Selector)Stub.builder()
            .handleMethod('query').with(
                Stub.method()
                	.handleCall(0).with(users)
                	.handleCall(1).with(fapList)
                	.handleCall(2).with(chats)
                	.handleCall(3).with(emailTemplate)
                	.handleCall(4).with(oweas)
            )
            .create(Selector.class);
        Dml mockDml = (Dml)Stub.builder().create(Dml.class);
        SystemUtil mockSystemUtil = (SystemUtil)Stub.builder().create(SystemUtil.class);
        
        //Instantiate email handler queueable class
        GmsLoginReminderEmailHandler handler = new GmsLoginReminderEmailHandler(
            mockReadReceiptService,
            mockSelector, 
            mockDml,
            mockSystemUtil
        );
        
        Test.startTest();
        System.enqueueJob(handler);
        Test.stopTest();
        Assert.isTrue(Stub.callNames.contains('sendEmail'),'Didn\'t find a sendEmail method call');
        
        List<Object> args = (List<Object>)
            Stub.callArgs[Stub.callNames.IndexOf('setTarget')];
        List<User> u = (List<User>)args[0];
        
        Assert.areEqual(System.Today(), u[0].Last_Login_Reminder_Sent__c, 'Last login date not updated for this user');
      }
    
    //Instantiate constructor
    @isTest
    public static void checkMethod() {
        GmsLoginReminderEmailHandler handler = new GmsLoginReminderEmailHandler();
        Assert.isNotNull(handler);
    }
    
    //Handle what happens when no users are found in the query
    @isTest
    public static void noUsersReturned() {
        List<User> emptyUserList = new List<User>();
        List<FundingAwardParticipant> emptyFun = new List<FundingAwardparticipant>();
        List<Chat__c> emptyChats = new List<Chat__c>();
        List<EmailTemplate> emailTemplate = createEmailTemplate();
        ChatReadReceiptService mockReadReceiptService =
            (ChatReadReceiptService)Stub.builder()
            .handleMethod('getUnreadMessagesForUser').with(0)
            .create(ChatReadReceiptService.class);
        
        Selector mockSelector = (Selector)Stub.builder()
            .handleMethod('query').with(
                Stub.method()
                	.handleCall(0).with(emptyUserList)
                	.handleCall(1).with(emptyFun)
                	.handleCall(2).with(emptyChats)
                	.handleCall(3).with(emailTemplate))
            .create(Selector.class);
        
        Dml mockDml = (Dml)Stub.builder().create(Dml.class);
        SystemUtil mockSystemUtil = (SystemUtil)Stub.builder().create(SystemUtil.class);
        GmsLoginReminderEmailHandler handler = new GmsLoginReminderEmailHandler(
        	mockReadReceiptService,
            mockSelector, 
            mockDml,
        	mockSystemUtil);
        
        Test.startTest();
        System.enqueueJob(handler);
        Test.stopTest();
        Assert.isFalse(Stub.callNames.contains('sendEmail'),'A sendEmail method call was found');
    }
}