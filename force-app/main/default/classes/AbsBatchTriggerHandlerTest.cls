@istest
public class AbsBatchTriggerHandlerTest {
    private static Integer num = 0;

    private static String getBaselineId(sObject record){ 
        String result = String.valueOf(num++);
        return record.getSObjectType().getDescribe().getKeyPrefix() + '0'.repeat(12-result.length()) + result;
    } 

    @TestSetup
    public static void makeData(){
        FundingAward fa1 = new FundingAward();
        FundingAward fa2 = new FundingAward();
        FundingAward fa3 = new FundingAward();
        FundingAward fa4 = new FundingAward();
        FundingAward fa5 = new FundingAward();
        List<FundingAward> fas = new List<FundingAward>{fa1, fa2, fa3, fa4, fa5};
        insert fas;
        
        FundingBaseline__c awardBaseline1 = new FundingBaseline__c(Baseline_Type__c = 'Award', Funding_Award__c = fa1.Id, Status__c = 'Active');
        FundingBaseline__c awardBaseline2 = new FundingBaseline__c(Baseline_Type__c = 'Award', Funding_Award__c = fa2.Id, Status__c = 'Active');
        FundingBaseline__c awardBaseline3 = new FundingBaseline__c(Baseline_Type__c = 'Award', Funding_Award__c = fa3.Id, Status__c = 'Active');
        FundingBaseline__c awardBaseline4 = new FundingBaseline__c(Baseline_Type__c = 'Award', Funding_Award__c = fa4.Id, Status__c = 'Active');
        FundingBaseline__c awardBaseline5 = new FundingBaseline__c(Baseline_Type__c = 'Award', Funding_Award__c = fa5.Id, Status__c = 'Active');

        FundingBaseline__c fy11 = new FundingBaseline__c(Baseline_Type__c = 'Financial Year');
        fy11.Funding_Award__c = fa1.Id;
        FundingBaseline__c fy12 = new FundingBaseline__c(Baseline_Type__c = 'Financial Year');
        fy12.Funding_Award__c = fa2.Id;
        FundingBaseline__c fy13 = new FundingBaseline__c(Baseline_Type__c = 'Financial Year');
        fy13.Funding_Award__c = fa3.Id;
        FundingBaseline__c fy14 = new FundingBaseline__c(Baseline_Type__c = 'Financial Year');
        fy14.Funding_Award__c = fa4.Id;
        FundingBaseline__c fy15 = new FundingBaseline__c(Baseline_Type__c = 'Financial Year');
        fy15.Funding_Award__c = fa5.Id;
        
        FundingBaseline__c fy23 = new FundingBaseline__c(Baseline_Type__c = 'Financial Year');
        fy23.Funding_Award__c = fa3.Id;
        FundingBaseline__c fy24 = new FundingBaseline__c(Baseline_Type__c = 'Financial Year');
        fy24.Funding_Award__c = fa4.Id;
        FundingBaseline__c fy25 = new FundingBaseline__c(Baseline_Type__c = 'Financial Year');
        fy25.Funding_Award__c = fa5.Id;
        
        FundingBaseline__c fy35 = new FundingBaseline__c(Baseline_Type__c = 'Financial Year');
        fy35.Funding_Award__c = fa5.Id;
        List<FundingBaseline__c> fyBaselines = new List<FundingBaseline__c>{fy11, fy12, fy13, fy14, fy15, fy23, fy24, fy25, fy35, awardBaseline1, awardBaseline2, awardBaseline3, awardBaseline4, awardBaseline5};
        insert fyBaselines;

        FundingBatch__c fb1 = new FundingBatch__c();
        fb1.OOEP_Grant_Total__c = 1;
        fb1.FY1_Baseline__c = fy11.Id;
        fb1.Active_Baseline__c = awardBaseline1.Id;

        FundingBatch__c fb2 = new FundingBatch__c();
        fb2.OOEP_Grant_Total__c = 2;
        fb2.FY1_Baseline__c = fy12.Id;
        //fb2.ABS_Status__c = 'Approved';
        fb2.Active_Baseline__c = awardBaseline2.Id;

        FundingBatch__c fb3 = new FundingBatch__c();
        fb3.OOEP_Grant_Total__c = 3;
        fb3.Funding_Used_value__c = 1;
        fb3.FY1_Baseline__c = fy13.Id;
        fb3.FY2_Baseline__c = fy23.Id;
        fb3.Active_Baseline__c = awardBaseline3.Id;

        FundingBatch__c fb4 = new FundingBatch__c();
        fb4.OOEP_Grant_Total__c = 4;
        fb4.Funding_Used_value__c = 1;
        fb4.FY1_Baseline__c = fy14.Id;
        fb4.FY2_Baseline__c = fy24.Id;
        fb4.Active_Baseline__c = awardBaseline4.Id;

        FundingBatch__c fb5 = new FundingBatch__c();
        fb4.OOEP_Grant_Total__c = 5;
        fb4.Funding_Used_value__c = 1;
        fb4.Funding_Used_In_2nd_FY__c = 1;
        fb4.FY1_Baseline__c = fy15.Id;
        fb4.FY2_Baseline__c = fy25.Id;
        fb4.FY3_Baseline__c = fy35.Id;
        fb4.Active_Baseline__c = awardBaseline5.Id;

        List<FundingBatch__c> batches = new List<FundingBatch__c>{fb1, fb2, fb3, fb4};
        insert batches;
        
    }

