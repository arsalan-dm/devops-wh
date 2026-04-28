@istest
public with sharing class FollowController_Test {

    @TestSetup
    public static void makeData(){
        Account a = new Account();
        a.Name = 'test1';
        Account a2 = new Account();
        a2.Name = 'test2';
        Account a3 = new Account();
        a3.Name = 'test3';
        insert new List<Account>{a, a2, a3};

        Follow__c f = new Follow__c(Context__c = a.Id);
        Follow__c f2 = new Follow__c(Context__c = a2.Id);
        insert new List<Follow__c>{f, f2};
        
        Follow__Share fs = new Follow__Share();
        fs.UserOrGroupId = UserInfo.getUserId();
        fs.RowCause = Schema.Follow__Share.RowCause.Messaging__c;   
        fs.AccessLevel = 'Read';
        fs.ParentID = f.Id;

        Follow__Share fs2 = new Follow__Share();
        fs2.UserOrGroupId = UserInfo.getUserId();
        fs2.RowCause = Schema.Follow__Share.RowCause.Messaging__c;   
        fs2.AccessLevel = 'Read';
        fs2.ParentID = f2.Id;

        insert new List<Follow__Share>{fs, fs2};
    }

    @IsTest
    public static void createFollow() {
        Account a = new Account(Name = 'DESNZ');
        insert a;

        Test.startTest();
        Follow__Share followShare = FollowController.createFollow(a.Id);
        Test.stopTest();

        System.assert(followShare != null, 'should have returned a valid followShare record');
        System.assert(followShare.Id != null, 'should have returned a valid followShare record');
    }


    @IsTest
    public static void testCreateFollowException() {
        Test.startTest();
        try{
            Follow__Share followShare = FollowController.createFollow(null);
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Upsert failed'));
        }
        Test.stopTest();
    }

    @IsTest
    public static void deleteFollow() {
        Id contextId = [SELECT Id FROM Account WHERE Name = 'test1' LIMIT 1].Id;
        
        Test.startTest();
        List<Follow__Share> followShare = FollowController.deleteFollow(contextId);
        Test.stopTest();
        Map<Id, Follow__Share> shares = new Map<Id, Follow__Share>(followShare);
        List<Follow__Share> sharesRemaining = [SELECT Id FROM Follow__Share WHERE Id IN :shares.keySet()];
        Assert.areEqual(0, sharesRemaining.size(), 'number of shares remaining');
    }

    @IsTest
    public static void currentUserFollows_true(){
        Id contextId = [SELECT Id FROM Account WHERE Name = 'test2' LIMIT 1].Id;
        Test.startTest();
        Boolean current = FollowController.currentUserFollows(contextId);
        Test.stopTest();
        Assert.isTrue(current, 'the current user does not follow the context given \'' + contextId + '\'');
    }

    @IsTest
    public static void currentUserFollows_false(){
        Id contextId = [SELECT Id FROM Account WHERE Name = 'test3' LIMIT 1].Id;
        Test.startTest();
        Boolean current = FollowController.currentUserFollows(contextId);
        Test.stopTest();
        Assert.isFalse(current, 'the current user does follow the context given \'' + contextId + '\'');
    }
}