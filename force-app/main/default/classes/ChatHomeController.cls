public without sharing class ChatHomeController {

    public static ChatReadReceiptService readReceiptService = new ChatReadReceiptService();
    
    @AuraEnabled
    public static List<ChatRecord> getUserFollowingChats(){
        try {
            Map<Id, ChatRecord> chatRecords = new  Map<Id, ChatRecord>();

            // 1 - Get a list of follow shares for the current user
            Set<Id> followedContextIds = new Set<Id>();
            for (Follow__Share fs : [SELECT Id, ParentId,Parent.Name,Parent.Context__c, AccessLevel, RowCause, UserOrGroupId, UserOrGroup.Name FROM Follow__Share WHERE UserOrGroupId = :UserInfo.getUserId() AND RowCause =:Schema.Follow__Share.RowCause.Messaging__c]){
                followedContextIds.add(fs.Parent.Context__c);
            }
            
            Id runningUserId = UserInfo.getUserId();

            // Per parent context store all the child contexts and the number of unread messages
            Map<Id, Read> lastReadByContext = new Map<Id, Read>();
            // get and loop all parent contexts the current user is following
            for (Chat__c chat : [
                SELECT Id, Context_Parent__c, Context_Child__c, LastModifiedDate, Messages__c,
                    Read_Receipts__c,
                    Message_Count__c,
                    Previous_Chat__c, First_Message__c, Last_Message__c
                FROM Chat__c
                WHERE Context_Parent__c IN :followedContextIds
                ORDER BY Last_Message__c DESC
            ]) {
                Id ctxId = chat.Context_Parent__c;
                // calculate number of unread messages for each child context
                Read read = lastReadByContext?.get(ctxId) ?? new Read(); 
                Integer readCount = (readReceiptService.getReadReceiptNumber(chat.Read_Receipts__c, runningUserId) ?? 0);
                Integer unreadCount = (Integer)Math.max(0, chat.Message_Count__c - readCount);
                read.add(chat.Context_Child__c ?? chat.Context_Parent__c, unreadCount);
                lastReadByContext.put(ctxId, read);
                // create one ChatRecord per parent context that is being followed that has chats 
                if (followedContextIds.remove(ctxId)) {
                    chatRecords.put(ctxId, new ChatRecord(chat));
                }
            }

            for (Id parentContextId : chatRecords.keySet()){
                chatRecords.get(parentContextId).unreadMessageCount = lastReadByContext?.get(parentContextId)?.getTotalUnread() ?? 0;
            }
            // 3 - Some parent contexts (funding awards) wont have any chat messages and these wont have a chat record in the database. Add Chat records for followed contexts that do not yet have a Chat record based on parent context Id
            
            // add in chatRecords for followed contexts that have no chats 
            for (Id ctxId : followedContextIds) {
                chatRecords.put(ctxId, new ChatRecord((String)ctxId));
            }
                        
            // static helper
            appendExtraData(chatRecords);

            return chatRecords.values();
            
        } catch (Exception e) {
            return (List<ChatRecord>)handleAuraExpection(e);
        }
    }

    public static Object handleAuraExpection(Exception e){ // this is to help with getting better code coverage %, without going full mocking 
        //String message = 'Bad Request';
        AuraHandledException ahe = new AuraHandledException(e.getMessage());
        ahe.setMessage(e.getMessage());
        throw ahe;
    }


    public static void appendExtraData(Map<Id, ChatRecord> chatRecords){

        // lookup parent context records 
        Map<Id, FundingAward> parentContextRecords = new Map<Id, FundingAward>([SELECT Id, Name, Awardee.Name FROM FundingAward WHERE Id IN :chatRecords.keySet()]);
        System.debug('appendExtraData - parentContextRecords:' + parentContextRecords);

        // populate the records with the extra data
        for (ChatRecord chatRecord : chatRecords.values()){
            FundingAward parentRecord = parentContextRecords.get((Id)chatRecord.contextParent);
            chatRecord.contextParentName = parentRecord != null ? parentRecord.Name : 'Unknown Funding Award';     
            chatRecord.awardeeName = parentRecord != null ? parentRecord.Awardee.Name : 'Unknown Awardee';            
        }
    }

    // need to capture how many messages are unread per child context and then sum them to give the number of unreads per parent context
    private class Read{
        private Map<Id, Integer> unreadCount;

        Read(){
            this.unreadCount = new Map<Id, Integer>();
        }

        void add(String context, Integer countOfUnread){
            unreadCount.put(context, countOfUnread);
        }

        Integer getTotalUnread(){
            Integer count = 0;
            for (Integer c : unreadCount.values()){
                count += c;
            }
            return count;
        }
    }
}