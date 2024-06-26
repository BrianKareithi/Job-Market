# JobMarket Module

## Overview

The jobMarket module is designed to facilitate the creation and management of an online job marketplace. This module provides a robust framework for administrators to create and manage job listings, handle job applications and completions by freelancers, and manage financial transactions within the marketplace. Key functionalities include listing jobs, accepting job applications, marking jobs as completed, and managing the marketplace balance, ensuring a smooth and efficient operation for both administrators and freelancers.

This module aims to streamline the job marketplace process, making it easier for administrators to manage job listings and for freelancers to find and complete jobs. It provides a comprehensive set of tools and functionalities to create a vibrant and efficient job marketplace ecosystem.

## Key Features

- Create Marketplace: Allows the creation of a new job marketplace.
- Add Job: Enables administrators to add jobs to the marketplace.
- Unlist Job: Allows administrators to unlist a job from the marketplace.
- Accept Job: Facilitates the acceptance of jobs by freelancers.
- **Complete Job: Allows freelancers to mark jobs as completed.
- Withdraw from Marketplace: Enables administrators to withdraw funds from the marketplace balance.
- Query Functions: Provides details about the marketplace, jobs, and accepted jobs.

## Structs

### Marketplace
Represents the job marketplace.
- `id: UID`
- `admin_cap: ID`
- `balance: Balance<SUI>`
- `jobs: vector<Job>`
- `job_count: u64`

### AdminCapability
Represents administrative capabilities within the marketplace.
- `id: UID`
- `marketplace: ID`

### Job
Represents a job in the marketplace.
- `id: u64`
- `title: String`
- `description: String`
- `price: u64`
- `url: Url`
- `listed: bool`
- `category: u8`
- `total_supply: u64`
- `available: u64`

### AcceptedJob
Represents a job that has been accepted by a freelancer.
- `id: UID`
- `marketplace_id: ID`
- `job_id: u64`

### Events
- `MarketplaceCreated`
- `JobAdded`
- `JobAccepted`
- `JobCompleted`
- `JobUnlisted`
- `MarketplaceWithdrawal`

## Functions

### Public Functions

create_marketplace
  - Creates a new marketplace.
  - Parameters: `recipient: address`, `ctx: &mut TxContext`

add_job
  - Adds a job to the marketplace.
  - Parameters: `marketplace: &mut Marketplace`, `admin_cap: &AdminCapability`, `title: vector<u8>`, `description: vector<u8>`, `url: vector<u8>`, `price: u64`, `supply: u64`, `category: u8`

unlist_job
  - Unlists a job from the marketplace.
  - Parameters: `marketplace: &mut Marketplace`, `admin_cap: &AdminCapability`, `job_id: u64`

accept_job
  - Accepts a job in the marketplace.
  - Parameters: `marketplace: &mut Marketplace`, `admin_cap: &AdminCapability`, `job_id: u64`, `quantity: u64`, `freelancer: address`, `payment_coin: &mut Coin<SUI>`, `ctx: &mut TxContext`

complete_job
  - Completes a job in the marketplace.
  - Parameters: `marketplace: &mut Marketplace`, `accepted_job: &AcceptedJob`, `freelancer: address`, `ctx: &mut TxContext`

withdraw_from_marketplace
  - Withdraws a specific amount from the marketplace balance.
  - Parameters: `marketplace: &mut Marketplace`, `admin_cap: &AdminCapability`, `amount: u64`, `recipient: address`, `ctx: &mut TxContext`

withdraw_all_from_marketplace
  - Withdraws the entire balance from the marketplace.
  - Parameters: `marketplace: &mut Marketplace`, `admin_cap: &AdminCapability`, `recipient: address`, `ctx: &mut TxContext`

get_marketplace_details
  - Retrieves the details of the marketplace.
  - Parameters: `marketplace: &Marketplace`
  - Returns: `(&UID, ID, &Balance<SUI>, &vector<Job>, u64)`

get_job_details
  - Retrieves the details of a specific job.
  - Parameters: `marketplace: &Marketplace`, `job_id: u64`
  - Returns: `(u64, String, String, u64, Url, bool, u8, u64, u64)`

get_accepted_job_details
  - Retrieves the details of an accepted job.
  - Parameters: `accepted_job: &AcceptedJob`
  - Returns: `(&UID, ID, u64)`

update_accepted_job_freelancer
  - Updates the freelancer of an accepted job.
  - Parameters: `accepted_job: &mut JobAccepted`, `freelancer: address`

## Error Codes

- `Error_Not_Admin: u64 = 1`
- `Error_Invalid_WithdrawalAmount: u64 = 2`
- `Error_Invalid_Quantity: u64 = 3`
- `Error_Insufficient_Payment: u64 = 4`
- `Error_Invalid_JobId: u64 = 5`
- `Error_Invalid_Price: u64 = 6`
- `Error_Invalid_Supply: u64 = 7`
- `Error_JobIsNotListed: u64 = 8`
- `Error_Not_Freelancer: u64 = 9`

## Usage

### Creating a Marketplace

jobmarket::create_marketplace(recipient_address, &mut ctx);


### Adding a Job

jobmarket::add_job(&mut marketplace, &admin_cap, title, description, url, price, supply, category);


### Accepting a Job

jobmarket::accept_job(&mut marketplace, &admin_cap, job_id, quantity, freelancer_address, &mut payment_coin, &mut ctx);


### Completing a Job

jobmarket::complete_job(&mut marketplace, &accepted_job, freelancer_address, &mut ctx);


### Withdrawing from the Marketplace

jobmarket::withdraw_from_marketplace(&mut marketplace, &admin_cap, amount, recipient_address, &mut ctx);


### Getting Marketplace Details

let details = jobmarket::get_marketplace_details(&marketplace);


### Getting Job Details
let job_details = jobmarket::get_job_details(&marketplace, job_id);

## Conclusion

The jobmarket module provides a comprehensive and efficient way to manage an online job marketplace. By leveraging this module, administrators can easily create and manage job listings, accept job applications, and handle job completions by freelancers. Additionally, the module provides robust financial management tools to handle marketplace balances. The provided functions and error handling ensure a smooth and secure operation, making it an essential tool for any job marketplace platform.