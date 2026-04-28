public without sharing class FollowController {
    
    // DG Dropped this for now 
    // following only implemented internally so need to access control
    // public static MessagingAccessController messagingAccessController = new MessagingAccessController();
    
    // aura handled methods
    @AuraEnabled
    public static Follow__Share createFollow(String contextId){
        try {
            ChatMessage message = new ChatMessage();
            message.contextParent = contextId;
            
            // DG Dropped this for now
            // messagingAccessController.checkCurrentUserAccess(message);

            Follow__c follow = new Follow__c();
            follow.Context__c = contextId;
            upsert follow Context__c; // upsert against the context field, creating or just updating the follow record 
            Follow__Share followShare = new Follow__Share();
            followShare.ParentID = follow.Id;
            followShare.UserOrGroupId = UserInfo.getUserId();
            followShare.AccessLevel = 'Read';
            followShare.rowCause = Schema.Follow__Share.RowCause.Messaging__c;
            Database.SaveResult sr = Database.insert(followShare);
            if (!sr.isSuccess()){
                for (Database.Error dErr : sr.getErrors()){
                    DmlException dmlException = new DmlException(dErr.getMessage());
                    throw dmlException;
                }
            }
            return followShare;
        } catch (Exception e) {
            return (Follow__Share)handleAuraExpection(e);
        }
    }

    @AuraEnabled
    public static Boolean currentUserFollows(String contextId){
        try {
            ChatMessage message = new ChatMessage();
            message.contextParent = contextId;

            // DG Dropped this for now
            //messagingAccessController.checkCurrentUserAccess(message);
            
            // check if the current user is a user on the contextId
            List<Follow__c> follows = [SELECT Id FROM Follow__c WHERE Context__c = :contextId WITH SECURITY_ENFORCED];
            if (follows.isEmpty()){
                return false;
            }
            Integer followCount = [SELECT COUNT() FROM Follow__Share WHERE ParentID = :follows.get(0).Id AND UserOrGroupId = :UserInfo.getUserId() AND RowCause =:Schema.Follow__Share.RowCause.Messaging__c WITH SECURITY_ENFORCED];
            return followCount > 0;
        } catch (Exception e) {
            return (Boolean)handleAuraExpection(e);
        }
    }

    @AuraEnabled
    public static List<Follow__Share> deleteFollow(String contextId){
        try {
            ChatMessage message = new ChatMessage();
            message.contextParent = contextId;

            // DG Dropped this for now
            // messagingAccessController.checkCurrentUserAccess(message);
            Set<String> userIds = new Set<String>();
            userIds.add(UserInfo.getUserId());
            List<Follow__Share> fs = getFollows(contextId, userIds);
            delete fs;
            return fs;
        } catch (Exception e) {
            return (List<Follow__Share>)handleAuraExpection(e);
        }
    }

    // reuseable methods
    public static List<Follow__Share> getFollows(String contextId, Set<String> userIds){
        List<Follow__c> follow = [SELECT Id FROM Follow__c WHERE Context__c = :contextId WITH SECURITY_ENFORCED];
        if (follow.size() > 0){
            List<Follow__Share> fs = [SELECT Id, ParentId, RowCause FROM Follow__Share WHERE ParentID = :follow.get(0).Id AND UserOrGroupId IN :userIds AND RowCause =:Schema.Follow__Share.RowCause.Messaging__c WITH SECURITY_ENFORCED];
            return fs;
        }
        throw new HandledException('Having fun?');
    }

    public static Object handleAuraExpection(Exception e){ // this is to help with getting better code coverage %, without going full mocking 
        AuraHandledException ahe = new AuraHandledException(e.getMessage());
        ahe.setMessage(e.getMessage());
        throw ahe;
    }
}