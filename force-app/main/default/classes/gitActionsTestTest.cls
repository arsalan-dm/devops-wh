@isTest
private class gitActionsTestTest {
    
    @isTest
    static void testConstructor() {
        // Start the test context
        Test.startTest();
        
        // Instantiate the class to cover the constructor
        gitActionsTest testInstance = new gitActionsTest();
        
        // Stop the test context
        Test.stopTest();
        
        // Assert that the instance was successfully created
        System.assertNotEquals(null, testInstance, 'The gitActionsTest instance should be created successfully.');
    }
}