public with sharing class AbsMeasurePriceAverages {
    
    public static final Set<String> APPROVED_STATUS = new Set<String>{'Approved', 'Closed'};

    @invocableMethod(label = 'Calculate Measure Price Averages and Limits for a batch')
    public static List<MeasureSpends> calculateMeasurePriceAveragesAndLimits(List<Id> batchIds){
        List<MeasureSpends> measureSpendOutput = new List<MeasureSpends>();
        List<FundingBatch__c> batches = [SELECT Id, Funding_Award__c FROM FundingBatch__c WHERE Id = :batchIds.get(0) LIMIT 1];
        List<FundingBatchMeasureSpend__c> measureSpends = [SELECT Id, Measure_Type__c, Average_Spend__c, Property_Measure_Type_Average_Price__c, Measure_Type_Name__c FROM FundingBatchMeasureSpend__c WHERE Batch__c = :batchIds.get(0) AND Measure_Type__c != null];
        if (batches.size() == 0 || measureSpends.size() == 0){
            return measureSpendOutput;
        }

        Set<Id> fundingAwardIds = new Set<Id>();
        for (FundingBatch__c batch : batches){
            fundingAwardIds.add(batch.Funding_Award__c);
        }
        List<AggregateResult> results = [SELECT SUM(Spend__c)totalSpend, SUM(House_Count__c)totalHomes, Measure_Type__c FROM FundingBatchMeasureSpend__c WHERE Batch__r.Funding_Award__c IN :fundingAwardIds AND (Batch__r.ABS_Status__c IN :APPROVED_STATUS OR Batch__c = :batchIds.get(0))GROUP BY Measure_Type__c]; 
        if (results.size() == 0){
            return measureSpendOutput;
        }
        Map<Id, AggregateResult> organisedResults = new Map<Id, AggregateResult>();
        for (AggregateResult result : results){
            if (result.get('Measure_Type__c') != null){
                organisedResults.put((Id)result.get('Measure_Type__c'), result);
            }
        }

        for (FundingBatchMeasureSpend__c measureSpend : measureSpends){
            AggregateResult measuresResult = organisedResults.get(measureSpend.Measure_Type__c);
            // Null-safety: handle missing AggregateResult or null totals, and avoid divide-by-zero
            if (measuresResult == null) {
                // No data for this measure type; set to 0 safely
                measureSpend.Average_Spend__c = 0;
                continue;
            }
            Double totalSpend = (Double)measuresResult.get('totalSpend');
            Double totalHomes = (Double)measuresResult.get('totalHomes');
            // Default nulls to 0
            totalSpend = (totalSpend == null) ? 0 : totalSpend;
            totalHomes = (totalHomes == null) ? 0 : totalHomes;
            // Avoid divide-by-zero; if no homes counted, average spend is 0 by convention
            measureSpend.Average_Spend__c = (totalHomes == 0) ? 0 : (totalSpend / totalHomes);
        }
        measureSpendOutput.add(new MeasureSpends(measureSpends));
        return measureSpendOutput;
    }

    public class MeasureSpends{
        @InvocableVariable
        public List<FundingBatchMeasureSpend__c> batchMeasureSpends;
        MeasureSpends(List<FundingBatchMeasureSpend__c> measureSpends){
            this.batchMeasureSpends = measureSpends;
        }
    }
}