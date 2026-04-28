public without sharing class AbsAwardMeasureSpendAverages {
   
    public static final Set<String> APPROVED_STATUS = new Set<String>{'Approved', 'Closed'};

    @invocableMethod(label = 'Calculate Measure Price Averages and Limits for a group of Awards')
    public static List<MeasureSpend> getAwardMeasureSpendAverages(List<String> fundingAwardIds){
        List<MeasureSpend> measureSpends = new List<MeasureSpend>();
        if (fundingAwardIds == null){
            return measureSpends;
        }
        Map<Id, PropertyMeasureType__c> measureTypes = new Map<Id, PropertyMeasureType__c>([SELECT Id, Name FROM PropertyMeasureType__c LIMIT 500]);
        List<AggregateResult> results = [SELECT SUM(Spend__c)totalSpend, SUM(House_Count__c)totalHomes, Measure_Type__c FROM FundingBatchMeasureSpend__c WHERE Batch__r.Funding_Award__c IN :fundingAwardIds AND Batch__r.ABS_Status__c IN :APPROVED_STATUS GROUP BY Measure_Type__c]; 
        if (results.size() == 0){
            return measureSpends;
        }

        List<FundingBatchMeasureSpend__c> batchMeasureSpends = new List<FundingBatchMeasureSpend__c>();

        Map<Id, AggregateResult> organisedResults = new Map<Id, AggregateResult>();
        for (AggregateResult result : results){
            FundingBatchMeasureSpend__c batchMeasureSpend = new FundingBatchMeasureSpend__c();
            
            Double totalSpend = (Double)result?.get('totalSpend') ?? 0;
            Double totalHomes = (Double)result?.get('totalHomes') ?? 0;
            // Default nulls to 0
            batchMeasureSpend.Spend__c = totalSpend ?? 0;
            batchMeasureSpend.House_Count__c = totalHomes ?? 0;
            batchMeasureSpend.Average_Spend__c = (totalHomes == 0) ? 0 : (totalSpend / totalHomes);
            batchMeasureSpend.Measure_Type__c = (String)result?.get('Measure_Type__c');
            batchMeasureSpend.Description__c = measureTypes?.get(batchMeasureSpend?.Measure_Type__c)?.Name; // use the description to store the name instead of doing a formula calculate that'll do a select in a loop
            batchMeasureSpends.add(batchMeasureSpend);
        }

        measureSpends.add(new MeasureSpend(batchMeasureSpends));
        return measureSpends;
    }

    public class MeasureSpend{
        @InvocableVariable
        public List<FundingBatchMeasureSpend__c> batchMeasureSpends;
        MeasureSpend(List<FundingBatchMeasureSpend__c> measureSpends){
            this.batchMeasureSpends = measureSpends;
        }
    }
}