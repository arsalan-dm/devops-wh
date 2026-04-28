@isTest
public class DESNZ_OSAddressMatch_ExceptionMock implements HttpCalloutMock {

    public HTTPResponse respond(HTTPRequest req) {
        throw new CalloutException('Simulated callout exception');
    }
}