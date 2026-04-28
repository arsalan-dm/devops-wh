@isTest
public class DESNZ_OSAddressMatch_Mock implements HttpCalloutMock {

    public HTTPResponse respond(HTTPRequest req) {
        // Create a fake HTTP response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);

        // Set the mock response body
        String responseBody = '{"header": {"matchprecision": 1.0},' +
                              '"results": [' +
                              '{' +
                              '"DPA": {' +
                              '"UPRN": "123456789",' +
                              '"ADDRESS": "123 Main St, Anytown, AB1 2CD",' +
                              '"MATCH_DESCRIPTION": "EXACT",' +
                              '"X_COORDINATE": 123456.78,' +
                              '"Y_COORDINATE": 987654.32,' +
                              '"POSTCODE": "AB1 2CD",' +
                              '"POST_TOWN": "Anytown",' +
                              '"DEPENDENT_LOCALITY": "",' +
                              '"THOROUGHFARE_NAME": "Main St",' +
                              '"BUILDING_NAME": "",' +
                              '"BUILDING_NUMBER": "123",' +
                              '"CLASSIFICATION_CODE": "RD",' +
                              '"CLASSIFICATION_CODE_DESCRIPTION": "Residential",' +
                              '"LOCAL_CUSTODIAN_CODE_DESCRIPTION": "Local Authority"' +
                              '}' +
                              '}' +
                              ']' +
                              '}';
        res.setBody(responseBody);

        return res;
    }
}