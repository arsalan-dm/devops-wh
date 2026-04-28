@isTest
private class TestClassTest {
    
    @isTest
    static void verifyTestSomething() {
        // Start the test context
        Test.startTest();
        
        // Call the static method directly using the class name
        TestClass.testSomething();
        
        // Stop the test context
        Test.stopTest();
        
        // Since the method is void and only contains a debug statement, 
        // we use a simple assertion to ensure the test completes without exceptions.
        System.assert(true, 'The testSomething method should execute without throwing an error.');
    }
}