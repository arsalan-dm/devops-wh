@IsTest
public with sharing class GmsMilestoneTriggerHandler_Test {
    
    @TestSetup
    static void makeData(){

        Schema.Location location = new Schema.Location();
        location.Name = 'Warm Homes';
        insert location;

        PropertyMeasureType__c pmt = new PropertyMeasureType__c();
        pmt.Name = 'Loft Insulation';

        PropertyMeasureType__c pmt2 = new PropertyMeasureType__c();
        pmt2.Name = 'Double Glasing';

        PropertyMeasureType__c pmt3 = new PropertyMeasureType__c();
        pmt3.Name = 'Draughtproofing';
        insert new List<PropertyMeasureType__c>{pmt, pmt2, pmt3};

        FundingAward fa = new FundingAward();
        insert fa;

        FundingBaseline__c fb = new FundingBaseline__c(
            Funding_Award__c = fa.Id
        );
        insert fb;

        BaselineMeasureDetail__c bmd = new BaselineMeasureDetail__c(
            Property_Measure_Type__c = pmt.Id,
            Measure_KPI_Number__c = 10,
            Funding_Baseline__c = fb.Id
        );

        BaselineMeasureDetail__c bmd2 = new BaselineMeasureDetail__c(
            Property_Measure_Type__c = pmt2.Id,
            Measure_KPI_Number__c = 20,
            Funding_Baseline__c = fb.Id
        );

        BaselineMeasureDetail__c bmd3 = new BaselineMeasureDetail__c(
            Property_Measure_Type__c = pmt3.Id,
            Measure_KPI_Number__c = 10,
            Funding_Baseline__c = fb.Id
        );

        insert new List<BaselineMeasureDetail__c>{bmd, bmd2, bmd3};

        OS_Candidate_Address__c os = new OS_Candidate_Address__c(
            OS_UPRN__c = '1',
            Baseline__c = fb.Id,
            Address_Search_String__c = '1 X1 1XX'
        );

        OS_Candidate_Address__c os2 = new OS_Candidate_Address__c(
            OS_UPRN__c = '2',
            Baseline__c = fb.Id,
            Address_Search_String__c = '2 X1 1XX'
        );

        OS_Candidate_Address__c os3 = new OS_Candidate_Address__c(
            OS_UPRN__c = '3',
            Baseline__c = fb.Id,
            Address_Search_String__c = '3 X1 1XX'
        );
        insert new List<OS_Candidate_Address__c>{os, os2, os3};

        FundingPropertyDetail__c fpd = new FundingPropertyDetail__c(
            Baseline__c = fb.Id,
            Funding_Award__c = fa.Id,
            TM_UPRN__c = '1'
        );
        FundingPropertyDetail__c fpd2 = new FundingPropertyDetail__c(
            Baseline__c = fb.Id,
            Funding_Award__c = fa.Id,
            TM_UPRN__c = '2'
        );
        FundingPropertyDetail__c fpd3 = new FundingPropertyDetail__c(
            Baseline__c = fb.Id,
            Funding_Award__c = fa.Id,
            TM_UPRN__c = '3'
        );
        insert new List<FundingPropertyDetail__c>{fpd, fpd2, fpd3};

        Property_Measure__c pm = new Property_Measure__c(
            Measure_Type_Parent__c = pmt.Id,
            Property_Detail__c = fpd.Id,
            Related_Funding_Award__c = fa.Id
        );
        Property_Measure__c pm2 = new Property_Measure__c(
            Measure_Type_Parent__c = pmt2.Id,
            Property_Detail__c = fpd.Id,
            Related_Funding_Award__c = fa.Id
        );
        Property_Measure__c pm3 = new Property_Measure__c(
            Measure_Type_Parent__c = pmt3.Id,
            Property_Detail__c = fpd.Id,
            Related_Funding_Award__c = fa.Id
        );
        Property_Measure__c pm4 = new Property_Measure__c(
            Measure_Type_Parent__c = pmt2.Id,
            Property_Detail__c = fpd2.Id,
            Related_Funding_Award__c = fa.Id
        );
        Property_Measure__c pm5 = new Property_Measure__c(
            Measure_Type_Parent__c = pmt.Id,
            Property_Detail__c = fpd2.Id,
            Related_Funding_Award__c = fa.Id
        );
        Property_Measure__c pm6 = new Property_Measure__c(
            Measure_Type_Parent__c = pmt.Id,
            Property_Detail__c = fpd3.Id,
            Related_Funding_Award__c = fa.Id
        );

        insert new List<Property_Measure__c>{pm, pm2, pm3, pm4, pm5, pm6};

    }   
    
    @IsTest
    public static void onAfterInsert(){
        FundingBaseline__c baseline = [SELECT Id FROM FundingBaseline__c LIMIT 1];
        List<FundingPropertyDetail__c> properties = [SELECT Baseline__c FROM FundingPropertyDetail__c];
        for (FundingPropertyDetail__c property : properties){
            property.Baseline__c = baseline.Id;
        }
        update properties;
        
        Funding_Award_Milestone__c fm = new Funding_Award_Milestone__c(
            Parent_Baseline__c = baseline.Id
        );

        Test.startTest();
        insert new list<Funding_Award_Milestone__c>{fm};
        Test.stopTest();
        List<Funding_Award_Milestone_Measure__c> famms = [SELECT Id, Funding_Award_Milestone__c, Property_Measure_Type__c, Target_Measure_Count__c, Installed_Measure_Count__c FROM Funding_Award_Milestone_Measure__c];
        Assert.areEqual(3, famms.size(), 'the number of milestone measures created');
        List<Funding_Award_Milestone_Measure__c> famms2 = [SELECT Id, Funding_Award_Milestone__c, Property_Measure_Type__c, Target_Measure_Count__c, Installed_Measure_Count__c FROM Funding_Award_Milestone_Measure__c WHERE Property_Measure_Type__r.Name = 'Loft Insulation'];
        Assert.areEqual(3, famms2[0].Installed_Measure_Count__c, 'installed measure count for Loft insulation');
        List<Funding_Award_Milestone_Measure__c> famms3 = [SELECT Id, Funding_Award_Milestone__c, Property_Measure_Type__c, Target_Measure_Count__c, Installed_Measure_Count__c FROM Funding_Award_Milestone_Measure__c WHERE Property_Measure_Type__r.Name = 'Double Glasing'];
        Assert.areEqual(2, famms3[0].Installed_Measure_Count__c, 'installed measure count for Double Glasing');
        List<Funding_Award_Milestone_Measure__c> famms4 = [SELECT Id, Funding_Award_Milestone__c, Property_Measure_Type__c, Target_Measure_Count__c, Installed_Measure_Count__c FROM Funding_Award_Milestone_Measure__c WHERE Property_Measure_Type__r.Name = 'Draughtproofing'];
        Assert.areEqual(1, famms4[0].Installed_Measure_Count__c, 'installed measure count for Draughtproofing');
    }
}