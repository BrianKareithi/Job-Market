#[test_only]
module jobMarket::water_cooler_test {
    use sui::test_scenario::{Self as ts, next_tx, Scenario};
    use sui::coin::{Self, Coin, mint_for_testing};
    use sui::sui::SUI;
    use sui::test_utils::{assert_eq};
    use sui::transfer::{Self};
    use sui::balance::{Self, Balance};

    use std::vector::{Self};
    use std::string::{Self, String};

    use jobMarket::helpers::{Self, init_test_helper};
    use jobMarket::jobMarket::{Self, Marketplace, AdminCapability, Job, AcceptedJob};

    const ADMIN: address = @0xA;
    const TEST_ADDRESS1: address = @0xB;
    const TEST_ADDRESS2: address = @0xC;

    #[test]
    public fun test_water_cooler() {

        let mut scenario_test = init_test_helper();
        let scenario = &mut scenario_test;
        
        // User has to buy water_cooler from cooler_factory share object. 
        next_tx(scenario, TEST_ADDRESS1);
        {

   
        };
        ts::end(scenario_test);
    }
}