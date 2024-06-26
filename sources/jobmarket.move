module jobmarket::jobmarket {

    use sui::event; // Import sui event module
    use sui::sui::SUI; // Import sui module for SUI
    use sui::url::{Self, Url}; // Import sui url module
    use std::string::{Self, String}; // Import std string module
    use sui::coin::{Self, Coin}; // Import sui coin module
    use sui::balance::{Self, Balance}; // Import sui balance module

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
        admin_cap: ID, // Admin capability ID
		balance: Balance<SUI>, // Balance of SUI in the marketplace
		jobs: vector<Job>, // Vector of jobs in the marketplace
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
        // let marketplace_uid = object::new(ctx); // Create a new UID for the marketplace
        // let admin_cap_uid = object::new(ctx); // Create a new UID for the admin capability

        let marketplace_uid = object::new(ctx); // Create a new UID for the marketplace
        let admin_cap_uid = object::new(ctx); // Create a new UID for the admin capability

        let marketplace_id = object::uid_to_inner(&marketplace_uid); // Get the inner ID of the marketplace UID
        let admin_cap_id = object::uid_to_inner(&admin_cap_uid); // Get the inner ID of the admin capability UID

        transfer::transfer(AdminCapability { // Transfer the admin capability
            id: admin_cap_uid, // Set the admin capability UID
            marketplace: marketplace_id // Set the marketplace ID
         }, recipient); // Transfer to the recipient

        transfer::share_object(Marketplace { // Share the marketplace object
            id: marketplace_uid, // Set the marketplace UID
            admin_cap: admin_cap_id, // Set the admin capability ID
            balance: balance::zero<SUI>(), // Initialize the balance to zero
            jobs: vector::empty(), // Initialize the jobs vector to empty
            job_count: 0, // Initialize the job count to zero
        });

        event::emit(MarketplaceCreated { // Emit the MarketplaceCreated event
           marketplace_id, // Set the marketplace ID
           admin_cap_id // Set the admin capability ID
        })
    }

    // Function to add a job to the marketplace
    public fun add_job(
        marketplace: &mut Marketplace,
        admin_cap: &AdminCapability, 
        title: vector<u8>, 
        description: vector<u8>,
        url: vector<u8>, // URL for the job
        price: u64,
        supply: u64,
        category: u8
    ) {
        assert!(marketplace.admin_cap == object::uid_to_inner(&admin_cap.id), Error_Not_Admin); // Check if the caller is an admin
        assert!(price > 0, Error_Invalid_Price); // Check if the price is valid
        assert!(supply > 0, Error_Invalid_Supply); // Check if the supply is valid

        let job_id = marketplace.jobs.length(); // Get the current length of the jobs vector

        let job = Job { // Create a new job
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

        marketplace.jobs.push_back(job); // Add the job to the jobs vector
        marketplace.job_count = marketplace.job_count + 1; // Increment the job count

        event::emit(JobAdded { // Emit the JobAdded event
            marketplace_id: admin_cap.marketplace, // Set the marketplace ID
            job: job_id // Set the job ID
        });
    }

    // Function to unlist a job from the marketplace
    public fun unlist_job(
        marketplace: &mut Marketplace,
        admin_cap: &AdminCapability,
        job_id: u64
    ) {
        assert!(marketplace.admin_cap == object::uid_to_inner(&admin_cap.id), Error_Not_Admin); // Check if the caller is an admin
        assert!(job_id <= marketplace.jobs.length(), Error_Invalid_JobId); // Check if the job ID is valid

        let job = &mut marketplace.jobs[job_id]; // Get the job by ID
        job.listed = false; // Unlist the job

        event::emit(JobUnlisted { // Emit the JobUnlisted event
            marketplace_id: object::uid_to_inner(&marketplace.id), // Set the marketplace ID
            job_id: job_id // Set the job ID
        });
    }

    // Function to accept a job in the marketplace
    public fun accept_job(
        marketplace: &mut Marketplace,
        admin_cap: &AdminCapability,
        job_id: u64,
        quantity: u64,
        freelancer: address,
        payment_coin: &mut Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert!(job_id <= marketplace.jobs.length(), Error_Invalid_JobId); // Check if the job ID is valid
        assert!(quantity > 0, Error_Invalid_Quantity); // Check if the quantity is valid

        let job = &mut marketplace.jobs[job_id]; // Get the job by ID
        assert!(job.available >= quantity, Error_Invalid_Quantity); // Check if the available quantity is sufficient

        let value = payment_coin.value(); // Get the value of the payment coin
        let total_price = job.price * quantity; // Calculate the total price
        assert!(value >= total_price, Error_Insufficient_Payment); // Check if the payment is sufficient

        assert!(job.listed == true, Error_JobIsNotListed); // Check if the job is listed

        job.available = job.available - quantity; // Update the available quantity

        let paid = payment_coin.split(total_price, ctx); // Split the payment coin

        coin::put(&mut marketplace.balance, paid); // Add the payment to the marketplace balance

        let mut i = 0_u64; // Initialize a counter

        while (i < quantity) { // Loop for the quantity
            let accepted_job_uid = object::new(ctx); // Create a new UID for the accepted job

            transfer::transfer(AcceptedJob { // Transfer the accepted job
                id: accepted_job_uid, // Set the accepted job UID
                marketplace_id: object::uid_to_inner(&marketplace.id), // Set the marketplace ID
                job_id: job_id }, freelancer); // Set the job ID and freelancer address

            i = i+1; // Increment the counter
        };

        event::emit(JobAccepted { // Emit the JobAccepted event
            marketplace_id: object::uid_to_inner(&marketplace.id), // Set the marketplace ID
            job_id: job_id, // Set the job ID
            quantity: quantity, // Set the quantity
            freelancer: freelancer, // Set the freelancer address
        });

        if (job.available == 0 ) { // Check if the available quantity is zero
           unlist_job(marketplace, admin_cap, job_id); // Unlist the job
        }
    }
    
    // Function to complete a job in the marketplace
    public fun complete_job(
        marketplace: &mut Marketplace,
        accepted_job: &AcceptedJob,
        freelancer: address,
        ctx: &mut TxContext
    ) {
        assert!(accepted_job.marketplace_id == object::uid_to_inner(&marketplace.id), Error_Invalid_JobId); // Check if the marketplace ID is valid
        assert!(accepted_job.job_id <= marketplace.jobs.length(), Error_Invalid_JobId); // Check if the job ID is valid
        assert!(tx_context::sender(ctx) == freelancer, Error_Not_Freelancer); // Check if the caller is the freelancer

        let job = &mut marketplace.jobs[accepted_job.job_id]; // Get the job by ID
        job.available = job.available + 1; // Update the available quantity

        event::emit(JobCompleted { // Emit the JobCompleted event
            marketplace_id: object::uid_to_inner(&marketplace.id), // Set the marketplace ID
            job_id: accepted_job.job_id, // Set the job ID
            quantity: 1, // Set the quantity
            freelancer: freelancer, // Set the freelancer address
        });

        if (job.available >= 1) { // Check if the available quantity is at least 1
            vector::borrow_mut(&mut marketplace.jobs, accepted_job.job_id).listed = true; // Relist the job
        }
    }

    // Function to withdraw from the marketplace balance
    public fun withdraw_from_marketplace(
        marketplace: &mut Marketplace,
        admin_cap: &AdminCapability,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        assert!(marketplace.admin_cap == object::uid_to_inner(&admin_cap.id), Error_Not_Admin); // Check if the caller is an admin
        assert!(amount > 0 && amount <= marketplace.balance.value(), Error_Invalid_WithdrawalAmount); // Check if the withdrawal amount is valid

        let take_coin = coin::take(&mut marketplace.balance, amount, ctx); // Take the coin from the balance
        
        transfer::public_transfer(take_coin, recipient); // Transfer the coin to the recipient
        
        event::emit(MarketplaceWithdrawal { // Emit the MarketplaceWithdrawal event
            marketplace_id: object::uid_to_inner(&marketplace.id), // Set the marketplace ID
            amount: amount, // Set the withdrawal amount
            recipient: recipient // Set the recipient address
        });
    }

    // Function to withdraw all balance from the marketplace
    public fun withdraw_all_from_marketplace(
        marketplace: &mut Marketplace,
        admin_cap: &AdminCapability,
        recipient: address,
        ctx: &mut TxContext
    ) {
        assert!(marketplace.admin_cap == object::uid_to_inner(&admin_cap.id), Error_Not_Admin); // Check if the caller is an admin
        let amount = marketplace.balance.value(); // Get the balance value
        let take_coin = coin::take(&mut marketplace.balance, amount, ctx); // Take the coin from the balance
        
        transfer::public_transfer(take_coin, recipient); // Transfer the coin to the recipient
        
        event::emit(MarketplaceWithdrawal { // Emit the MarketplaceWithdrawal event
            marketplace_id: object::uid_to_inner(&marketplace.id), // Set the marketplace ID
            amount: amount, // Set the withdrawal amount
            recipient: recipient // Set the recipient address
        });
    }

    // Getter function for marketplace details
    public fun get_marketplace_details(marketplace: &Marketplace) : (&UID, ID, &Balance<SUI>, &vector<Job>, u64) {
        (
            &marketplace.id, // Return the marketplace UID
            marketplace.admin_cap, // Return the admin capability ID
            &marketplace.balance, // Return the marketplace balance
            &marketplace.jobs, // Return the jobs vector
            marketplace.job_count // Return the job count
        )
    }
    
    // Getter function for job details by job ID
    public fun get_job_details(marketplace: &Marketplace, job_id: u64) : (u64, String, String, u64, Url, bool, u8, u64, u64) {
        let job = &marketplace.jobs[job_id]; // Get the job by ID
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
        accepted_job.freelancer = freelancer; // Update the freelancer address
    }

}
