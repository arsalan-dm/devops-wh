public without sharing class GmsCcrFormPhaseChange {
    
    @InvocableMethod(label='GMS - CCR - Convert Baselines to Phase Change Items')
    public static List<Output> getPhaseItems(List<Input> inputs){
        Id recordTypeId = Schema.Change_Control_Request_Line_Item__c.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName().get('SHF_Challenge_Fund').getRecordTypeId();
        Output output = new Output();
        List<Output> outputs = new List<Output>{output};
        List<FundingBaseline__c> baselines = inputs?.get(0)?.baselines;

        Map<Id, Change_Control_Request_Line_Item__c> initialItems = new Map<Id, Change_Control_Request_Line_Item__c>(); 
        List<Change_Control_Request_Line_Item__c> newItems = new List<Change_Control_Request_Line_Item__c>();

        if (inputs?.get(0)?.items != null){
            if (baselines == null){ // no baselines and items, just return the items 
                output.items = inputs?.get(0)?.items;
                return outputs;
            }

            if (baselines.size() == 0){ // no baselines and items, just return the items 
                output.items = inputs?.get(0)?.items;
                return outputs;
            }
            
            for (Change_Control_Request_Line_Item__c item : inputs?.get(0)?.items){
                if (item.Baseline__c == null){
                    newItems.add(item); // these are requests for new phases so add them at the end 
                }else{
                    initialItems.put(item.Baseline__c, item);
                }
            }
        }
        if (baselines == null){ // no baselines and items, just return the items 
            return outputs;
        }
        

        List<Change_Control_Request_Line_Item__c> outputItems = new List<Change_Control_Request_Line_Item__c>();
        for (FundingBaseline__c baseline : baselines){
            if (initialItems?.get(baseline.Id) != null){
                Change_Control_Request_Line_Item__c item = initialItems.get(baseline.Id);
                item.Baseline_Measure_Description__c = baseline.Baseline_Version__c;
                item.Baseline_Measure_Description_Previous__c = baseline.Status__c;
                item.Cache__c = baseline.Total_Homes_to_be_Upgraded__c;
                outputItems.add(item);
            }else{
                Change_Control_Request_Line_Item__c item = new Change_Control_Request_Line_Item__c();
                item.Baseline__c = baseline.Id;
                item.Type__c = 'Phase Change';
                item.RecordTypeId = recordTypeId;
                item.Start_Date__c = baseline.Baseline_Start_Date__c;
                item.Start_Date_Previous__c = baseline.Baseline_Start_Date__c;
                item.End_Date__c = baseline.Baseline_End_Date__c;
                item.End_Date_Previous__c = baseline.Baseline_End_Date__c;
                item.Total_number_of_homes_to_be_upgraded__c = baseline.Total_Homes_to_be_Upgraded__c;
                item.Cache__c = baseline.Total_Homes_to_be_Upgraded__c;
                item.Baseline_Measure_Description__c = baseline.Baseline_Version__c;
                item.Baseline_Measure_Description_Previous__c = baseline.Status__c;
                outputItems.add(item);
            }
        }
        outputItems.addAll(newItems);
        output.items = outputItems;
        return outputs;
    } 


    public class Input{
        @InvocableVariable
        public List<FundingBaseline__c> baselines;
        @InvocableVariable
        public List<Change_Control_Request_Line_Item__c> items;

    }

    public class Output{
        @InvocableVariable
        public List<Change_Control_Request_Line_Item__c> items;
    }

}