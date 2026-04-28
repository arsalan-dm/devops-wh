@istest
public with sharing class AbsAwardMeasureSpendAverages_Test {
    
    @istest
    public static void getAwardMeasureSpendAverages_happyPath(){
        FundingAward fa1 = new FundingAward();
        insert fa1;
        FundingBaseline__c awardBaseline = new FundingBaseline__c(Baseline_Type__c = 'Award');
        awardBaseline.Funding_Award__c = fa1.Id;
        awardBaseline.Status__c = 'Active';
        insert awardBaseline;

        FundingBatch__c fb1 = new FundingBatch__c(Funding_Award__c = fa1.Id, Active_Baseline__c = awardBaseline.Id, ABS_Status__c = 'Approved');
        FundingBatch__c fb2 = new FundingBatch__c(Funding_Award__c = fa1.Id, Active_Baseline__c = awardBaseline.Id, ABS_Status__c = 'Approved');
        List<FundingBatch__c> fbs = new List<FundingBatch__c>{fb1, fb2};
        insert fbs;

        PropertyMeasureType__c pmt = new PropertyMeasureType__c(Name = 'Insulation', Average_Price_Limit__c = 12000);
        pmt.Cost_Cap_Category__c = 'Energy Performance';
        insert pmt;

        FundingBatchMeasureSpend__c fbms = new FundingBatchMeasureSpend__c();
        fbms.Batch__c = fb1.Id;
        fbms.Spend__c = 1;
        fbms.House_Count__c = 1; 
        fbms.Measure_Type__c = pmt.Id;

        FundingBatchMeasureSpend__c fbms2 = new FundingBatchMeasureSpend__c();
        fbms2.Batch__c = fb2.Id;
        fbms2.Spend__c = 3;
        fbms2.House_Count__c = 1; 
        fbms2.Measure_Type__c = pmt.Id;

        List<FundingBatchMeasureSpend__c> fbmss = new List<FundingBatchMeasureSpend__c>{fbms, fbms2};
        insert fbmss;

        Test.startTest();
        List<AbsAwardMeasureSpendAverages.MeasureSpend> response = AbsAwardMeasureSpendAverages.getAwardMeasureSpendAverages(new List<Id>{fa1.Id});
        Test.stopTest();

        for (AbsAwardMeasureSpendAverages.MeasureSpend measureSpends : response){
            for (FundingBatchMeasureSpend__c measureSpend : measureSpends.batchMeasureSpends){
                if (measureSpend.Measure_Type__c == pmt.Id){
                    Double averageSpend = (fbms.Spend__c + fbms2.Spend__c)/(fbms.House_Count__c + fbms2.House_Count__c);
                    Assert.areEqual(averageSpend, measureSpend.Average_Spend__c, 'Average spend' );
                }
            }
        }
    }

    @istest
    public static void getAwardMeasureSpendAverages_nullAwardIdList(){
        
        List<Id> faIds;
        Test.startTest();
        List<AbsAwardMeasureSpendAverages.MeasureSpend> response = AbsAwardMeasureSpendAverages.getAwardMeasureSpendAverages(faIds);
        Test.stopTest();
        Assert.areEqual(0, response.size(), 'number of response records');
    }
}