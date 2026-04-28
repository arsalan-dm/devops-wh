@istest
public with sharing class GmsCcrMappingService_Test {


    @istest 
    public static void get(){
        GmsCcrMappingService mappingService = new GmsCcrMappingService();   
        Test.startTest();
        Map<String, String> mappings = mappingService.get('Sub Baseline', 'Local Grant');
        Test.stopTest();
        Assert.areEqual('Total_number_of_homes_to_be_upgraded__c', mappings.get('Total_Homes_to_be_Upgraded__c'), 'the LG mapping for \'Total_Homes_to_be_Upgraded__c\'');
    }
}