    @istest
    public static void onAfterUpdate_SetStatusToApprovedSpans2FY(){
        FundingBatch__c fb = [SELECT Id, ABS_Status__c, FY1_Baseline__c, FY2_Baseline__c, Total_Grant_Fund_Requested__c, Funding_Used_value__c FROM FundingBatch__c WHERE OOEP_Grant_Total__c = 3];
        FundingBaseline__c beforeBaseline1 = [SELECT Id, ABS_FY_Grant_Spend_Rollup__c FROM FundingBaseline__c WHERE Id =:fb.FY1_Baseline__c];
        FundingBaseline__c beforeBaseline2 = [SELECT Id, ABS_FY_Grant_Spend_Rollup__c FROM FundingBaseline__c WHERE Id =:fb.FY2_Baseline__c];

        Test.startTest();
        fb.ABS_Status__c = 'Approved';
        fb.Version_Status__c = 'Active';
        update fb;
        Test.stopTest();

        FundingBaseline__c afterBaseline1 = [SELECT Id, ABS_FY_Grant_Spend_Rollup__c FROM FundingBaseline__c WHERE Id =:fb.FY1_Baseline__c];
        FundingBaseline__c afterBaseline2 = [SELECT Id, ABS_FY_Grant_Spend_Rollup__c FROM FundingBaseline__c WHERE Id =:fb.FY2_Baseline__c];
        
        Double afterAmount1 = (beforeBaseline1.ABS_FY_Grant_Spend_Rollup__c ?? 0) + (fb.Funding_Used_value__c ?? 0);
        Double afterAmount2 = (beforeBaseline2.ABS_FY_Grant_Spend_Rollup__c ?? 0) + (fb.Total_Grant_Fund_Requested__c ?? 0) - (fb.Funding_Used_value__c ?? 0);
        Assert.isTrue(afterBaseline1.ABS_FY_Grant_Spend_Rollup__c == afterAmount1, 'Expect the rollup on the FY1 baseline after the change to be \'' + afterAmount1.format() +'\' but received \'' + afterBaseline1.ABS_FY_Grant_Spend_Rollup__c?.format() + '\'' );
        Assert.isTrue(afterBaseline2.ABS_FY_Grant_Spend_Rollup__c == afterAmount2, 'Expect the rollup on the FY2 baseline after the change to be \'' + afterAmount2.format() +'\' but received \'' + afterBaseline2.ABS_FY_Grant_Spend_Rollup__c?.format() + '\'' );
    }

