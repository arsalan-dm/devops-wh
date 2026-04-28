public with sharing class GmsCcrMappingService {
    
    public Map<String, Map<String, String>> mappingStorage = new Map<String, Map<String, String>>();

    public GmsCcrMappingService(){

        // i known this is aweful, I think we need a mdt for these but didn't have time to make one 
        Map<String, String> abLG = new Map<String, String>{
            'Total_Homes_to_be_Upgraded__c' => 'Total_number_of_homes_to_be_upgraded__c',
            'Baseline_Grant_Capital_Spend__c' => 'Grant_Capital_Spend__c',
            'Baseline_Grant_A_A_Spend__c' => 'Grant_A_A_Spend__c'
        };
        Map<String, String> abCF = new Map<String, String>{
            'No_of_Homes_to_EPC_C__c' => 'No_of_Homes_to_EPC_C__c',
            'Total_Homes_to_be_Upgraded__c' => 'Total_number_of_homes_to_be_upgraded__c',
            'Energy_Savings_kWh__c' => 'Energy_Savings__c',
            'Baseline_Grant_Capital_Spend__c' => 'Grant_Capital_Spend__c',
            'Baseline_Grant_A_A_Spend__c' => 'Grant_A_A_Spend__c',
            'Baseline_Co_Funding_Capital_Spend__c' => 'Co_Funding_Capital_Spend__c',
            'Baseline_Co_funding_A_A_spend__c' => 'Co_funding_A_A_spend__c',
            'No_of_Homes_for_Off_Gas_grid_LCH_Uplift__c' => 'No_of_Homes_for_Off_Gas_grid_LCH_Uplift__c',
            'No_of_Homes_for_On_Gas_grid_LCH_Offer__c' => 'No_of_Homes_for_On_Gas_grid_LCH_Uplift__c',
            'Co_Funding_Spend_24_25__c' => 'Co_Funding_Spend_24_25__c',
            'Co_Funding_Spend_25_26__c' => 'Co_Funding_Spend_25_26__c',
            'Co_Funding_Spend_26_27__c' => 'Co_Funding_Spend_26_27__c',
            'Co_Funding_Spend_27_28__c' => 'Co_Funding_Spend_27_28__c',
            'Co_Funding_Spend_28_29__c' => 'Co_Funding_Spend_28_29__c',
            'Co_Funding_Spend_29_30__c' => 'Co_Funding_Spend_29_30__c',
            'Grant_Spend_25_26__c' => 'Grant_Spend_25_26__c',
            'Grant_Spend_26_27__c' => 'Grant_Spend_26_27__c',
            'Grant_Spend_27_28__c' => 'Grant_Spend_27_28__c'
        };
        Map<String, String> abSH = new Map<String, String>{
            'No_of_Homes_to_EPC_C__c' => 'No_of_Homes_to_EPC_C__c',
            'Total_Homes_to_be_Upgraded__c' => 'Total_number_of_homes_to_be_upgraded__c',
            'Energy_Savings_kWh__c' => 'Energy_Savings__c',
            'Baseline_Grant_Capital_Spend__c' => 'Grant_Capital_Spend__c',
            'Baseline_Grant_A_A_Spend__c' => 'Grant_A_A_Spend__c',
            'Baseline_Co_Funding_Capital_Spend__c' => 'Co_Funding_Capital_Spend__c',
            'Baseline_Co_funding_A_A_spend__c' => 'Co_funding_A_A_spend__c',
            'No_of_Homes_for_Off_Gas_grid_LCH_Uplift__c' => 'No_of_Homes_for_Off_Gas_grid_LCH_Uplift__c',
            'No_of_Homes_for_On_Gas_grid_LCH_Offer__c' => 'No_of_Homes_for_On_Gas_grid_LCH_Uplift__c'
        };
        Map<String, String> sbLG = new Map<String, String>{
            'Total_Homes_to_be_Upgraded__c' => 'Total_number_of_homes_to_be_upgraded__c',
            'Baseline_Grant_Capital_Spend__c' => 'Grant_Capital_Spend__c',
            'Baseline_Grant_A_A_Spend__c' => 'Grant_A_A_Spend__c'
        };
        Map<String, String> sbCF = new Map<String, String>{
            'No_of_Homes_to_EPC_C__c' => 'No_of_Homes_to_EPC_C__c',
            'Total_Homes_to_be_Upgraded__c' => 'Total_number_of_homes_to_be_upgraded__c',
            'Energy_Savings_kWh__c' => 'Energy_Savings__c',
            'Baseline_Grant_Capital_Spend__c' => 'Grant_Capital_Spend__c',
            'Baseline_Grant_A_A_Spend__c' => 'Grant_A_A_Spend__c',
            'Baseline_Co_Funding_Capital_Spend__c' => 'Co_Funding_Capital_Spend__c',
            'Baseline_Co_funding_A_A_spend__c' => 'Co_funding_A_A_spend__c',
            'No_of_homes_starting_at_A__c' => 'No_of_homes_starting_at_EPC_A__c',
            'No_of_homes_starting_at_EPC_B__c' => 'No_of_homes_starting_at_EPC_B__c',
            'No_of_homes_starting_at_EPC_C__c' => 'No_of_homes_starting_at_EPC_C__c',
            'No_of_homes_starting_at_EPC_D__c' => 'No_of_homes_starting_at_EPC_D__c',
            'No_of_homes_starting_at_EPC_E__c' => 'No_of_homes_starting_at_EPC_E__c',
            'No_of_homes_starting_at_EPC_F__c' => 'No_of_homes_starting_at_EPC_F__c',
            'No_of_homes_starting_at_EPC_G__c' => 'No_of_homes_starting_at_EPC_G__c',
            'No_of_homes_ending_at_EPC_A__c' => 'No_of_homes_ending_at_EPC_A__c',
            'No_of_homes_ending_at_EPC_B__c' => 'No_of_homes_ending_at_EPC_B__c',
            'No_of_homes_ending_at_EPC_C__c' => 'No_of_homes_ending_at_EPC_C__c',
            'No_of_homes_ending_at_EPC_D__c' => 'No_of_homes_ending_at_EPC_D__c',
            'No_of_homes_ending_at_EPC_E__c' => 'No_of_homes_ending_at_EPC_E__c',
            'No_of_homes_ending_at_EPC_F__c' => 'No_of_homes_ending_at_EPC_F__c',
            'No_of_homes_ending_at_EPC_G__c' => 'No_of_homes_ending_at_EPC_G__c',
            'No_of_Homes_for_Off_Gas_grid_LCH_Uplift__c' => 'No_of_Homes_for_Off_Gas_grid_LCH_Uplift__c',
            'No_of_Homes_for_On_Gas_grid_LCH_Offer__c' => 'No_of_Homes_for_On_Gas_grid_LCH_Uplift__c'
        };
        Map<String, String> sbSH = new Map<String, String>{
            'No_of_Homes_to_EPC_C__c' => 'No_of_Homes_to_EPC_C__c',
            'Total_Homes_to_be_Upgraded__c' => 'Total_number_of_homes_to_be_upgraded__c',
            'Energy_Savings_kWh__c' => 'Energy_Savings__c',
            'SP_Baseline_Grant_Spend__c' => 'Grant_Funding_Spend__c',
            'SP_Baseline_Co_Funding_Spend__c' => 'Co_funding_Spend__c',
            'No_of_Homes_for_Off_Gas_grid_LCH_Uplift__c' => 'No_of_Homes_for_Off_Gas_grid_LCH_Uplift__c',
            'No_of_Homes_for_On_Gas_grid_LCH_Offer__c' => 'No_of_Homes_for_On_Gas_grid_LCH_Uplift__c'
        };
        mappingStorage.put('Award BaselineLocal Grant',abLG);
        mappingStorage.put('Award BaselineSHF Challenge Fund',abCF);
        mappingStorage.put('Award BaselineSHF Strategic Partner',abSH);
        mappingStorage.put('Sub BaselineLocal Grant',sbLG);
        mappingStorage.put('Sub BaselineSHF Challenge Fund',sbCF);
        mappingStorage.put('Sub BaselineSHF Strategic Partner',sbSH);

    }

    public Map<String, String> get(String baselineType, String scheme){
        String storageKey = baselineType+scheme;
        return mappingStorage.get(storageKey);
    }
}