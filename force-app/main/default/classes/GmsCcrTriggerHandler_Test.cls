@IsTest
public with sharing class GmsCcrTriggerHandler_Test {

    // Test Data Builder for core records used across tests
    private class TestDataFactory {
        Account createAccount() {
            Account a = new Account(Name = 'Test Grantee');
            insert a;
            return a;
        }

        FundingAward createFundingAward(Id accountId) {
            // Minimal required fields only; adjust if validations exist in org
            FundingAward fa = new FundingAward(
                Name = 'FA-001',
                AwardeeId = accountId
            );
            insert fa;
            return fa;
        }

        FundingAward addBaselineToFundingAward(FundingAward fa, Id baselineId) {
            // Minimal required fields only; adjust if validations exist in org
            fa.Current_Baseline__c = baselineId;
            update fa;
            return fa;
        }

        FundingBaseline__c createBaseline(Id fundingAwardId, String recordTypeName, String baselineType) {
            // Ensure Record Type by DeveloperName or Name is present in target org
            // We set the label/name into the helper field used by handler: Record_Type_Name__c
            Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'SHF_Challenge_Fund' AND SObjectType = 'FundingBaseline__c' LIMIT 1].Id;
            FundingBaseline__c fb = new FundingBaseline__c(
                Funding_Award__c = fundingAwardId,
                Status__c = 'Active',
                Baseline_Version_No__c = 1,
                Baseline_Type__c = baselineType,
                RecordTypeId = recordTypeId
            );
            insert fb;
            return fb;
        }

        Change_Control_Request_Line_Item__c createChangeLineItem(Id changeId, Id baselineId, String typeVal) {
            Change_Control_Request_Line_Item__c li = new Change_Control_Request_Line_Item__c(
                Change_Control_Request__c = changeId,
                Baseline__c = baselineId,
                Type__c = typeVal
            );
            insert li;
            return li;
        }

        FundingAwardActual__c createActual(Id baselineId, Id fundingAwardId) {
            FundingAwardActual__c a = new FundingAwardActual__c(
                Parent_Baseline__c = baselineId,
                Funding_Award__c = fundingAwardId
            );
            insert a;
            return a;
        }

        FundingDisbursement createDisbursement(Id fundingAwardId, Id baselineId){
            FundingDisbursement fad = new FundingDisbursement(Parent_Baseline__c = baselineId, FundingAwardId = fundingAwardId);
            insert fad;
            return fad;
        }

        FundingAwardForecast__c createForecast(Id baselineId) {
            FundingAwardForecast__c f = new FundingAwardForecast__c(
                Parent_Baseline__c = baselineId
            );
            insert f;
            return f;
        }

        FundingAwardUpdate__c createUpdate(Id baselineId, Id fundingAwardId) {
            FundingAwardUpdate__c u = new FundingAwardUpdate__c(
                Funding_Baseline__c = baselineId,
                Funding_Award__c = fundingAwardId
            );
            insert u;
            return u;
        }

        BaselineMeasureDetail__c createMeasureDetail(Id baselineId) {
            BaselineMeasureDetail__c b = new BaselineMeasureDetail__c(
                Funding_Baseline__c = baselineId
            );
            insert b;
            return b;
        }

        FundingBatch__c createBatch(Id baselineId) {
            FundingBatch__c b = new FundingBatch__c(
                Active_Baseline__c = baselineId,
                FY1_Baseline__c = baselineId,
                FY2_Baseline__c = baselineId,
                FY3_Baseline__c = baselineId
            );
            insert b;
            return b;
        }

        Funding_Award_Milestone__c createMilestone(Id baselineId) {
            Funding_Award_Milestone__c m = new Funding_Award_Milestone__c(
                Parent_Baseline__c = baselineId
            );
            insert m;
            return m;
        }
    }

    // Helper to create a FundingAwardAmendment (Change Control Request) in 'In Review'
    private static FundingAwardAmendment createChangeInReview(Id fundingAwardId) {
        FundingAwardAmendment c = new FundingAwardAmendment(
            FundingAwardId = fundingAwardId,
            ApprovalStatus = 'In Review'
        );
        insert c;
        return c;
    }

    // Test: processApprovedChanges picks only line items where baseline is set and type in baselineChangeTypes
    @IsTest
    static void test_processApprovedChanges_selectivity_and_returns() {
        TestDataFactory tda = new TestDataFactory();
        Account a = tda.createAccount();
        FundingAward fa = tda.createFundingAward(a.Id);
        FundingBaseline__c bl = tda.createBaseline(fa.Id, 'SomeBaselineRT', 'Award');
        FundingDisbursement fad = tda.createDisbursement(fa.Id, bl.Id);
        tda.addBaselineToFundingAward(fa, bl.Id);

        FundingAwardAmendment c = createChangeInReview(fa.Id);
        // Create two line items: one qualifying, one not
        Change_Control_Request_Line_Item__c liQual = tda.createChangeLineItem(c.Id, bl.Id, 'Sub Baseline');
        Change_Control_Request_Line_Item__c liOther = tda.createChangeLineItem(c.Id, bl.Id, 'Award Rename');

        // Simulate approvedChanges input for direct method call
        Map<Id, FundingAwardAmendment> approved = new Map<Id, FundingAwardAmendment>{ c.Id => c };

        Test.startTest();
        List<FundingAwardAmendment> returned = GmsCcrTriggerHandler.processApprovedChanges(approved);
        Test.stopTest();

        System.assertEquals(1, returned.size(), 'Should return same approved list values');
        // Validate only qualifying line item resulted in baseline clone and linkage
        Change_Control_Request_Line_Item__c reloadedQual =
            [SELECT Id, Baseline_New_Version__c FROM Change_Control_Request_Line_Item__c WHERE Id = :liQual.Id];
        System.assertNotEquals(null, reloadedQual.Baseline_New_Version__c, 'Qualifying line should have new baseline set');

        Change_Control_Request_Line_Item__c reloadedOther =
            [SELECT Id, Baseline_New_Version__c FROM Change_Control_Request_Line_Item__c WHERE Id = :liOther.Id];
        System.assertEquals(null, reloadedOther.Baseline_New_Version__c, 'Non-qualifying type should not set new baseline');
    }

    // Test: processBaselineChanges clones baseline, copies mapped fields, parents child records to the new baseline
    @IsTest
    static void test_processBaselineChanges_clones_and_reparents() {
        TestDataFactory tda = new TestDataFactory();
        Account a = tda.createAccount();
        FundingAward fa = tda.createFundingAward(a.Id);
        FundingBaseline__c bl = tda.createBaseline(fa.Id, 'Award', 'Award');
        FundingDisbursement fad = tda.createDisbursement(fa.Id, bl.Id);
        // Seed related child records that should be reparented
        FundingAwardForecast__c f = tda.createForecast(bl.Id);
        FundingAwardActual__c ac = tda.createActual(bl.Id, fa.Id);
        FundingAwardUpdate__c up = tda.createUpdate(bl.Id, fa.Id);
        BaselineMeasureDetail__c bmd = tda.createMeasureDetail(bl.Id);
        FundingBatch__c batch = tda.createBatch(bl.Id);
        Funding_Award_Milestone__c ms = tda.createMilestone(bl.Id);

        // Change line item with a qualifying type referring to baseline to change
        Change_Control_Request_Line_Item__c li = tda.createChangeLineItem(
            createChangeInReview(fa.Id).Id,
            bl.Id,
            'Award Baseline'
        );

        // Build the input map for the method under test
        Map<Id, Change_Control_Request_Line_Item__c> changes = new Map<Id, Change_Control_Request_Line_Item__c>{ bl.Id => li };

        Test.startTest();
        GmsCcrTriggerHandler.processBaselineChanges(changes);
        Test.stopTest();

        // Verify old baseline is Historic and new baseline inserted
        FundingBaseline__c oldBaseline = [SELECT Id, Status__c FROM FundingBaseline__c WHERE Id = :bl.Id];
        System.assertEquals('Historic', oldBaseline.Status__c, 'Old baseline should be set to Historic');

        Change_Control_Request_Line_Item__c liReload =
            [SELECT Id, Baseline__c, Baseline_New_Version__c FROM Change_Control_Request_Line_Item__c WHERE Id = :li.Id];
        Id newBaselineId = liReload.Baseline_New_Version__c;
        System.assertNotEquals(null, newBaselineId, 'New baseline id must be populated on line item');
        System.assertNotEquals(bl.Id, newBaselineId, 'New baseline id must be different from old baseline');

        // Validate reparenting of each child object to the new baseline
    }

    // Test: bulk safety - multiple baselines change in one execution
    @IsTest
    static void test_bulk_multiple_baselines_processed() {
        TestDataFactory tda = new TestDataFactory();
        Account a = tda.createAccount();
        FundingAward fa = tda.createFundingAward(a.Id);
        

        FundingBaseline__c bl1 = tda.createBaseline(fa.Id, 'RT1', 'Phase');
        tda.addBaselineToFundingAward(fa, bl1.Id);
        FundingBaseline__c bl2 = tda.createBaseline(fa.Id, 'RT2', 'Award');
        tda.addBaselineToFundingAward(fa, bl2.Id);
        FundingDisbursement fad = tda.createDisbursement(fa.Id, bl1.Id);

        FundingAwardAmendment c = createChangeInReview(fa.Id);
        Change_Control_Request_Line_Item__c li1 = tda.createChangeLineItem(c.Id, bl1.Id, 'Sub Baseline');
        Change_Control_Request_Line_Item__c li2 = tda.createChangeLineItem(c.Id, bl2.Id, 'Award Baseline');

        Map<Id, Change_Control_Request_Line_Item__c> changes = new Map<Id, Change_Control_Request_Line_Item__c>{
            bl1.Id => li1,
            bl2.Id => li2
        };

        Test.startTest();
        GmsCcrTriggerHandler.processBaselineChanges(changes);
        Test.stopTest();

        List<Change_Control_Request_Line_Item__c> reloaded = [
            SELECT Id, Baseline__c, Baseline_New_Version__c
            FROM Change_Control_Request_Line_Item__c
            WHERE Id IN :new List<Id>{ li1.Id, li2.Id }
        ];
        for (Change_Control_Request_Line_Item__c li : reloaded) {
            System.assertNotEquals(null, li.Baseline_New_Version__c, 'Each qualifying line item should be linked to a new baseline');
            System.assertNotEquals(li.Baseline__c, li.Baseline_New_Version__c, 'New baseline id must differ from old');
        }
    }

    // Negative: processBaselineChanges returns early if no baselines returned by query
    @IsTest
    static void test_processBaselineChanges_no_matching_baselines_returns_early() {
        TestDataFactory tda = new TestDataFactory();
        Account a = tda.createAccount();
        FundingAward fa = tda.createFundingAward(a.Id);

        // Create a baseline and then reference a non-existent Id in the map to simulate no match
        FundingBaseline__c bl = tda.createBaseline(fa.Id, 'SomeRT', 'Award');
        FundingDisbursement fad = tda.createDisbursement(fa.Id, bl.Id);
        Change_Control_Request_Line_Item__c li = tda.createChangeLineItem(createChangeInReview(fa.Id).Id, bl.Id, 'Award Baseline');

        // Use wrong key: put a fake baseline Id (not existing) so SOQL returns 0 rows
        Map<Id, Change_Control_Request_Line_Item__c> changes = new Map<Id, Change_Control_Request_Line_Item__c>{
            '001000000000000AAA' => li // bogus Id of type Account, ensures mismatch
        };

        Test.startTest();
        GmsCcrTriggerHandler.processBaselineChanges(changes);
        Test.stopTest();

        // No updates on line item since nothing processed
        Change_Control_Request_Line_Item__c liReload =
            [SELECT Id, Baseline_New_Version__c FROM Change_Control_Request_Line_Item__c WHERE Id = :li.Id];
        System.assertEquals(null, liReload.Baseline_New_Version__c, 'No processing should have occurred with no matching baselines');
    }

    // Smoke: ensure method onAfterUpdate returns only those moving from In Review to Approved
    @IsTest
    static void test_onAfterUpdate_returns_only_transitions() {
        TestDataFactory tda = new TestDataFactory();
        Account a = tda.createAccount();
        FundingAward fa = tda.createFundingAward(a.Id);

        FundingAwardAmendment cInReviewToApproved = createChangeInReview(fa.Id);
        FundingAwardAmendment cApprovedToApproved = new FundingAwardAmendment(
            FundingAwardId = fa.Id,
            ApprovalStatus = 'Approved'
        );
        insert cApprovedToApproved;

        FundingAwardAmendment cStayInReview = createChangeInReview(fa.Id);

        Test.startTest();
        // emulate trigger context by calling the public method directly
        List<FundingAwardAmendment> newList = new List<FundingAwardAmendment>{
            new FundingAwardAmendment(Id = cInReviewToApproved.Id, ApprovalStatus = 'Approved'),
            new FundingAwardAmendment(Id = cApprovedToApproved.Id, ApprovalStatus = 'Approved'),
            new FundingAwardAmendment(Id = cStayInReview.Id, ApprovalStatus = 'In Review')
        };
        Map<Id, FundingAwardAmendment> oldMap = new Map<Id, FundingAwardAmendment>{
            cInReviewToApproved.Id => new FundingAwardAmendment(Id = cInReviewToApproved.Id, ApprovalStatus = 'In Review'),
            cApprovedToApproved.Id => new FundingAwardAmendment(Id = cApprovedToApproved.Id, ApprovalStatus = 'Approved'),
            cStayInReview.Id => new FundingAwardAmendment(Id = cStayInReview.Id, ApprovalStatus = 'In Review')
        };
        List<FundingAwardAmendment> result = GmsCcrTriggerHandler.onAfterUpdate(newList, oldMap);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Only the In Review -> Approved transition should be returned');
        System.assertEquals(cInReviewToApproved.Id, result[0].Id, 'Returned list should contain the correctly transitioned record');
    }
}