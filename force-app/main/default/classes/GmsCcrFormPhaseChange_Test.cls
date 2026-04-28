@istest
public with sharing class GmsCcrFormPhaseChange_Test {
    
    // agent force wrote some ass code and I've cleaned it up
    private static Id getCcrLineItemShfRecordTypeId() {
        return Schema.Change_Control_Request_Line_Item__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('SHF_Challenge_Fund').getRecordTypeId();
    }

    
    private static FundingBaseline__c makeBaseline(Date startDate, Date endDate, Integer homesToUpgrade) {
        FundingBaseline__c fb = new FundingBaseline__c();
        fb.Baseline_Start_Date__c = startDate;
        fb.Baseline_End_Date__c = endDate;
        fb.Total_Homes_to_be_Upgraded__c = homesToUpgrade;
        fb.Id = Stub.getId(fb);
        return fb;
    }

    // Creates an initial CCR Line Item linked to a baseline
    private static Change_Control_Request_Line_Item__c makeExistingItem(Id baselineId, Date startDate, Date endDate, Integer totalHomes) {
        Change_Control_Request_Line_Item__c item = new Change_Control_Request_Line_Item__c();
        item.Baseline__c = baselineId;
        item.Type__c = 'Phase Change';
        item.RecordTypeId = getCcrLineItemShfRecordTypeId();
        item.Start_Date__c = startDate;
        item.Start_Date_Previous__c = startDate;
        item.End_Date__c = endDate;
        item.End_Date_Previous__c = endDate;
        item.Total_number_of_homes_to_be_upgraded__c = totalHomes;
        item.Cache__c = totalHomes;
        return item;
    }

    // Wraps inputs for invocable call
    private static List<GmsCcrFormPhaseChange.Input> makeInput(List<FundingBaseline__c> baselines, List<Change_Control_Request_Line_Item__c> items) {
        GmsCcrFormPhaseChange.Input i = new GmsCcrFormPhaseChange.Input();
        i.baselines = baselines;
        i.items = items;
        return new List<GmsCcrFormPhaseChange.Input>{ i };
    }

    @IsTest
    public static void getPhaseItems_getItemsForBaselines() {

        List<FundingBaseline__c> baselines = new List<FundingBaseline__c>{
            makeBaseline(Date.today(), Date.today().addMonths(1), 10),
            makeBaseline(Date.today().addDays(1), Date.today().addMonths(2), 20)
        };

        Test.startTest();
        List<GmsCcrFormPhaseChange.Output> outputs = GmsCcrFormPhaseChange.getPhaseItems(makeInput(baselines, null));
        Test.stopTest();
        List<Change_Control_Request_Line_Item__c> outputItems = outputs.get(0).items;
        Assert.areEqual(2, outputItems.size(), 'number of Items returned for 2 baselines');
        Assert.areEqual(outputItems.get(0).Total_number_of_homes_to_be_upgraded__c, 10,'number of homes to be upgraded for item 1');
    }

    @IsTest
    public static void getPhaseItems_getItemsWithExistingItems() {
        
        List<FundingBaseline__c> baselines = new List<FundingBaseline__c>{
            makeBaseline(Date.today(), Date.today().addMonths(1), 10),
            makeBaseline(Date.today().addDays(1), Date.today().addMonths(2), 20)
        };
        

        Change_Control_Request_Line_Item__c existing = makeExistingItem(
            baselines[0].Id,
            baselines[0].Baseline_Start_Date__c.addDays(-1),
            baselines[0].Baseline_End_Date__c.addDays(1),
            (Integer)(baselines[0].Total_Homes_to_be_Upgraded__c + 1) 
        );

        Test.startTest();
        List<GmsCcrFormPhaseChange.Output> outputs = GmsCcrFormPhaseChange.getPhaseItems(
            makeInput(baselines, new List<Change_Control_Request_Line_Item__c>{ existing })
        );
        Test.stopTest();
        List<Change_Control_Request_Line_Item__c> outputItems = outputs.get(0).items;
        Assert.areEqual(2, outputItems.size(), 'number of Items returned for 2 baselines');
        Assert.areEqual(outputItems.get(0).Total_number_of_homes_to_be_upgraded__c, 11,'number of homes to be upgraded for item 1');
    }

    @istest
    public static void getPhaseItems_newItemWithoutBaseline(){

        Change_Control_Request_Line_Item__c existing = makeExistingItem(
            null,
            System.today(),
            System.today().addDays(1),
            2 
        );

        Test.startTest();
        List<GmsCcrFormPhaseChange.Output> outputs = GmsCcrFormPhaseChange.getPhaseItems(
            makeInput(null, new List<Change_Control_Request_Line_Item__c>{ existing })
        );
        Test.stopTest();
        List<Change_Control_Request_Line_Item__c> outputItems = outputs.get(0).items;

        Assert.areEqual(1, outputItems.size(), 'number of Items returned for 2 baselines');
        Assert.areEqual(outputItems.get(0).Total_number_of_homes_to_be_upgraded__c, 2,'number of homes to be upgraded for item 1');
    }

    @istest
    public static void getPhaseItems_baselinsAndNewItemWithoutBaseline(){

        List<FundingBaseline__c> baselines = new List<FundingBaseline__c>{
            makeBaseline(Date.today(), Date.today().addMonths(1), 10),
            makeBaseline(Date.today().addDays(1), Date.today().addMonths(2), 20)
        };

        Change_Control_Request_Line_Item__c existing = makeExistingItem(
            null,
            System.today(),
            System.today().addDays(1),
            36 
        );

        Test.startTest();
        List<GmsCcrFormPhaseChange.Output> outputs = GmsCcrFormPhaseChange.getPhaseItems(
            makeInput(baselines, new List<Change_Control_Request_Line_Item__c>{ existing })
        );
        Test.stopTest();
        List<Change_Control_Request_Line_Item__c> outputItems = outputs.get(0).items;

        Assert.areEqual(3, outputItems.size(), 'number of Items returned for 2 baselines');
        Assert.areEqual(outputItems.get(outputItems.size() - 1).Total_number_of_homes_to_be_upgraded__c, 36,'number of homes to be upgraded for the last item');
    }


    @IsTest
    public static void getPhaseItems_nullBaselinesNullItems(){

        Test.startTest();
        List<GmsCcrFormPhaseChange.Output> outputs = GmsCcrFormPhaseChange.getPhaseItems(
            makeInput(null, null)
        );
        Test.stopTest();
        List<Change_Control_Request_Line_Item__c> outputItems = outputs.get(0).items;
        Assert.areEqual(null, outputItems, 'number of Items returned for 0 baselines');
    }

    @IsTest
    public static void getPhaseItems_emptyBaselines(){

        Test.startTest();
        List<GmsCcrFormPhaseChange.Output> outputs = GmsCcrFormPhaseChange.getPhaseItems(
            makeInput(new List<FundingBaseline__c>(), null)
        );
        Test.stopTest();
        List<Change_Control_Request_Line_Item__c> outputItems = outputs.get(0).items;
        Assert.areEqual(0, outputItems.size(), 'number of Items returned for 0 baselines');
    }
}