@isTest
public class DESNZ_AddressSplitterAction_Test {

    @isTest
    static void testSplitAddressesEmptyString() {
        // Test with an empty string
        List<String> input = new List<String> { '' };
        List<List<String>> result = DESNZ_AddressSplitterAction.splitAddresses(input);

        // Verify the result is an empty list
        System.assertEquals(1, result.size(), 'Result should contain one list.');
        System.assertEquals(0, result[0].size(), 'The inner list should be empty.');
    }

    @isTest
    static void testSplitAddressesSingleEntry() {
        // Test with a single address
        List<String> input = new List<String> { '123 Main St' };
        List<List<String>> result = DESNZ_AddressSplitterAction.splitAddresses(input);

        // Verify the result contains one address
        System.assertEquals(1, result.size(), 'Result should contain one list.');
        System.assertEquals(1, result[0].size(), 'The inner list should contain one address.');
        System.assertEquals('123 Main St', result[0][0], 'The address should match the input.');
    }

    @isTest
    static void testSplitAddressesMultipleEntries() {
        // Test with multiple addresses separated by new lines
        List<String> input = new List<String> {
            '123 Main St\n456 Elm St\n789 Oak St'
        };
        List<List<String>> result = DESNZ_AddressSplitterAction.splitAddresses(input);

        // Verify the result contains all addresses
        System.assertEquals(1, result.size(), 'Result should contain one list.');
        System.assertEquals(3, result[0].size(), 'The inner list should contain three addresses.');
        System.assertEquals('123 Main St', result[0][0], 'First address should match.');
        System.assertEquals('456 Elm St', result[0][1], 'Second address should match.');
        System.assertEquals('789 Oak St', result[0][2], 'Third address should match.');
    }

    @isTest
    static void testSplitAddressesMaxEntries() {
        // Test with the maximum number of addresses (100) separated by new lines
        List<String> inputAddresses = new List<String>();
        for (Integer i = 1; i <= 100; i++) {
            inputAddresses.add('Address ' + i);
        }
        String inputString = String.join(inputAddresses, '\n');
        List<String> input = new List<String> { inputString };

        List<List<String>> result = DESNZ_AddressSplitterAction.splitAddresses(input);

        // Verify the result contains 100 addresses
        System.assertEquals(1, result.size(), 'Result should contain one list.');
        System.assertEquals(100, result[0].size(), 'The inner list should contain 100 addresses.');
        for (Integer i = 1; i <= 100; i++) {
            System.assertEquals('Address ' + i, result[0][i - 1], 'Address ' + i + ' should match.');
        }
    }

    @isTest
    static void testSplitAddressesWithEmptyLines() {
        // Test with addresses interspersed with empty lines, including an empty line at the end
        List<String> input = new List<String> {
            '123 Main St\n\n456 Elm St\n\n789 Oak St\n'
        };
        List<List<String>> result = DESNZ_AddressSplitterAction.splitAddresses(input);

        // Verify the result contains only the valid addresses
        System.assertEquals(1, result.size(), 'Result should contain one list.');
        System.assertEquals(3, result[0].size(), 'The inner list should contain three addresses.');
        System.assertEquals('123 Main St', result[0][0], 'First address should match.');
        System.assertEquals('456 Elm St', result[0][1], 'Second address should match.');
        System.assertEquals('789 Oak St', result[0][2], 'Third address should match.');
    }
}