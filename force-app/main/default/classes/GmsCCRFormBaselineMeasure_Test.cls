@isTest
public class GmsCCRFormBaselineMeasure_Test {
    @isTest
    public static void convertBaselineMeasure() {
        // create test data
        GmsCCRFormBaselineMeasure.FlowInputs inputs = createData();

        Test.startTest();
        List<GmsCCRFormBaselineMeasure.FlowOutputs> results = GmsCCRFormBaselineMeasure.convertBaselineMeasure(
            new List<GmsCCRFormBaselineMeasure.FlowInputs>{inputs}
        );
        Test.stopTest();
        
        // Verify results
        Assert.areEqual(1, results.size(), 'Number of results');
        Assert.areEqual(3, results[0].lineItemsOutput.size(), 'Number of line items');
        //Assert.areEquals(2, results[0].lineItemsOutput.size());
    }

    @istest
    public static void convertBaselineMeasure_NoBaselineMeasureDetails(){
        GmsCCRFormBaselineMeasure.FlowInputs inputs = createData();
        inputs.measureDetails = null;

        Test.startTest();
        List<GmsCCRFormBaselineMeasure.FlowOutputs> results = GmsCCRFormBaselineMeasure.convertBaselineMeasure(
            new List<GmsCCRFormBaselineMeasure.FlowInputs>{inputs}
        );
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'Number of results');
        Assert.areEqual(1, results[0].lineItemsOutput.size(), 'Number of line items');
    }

    @istest
    public static void convertBaselineMeasure_NoLineItems(){
        GmsCCRFormBaselineMeasure.FlowInputs inputs = createData();
        inputs.lineItems = null;

        Test.startTest();
        List<GmsCCRFormBaselineMeasure.FlowOutputs> results = GmsCCRFormBaselineMeasure.convertBaselineMeasure(
            new List<GmsCCRFormBaselineMeasure.FlowInputs>{inputs}
        );
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'Number of results');
        Assert.areEqual(2, results[0].lineItemsOutput.size(), 'Number of line items');
    }

    public static GmsCCRFormBaselineMeasure.FlowInputs createData(){
        // Create test data, no need to insert as the code doesn't touch the database
        FundingAward fa1 = new FundingAward();
        
        //Create Baseline Measure Type
        PropertyMeasureType__c propertyMeasureType = new PropertyMeasureType__c(
            Name = 'External Wall Insulation',
            Status__c = 'DESNZ Approved',
            Cost_Cap_Category__c = 'Energy Performance'
        );
        insert propertyMeasureType;
        
        PropertyMeasureType__c propertyMeasureType1 = new PropertyMeasureType__c(
            Name = 'External Wall Insulation',
            Status__c = 'DESNZ Approved',
            Cost_Cap_Category__c = 'Energy Performance'
        );
        insert propertyMeasureType1;

        
        FundingBaseline__c phaseBaseline1 = new FundingBaseline__c(
            Baseline_Type__c = 'Phase', 
            Funding_Award__c = fa1.Id, 
            Status__c = 'Active'
        );

        BaselineMeasureDetail__c bmd1 = new BaselineMeasureDetail__c(
            Measure_KPI_Number__c = 100.0,
            Measure_Type__c = propertyMeasureType.Id,
            Description__c = 'Test Description 1',
            Funding_Baseline__c = phaseBaseline1.Id
        );
        
        BaselineMeasureDetail__c bmd2 = new BaselineMeasureDetail__c(
            Measure_KPI_Number__c = 200.0,
            Measure_Type__c = 'propertyMeasureType1',
            Description__c = 'Test Description 2',
            Funding_Baseline__c = phaseBaseline1.Id
        );

        FundingAwardAmendment ccr = new FundingAwardAmendment(
            Phase_Baseline__c = phaseBaseline1.Id,
            FundingAwardId = fa1.Id
        );

        Change_Control_Request_Line_Item__c ccr1 = new Change_Control_Request_Line_Item__c(
            Baseline_Measure_Detail__c = bmd1.Id,
            Measure_KPI_Number__c = 150.0
        );
        
        GmsCCRFormBaselineMeasure.FlowInputs inputs = new GmsCCRFormBaselineMeasure.FlowInputs();
        inputs.lineItems = new List<Change_Control_Request_Line_Item__c>{ccr1};
        inputs.measureDetails = new List<BaselineMeasureDetail__c>{bmd1, bmd2};
        return inputs;
    }
}