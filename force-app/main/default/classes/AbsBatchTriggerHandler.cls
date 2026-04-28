public without sharing class AbsBatchTriggerHandler {

    public static List<FundingBatch__c> onAfterUpdate(List<FundingBatch__c> newBatches, Map<Id, FundingBatch__c> oldBatches){
        Set<Id> baselineIds = new Set<Id>();
        for (FundingBatch__c fb : newBatches){
            FundingBatch__c oldFb = oldBatches.get(fb.Id);
            if ((fb.ABS_Status__c == 'Approved' && oldFb.ABS_Status__c != 'Approved')
                || (oldFb.ABS_Status__c == 'Approved' && fb.ABS_Status__c != 'Approved')
                || (fb.FY1_Baseline__c != oldFb.FY1_Baseline__c && fb.ABS_Status__c == 'Approved')
                || (fb.FY2_Baseline__c != oldFb.FY2_Baseline__c && fb.ABS_Status__c == 'Approved')
                || (fb.FY3_Baseline__c != oldFb.FY3_Baseline__c && fb.ABS_Status__c == 'Approved')
                || (fb.Version_Status__c != 'Active' && oldFb.Version_Status__c == 'Active')){ // all the conditions in which we want to recalculate FY baseline values

                if (fb.FY1_Baseline__c != null){ // sets are unique so it doesn't matter if we add the same value twice
                    baselineIds.add(fb.FY1_Baseline__c);
                }
                if (oldFb.FY1_Baseline__c != null){
                    baselineIds.add(oldFb.FY1_Baseline__c);
                }
                if (fb.FY2_Baseline__c != null){
                    baselineIds.add(fb.FY2_Baseline__c);
                }
                if (oldFb.FY2_Baseline__c != null){
                    baselineIds.add(oldFb.FY2_Baseline__c);
                }
                if (fb.FY3_Baseline__c != null){
                    baselineIds.add(fb.FY3_Baseline__c);
                }
                if (oldFb.FY3_Baseline__c != null){
                    baselineIds.add(oldFb.FY3_Baseline__c);
                }
                
            }
        }
        
        if (baselineIds.size() > 0){ // sum spends and update baselines 
            Map<Id, FundingBaseline__c> baselineUpdates = new Map<Id, FundingBaseline__c>();
            List<String> absStatus = new List<String>{'Approved', 'Closed'};
            List<FundingBatch__c> batchesOnTheBaselines = [SELECT Id, FY1_Baseline__c, FY2_Baseline__c, FY3_Baseline__c, Funding_Used_value__c, Funding_Used_In_2nd_FY__c, Total_Grant_Fund_Requested__c FROM FundingBatch__c WHERE (FY1_Baseline__c IN :baselineIds OR FY2_Baseline__c IN :baselineIds) AND Version_Status__c = 'Active' AND ABS_Status__c IN :absStatus];
            for (FundingBatch__c fb : batchesOnTheBaselines){
                if(fb.FY3_Baseline__c == null){
                    if (fb.FY2_Baseline__c == null){
                        if (fb.FY1_Baseline__c != null){
                            FundingBaseline__c baseline = baselineUpdates.get(fb.FY1_Baseline__c);
                            baselineUpdates.put(fb.FY1_Baseline__c, addToBaselineFyTotal(baseline, fb.FY1_Baseline__c, (Double)(fb.Total_Grant_Fund_Requested__c ?? 0)));
                        }
                    }else{
                        if (fb.FY1_Baseline__c != null){
                            FundingBaseline__c baseline = baselineUpdates.get(fb.FY1_Baseline__c);
                            baselineUpdates.put(fb.FY1_Baseline__c, addToBaselineFyTotal(baseline, fb.FY1_Baseline__c, (Double)(fb.Funding_Used_value__c ?? 0)));
                        }
                        FundingBaseline__c baseline2 = baselineUpdates.get(fb.FY2_Baseline__c);
                        Double batchFY2Spend = (fb.Total_Grant_Fund_Requested__c ?? 0) - (fb.Funding_Used_value__c ?? 0); // null coalescing operator
                        baselineUpdates.put(fb.FY2_Baseline__c, addToBaselineFyTotal(baseline2, fb.FY2_Baseline__c, batchFY2Spend));
                    }
                }else{
                    if (fb.FY2_Baseline__c == null){ //this will never get hit based on the logic in the input screens, in here for completeness/future proofing
                        if (fb.FY1_Baseline__c != null){
                            FundingBaseline__c baseline = baselineUpdates.get(fb.FY1_Baseline__c);
                            baselineUpdates.put(fb.FY1_Baseline__c, addToBaselineFyTotal(baseline, fb.FY1_Baseline__c, (Double)(fb.Total_Grant_Fund_Requested__c ?? 0)));
                        }
                    }else{
                        if (fb.FY1_Baseline__c != null){
                            FundingBaseline__c baseline = baselineUpdates.get(fb.FY1_Baseline__c);
                            baselineUpdates.put(fb.FY1_Baseline__c, addToBaselineFyTotal(baseline, fb.FY1_Baseline__c, (Double)(fb.Funding_Used_value__c ?? 0)));
                        }
                        FundingBaseline__c baseline2 = baselineUpdates.get(fb.FY2_Baseline__c);
                        Double batchFY2Spend = (fb.Funding_Used_In_2nd_FY__c ?? 0); // null coalescing operator
                        baselineUpdates.put(fb.FY2_Baseline__c, addToBaselineFyTotal(baseline2, fb.FY2_Baseline__c, batchFY2Spend));
                    }
                    FundingBaseline__c baseline3 = baselineUpdates.get(fb.FY3_Baseline__c);
                    Double batchFY3pend = (fb.Total_Grant_Fund_Requested__c ?? 0) - (fb.Funding_Used_In_2nd_FY__c ?? 0) - (fb.Funding_Used_value__c ?? 0);
                    baselineUpdates.put(fb.FY3_Baseline__c, addToBaselineFyTotal(baseline3, fb.FY3_Baseline__c, batchFY3pend));
                }
            }
            update baselineUpdates.values();
        }
        return newBatches;
    }

    public static FundingBaseline__c addToBaselineFyTotal(FundingBaseline__c baseline, Id baselineId, Double amount){
        if (amount == null){
            return baseline;
        }
        if (baseline!= null){
            if (baseline.ABS_FY_Grant_Spend_Rollup__c == null){
                baseline.ABS_FY_Grant_Spend_Rollup__c = amount;
            }else{
                baseline.ABS_FY_Grant_Spend_Rollup__c += amount;
            }
        }else{
            baseline = new FundingBaseline__c(Id = baselineId, ABS_FY_Grant_Spend_Rollup__c = amount);
        }
        return baseline;
    }
}