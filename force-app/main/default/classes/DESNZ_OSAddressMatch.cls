public class DESNZ_OSAddressMatch {

    // Define the Invocable Variables
    public class Request {
        @InvocableVariable(required = true)
        public String address;  // Address to be passed to the API
    }
    
    public class Response {
        @InvocableVariable
        public Double matchPrecision;  // Match precision for the best result
        
        @InvocableVariable
        public String bestMatchJson;  // JSON string for the best match result
        
        @InvocableVariable
        public String bestMatchUPRN;  // UPRN for the best match
        
        @InvocableVariable
        public String bestMatchAddress;  // Address string for the best match

        @InvocableVariable
        public String bestMatchBuildingName;

        @InvocableVariable
        public String bestMatchBuildingNumber;
        
        @InvocableVariable
        public String bestMatchLocality;

        @InvocableVariable
        public String bestMatchStreet;

        @InvocableVariable
        public String bestMatchDependentThoroughfare;
        
        @InvocableVariable
        public String bestMatchPostCode;  
        
        @InvocableVariable
        public String bestMatchPostTown;  
        
        @InvocableVariable
        public String bestMatchClassificationCode;
        
        @InvocableVariable
        public String bestMatchClassificationDescription;
        
        @InvocableVariable
        public String bestMatchLocalCustodianCode;
        
        @InvocableVariable
        public String bestMatchLocalCustodianCodeDescription;
        
        @InvocableVariable
        public String matchDescription;  // Match description for the best match (e.g., EXACT, PARTIAL)
        
        @InvocableVariable
        public Double xCoordinate;  // X coordinate for the best match
        
        @InvocableVariable
        public Double yCoordinate;  // Y coordinate for the best match
        
        @InvocableVariable
        public String entireResponseJson;  // Full JSON response body for audit
        
        @InvocableVariable
        public String apiCallStatus;  // Status of the API call (success, timeout, or error details)
    }

    @InvocableMethod
    public static List<Response> matchAddress(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response response = new Response();
            try {
                
                // Get OS API Key
                digitalmodus__API_Credentials__c cred = [SELECT Id, Name, digitalmodus__Key__c, digitalmodus__Service__c, digitalmodus__Value__c FROM digitalmodus__API_Credentials__c
                                                         WHERE digitalmodus__Key__c = 'OS_Key'
                                                         LIMIT 1];
                String key = cred.digitalmodus__Value__c;
                
                /* OS Match & Cleanse API endpoint with parameters
                String endpoint = 'https://api.os.uk/search/match/v1/match?query=' 
                                  + EncodingUtil.urlEncode(req.address, 'UTF-8') 
                                  + '&maxresults=5&lr=EN&minmatch=0.8&dataset=DPA'
                                  + '&key=' + key;
                */
                
                // OS Places Find API endpoint with parameters
                String endpoint = 'https://api.os.uk/search/places/v1/find?query=' 
                                  + EncodingUtil.urlEncode(req.address, 'UTF-8') 
                                  + '&maxresults=5&lr=EN&minmatch=0.8&dataset=DPA'
                                  + '&key=' + key;
                
                // Set up the HTTP request
                Http http = new Http();
                HttpRequest httpRequest = new HttpRequest();
                httpRequest.setEndpoint(endpoint);
                httpRequest.setMethod('GET');
                httpRequest.setTimeout(120000); // Set timeout to 120 seconds (120,000 ms)
                
                // Send the HTTP request
                HttpResponse httpResponse = http.send(httpRequest);
                
                // Process the response
                if (httpResponse.getStatusCode() == 200) {
                    response.apiCallStatus = 'Success';
                    
                    String responseBody = httpResponse.getBody();
                    Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                    
                    // Capture entire JSON body for audit
                    response.entireResponseJson = responseBody;
                    
                    // Extract header data for match precision
                    Map<String, Object> header = (Map<String, Object>) jsonResponse.get('header');
                    if (header.containsKey('matchprecision')) {
                        response.matchPrecision = (Double) header.get('matchprecision');
                    }
                    
                    // Extract the best result (first in the results array)
                    List<Object> results = (List<Object>) jsonResponse.get('results');
                    if (results != null && !results.isEmpty()) {
                        Map<String, Object> bestResult = (Map<String, Object>) results[0];
                        Map<String, Object> DPA = (Map<String, Object>) bestResult.get('DPA');
                        
                        // Set JSON and specific attributes for best result
                        response.bestMatchJson = JSON.serialize(DPA);
                        response.bestMatchUPRN = (String) DPA.get('UPRN');
                        response.bestMatchAddress = (String) DPA.get('ADDRESS');
                        response.matchDescription = (String) DPA.get('MATCH_DESCRIPTION');
                        response.xCoordinate = (Double) DPA.get('X_COORDINATE');
                        response.yCoordinate = (Double) DPA.get('Y_COORDINATE');
                        response.bestMatchPostCode = (String) DPA.get('POSTCODE');
                        response.bestMatchPostTown = (String) DPA.get('POST_TOWN');
                        response.bestMatchLocality = (String) DPA.get('DEPENDENT_LOCALITY');
                        response.bestMatchStreet = (String) DPA.get('THOROUGHFARE_NAME');
                        response.bestMatchDependentThoroughfare = (String) DPA.get('DEPENDENT_THOROUGHFARE_NAME');
                        response.bestMatchBuildingName = (String) DPA.get('BUILDING_NAME');
                        response.bestMatchBuildingNumber = (String) DPA.get('BUILDING_NUMBER');
                        response.bestMatchClassificationCode = (String) DPA.get('CLASSIFICATION_CODE');
                        response.bestMatchClassificationDescription = (String) DPA.get('CLASSIFICATION_CODE_DESCRIPTION');
                        //response.bestMatchLocalCustodianCode = (String) DPA.get('LOCAL_CUSTODIAN_CODE');
                        response.bestMatchLocalCustodianCodeDescription = (String) DPA.get('LOCAL_CUSTODIAN_CODE_DESCRIPTION');
                        
                    }
                    else{
                        response.matchPrecision = 0.0;
                        response.matchDescription = 'NO MATCH';
                    }
                } else {
                    response.matchPrecision = 0.0;
                    response.apiCallStatus = 'Error: ' + httpResponse.getStatusCode() + ' - ' + httpResponse.getStatus();
                    response.entireResponseJson = 'Error: ' + httpResponse.getStatusCode() + ' - ' + httpResponse.getStatus();
                }
            } catch (CalloutException e) {
                if (e.getMessage().contains('Read timed out')) {
                    response.apiCallStatus = 'Error: Salesforce timeout while waiting for API response.';
                } else {
                    response.apiCallStatus = 'Error: ' + e.getMessage();
                }
                response.matchPrecision = 0.0;
                response.entireResponseJson = response.apiCallStatus;
            } catch (Exception e) {
                response.apiCallStatus = 'Exception: ' + e.getMessage();
                response.matchPrecision = 0.0;
            }
            responses.add(response);
        }
        
        return responses;
    }
}