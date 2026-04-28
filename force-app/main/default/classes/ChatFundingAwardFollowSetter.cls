public without sharing class ChatFundingAwardFollowSetter {
    @invocableMethod(label = 'Set default follows')
    public static void setDefaultFollows(){
        Map<Id, FundingAward> fas = new Map<Id, FundingAward>([SELECT Id, OwnerId FROM FundingAward]); 
        
        List<Follow__c> follows = new List<Follow__c>();
        List<Follow__Share> followShares = new List<Follow__Share>();
        for (FundingAward fa : fas.values()){
            Follow__c f = new Follow__c();
            f.Context__c = fa.Id;
            follows.add(f);            
        }

        upsert follows Context__c;

        for (Follow__c f : follows){
            Follow__Share fs = new Follow__Share();
            fs.ParentId = f.Id;
            fs.UserOrGroupId = fas.get(f.Context__c).OwnerId;
            fs.AccessLevel = 'Read';
            fs.rowCause = Schema.Follow__Share.RowCause.Messaging__c;
            followShares.add(fs);
        }

        List<Database.SaveResult> sr = Database.insert(followShares);
    }
}