public class DESNZ_AddressSplitterAction {
    
    @InvocableMethod(label='Split Address List' description='Splits a string of addresses into individual entries.')
    public static List<List<String>> splitAddresses(List<String> input) {
        List<String> result = new List<String>();

        // Check if the input list is not empty and has a single string entry
        if (input != null && !input.isEmpty()) {
            // Split the input string by new line characters
            String addresses = input[0];
            if (!String.isEmpty(addresses)) {
                // Split the input string by new line characters
                List<String> splitAddresses = addresses.split('\n');
                // Filter out empty strings
                for (String address : splitAddresses) {
                    if (!String.isEmpty(address)) {
                        result.add(address);
                    }
                }
            }
        }

        // Return the result as a list of lists to comply with Flow requirements
        return new List<List<String>> { result };
    }
    
}