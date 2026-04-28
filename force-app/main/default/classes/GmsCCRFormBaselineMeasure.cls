public without sharing class GmsCCRFormBaselineMeasure {
    
    @InvocableMethod(label='Baseline Measure Convert to CCF')
    public static List<FlowOutputs> convertBaselineMeasure(List<FlowInputs> inputs) {
        FlowOutputs result = new FlowOutputs();
        List<FlowOutputs> resultList = new List<FlowOutputs>{result};
        List<Change_Control_Request_Line_Item__c> ccrUpdate = new List<Change_Control_Request_Line_Item__c>();

        Map<Id,Change_Control_Request_Line_Item__c> ccrMap = new Map<Id,Change_Control_Request_Line_Item__c>();
        List<Change_Control_Request_Line_Item__c> newLineItems = new List<Change_Control_Request_Line_Item__c>();

        if(inputs?.get(0)?.lineItems != null) {
        	for(Change_Control_Request_Line_Item__c ccrs : inputs.get(0).lineItems) {
                if (ccrs.Baseline_Measure_Detail__c == null){
                    newLineItems.add(ccrs);
                }else{
                    ccrMap.put(ccrs.Baseline_Measure_Detail__c, ccrs);
                }
            }
        }

        if (inputs?.get(0)?.measureDetails != null){
            for(BaselineMeasureDetail__c bmd : inputs.get(0).measureDetails){
                Change_Control_Request_Line_Item__c item = new Change_Control_Request_Line_Item__c();
                if(ccrMap.containsKey(bmd.Id)) {
                    item.Measure_KPI_Number__c = ccrMap.get(bmd.Id).Measure_KPI_Number__c;
                    item.Measure_Type__c = ccrMap.get(bmd.Id).Measure_Type__c;
                    item.Baseline_Measure_Description__c = ccrMap.get(bmd.Id).Baseline_Measure_Description__c;
                    item.Cost_To_Install_Measure__c = ccrMap.get(bmd.Id).Cost_To_Install_Measure__c;
                } else {
                    item.Measure_KPI_Number__c = bmd.Measure_KPI_Number__c;
                    item.Measure_Type__c = bmd.Property_Measure_Type__c;
                    item.Baseline_Measure_Description__c = bmd.Description__c;
                    item.Cost_To_Install_Measure__c = bmd.Cost_to_install_measure__c;
                }
                item.Previous_Measure_KPI_Number__c = bmd.Measure_KPI_Number__c;
                item.Previous_Cost_To_Install_Measure__c = bmd.Cost_to_install_measure__c;
                item.Baseline_Measure_Detail__c = bmd.Id;

                ccrUpdate.add(item);
            }
        }

        if(newLineItems.size() > 0){
            ccrUpdate.addAll(newLineItems);
        }

        result.lineItemsOutput = ccrUpdate;
        return resultList;
    }
    
    public class FlowInputs{
        
    	@InvocableVariable
    	public List<BaselineMeasureDetail__c> measureDetails;
        
    	@InvocableVariable
    	public List<Change_Control_Request_Line_Item__c> lineItems;
    
    }
    
    public class FlowOutputs{
      	
        @InvocableVariable
        public List<Change_Control_Request_Line_Item__c> lineItemsOutput;
    
    }

}