    @istest
    public static void onAfterUpdate_SetStatusToApproved(){
        FundingBatch__c fb = [SELECT Id, ABS_Status__c, FY1_Baseline__c, Total_Grant_Fund_Requested__c, Funding_Used_value__c FROM FundingBatch__c WHERE OOEP_Grant_Total__c = 1];
        FundingBaseline__c beforeBaseline = [SELECT Id, ABS_FY_Grant_Spend_Rollup__c FROM FundingBaseline__c WHERE Id =:fb.FY1_Baseline__c];

        Test.startTest();
        fb.ABS_Status__c = 'Approved';
        fb.Version_Status__c = 'Active';
        update fb;
        Test.stopTest();

        FundingBaseline__c afterBaseline = [SELECT Id, ABS_FY_Grant_Spend_Rollup__c FROM FundingBaseline__c WHERE Id =:fb.FY1_Baseline__c];
        
        Double afterAmount = (beforeBaseline.ABS_FY_Grant_Spend_Rollup__c ?? 0) + (fb.Total_Grant_Fund_Requested__c ?? 0);
        Assert.isTrue(afterBaseline.ABS_FY_Grant_Spend_Rollup__c == afterAmount, 'Expect the rollup on the baseline after the change to be \'' + afterAmount.format() +'\' but received \'' + afterBaseline.ABS_FY_Grant_Spend_Rollup__c?.format() + '\'' );
    }

    @istest
    public static void onAfterUpdate_SetStatusToApproved3FY(){
        FundingBatch__c fb = [SELECT Id, ABS_Status__c, FY1_Baseline__c, FY2_Baseline__c, FY3_Baseline__c, Total_Grant_Fund_Requested__c, Funding_Used_value__c,Funding_Used_In_2nd_FY__c  FROM FundingBatch__c WHERE OOEP_Grant_Total__c = 5];
        FundingBaseline__c beforeBaseline1 = [SELECT Id, ABS_FY_Grant_Spend_Rollup__c FROM FundingBaseline__c WHERE Id =:fb.FY1_Baseline__c];
        FundingBaseline__c beforeBaseline2 = [SELECT Id, ABS_FY_Grant_Spend_Rollup__c FROM FundingBaseline__c WHERE Id =:fb.FY2_Baseline__c];
        FundingBaseline__c beforeBaseline3 = [SELECT Id, ABS_FY_Grant_Spend_Rollup__c FROM FundingBaseline__c WHERE Id =:fb.FY3_Baseline__c];

        Test.startTest();
        fb.ABS_Status__c = 'Approved';
        fb.Version_Status__c = 'Active';
        update fb;
        Test.stopTest();

        FundingBaseline__c afterBaseline1 = [SELECT Id, ABS_FY_Grant_Spend_Rollup__c FROM FundingBaseline__c WHERE Id =:fb.FY1_Baseline__c];
        FundingBaseline__c afterBaseline2 = [SELECT Id, ABS_FY_Grant_Spend_Rollup__c FROM FundingBaseline__c WHERE Id =:fb.FY2_Baseline__c];
        FundingBaseline__c afterBaseline3 = [SELECT Id, ABS_FY_Grant_Spend_Rollup__c FROM FundingBaseline__c WHERE Id =:fb.FY3_Baseline__c];
        
        Double afterAmount1 = (beforeBaseline1.ABS_FY_Grant_Spend_Rollup__c ?? 0) + (fb.Funding_Used_value__c ?? 0);
        Double afterAmount2 = (beforeBaseline2.ABS_FY_Grant_Spend_Rollup__c ?? 0) + (fb.Funding_Used_In_2nd_FY__c ?? 0);
        Double afterAmount3 = (beforeBaseline3.ABS_FY_Grant_Spend_Rollup__c ?? 0) + (fb.Total_Grant_Fund_Requested__c ?? 0) - (fb.Funding_Used_value__c ?? 0) - (fb.Funding_Used_In_2nd_FY__c ?? 0);
        Assert.isTrue(afterBaseline1.ABS_FY_Grant_Spend_Rollup__c == afterAmount1, 'Expect the rollup on the FY1 baseline after the change to be \'' + afterAmount1.format() +'\' but received \'' + afterBaseline1.ABS_FY_Grant_Spend_Rollup__c?.format() + '\'' );
        Assert.isTrue(afterBaseline2.ABS_FY_Grant_Spend_Rollup__c == afterAmount2, 'Expect the rollup on the FY2 baseline after the change to be \'' + afterAmount2.format() +'\' but received \'' + afterBaseline2.ABS_FY_Grant_Spend_Rollup__c?.format() + '\'' );
        Assert.isTrue(afterBaseline3.ABS_FY_Grant_Spend_Rollup__c == afterAmount3, 'Expect the rollup on the FY3 baseline after the change to be \'' + afterAmount3.format() +'\' but received \'' + afterBaseline3.ABS_FY_Grant_Spend_Rollup__c?.format() + '\'' );
    }

