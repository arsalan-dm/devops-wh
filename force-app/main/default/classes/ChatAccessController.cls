public without sharing class ChatAccessController {
    // to make this org independent this will need to be reflective
    // https://zachelrath.wordpress.com/2012/10/21/apex-reflection-brought-to-you-by-json/

    public Boolean checkCurrentUserAccess(String fundingAwardId){ 
        if (!currentUserOnFundingAward(fundingAwardId)){
            throw new HandledException('User does not have access to this chat');
        }
        return true;
    }

    public Boolean checkCurrentUserEdit(ChatMessage message, ChatMessaging chatMessaging){
        if (!currentUserCanEdit(message, chatMessaging)){
            throw new HandledException('User does not have access to edit this chat');
        }
        return true;
    }

    private Boolean currentUserOnFundingAward(String fundingAwardId){
        if (FeatureManagement.checkPermission('Chat_View_All')){
            return true;
        }
        List<FundingAwardParticipant> usersParticipantRecord = [SELECT Id, ParticipantId, FundingAwardId FROM FundingAwardParticipant WHERE IsParticipantActive = true AND ParticipantId = :UserInfo.getUserId() AND FundingAwardId = :fundingAwardId LIMIT 1];
        if (usersParticipantRecord.size() > 0){
            return true;
        }
        return false;
    }

    private Boolean currentUserCanEdit(ChatMessage message, ChatMessaging chatMessaging){
        if (FeatureManagement.checkPermission('Chat_Internal_User')){ // all internal users can edit
            return true;
        }
        ChatMessage storedMessage = chatMessaging.get(message.key);
        if (UserInfo.getUserId() == storedMessage.authorId){
            return true;
        }

        return false;
    }
}