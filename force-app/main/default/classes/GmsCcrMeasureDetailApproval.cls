public without sharing class GmsCcrMeasureDetailApproval {

    @InvocableMethod(label='Create Baseline Measure Details From CCR Items')
    public static List<Output> createBaselineMeasureDetailsFromItems(List<Input> inputs){
        List<Output> outputs = new List<Output>();
        Input input = inputs.get(0);

        Set<Id> baselineIds = new Set<Id>();
        for (Change_Control_Request_Line_Item__c item : input.measureItems){
            baselineIds.add(item.Baseline__c);
        }

        Map<Id, Id> newBaselineVersions = new Map<Id, Id>();
        List<FundingBaseline__c> baselines = [SELECT Id, Previous_Baseline__c FROM FundingBaseline__c WHERE Previous_Baseline__c IN :baselineIds];
        for (FundingBaseline__c baseline : baselines){
            if (baseline.Previous_Baseline__c != null){
                newBaselineVersions.put(baseline.Previous_Baseline__c, baseline.Id);
            }
        }

        List<BaselineMeasureDetail__c> forUpdate = new List<BaselineMeasureDetail__c>();
        Map<Change_Control_Request_Line_Item__c, BaselineMeasureDetail__c> forInsert = new Map<Change_Control_Request_Line_Item__c, BaselineMeasureDetail__c>();
        List<BaselineMeasureDetail__c> forDelete = new List<BaselineMeasureDetail__c>();

        for (Change_Control_Request_Line_Item__c item : input.measureItems){
            BaselineMeasureDetail__c bmd = new BaselineMeasureDetail__c(
                Measure_KPI_Number__c = item.Measure_KPI_Number__c,
                Id = item.Baseline_Measure_Detail__c,
                Measure_Type__c = item.Property_Measure_Type__c,
                Description__c = item.Baseline_Measure_Description__c,
                Cost_to_install_measure__c = item.Cost_To_Install_Measure__c,
                Status__c = 'Active',
                Funding_Award__c = input.fundingAwardId,
                Funding_Baseline__c = newBaselineVersions.get(item.Baseline__c) ?? item.Baseline__c
            );

            if (bmd.Id == null){
                forInsert.put(item, bmd);
            }else{
                forUpdate.add(bmd);
            }
            if (item.Is_Delete_Change__c && bmd.Id != null){
                forDelete.add(bmd);
            }
        }

        update forUpdate;
        insert forInsert.values();
        delete forDelete;

        List<Change_Control_Request_Line_Item__c> itemsToUpdate = new List<Change_Control_Request_Line_Item__c>();
        for (Change_Control_Request_Line_Item__c item : forInsert.keySet()){
            item.Baseline_Measure_Detail__c = forInsert?.get(item)?.Id;
            itemsToUpdate.add(item);
        }

        update itemsToUpdate;

        Output output = new Output();
        output.measureDetails.addAll(forUpdate);
        outputs.add(output);

        return outputs; 
    }

    public class Input{
        @InvocableVariable
        public List<Change_Control_Request_Line_Item__c> measureItems;
        @InvocableVariable
        public Id fundingAwardId;
    }

    public class Output{
        @InvocableVariable
        public List<BaselineMeasureDetail__c> measureDetails;
        public Output(){
            measureDetails = new List<BaselineMeasureDetail__c>();
        }
    }
}