    @istest
    public static void addToBaselineFyTotalAll(){
        Double amount = 1;
        Double startAmount = 5;
        FundingBaseline__c baseline = new FundingBaseline__c();
        baseline.Id = getBaselineId(baseline);
        baseline.ABS_FY_Grant_Spend_Rollup__c = startAmount;

        Test.startTest();
        FundingBaseline__c outputBaseline = AbsBatchTriggerHandler.addToBaselineFyTotal(baseline, baseline.Id, amount);
        Test.stopTest();
        Double expectedAmount = amount + startAmount;
        Assert.isTrue(outputBaseline.ABS_FY_Grant_Spend_Rollup__c == expectedAmount, 'Expect the returned baseline to have a total FY spend of \'' + expectedAmount.format() + '\', but recieved \'' + outputBaseline.ABS_FY_Grant_Spend_Rollup__c.format() + '\'' );
    }

    @istest
    public static void addToBaselineFyTotalNullAmount(){
        Double amount;
        FundingBaseline__c baseline = new FundingBaseline__c();
        baseline.Id = getBaselineId(baseline);
        baseline.ABS_FY_Grant_Spend_Rollup__c = 5;

        Test.startTest();
        FundingBaseline__c outputBaseline = AbsBatchTriggerHandler.addToBaselineFyTotal(baseline, baseline.Id, amount);
        Test.stopTest();
        Double expectedAmount = baseline.ABS_FY_Grant_Spend_Rollup__c;
        Assert.isTrue(outputBaseline.ABS_FY_Grant_Spend_Rollup__c == expectedAmount, 'Expect the returned baseline to have a total FY spend of \'' + expectedAmount.format() + '\', but recieved \'' + outputBaseline.ABS_FY_Grant_Spend_Rollup__c.format() + '\'' );
    }

    @istest
    public static void addToBaselineFyTotalNullBaseline(){
        Double amount = 1;
        FundingBaseline__c baseline;
        Id baselineId = getBaselineId(new FundingBaseline__c());
        Test.startTest();
        FundingBaseline__c outputBaseline = AbsBatchTriggerHandler.addToBaselineFyTotal(baseline, baselineId, amount);
        Test.stopTest();
        Double expectedAmount = outputBaseline.ABS_FY_Grant_Spend_Rollup__c;
        Assert.isTrue(outputBaseline.ABS_FY_Grant_Spend_Rollup__c == expectedAmount, 'Expect the returned baseline to have a total FY spend of \'' + expectedAmount.format() + '\', but recieved \'' + outputBaseline.ABS_FY_Grant_Spend_Rollup__c.format() + '\'' );
    }

    @istest
    public static void addToBaselineFyTotalNullBaselineFYAmount(){
        Double amount = 1;
        FundingBaseline__c baseline = new FundingBaseline__c();
        baseline.Id = getBaselineId(baseline);

        Test.startTest();
        FundingBaseline__c outputBaseline = AbsBatchTriggerHandler.addToBaselineFyTotal(baseline, baseline.Id, amount);
        Test.stopTest();
        Double expectedAmount = amount;
        Assert.isTrue(outputBaseline.ABS_FY_Grant_Spend_Rollup__c == expectedAmount, 'Expect the returned baseline to have a total FY spend of \'' + expectedAmount.format() + '\', but recieved \'' + outputBaseline.ABS_FY_Grant_Spend_Rollup__c.format() + '\'' );
    }
}