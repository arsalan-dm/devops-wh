public without sharing class GmsCcrLineItemTriggerHandler {
    
    public static final Map<String, String> fieldMapping = new Map<String, String>{
        'No_of_Homes_for_On_Gas_grid_LCH_Uplift__c'=>'On_Gas_Variance__c',
        'No_of_Homes_for_Off_Gas_grid_LCH_Uplift__c'=>'Off_Gas_Variance__c',
        'Co_funding_A_A_spend__c' => 'Co_Funding_A_A_spend_variance__c'
    };

    public static final List<String> typesToAction = new List<String>{'Award Baseline', 'Sub Baseline'};

    public static Map<String, Schema.SObjectField> fieldMap = Schema.Change_Control_Request_Line_Item__c.getSObjectType().getDescribe().fields.getMap();

    public static List<Change_Control_Request_Line_Item__c> onAfterInsert(
        List<Change_Control_Request_Line_Item__c> ccrlis
    ){
        List<Field_Audit__c> fieldChanges = buildFieldChanges(ccrlis);
        insert fieldChanges;
        return ccrlis;
    }

    public static List<Field_Audit__c> buildFieldChanges(List<Change_Control_Request_Line_Item__c> ccrlis){
        List<Field_Audit__c> fieldChanges = new List<Field_Audit__c>();
        for (Change_Control_Request_Line_Item__c item : ccrlis){
            if (typesToAction.contains(item.Type__c)){
                Map<String, Object> itemFields = item.getPopulatedFieldsAsMap();
                for (String fieldName : itemFields.keySet()){
                    if (!fieldName.contains('Variance') && !fieldName.contains('Previous_')){
                        Field_Audit__c change = sortFieldChange(itemFields, fieldName);
                        if (change != null){
                            fieldChanges.add(change);
                        }
                    }
                }
            }
        }
        return fieldChanges;
    }

    public static List<Change_Control_Request_Line_Item__c> onAfterUpdate(
        List<Change_Control_Request_Line_Item__c> newItems,
        Map<Id, Change_Control_Request_Line_Item__c> oldMap
    ){ 
        deleteFieldAudits(oldMap.keySet());
        List<Field_Audit__c> fieldChanges = buildFieldChanges(newItems);
        insert fieldChanges;
        return newItems;        
    }

    public static List<Field_Audit__c> onAfterDelete(
        Map<Id, Change_Control_Request_Line_Item__c> oldMap    
    ){
        return deleteFieldAudits(oldMap.keySet());
    }   

    public static List<Field_Audit__c> deleteFieldAudits(Set<Id> itemIds){
        List<Field_Audit__c> fieldAudits = [SELECT Id, Parent__c FROM Field_Audit__c WHERE Parent__c IN :itemIds];
        delete fieldAudits;
        return fieldAudits;
    }

    public static Field_Audit__c sortFieldChange(Map<String, Object> itemFields, String fieldName){
        Schema.DescribeFieldResult fieldDescribe = fieldMap?.get(fieldName.toLowerCase())?.getDescribe();
        if (fieldDescribe.isCalculated()){
            return null;
        }

        String varianceFieldName = fieldMapping?.get(fieldName);
        if (varianceFieldName == null){
            varianceFieldName = fieldName.removeEnd('__c');
            varianceFieldName += '_Variance__c';
        }

        if (itemFields.get('Type__c') == 'Forecast'){
            if (itemFields.get('Forecast_' + varianceFieldName) != null){
                varianceFieldName = 'Forecast_' + varianceFieldName;
            }
        }
        
        Decimal varianceValue = (Decimal)itemFields.get(varianceFieldName);
        if (varianceValue == null){
            return null;
        }
        if (varianceValue == 0){
            return null;
        }

        Field_Audit__c fieldChange = new Field_Audit__c();

        fieldChange.Variance__c = ((Decimal)itemFields.get(varianceFieldName)).format();
        fieldChange.Field_API_Name__c = fieldName;
        fieldChange.Change_Date__c = System.today();
        fieldChange.Field__c = fieldDescribe.getLabel() ?? 'No field name found';
        fieldChange.Field_Data_Type__c = String.valueOf(fieldDescribe.getType()) ?? 'No field type found';
        fieldChange.New_Value__c = getNewValue(itemFields.get(fieldName));
        fieldChange.Old_Value__c = getOldValue(itemFields.get(fieldName), itemFields.get(varianceFieldName));
        
        fieldChange.Parent__c = String.valueOf(itemFields.get('Id'));
        return fieldChange;
    }

    public static String getNewValue(Object fieldValue){
        if (fieldValue instanceOf Date){
            return ((Date)fieldValue).format();
        }else if (fieldValue instanceOf Decimal){
            return ((Decimal)fieldValue).format();
        }else{
            return String.valueOf(fieldValue);
        }
    }

    public static String getOldValue(Object fieldValue, Object varianceValue){
        if (fieldValue instanceOf Date){
            Date oldDate = (Date)fieldValue;
            oldDate.addDays(Math.round(-1*(Decimal)varianceValue));
            return oldDate.format();
        }
        // assume its a decimal if we get here 
        return ((Decimal)fieldValue - (Decimal)varianceValue).format();
    }
}