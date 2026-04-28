@istest
public with sharing class GmsCcrLineItemTriggerHandler_Test {
    
    @TestSetup
    static void makeData(){
        FundingAward fa = new FundingAward();
        insert fa;

        FundingBaseline__c fb = new FundingBaseline__c();
        fb.Funding_Award__c = fa.Id;
        insert fb;

        FundingAwardAmendment faa = new FundingAwardAmendment(FundingAwardId = fa.Id);
        insert faa;

        Change_Control_Request_Line_Item__c ccrli1 = new Change_Control_Request_Line_Item__c(Change_Control_Request__c = faa.Id);
        ccrli1.Grant_A_A_Spend__c = 15;
        ccrli1.Type__c = 'Sub Baseline';
        ccrli1.Baseline__c = fb.Id;

        Change_Control_Request_Line_Item__c ccrli2 = new Change_Control_Request_Line_Item__c(Change_Control_Request__c = faa.Id);
        ccrli2.Grant_A_A_Spend__c = 15;
        ccrli2.Type__c = 'Sub Baseline';
        ccrli2.Baseline__c = fb.Id;
        List<Change_Control_Request_Line_Item__c> ccrlis = new List<Change_Control_Request_Line_Item__c>{ccrli1, ccrli2};
        insert ccrlis;
    }
    
    @istest
    public static void onAfterInsert(){
        // quick (to write) basic tests 
        FundingAwardAmendment faa = [SELECT Id FROM FundingAwardAmendment LIMIT 1];
        Change_Control_Request_Line_Item__c ccrli = new Change_Control_Request_Line_Item__c(Change_Control_Request__c = faa.Id);
        ccrli.Grant_A_A_Spend__c = 15;
        ccrli.Type__c = 'Sub Baseline';
        Test.startTest();
        insert ccrli;
        Test.stopTest();
        List<Field_Audit__c> changes = [SELECT Id, New_Value__c, Old_Value__c FROM Field_Audit__c WHERE Parent__c = :ccrli.Id];
        Assert.areEqual(15, Integer.valueOf(changes[0].New_Value__c), 'Field Audits new value');
        Assert.areEqual(0, Integer.valueOf(changes[0].Old_Value__c), 'Field Audits new value');
    }

    @istest
    public static void onAfterUpdate(){
        Change_Control_Request_Line_Item__c ccrli = [SELECT Id, Grant_A_A_Spend__c, Grant_A_A_Spend_Variance__c FROM Change_Control_Request_Line_Item__c LIMIT 1];
        ccrli.Grant_A_A_Spend__c = 20;
        Test.startTest();
        update ccrli;
        Test.stopTest();
        List<Field_Audit__c> changes = [SELECT Id, New_Value__c, Old_Value__c FROM Field_Audit__c WHERE Parent__c = :ccrli.Id];
    
        Assert.areEqual(1, changes.size(), 'the number of field audit records');
        Assert.areEqual(20, Integer.valueOf(changes[0].New_Value__c), 'Field Audits new value');
    }

    @istest
    public static void onAfterDelete(){
        Change_Control_Request_Line_Item__c ccrli = [SELECT Id, Grant_A_A_Spend__c, Grant_A_A_Spend_Variance__c FROM Change_Control_Request_Line_Item__c LIMIT 1];
        Test.startTest();
        delete ccrli;
        Test.stopTest();
        List<Field_Audit__c> changes = [SELECT Id, New_Value__c, Old_Value__c FROM Field_Audit__c WHERE Parent__c = :ccrli.Id];
    
        Assert.areEqual(0, changes.size(), 'the number of field audit records');
    }
}