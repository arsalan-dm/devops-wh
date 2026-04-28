public without sharing class GmsMilestoneTriggerHandler {

    public static void onAfterInsert(List<Funding_Award_Milestone__c> milestones){
        Map<Id, Funding_Award_Milestone__c> baselineIds = new Map<Id, Funding_Award_Milestone__c>();
        for (Funding_Award_Milestone__c milestone : milestones){
            baselineIds.put(milestone.Parent_Baseline__c, milestone);
        }
        
        Map<String, Decimal> installedMeasureCounts = new Map<String, Decimal>();
        List<AggregateResult> ags = [SELECT COUNT(Id) measureCount, Measure_Type_Parent__c type, Property_Detail__r.Baseline__c baseline FROM Property_Measure__c WHERE Property_Detail__r.Baseline__c IN :baselineIds.keySet() GROUP BY CUBE(Measure_Type_Parent__c, Property_Detail__r.Baseline__c)];
        for (AggregateResult ag :ags){
            installedMeasureCounts.put((String)ag.get('type') + (String)ag.get('baseline') ,(Decimal)ag.get('measureCount'));
        }

        List<BaselineMeasureDetail__c> bmds = [SELECT Id, Property_Measure_Type__c, Measure_KPI_Number__c, Funding_Baseline__c FROM BaselineMeasureDetail__c WHERE Funding_Baseline__c = :baselineIds.keySet()];
        
        // create the new milestone measure records based on baseline measure details 
        List<Funding_Award_Milestone_Measure__c> famms = new List<Funding_Award_Milestone_Measure__c>();
        for (BaselineMeasureDetail__c bmd : bmds){
            Funding_Award_Milestone_Measure__c famm = new Funding_Award_Milestone_Measure__c(
                Funding_Award_Milestone__c = baselineIds.get(bmd.Funding_Baseline__c).Id,
                Property_Measure_Type__c = bmd.Property_Measure_Type__c,
                Target_Measure_Count__c = bmd.Measure_KPI_Number__c,
                Installed_Measure_Count__c = installedMeasureCounts.get((String)bmd.Property_Measure_Type__c + (String)bmd.Funding_Baseline__c) ?? 0
            );
            famms.add(famm);
        }

        insert famms;
    }
}