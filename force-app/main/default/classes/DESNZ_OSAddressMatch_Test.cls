@isTest
public class DESNZ_OSAddressMatch_Test {

    @testSetup
    static void setup() {
        // Insert a custom setting record for API credentials
        digitalmodus__API_Credentials__c apiCredential = new digitalmodus__API_Credentials__c(
            Name = 'OS Places Key',
            digitalmodus__Key__c = 'OS_Key',
            digitalmodus__Service__c = 'OS',
            digitalmodus__Value__c = '123456789',
            digitalmodus__Endpoint__c = 'https://api.os.uk/search/places/v1/'
        );
        insert apiCredential;
    }

    @isTest
    static void testMatchAddress() {
        Test.startTest();
        // Create a mock request
        DESNZ_OSAddressMatch.Request request = new DESNZ_OSAddressMatch.Request();
        request.address = '123 Main St, Anytown';

        // Set up the mock HTTP response
        Test.setMock(HttpCalloutMock.class, new DESNZ_OSAddressMatch_Mock());

        // Invoke the matchAddress method
        List<DESNZ_OSAddressMatch.Request> requests = new List<DESNZ_OSAddressMatch.Request> { request };
        List<DESNZ_OSAddressMatch.Response> responses = DESNZ_OSAddressMatch.matchAddress(requests);

        // Verify the response
        System.assertEquals(1, responses.size(), 'One response should be returned.');
        DESNZ_OSAddressMatch.Response response = responses[0];

        System.assertEquals('Success', response.apiCallStatus, 'API call should succeed.');
        System.assertEquals('123456789', response.bestMatchUPRN, 'UPRN should match the mock response.');
        System.assertEquals('123 Main St, Anytown, AB1 2CD', response.bestMatchAddress, 'Address should match the mock response.');
        System.assertEquals('EXACT', response.matchDescription, 'Match description should be EXACT.');
        Test.stopTest();
    }

    @isTest
    static void testMatchAddressCalloutException() {
        Test.startTest();
        // Create a mock request
        DESNZ_OSAddressMatch.Request request = new DESNZ_OSAddressMatch.Request();
        request.address = '123 Main St, Anytown';

        // Set up a mock that simulates a callout exception
        Test.setMock(HttpCalloutMock.class, new DESNZ_OSAddressMatch_ExceptionMock());

        // Invoke the matchAddress method
        List<DESNZ_OSAddressMatch.Request> requests = new List<DESNZ_OSAddressMatch.Request> { request };
        List<DESNZ_OSAddressMatch.Response> responses = DESNZ_OSAddressMatch.matchAddress(requests);

        // Verify the response
        System.assertEquals(1, responses.size(), 'One response should be returned.');
        DESNZ_OSAddressMatch.Response response = responses[0];

        System.assert(response.apiCallStatus.contains('Error'), 'API call status should indicate an error.');
        System.assertEquals(0.0, response.matchPrecision, 'Match precision should be 0.0 for an error.');
        Test.stopTest();
    }

    @isTest
    static void testMatchAddressApexException() {
        Test.startTest();
        // Create a mock request with a problematic address to simulate an exception
        DESNZ_OSAddressMatch.Request request = new DESNZ_OSAddressMatch.Request();
        request.address = null; // Null address to force an exception

        // Invoke the matchAddress method
        List<DESNZ_OSAddressMatch.Request> requests = new List<DESNZ_OSAddressMatch.Request> { request };
        List<DESNZ_OSAddressMatch.Response> responses = DESNZ_OSAddressMatch.matchAddress(requests);

        // Verify the response
        System.assertEquals(1, responses.size(), 'One response should be returned.');
        DESNZ_OSAddressMatch.Response response = responses[0];

        System.assert(response.apiCallStatus.contains('Exception'), 'API call status should indicate an exception.');
        System.assertEquals(0.0, response.matchPrecision, 'Match precision should be 0.0 for an exception.');
        Test.stopTest();
    }
}