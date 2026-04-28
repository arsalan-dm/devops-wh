@IsTest
public with sharing class ChatFundingAwardFollowSetter_Test {
    /**
     * Verifies no records are created when there are no FundingAward records.
     */
    @IsTest
    static void followsCreated() {
        Integer faCount = [SELECT COUNT() FROM FundingAward];

        Test.startTest();
        ChatFundingAwardFollowSetter.setDefaultFollows();
        Test.stopTest();

        Assert.areEqual(faCount, [SELECT COUNT() FROM Follow__c], 'number of follow shares should equal funding award count'); 
    }

    /**
     * Verifies a single FundingAward produces one Follow__c tied to the FA Id
     * and one Follow__Share with Read/Messaging__c for the owning user.
     */
    @IsTest
    static void test_singleFundingAward_createsOneFollowAndShare() {
        // Create a dedicated owner user
        User owner = createUser('owner1@example.com');

        // Create a FundingAward owned by that user
        FundingAward fa = new FundingAward();
        fa.OwnerId = owner.Id;
        insert fa;

        Test.startTest();
        ChatFundingAwardFollowSetter.setDefaultFollows();
        Test.stopTest();

        // Verify Follow__c created and linked via Context__c
        List<Follow__c> follows = [
            SELECT Id, Context__c
            FROM Follow__c
        ];
        Assert.areEqual(1, follows.size(), 'Exactly one Follow__c should be created');
        Assert.areEqual(fa.Id, follows[0].Context__c, 'Follow.Context__c should reference the FundingAward Id');

        // Verify Follow__Share - note: in the implementation, shares are inserted after follows
        // and fields set: ParentId (to Follow Id), UserOrGroupId (FA Owner), AccessLevel Read, RowCause Messaging__c
        List<Follow__Share> shares = [
            SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause
            FROM Follow__Share WHERE RowCause = :Schema.Follow__Share.RowCause.Messaging__c
        ];
        Assert.areEqual(1, shares.size(), 'Exactly one Follow__Share should be created');
        Assert.areEqual('Read', String.valueOf(shares[0].AccessLevel), 'AccessLevel must be Read');
        Assert.areEqual(String.valueOf(Schema.Follow__Share.RowCause.Messaging__c), String.valueOf(shares[0].RowCause), 'RowCause must be Messaging__c');
        Assert.areEqual(owner.Id, shares[0].UserOrGroupId, 'Share should be granted to the FundingAward owner');

        // Because the class sets fs.ParentId = f.Id before f is inserted,
        // the ParentId should reference the inserted Follow__c record.
        // We cannot directly correlate to follows[0].Id if multiple were possible; here there is only one.
        Assert.areEqual(follows[0].Id, shares[0].ParentId, 'Share ParentId should reference the created Follow__c');
    }

    /**
     * Verifies multiple FundingAwards produce a Follow__c and a Follow__Share each,
     * assigned to the correct owning users.
     */
    @IsTest
    static void test_multipleFundingAwards_bulkCreatesFollowAndShares() {
        User ownerA = createUser('ownerA@example.com');
        User ownerB = createUser('ownerB@example.com');

        List<FundingAward> fas = new List<FundingAward>();
        FundingAward fa1 = new FundingAward(OwnerId = ownerA.Id);
        FundingAward fa2 = new FundingAward(OwnerId = ownerB.Id);
        fas.add(fa1);
        fas.add(fa2);
        insert fas;

        Test.startTest();
        ChatFundingAwardFollowSetter.setDefaultFollows();
        Test.stopTest();

        // Collect follows and map by Context__c (which should be FA Id)
        List<Follow__c> follows = [
            SELECT Id, Context__c
            FROM Follow__c
            WHERE Context__c IN :new Set<Id>{fa1.Id, fa2.Id}
        ];
        Assert.areEqual(2, follows.size(), 'Two Follow__c should be created for two FundingAwards');

        // Shares - there should be exactly two, one per Follow
        List<Follow__Share> shares = [
            SELECT Id, ParentId, UserOrGroupId, AccessLevel, RowCause
            FROM Follow__Share WHERE RowCause = :Schema.Follow__Share.RowCause.Messaging__c
        ];
        Assert.areEqual(2, shares.size(), 'Two Follow__Share should be created for two FundingAwards');
        for (Follow__Share s : shares) {
            Assert.areEqual('Read', String.valueOf(s.AccessLevel), 'AccessLevel must be Read for all shares');
            Assert.areEqual(String.valueOf(Schema.Follow__Share.RowCause.Messaging__c), String.valueOf(s.RowCause), 'RowCause must be Messaging__c for all shares');
        }

        // Validate user assignment by correlating share ParentId back to Follow.Context__c (FA Id) via a map
        Map<Id, Follow__c> followById = new Map<Id, Follow__c>(follows);
        Set<Id> parentIds = new Set<Id>();
        for (Follow__Share s : shares) parentIds.add(s.ParentId);
        Assert.areEqual(2, parentIds.size(), 'Each share should reference a unique Follow__c parent');

        // Check each share: find its follow, then from Context__c infer which FA and verify UserOrGroupId matches FA.OwnerId
        Map<Id, Id> faIdByFollowId = new Map<Id, Id>();
        for (Follow__c f : follows) {
            faIdByFollowId.put(f.Id, f.Context__c);
        }

        for (Follow__Share s : shares) {
            Follow__c parentFollow = followById.get(s.ParentId);
            Assert.areNotEqual(null, parentFollow, 'Share must point to an existing Follow__c');

            Id contextFaId = parentFollow.Context__c;
            // Match expected owner
            Id expectedOwnerId = (contextFaId == fa1.Id) ? ownerA.Id : (contextFaId == fa2.Id) ? ownerB.Id : null;
            Assert.areNotEqual(null, expectedOwnerId, 'Share should map back to one of the created FundingAwards');
            Assert.areEqual(expectedOwnerId, s.UserOrGroupId, 'Share should be granted to the FundingAward owner that matches Follow.Context__c');
        }
    }

    // Utility: create a user with a unique username and basic profile
    private static User createUser(String uniqueEmail) {
        // Leverage an active profile for standard users
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User u = new User(
            FirstName = 'Test',
            LastName  = 'User',
            Email     = uniqueEmail,
            Username  = uniqueEmail + '.' + System.currentTimeMillis(),
            Alias     = 'tusr',
            TimeZoneSidKey = 'Europe/London',
            LocaleSidKey   = 'en_GB',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;
        return u;
    }
}
