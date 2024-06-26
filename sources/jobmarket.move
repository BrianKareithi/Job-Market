module jobMarket::jobMarket {

    use sui::event; // Import sui event module
    use sui::sui::SUI; // Import sui module for SUI
    use sui::url::{Self, Url}; // Import sui url module
    use std::string::{Self, String}; // Import std string module
    use sui::coin::{Self, Coin}; // Import sui coin module
    use sui::balance::{Self, Balance}; // Import sui balance module
    use sui::table_vec::{Self, TableVec};

    // Define error codes
    const Error_Not_Admin: u64 = 1; // Error code for not an admin
    const Error_Invalid_WithdrawalAmount: u64 = 2; // Error code for invalid withdrawal amount
    const Error_Invalid_Quantity: u64 = 3; // Error code for invalid quantity
    const Error_Insufficient_Payment: u64 = 4; // Error code for insufficient payment
    const Error_Invalid_JobId: u64 = 5; // Error code for invalid job id
    const Error_Invalid_Price: u64 = 6; // Error code for invalid price
    const Error_Invalid_Supply: u64 = 7; // Error code for invalid supply
    const Error_JobIsNotListed: u64 = 8; // Error code for job not listed
    const Error_Not_Freelancer: u64 = 9; // Error code for not a freelancer

    // Define Marketplace struct with key ability
    public struct Marketplace has key {
        id: UID, // Unique ID for the marketplace
        balance: Balance<SUI>, // Balance of SUI in the marketplace
        jobs: TableVec<Job>, // Vector of jobs in the marketplace
        job_count: u64 // Count of jobs in the marketplace
    }

    // Define AdminCapability struct with key ability
    public struct AdminCapability has key {
        id: UID, // Unique ID for the admin capability
        marketplace: ID, // Marketplace ID
    }

    // Define Job struct with store ability
    public struct Job has store {
        id: u64, // Job ID
        title: String, // Title of the job
        description: String, // Description of the job
        price: u64, // Price of the job
        url: Url, // URL of the job
        listed: bool, // Whether the job is listed
        category: u8, // Category of the job
        total_supply: u64, // Total supply of the job
        available: u64 // Available quantity of the job
    }

    // Define AcceptedJob struct with key ability
    public struct AcceptedJob has key {
        id: UID, // Unique ID for the accepted job
        marketplace_id: ID, // Marketplace ID
        job_id: u64 // Job ID
    }

    // Define MarketplaceCreated event struct with copy and drop abilities
    public struct MarketplaceCreated has copy, drop {
        marketplace_id: ID, // Marketplace ID
        admin_cap_id: ID, // Admin capability ID
    }

    // Define JobAdded event struct with copy and drop abilities
    public struct JobAdded has copy, drop {
        marketplace_id: ID, // Marketplace ID
        job: u64, // Job ID
    }

    // Define JobAccepted event struct with copy and drop abilities
    public struct JobAccepted has copy, drop {
        marketplace_id: ID, // Marketplace ID
        job_id: u64, // Job ID
        quantity: u64, // Quantity of jobs accepted
        freelancer: address, // Freelancer address
    }

    // Define JobCompleted event struct with copy and drop abilities
    public struct JobCompleted has copy, drop {
        marketplace_id: ID, // Marketplace ID
        job_id: u64, // Job ID
        quantity: u64, // Quantity of jobs completed
        freelancer: address, // Freelancer address
    }

    // Define JobUnlisted event struct with copy and drop abilities
    public struct JobUnlisted has copy, drop {
        marketplace_id: ID, // Marketplace ID
        job_id: u64 // Job ID
    }

    // Define MarketplaceWithdrawal event struct with copy and drop abilities
    public struct MarketplaceWithdrawal has copy, drop {
        marketplace_id: ID, // Marketplace ID
        amount: u64, // Withdrawal amount
        recipient: address // Recipient address
    }

    // Function to create a new marketplace
    public fun create_marketplace(recipient: address, ctx: &mut TxContext) {
        // Create a new UID for the marketplace
        let marketplace_uid = object::new(ctx);
        // Create a new UID for the admin capability
        let admin_cap_uid = object::new(ctx);

        // Get the inner ID of the marketplace UID
        let marketplace_id = object::uid_to_inner(&marketplace_uid);
        // Get the inner ID of the admin capability UID
        let admin_cap_id = object::uid_to_inner(&admin_cap_uid);

        // Transfer the admin capability to the recipient
        transfer::transfer(AdminCapability {
            id: admin_cap_uid, // Set the admin capability UID
            marketplace: marketplace_id // Set the marketplace ID
         }, recipient);

        // Share the marketplace object
        transfer::share_object(Marketplace {
            id: marketplace_uid, // Set the marketplace UID
            balance: balance::zero<SUI>(), // Initialize the balance to zero
            jobs: table_vec::empty(ctx), // Initialize the jobs vector to empty
            job_count: 0, // Initialize the job count to zero
        });

        // Emit the MarketplaceCreated event
        event::emit(MarketplaceCreated {
           marketplace_id, // Set the marketplace ID
           admin_cap_id // Set the admin capability ID
        })
    }

    // Function to add a job to the marketplace
    public fun add_job(
        marketplace: &mut Marketplace, // Mutable reference to the marketplace
        admin_cap: &AdminCapability, // Reference to the admin capability
        title: vector<u8>, // Title of the job
        description: vector<u8>, // Description of the job
        url: vector<u8>, // URL for the job
        price: u64, // Price of the job
        supply: u64, // Total supply of the job
        category: u8 // Category of the job
    ) {
        // Check if the caller is an admin
        assert!(admin_cap.marketplace == object::uid_to_inner(&marketplace.id), Error_Not_Admin);
        // Check if the price is valid
        assert!(price > 0, Error_Invalid_Price);
        // Check if the supply is valid
        assert!(supply > 0, Error_Invalid_Supply);

        // Get the current length of the jobs vector
        let job_id = marketplace.jobs.length();

        // Create a new job
        let job = Job {
            id: job_id, // Set the job ID
            title: string::utf8(title), // Set the job title
            description: string::utf8(description), // Set the job description
            price: price, // Set the job price
            url: url::new_unsafe_from_bytes(url), // Set the job URL
            listed: true, // Set the job as listed
            category: category, // Set the job category
            total_supply: supply, // Set the total supply of the job
            available: supply, // Set the available quantity of the job
        };

        // Add the job to the jobs vector
        marketplace.jobs.push_back(job);
        // Increment the job count
        marketplace.job_count = marketplace.job_count + 1;

        // Emit the JobAdded event
        event::emit(JobAdded {
            marketplace_id: admin_cap.marketplace, // Set the marketplace ID
            job: job_id // Set the job ID
        });
    }

    // Function to unlist a job from the marketplace
    public fun unlist_job(
        marketplace: &mut Marketplace, // Mutable reference to the marketplace
        admin_cap: &AdminCapability, // Reference to the admin capability
        job_id: u64 // ID of the job to be unlisted
    ) {
        // Check if the caller is an admin
        assert!(admin_cap.marketplace == object::uid_to_inner(&marketplace.id), Error_Not_Admin);
        // Check if the job ID is valid
        assert!(job_id <= marketplace.jobs.length(), Error_Invalid_JobId);

        // Get the job by ID
        let job = &mut marketplace.jobs[job_id];
        // Unlist the job
        job.listed = false;

        // Emit the JobUnlisted event
        event::emit(JobUnlisted {
            marketplace_id: object::uid_to_inner(&marketplace.id), // Set the marketplace ID
            job_id: job_id // Set the job ID
        });
    }

    fun unlist(
        marketplace: &mut Marketplace, // Mutable reference to the marketplace
        job_id: u64 // ID of the job to be unlisted
    ) {
        // Check if the job ID is valid
        assert!(job_id <= marketplace.jobs.length(), Error_Invalid_JobId);

        // Get the job by ID
        let job = &mut marketplace.jobs[job_id];
        // Unlist the job
        job.listed = false;

        // Emit the JobUnlisted event
        event::emit(JobUnlisted {
            marketplace_id: object::uid_to_inner(&marketplace.id), // Set the marketplace ID
            job_id: job_id // Set the job ID
        });
    }

    // Function to accept a job in the marketplace
    public fun accept_job(
        marketplace: &mut Marketplace, // Mutable reference to the marketplace
        job_id: u64, // ID of the job to be accepted
        quantity: u64, // Quantity of jobs to be accepted
        freelancer: address, // Address of the freelancer accepting the job
        payment_coin: &mut Coin<SUI>, // Payment coin for the job
        ctx: &mut TxContext // Transaction context
    ) {
        // Check if the job ID is valid
        assert!(job_id <= marketplace.jobs.length(), Error_Invalid_JobId);
        // Check if the quantity is valid
        assert!(quantity > 0, Error_Invalid_Quantity);

        // Get the job by ID
        let job = &mut marketplace.jobs[job_id];
        // Check if the available quantity is sufficient
        assert!(job.available >= quantity, Error_Invalid_Quantity);

        // Get the value of the payment coin
        let value = payment_coin.value();
        // Calculate the total price
        let total_price = job.price * quantity;
        // Check if the payment is sufficient
        assert!(value >= total_price, Error_Insufficient_Payment);

        // Check if the job is listed
        assert!(job.listed == true, Error_JobIsNotListed);

        // Update the available quantity
        job.available = job.available - quantity;

        // Split the payment coin
        let paid = payment_coin.split(total_price, ctx);

        // Add the payment to the marketplace balance
        coin::put(&mut marketplace.balance, paid);

        // Initialize a counter
        let mut i = 0_u64;

        // Loop for the quantity
        while (i < quantity) {
            // Create a new UID for the accepted job
            let accepted_job_uid = object::new(ctx);

            // Transfer the accepted job
            transfer::transfer(AcceptedJob {
                id: accepted_job_uid, // Set the accepted job UID
                marketplace_id: object::uid_to_inner(&marketplace.id), // Set the marketplace ID
                job_id: job_id // Set the job ID
            }, freelancer);

            // Increment the counter
            i = i + 1;
        };

        // Emit the JobAccepted event
        event::emit(JobAccepted {
            marketplace_id: object::uid_to_inner(&marketplace.id), // Set the marketplace ID
            job_id: job_id, // Set the job ID
            quantity: quantity, // Set the quantity
            freelancer: freelancer, // Set the freelancer address
        });

        if (job.available == 0) {
            // Unlist the job
            unlist(marketplace, job_id);
        }    
    }

    // Function to complete a job in the marketplace
    public fun complete_job(
        marketplace: &mut Marketplace, // Mutable reference to the marketplace
        accepted_job: &AcceptedJob, // Reference to the accepted job
        freelancer: address, // Address of the freelancer completing the job
        ctx: &mut TxContext // Transaction context
    ) {
        // Check if the marketplace ID is valid
        assert!(accepted_job.marketplace_id == object::uid_to_inner(&marketplace.id), Error_Invalid_JobId);
        // Check if the job ID is valid
        assert!(accepted_job.job_id <= marketplace.jobs.length(), Error_Invalid_JobId);
        // Check if the caller is the freelancer
        assert!(tx_context::sender(ctx) == freelancer, Error_Not_Freelancer);

        // Get the job by ID
        let job = &mut marketplace.jobs[accepted_job.job_id];
        // Update the available quantity
        job.available = job.available + 1;

        // Emit the JobCompleted event
        event::emit(JobCompleted {
            marketplace_id: object::uid_to_inner(&marketplace.id), // Set the marketplace ID
            job_id: accepted_job.job_id, // Set the job ID
            quantity: 1, // Set the quantity
            freelancer: freelancer, // Set the freelancer address
        });

        // Check if the available quantity is at least 1
        if (job.available >= 1) {
            // Relist the job
            table_vec::borrow_mut(&mut marketplace.jobs, accepted_job.job_id).listed = true;
        }
    }

    // Function to withdraw from the marketplace balance
    public fun withdraw_from_marketplace(
        marketplace: &mut Marketplace, // Mutable reference to the marketplace
        admin_cap: &AdminCapability, // Reference to the admin capability
        amount: u64, // Amount to be withdrawn
        recipient: address, // Address of the recipient
        ctx: &mut TxContext // Transaction context
    ) {
        // Check if the caller is an admin
        assert!(admin_cap.marketplace == object::uid_to_inner(&marketplace.id), Error_Not_Admin);
        // Check if the withdrawal amount is valid
        assert!(amount > 0 && amount <= marketplace.balance.value(), Error_Invalid_WithdrawalAmount);

        // Take the coin from the balance
        let take_coin = coin::take(&mut marketplace.balance, amount, ctx);

        // Transfer the coin to the recipient
        transfer::public_transfer(take_coin, recipient);

        // Emit the MarketplaceWithdrawal event
        event::emit(MarketplaceWithdrawal {
            marketplace_id: object::uid_to_inner(&marketplace.id), // Set the marketplace ID
            amount: amount, // Set the withdrawal amount
            recipient: recipient // Set the recipient address
        });
    }

    // Getter function for marketplace details
    public fun get_marketplace_details(marketplace: &Marketplace) : (&Balance<SUI>, u64) {
        (
            &marketplace.balance, // Return the marketplace balance
            marketplace.job_count // Return the job count
        )
    }

    // Getter function for job details by job ID
    public fun get_job_details(marketplace: &Marketplace, job_id: u64) : (u64, String, String, u64, Url, bool, u8, u64, u64) {
        // Get the job by ID
        let job = &marketplace.jobs[job_id];
        (
            job.id, // Return the job ID
            job.title, // Return the job title
            job.description, // Return the job description
            job.price, // Return the job price
            job.url, // Return the job URL
            job.listed, // Return whether the job is listed
            job.category, // Return the job category
            job.total_supply, // Return the total supply of the job
            job.available // Return the available quantity of the job
        )
    }

    // Getter function for accepted job details by accepted job ID
    public fun get_accepted_job_details(accepted_job: &AcceptedJob) : (&UID, ID, u64) {
        (
            &accepted_job.id, // Return the accepted job UID
            accepted_job.marketplace_id, // Return the marketplace ID
            accepted_job.job_id // Return the job ID
        )
    }

    // Function to update the freelancer of an accepted job
    public fun update_accepted_job_freelancer(accepted_job: &mut JobAccepted, freelancer: address) {
        // Update the freelancer address
        accepted_job.freelancer = freelancer;
    }

    // === Test Functions ===
    
  
}
