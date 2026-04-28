public with sharing class FundingAwardTriggerHandler {
    
    public static List<FundingAward> onBeforeInsert(List<FundingAward> fundingAwards){
        defaultCustomOwner(fundingAwards);
        return fundingAwards;
    }

    public static List<FundingAward> onBeforeUpdate(List<FundingAward> fundingAwards, Map<Id, FundingAward> oldMap){
        defaultCustomOwner(fundingAwards);
        return fundingAwards;
    }

    public static void defaultCustomOwner(List<FundingAward> fundingAwards){
        for (FundingAward fa : fundingAwards){
            if (fa.OwnerId.getSObjectType() == Schema.User.getSObjectType()){
                fa.Owner__c = fa.OwnerId;
            }
        }
    }
}