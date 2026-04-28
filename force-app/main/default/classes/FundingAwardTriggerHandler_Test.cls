@IsTest
public with sharing class FundingAwardTriggerHandler_Test {

    @TestSetup
    public static void makeData(){
        FundingAward fa1 = new FundingAward();
        fa1.OwnerId = UserInfo.getUserId();
        fa1.Name = 'Test 1';

        FundingAward fa2 = new FundingAward();
        fa2.OwnerId = UserInfo.getUserId();
        fa2.Name = 'Test 2';
        insert new List<FundingAward>{fa1, fa2};
    }
    
    @IsTest
    public static void defaultCustomOwner(){
        Id ownerId = UserInfo.getUserId();
        FundingAward fa1 = new FundingAward();
        fa1.OwnerId = ownerId;
        Test.startTest();
        FundingAwardTriggerHandler.defaultCustomOwner(new List<FundingAward>{fa1});
        Test.stopTest();
        Assert.areEqual(ownerId, fa1.Owner__c, 'The custom owner field should mirror the standard owner field');
    }

    @IsTest
    public static void onBeforeInsert(){
        Id ownerId = UserInfo.getUserId();
        FundingAward fa1 = new FundingAward();
        fa1.OwnerId = ownerId;
        Test.startTest();
        insert fa1;
        Test.stopTest();
        FundingAward faAfter = [SELECT Id, OwnerId, Owner__c FROM FundingAward WHERE Id = :fa1.Id LIMIT 1];
        Assert.areEqual(ownerId, faAfter.Owner__c, 'The custom owner field should mirror the standard owner field');
    }

    @IsTest
    public static void onBeforeUpdate(){
        FundingAward faBefore = [SELECT Id, OwnerId, Owner__c FROM FundingAward WHERE Owner__c = :UserInfo.getUserId() LIMIT 1];
        User user = [SELECT Id FROM User WHERE Id != :UserInfo.getUserId() AND IsActive = true AND Profile.Name = 'System Administrator' LIMIT 1];
        faBefore.OwnerId = user.Id;
        Test.startTest();
        update faBefore;
        Test.stopTest();
        FundingAward faAfter = [SELECT Id, OwnerId, Owner__c FROM FundingAward WHERE Id = :faBefore.Id LIMIT 1];
        Assert.areEqual(user.Id, faAfter.Owner__c,  'The custom owner field should mirror the standard owner field');
    }
}