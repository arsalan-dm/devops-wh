@isTest
private class Jira5ClassTest {
    
    @isTest
    static void testConstructor() {
        // Start the test context
        Test.startTest();
        
        // Instantiate the class to cover the constructor
        Jira5Class testInstance = new Jira5Class();
        
        // Stop the test context
        Test.stopTest();
        
        // Assert that the instance was successfully created
        System.assertNotEquals(null, testInstance, 'The Jira5Class instance should be created successfully.');
    }
}