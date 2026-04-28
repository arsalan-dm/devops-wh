public with sharing class GmsLoginReminderEmailHandler implements Queueable {
    
    //Chunck size constant to ensure email limits aren't reached
    private static final Integer CHUNK_SIZE = 10;
    private static final String EMAIL_TEMPLATE_NAME = 'GMS_Login_Reminder';

    @testVisible
    private ChatReadReceiptService readReceiptService;
    @testVisible
    private Selector selector;
    @testVisible
    private Dml dml;
    @testVisible
    private SystemUtil systemUtil;

    public GmsLoginReminderEmailHandler() {
        readReceiptService = new ChatReadReceiptService();
        selector = new Selector();
        dml = new Dml();
        SystemUtil = new SystemUtil();
    }

    public GmsLoginReminderEmailHandler(
        ChatReadReceiptService readReceiptService, 
        Selector selector, 
        Dml dml,
        SystemUtil systemUtil
    ) {
        this.readReceiptService = readReceiptService;
        this.selector = selector;
        this.dml = dml;
        this.systemUtil = systemUtil;
    }

    private List<User> getUsers() {
        Map<String, Object> bindParams = new Map<String, Object>{
            'chunkSize' => CHUNK_SIZE
        };
        String userQuery = 'SELECT Id, Email, LastLoginDate, FirstName FROM User WHERE LastLoginDate < LAST_N_DAYS:14 AND LastLoginDate >= LAST_N_MONTHS:4 AND (Last_Login_Reminder_Sent__c < LAST_N_DAYS:14 OR Last_Login_Reminder_Sent__c = null) AND IsActive = true AND Email != null AND Profile.UserLicense.Name != \'Salesforce\' LIMIT :chunkSize';
        List<User> userList = selector.query(userQuery, bindParams);
        return userList;
    }

    private List<FundingAwardParticipant> getFundingAwardParticipants(List<User> users) { 
        Map<Id, User> usersMap = new Map<Id, User>(users);
        Map<String, Object> bindParamsUser = new Map<String,Object>{ 
            'userIds' => usersMap.keySet()
        };
        String fundingAwardParticipantQuery = 'SELECT Id, ParticipantId, FundingAwardId FROM FundingAwardParticipant WHERE ParticipantId IN :userIds';
        List<FundingAwardParticipant> fundingAwardParticipants = selector.query(fundingAwardParticipantQuery, bindParamsUser);
        return fundingAwardParticipants;
    }

    private List<Chat__c> getChats(List<FundingAwardParticipant> fundingAwardParticipants) { 
        List<Id> fundingAwardIds = new List<Id>();
        for(FundingAwardParticipant fap : fundingAwardParticipants) {
            fundingAwardIds.add(fap.FundingAwardId);
        }
        Map<String, Object> bindParamsFundingAward = new Map<String,Object>{
            'fundingAwardIds' => fundingAwardIds
        };
        String chatQuery = 'SELECT Id, Name, CreatedDate, Context_Child__c, Context_Parent__c, Messages__c, Read_Receipts__c, Message_Count__c FROM Chat__c WHERE Context_Parent__c IN :fundingAwardIds';
        List<Chat__c> chats = selector.query(chatQuery, bindParamsFundingAward);
        return chats;
    }

    public EmailTemplate getEmailTemplate() {
        Map<String, Object> bindParamsTemplate = new Map<String, Object>{
            'templateName' => EMAIL_TEMPLATE_NAME
        };
        String emailTemplateSelected = 'SELECT Id, Subject, Body, HtmlValue FROM EmailTemplate WHERE DeveloperName = :templateName LIMIT 1';
        List<EmailTemplate> emailTemplate = selector.query(emailTemplateSelected, bindParamsTemplate);
        return emailTemplate[0];
    }
    
    public OrgWideEmailAddress getOrgWideEmailAddress() {
        String orgWideEmailQuery = 'SELECT Id FROM OrgWideEmailAddress WHERE Address = \'sigma.admin@ics.gov.uk\' LIMIT 1';
        List<OrgWideEmailAddress> owea = selector.query(orgWideEmailQuery);
        return owea[0];
    }
    
    public void execute(QueueableContext context) {

        List<User> userList = getUsers(); //List of users
        if(userList.size() == 0) {
            return;
        }
        Map<Id, List<Id>> fundingAwardIdToUserMap = new Map<Id, List<Id>>(); //Funding award Id to list of users
        Map<Id, String> userMap = new Map<Id, String>(); //User Id to unread chat messages
        List<FundingAwardParticipant> fundingAwardParticipants = getFundingAwardParticipants(userList); //List of funding award participants related to users

        //Loop funding awards related to users found and populate maps
        for(FundingAwardParticipant fpa : fundingAwardParticipants) {
            if(fundingAwardIdToUserMap.containsKey(fpa.FundingAwardId)) {
                fundingAwardIdToUserMap.get(fpa.FundingAwardId).add(fpa.ParticipantId);
            } else {
                fundingAwardIdToUserMap.put(fpa.FundingAwardId, new List<Id>{fpa.ParticipantId}); 
            }
            if(!userMap.containsKey(fpa.ParticipantId)) {
                userMap.put(fpa.ParticipantId,'0');
            }
        }

        for(Chat__c chat : getChats(fundingAwardParticipants)) {
            List<Id> userIds = fundingAwardIdToUserMap.get(chat.Context_Parent__c); //get a list of users this chat is relevant for
            readReceiptService.deserializeReadReceipts(chat); //pass chat ID into new readRecieptService method to deserialize
            for(Id userId : userIds) {
                Integer unreadMessages = readReceiptService.getUnreadMessagesForUser(userId);
                if(unreadMessages != null) {
                    userMap.put(userId, String.valueOf(Integer.valueOf(userMap.get(userId)) + unreadMessages)); 
                }
            }
        }


        EmailTemplate emailTemplate = getEmailTemplate(); //Get email template
        OrgWideEmailAddress owea = getOrgWideEmailAddress();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>(); //Create empty list of emails to send
        List<User> usrToUpdate = new List<User>(); //Empty list of users to update

        for(User usr : userList) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{usr.Email});
            email.setOrgWideEmailAddressId(owea.Id);
            String body = emailTemplate.HtmlValue;
            if(userMap.containsKey(usr.Id)) {
                body = body.replace('{UnreadMessages}', userMap.get(usr.Id));
            } else {
                body = body.replace('{UnreadMessages', '0');
            }
            body = body.replace('{FirstName}', usr.FirstName);
            email.setHtmlBody(body);
            emails.add(email);

            usr.Last_Login_Reminder_Sent__c = System.today();
            usrToUpdate.add(usr);
        }
        //send email stub
        dml.sendEmail(emails, true);
        //update users
        dml.setTarget(usrToUpdate).doUpdate();

        if(userList.size() >= CHUNK_SIZE) {
            systemUtil.enqueueJob(this);
        }
    }
}