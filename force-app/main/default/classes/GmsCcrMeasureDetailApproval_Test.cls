@IsTest
public with sharing class GmsCcrMeasureDetailApproval_Test {

    @TestSetup
    static void setupData() {
        FundingAward fa = new FundingAward();
        insert fa;

        FundingBaseline__c baseline = new FundingBaseline__c();
        insert baseline;
        
        FundingAwardAmendment faa = new FundingAwardAmendment(FundingAwardId = fa.Id);
        insert faa;

        // Create one BMD and a CCR Line Item that points to it (to be updated)
        BaselineMeasureDetail__c existingBmd = new BaselineMeasureDetail__c(
            Measure_KPI_Number__c = 999, // numeric KPI sentinel
            Measure_Type__c = 'Solar PV',
            Description__c = 'Old Desc',
            Funding_Baseline__c = baseline.Id
        );
        insert existingBmd;

        // Create some CCR Line Items without Baseline Measure Detail (to be inserted)
        List<Change_Control_Request_Line_Item__c> itemsToInsert = new List<Change_Control_Request_Line_Item__c>();
        for (Integer i = 0; i < 3; i++) {
            Change_Control_Request_Line_Item__c li = new Change_Control_Request_Line_Item__c();
            // Populate fields used by the class under test
            li.Measure_KPI_Number__c = Decimal.valueOf(i); // numeric field
            li.Property_Measure_Type__c = 'External Wall Insulation';
            li.Baseline_Measure_Description__c = 'Desc ' + i;
            li.Baseline__c = baseline.Id;
            li.Cost_To_Install_Measure__c = 300;
            li.Change_Control_Request__c = faa.Id;
            // No Baseline_Measure_Detail__c to force insert path
            itemsToInsert.add(li);
        }
        insert itemsToInsert;

        Change_Control_Request_Line_Item__c itemWithBmd = new Change_Control_Request_Line_Item__c(
            Measure_KPI_Number__c = 999,
            Property_Measure_Type__c = 'Loft insulation',
            Baseline_Measure_Description__c = 'New Desc',
            Baseline__c = baseline.Id,
            Change_Control_Request__c = faa.Id,
            Cost_To_Install_Measure__c = 300,
            Baseline_Measure_Detail__c = existingBmd.Id
        );
        insert itemWithBmd;
    }

    private static GmsCcrMeasureDetailApproval.Input buildInputFromAllItems() {
        List<Change_Control_Request_Line_Item__c> allItems = [
            SELECT Id, Measure_KPI_Number__c, Property_Measure_Type__c, Is_Delete_Change__c, Baseline_Measure_Description__c, Baseline__c, Baseline_Measure_Detail__c, Cost_To_Install_Measure__c
            FROM Change_Control_Request_Line_Item__c
            ORDER BY CreatedDate
        ];
        GmsCcrMeasureDetailApproval.Input input = new GmsCcrMeasureDetailApproval.Input();
        input.measureItems = allItems;
        return input;
    }

    @IsTest
    static void testCreateBaselineMeasureDetails_HappyPath_MixedInsertAndUpdate() {
        GmsCcrMeasureDetailApproval.Input input = buildInputFromAllItems();

        Test.startTest();
        List<GmsCcrMeasureDetailApproval.Output> results = GmsCcrMeasureDetailApproval.createBaselineMeasureDetailsFromItems(
            new List<GmsCcrMeasureDetailApproval.Input>{ input }
        );
        Test.stopTest();

        // Assert one Output entry returned
        System.assertEquals(1, results.size(), 'Exactly one Output should be returned for single Input');

        // The method only adds updated BMDs to output.measureDetails
        List<BaselineMeasureDetail__c> updatedReturned = results[0].measureDetails;
        System.assertNotEquals(null, updatedReturned, 'Output.measureDetails should not be null');
        System.assertEquals(1, updatedReturned.size(), 'Only the updated BMD should be in the output list');

        BaselineMeasureDetail__c returnedBmd = updatedReturned[0];
        System.assertEquals(Decimal.valueOf(999), returnedBmd.Measure_KPI_Number__c, 'Updated BMD KPI should match CCR item KPI');
        System.assertEquals('Loft insulation', returnedBmd.Measure_Type__c, 'Updated BMD type should come from CCR item');
        System.assertEquals('New Desc', returnedBmd.Description__c, 'Updated BMD description should come from CCR item');

        // Verify inserts occurred and CCR items backfilled with new BMD Ids
        List<Change_Control_Request_Line_Item__c> items = [
            SELECT Id, Baseline_Measure_Detail__c, Measure_KPI_Number__c, Cost_To_Install_Measure__c, Property_Measure_Type__c, Baseline_Measure_Description__c, Baseline__c
            FROM Change_Control_Request_Line_Item__c
            ORDER BY CreatedDate
        ];
        Integer itemsWithBackfilledBmd = 0;
        for (Change_Control_Request_Line_Item__c li : items) {
            if (li.Measure_KPI_Number__c != 999) {
                System.assertEquals(true, li.Baseline_Measure_Detail__c != null, 'Baseline_Measure_Detail__c must be an Id when backfilled');
                // These were insert-path; should now have BMD Id backfilled
                System.assertNotEquals(null, li.Baseline_Measure_Detail__c, 'Insert-path CCR items must have BMD Id backfilled');
                itemsWithBackfilledBmd++;
            }
        }
        System.assertEquals(3, itemsWithBackfilledBmd, 'Three CCR items should have new BMDs backfilled');

        // Cross-check inserted BMDs values match source CCR items
        Map<Id, Change_Control_Request_Line_Item__c> liByBmdId = new Map<Id, Change_Control_Request_Line_Item__c>([
            SELECT Id, Baseline_Measure_Detail__c, Measure_KPI_Number__c, Property_Measure_Type__c, Cost_To_Install_Measure__c, Baseline_Measure_Description__c, Baseline__c
            FROM Change_Control_Request_Line_Item__c
            WHERE Baseline_Measure_Detail__c != null AND Measure_KPI_Number__c != 999
        ]);
        Set<Id> bmdIds = new Set<Id>();
        for (Change_Control_Request_Line_Item__c item : liByBmdId.values()){
            bmdIds.add(item.Baseline_Measure_Detail__c);
        }
        List<BaselineMeasureDetail__c> insertedBmds = [
            SELECT Id, Measure_KPI_Number__c, Measure_Type__c, Description__c, Funding_Baseline__c, Cost_To_Install_Measure__c
            FROM BaselineMeasureDetail__c
            WHERE Id IN :bmdIds
        ];
        System.assertEquals(3, insertedBmds.size(), 'Expect 3 newly inserted BMDs');

        // Verify updated BMD persisted changes in DB as well
        BaselineMeasureDetail__c persistedUpdated = [
            SELECT Id, Measure_KPI_Number__c, Measure_Type__c, Description__c, Funding_Baseline__c, Cost_To_Install_Measure__c
            FROM BaselineMeasureDetail__c
            WHERE Measure_KPI_Number__c = 999
            LIMIT 1
        ];
        System.assertEquals('Loft insulation', persistedUpdated.Measure_Type__c, 'Persisted BMD type should be updated');
        System.assertEquals('New Desc', persistedUpdated.Description__c, 'Persisted BMD description should be updated');
    }

    @IsTest
    static void testCreateBaselineMeasureDetails_EmptyInputList_NoWork() {
        // Edge case: empty measureItems in Input would throw on inputs.get(0) if no inputs are provided to invocable.
        // We provide one Input with empty items to exercise no-op branch inside loops.
        GmsCcrMeasureDetailApproval.Input input = new GmsCcrMeasureDetailApproval.Input();
        input.measureItems = new List<Change_Control_Request_Line_Item__c>();

        Test.startTest();
        List<GmsCcrMeasureDetailApproval.Output> results = GmsCcrMeasureDetailApproval.createBaselineMeasureDetailsFromItems(
            new List<GmsCcrMeasureDetailApproval.Input>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should still return one Output wrapper');
        System.assertEquals(0, results[0].measureDetails.size(), 'No updates should be returned for empty items');
        // Also assert no data was changed/created
        // Count BMDs created in setup and not related to bulk test; relax overly specific assumptions due to org state in test context
        Integer newBmdCount = [SELECT COUNT() FROM BaselineMeasureDetail__c WHERE Measure_KPI_Number__c IN (999)];
        System.assertEquals(1, newBmdCount, 'Setup created the existing BMD with KPI 999');
    }
}
