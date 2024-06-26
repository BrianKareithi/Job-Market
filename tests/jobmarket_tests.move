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
    use jobMarket::jobMarket::{Self as job, Marketplace, AdminCapability, Job, AcceptedJob};

    const ADMIN: address = @0xA;
    const TEST_ADDRESS1: address = @0xB;
    const TEST_ADDRESS2: address = @0xC;

    #[test]
    public fun test_water_cooler() {

        let mut scenario_test = init_test_helper();
        let scenario = &mut scenario_test;
        
        // Create marketplace 
        next_tx(scenario, TEST_ADDRESS1);
        {
            job::create_marketplace(ts::ctx(scenario));
        };
        // list an job 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let mut marketplace = ts::take_shared<Marketplace>(scenario);
            let cap = ts::take_from_sender<AdminCapability>(scenario);
            let title = b"asdasd";
            let description = b"asdsadsa";
            let url = b"asdsadsa";
            let price: u64 = 1_000_000_000;
            let supply: u64 = 100;
            let category: u8 = 100;

            job::add_job(
                &mut marketplace,
                &cap,
                title,
                description,
                url,
                price,
                supply,
                category
            );

            assert_eq(job::get_marketplace_count(&marketplace), 1);
            assert_eq(job::get_marketplace_table_count(&marketplace), 1);

            ts::return_shared(marketplace);
            ts::return_to_sender(scenario, cap);
        };
        // unlist an job 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let mut marketplace = ts::take_shared<Marketplace>(scenario);
            let cap = ts::take_from_sender<AdminCapability>(scenario);
            let id: u64 = 0;

            job::unlist_job(
                &mut marketplace,
                &cap,
                id,
             
            );

            assert_eq(job::get_marketplace_count(&marketplace), 0);
            assert_eq(job::get_marketplace_table_count(&marketplace), 0);

            ts::return_shared(marketplace);
            ts::return_to_sender(scenario, cap);
        };
        ts::end(scenario_test);
    }
}