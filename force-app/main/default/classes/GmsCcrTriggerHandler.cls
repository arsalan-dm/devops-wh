public without sharing class GmsCcrTriggerHandler {

    public static GmsCcrMappingService mappingService = new GmsCcrMappingService();

    public static final List<String> baselineChangeTypes = new List<String>{'Award Baseline', 'Sub Baseline'};

    public static final List<String> approvalStatus = new List<String>{'Approved', 'Conditional Approval'};
    
    // FundingAwardAmendment is the PSS standard object that has been relabeled to Change Control Request 
    // using the term "Change" instead of "Change Control Request" for conciseness 
    // change line items instead of "Change Control Request Line Items" for conciseness

    public static Integer index = 0;

    public static Integer getIndex(){
        index += 1;
        return index;
    }

    public static List<FundingAwardAmendment> onAfterUpdate(
        List<FundingAwardAmendment> newChanges, 
        Map<Id, FundingAwardAmendment> oldChanges
    ){
        Map<Id, FundingAwardAmendment> approvedChanges = new Map<Id, FundingAwardAmendment>();
        for (FundingAwardAmendment newChange : newChanges){
            if (approvalStatus.contains(newChange.ApprovalStatus) &&
                oldChanges.get(newChange.Id).ApprovalStatus == 'In Review'){
                approvedChanges.put(newChange.Id, newChange);
            }
        }
        if (approvedChanges.size() > 0){
            processApprovedChanges(approvedChanges);
        }
        return approvedChanges.values();
    }


    public static List<FundingAwardAmendment> processApprovedChanges(
        Map<Id, FundingAwardAmendment> approvedChanges
    ){

        Map<String, Object> bindParams = new Map<String, Object>{'changeIds'=>approvedChanges.keySet()}; 
        List<String> itemFields = new List<String>(Schema.Change_Control_Request_Line_Item__c.SObjectType.getDescribe().fields.getMap().keySet());
        String changeItemQuery = 'SELECT ' + String.join(itemFields, ',') + ' FROM Change_Control_Request_Line_Item__c WHERE Change_Control_Request__c IN :changeIds';
        List<Change_Control_Request_Line_Item__c> changeLineItems = 
            (List<Change_Control_Request_Line_Item__c>)Database.queryWithBinds(
                changeItemQuery, 
                bindParams, 
                AccessLevel.SYSTEM_MODE
            );

        // select change request line items 
        // loop line items 
        Map<Id, Change_Control_Request_Line_Item__c> baselinesToChange = new Map<Id, Change_Control_Request_Line_Item__c>();
        for (Change_Control_Request_Line_Item__c changeLineItem : changeLineItems){
            if (changeLineItem.Baseline__c != null && baselineChangeTypes.contains(changeLineItem.Type__c)){
                baselinesToChange.put(changeLineItem.Baseline__c, changeLineItem);
            }
        }

        if (baselinesToChange.size() >= 0){
            processBaselineChanges(baselinesToChange);
        }

        return approvedChanges.values();
    }

    public static void processBaselineChanges(Map<Id, Change_Control_Request_Line_Item__c> changes){
        Set<Id> baselineIds = changes.keySet(); // used in all the queries in this method
        Map<String, Object> bindParams = new Map<String, Object>{'baselineIds'=>baselineIds}; 

        List<String> baselineFields = new List<String>(Schema.FundingBaseline__c.SObjectType.getDescribe().fields.getMap().keySet());
        String baselineQuery = 'SELECT ' + String.join(baselineFields, ',') + ' FROM FundingBaseline__c WHERE Id IN :baselineIds';
        List<FundingBaseline__c> baselines = (List<FundingBaseline__c>)Database.queryWithBinds(baselineQuery, bindParams, AccessLevel.SYSTEM_MODE);
        if (baselines.size() == 0){
            return;
        }
        
        Map<Id, FundingBaseline__c> newBaselines = new  Map<Id, FundingBaseline__c>(); // map of old baseline ids against cloned new baseline records 

        for(FundingBaseline__c baseline : baselines){
            FundingBaseline__c newBaseline = baseline.clone(false, true, false, false); 
            Change_Control_Request_Line_Item__c baselineItem = changes.get(baseline.Id);
            
            Map<String, String> baselineToChangeFields = mappingService.get(baselineItem.Type__c, baseline.Record_Type_Name__c);

            for (String field : baselineToChangeFields.keySet()){
                Object fieldValue = baselineItem.get(baselineToChangeFields.get(field)) ?? baseline.get(field);
                newBaseline.put(field, fieldValue);
            }
            newBaseline.Previous_Baseline__c = baseline.Id;
            newBaseline.DL_ID__c = baseline.Id + String.valueOf(getIndex());
            newBaselines.put(baseline.Id, newBaseline);
            newBaseline.Baseline_Version_No__c = (newBaseline?.Baseline_Version_No__c ?? 0) + 1;
            // baseline EPC round up fields 
            if (newBaseline.Baseline_Type__c == 'Phase'){
                newBaseline.No_of_Homes_which_will_not_reach_EPC_C__c =
                    (newBaseline.No_of_homes_ending_at_EPC_D__c ?? 0) + 
                    (newBaseline.No_of_homes_ending_at_EPC_E__c ?? 0) + 
                    (newBaseline.No_of_homes_ending_at_EPC_F__c ?? 0) + 
                    (newBaseline.No_of_homes_ending_at_EPC_G__c ?? 0);
                newBaseline.No_of_Homes_to_EPC_A_or_B__c = 
                    (newBaseline.No_of_homes_ending_at_EPC_A__c ?? 0) + 
                    (newBaseline.No_of_homes_ending_at_EPC_B__c ?? 0);
                newBaseline.Starting_No_of_Social_Homes_EPC_C_A__c = 
                    (newBaseline.No_of_homes_starting_at_A__c ?? 0) + 
                    (newBaseline.No_of_homes_starting_at_EPC_B__c ?? 0) +
                    (newBaseline.No_of_homes_starting_at_EPC_C__c ?? 0);
                newBaseline.Starting_No_of_Social_Homes_EPC_G_D__c = 
                    (newBaseline.No_of_homes_starting_at_EPC_D__c ?? 0) + 
                    (newBaseline.No_of_homes_starting_at_EPC_E__c ?? 0) +
                    (newBaseline.No_of_homes_starting_at_EPC_F__c ?? 0) +
                    (newBaseline.No_of_homes_starting_at_EPC_G__c ?? 0);
            }
            baseline.Status__c = 'Historic';
        }
        update baselines;

        insert newBaselines.values();
        // reparent baselines child records to the new version of the baseline 
        // get forecasts per baseline

        List<FundingAwardForecast__c> forecasts = [SELECT Id, Parent_Baseline__c FROM FundingAwardForecast__c WHERE Parent_Baseline__c IN :baselineIds];
        if (forecasts.size() > 0){
            for(FundingAwardForecast__c forecast : forecasts){
                if (newBaselines?.get(forecast.Parent_Baseline__c).Id != null){
                    forecast.Parent_Baseline__c = newBaselines.get(forecast.Parent_Baseline__c).Id;
                }
            }
            update forecasts;
        }
       
        // get actuals per baseline
        List<FundingAwardActual__c> actuals = [SELECT Id, Parent_Baseline__c FROM FundingAwardActual__c WHERE Parent_Baseline__c IN :baselineIds];
        if (actuals.size() > 0){
            for(FundingAwardActual__c actual : actuals){
                if (newBaselines?.get(actual.Parent_Baseline__c).Id != null){
                    actual.Parent_Baseline__c = newBaselines?.get(actual.Parent_Baseline__c).Id;
                }
            }
            update actuals;
        }
        
        // get Updates per baseline
        List<FundingAwardUpdate__c> faUpdates = [SELECT Id, Funding_Baseline__c FROM FundingAwardUpdate__c WHERE Funding_Baseline__c IN :baselineIds];
        if (faUpdates.size() > 0){
            for(FundingAwardUpdate__c faUpdate : faUpdates){
                if (newBaselines?.get(faUpdate.Funding_Baseline__c).Id != null){
                    faUpdate.Funding_Baseline__c = newBaselines?.get(faUpdate.Funding_Baseline__c).Id;
                }
            }
            update faUpdates;
        }
        
        // get child baselines per baseline
        List<FundingBaseline__c> childBaselines = [SELECT Id, Parent_Baseline__c FROM FundingBaseline__c WHERE Parent_Baseline__c IN :baselineIds];
        if (childBaselines.size() > 0){
            for(FundingBaseline__c childBaseline : childBaselines){
                if (newBaselines?.get(childBaseline.Parent_Baseline__c).Id != null){
                    childBaseline.Parent_Baseline__c = newBaselines?.get(childBaseline.Parent_Baseline__c)?.Id;
                }
            }
            update childBaselines;
        }

        List<BaselineMeasureDetail__c> baselineMeasureDetails = [SELECT Id, Funding_Baseline__c FROM BaselineMeasureDetail__c WHERE Funding_Baseline__c IN : baselineIds];
        if (baselineMeasureDetails.size() > 0){
            for (BaselineMeasureDetail__c baselineMeasureDetail : baselineMeasureDetails){
                if (newBaselines?.get(baselineMeasureDetail.Funding_Baseline__c).Id != null){
                    baselineMeasureDetail.Funding_Baseline__c = newBaselines?.get(baselineMeasureDetail.Funding_Baseline__c)?.Id;
                }
            }
            update baselineMeasureDetails;
        }

        List<FundingBatch__c> batches = [SELECT Id, Active_Baseline__c, FY1_Baseline__c, FY2_Baseline__c, FY3_Baseline__c FROM FundingBatch__c WHERE Active_Baseline__c IN : baselineIds OR FY1_Baseline__c IN :baselineIds OR FY2_Baseline__c IN :baselineIds OR FY3_Baseline__c IN :baselineIds];
        if (batches.size() > 0){
            for (FundingBatch__c batch : batches){
                if (newBaselines?.get(batch.Active_Baseline__c)?.Id != null){
                    batch.Active_Baseline__c = newBaselines?.get(batch.Active_Baseline__c)?.Id;
                }
                if (newBaselines?.get(batch.FY1_Baseline__c)?.Id != null){
                    batch.FY1_Baseline__c = newBaselines?.get(batch.FY1_Baseline__c)?.Id;
                }
                if (newBaselines?.get(batch.FY2_Baseline__c)?.Id != null){
                    batch.FY2_Baseline__c = newBaselines?.get(batch.FY2_Baseline__c)?.Id;
                }
                if (newBaselines?.get(batch.FY3_Baseline__c)?.Id != null){
                    batch.FY3_Baseline__c = newBaselines?.get(batch.FY3_Baseline__c)?.Id;
                }
            }
            update batches;
        }

        List<Funding_Award_Milestone__c> milestones = [SELECT Id, Parent_Baseline__c FROM Funding_Award_Milestone__c WHERE Parent_Baseline__c IN : baselineIds];
        if (milestones.size() > 0){
            for (Funding_Award_Milestone__c milestone : milestones){
                if (newBaselines?.get(milestone.Parent_Baseline__c).Id != null){
                    milestone.Parent_Baseline__c = newBaselines?.get(milestone.Parent_Baseline__c)?.Id;
                }
            }
            update milestones;
        }

        List<FundingAward> fundingAwards = [SELECT Id, Current_Baseline__c FROM FundingAward WHERE Current_Baseline__c IN : baselineIds];
        if (fundingAwards.size() > 0) {
            for (FundingAward fundingAward : fundingAwards){
                if (newBaselines?.get(fundingAward.Current_Baseline__c)?.Id != null){
                    fundingAward.Current_Baseline__c = newBaselines?.get(fundingAward.Current_Baseline__c)?.Id;
                }
            }
            update fundingAwards;
        }

        List<FundingDisbursement> disbursements = [SELECT Id, Parent_Baseline__c FROM FundingDisbursement WHERE Parent_Baseline__c IN :baselineIds];
        if (disbursements.size() > 0) {
            for (FundingDisbursement disbursement : disbursements){
                if (newBaselines?.get(disbursement.Parent_Baseline__c)?.Id != null){
                    disbursement.Parent_Baseline__c = newBaselines?.get(disbursement.Parent_Baseline__c)?.Id;
                }
            }
            update disbursements;
        }


        for (Change_Control_Request_Line_Item__c lineItem : changes.values()){
            lineItem.Baseline_New_Version__c = newBaselines?.get(lineItem.Baseline__c)?.Id;
        }
        update changes.values();
    }
}