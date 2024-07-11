module jobMarket::jobMarket {

    use sui::event;
    use sui::sui::SUI;
    use sui::url::{Self, Url};
    use std::string::{Self, String};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::table_vec::{Self, TableVec};
    use std::option::{Option};

    const Error_Not_Admin: u64 = 1;
    const Error_Invalid_WithdrawalAmount: u64 = 2;
    const Error_Invalid_Quantity: u64 = 3;
    const Error_Insufficient_Payment: u64 = 4;
    const Error_Invalid_JobId: u64 = 5;
    const Error_Invalid_Price: u64 = 6;
    const Error_Invalid_Supply: u64 = 7;
    const Error_JobIsNotListed: u64 = 8;
    const Error_Not_Freelancer: u64 = 9;
    const Error_Invalid_Url: u64 = 10;

    public struct Marketplace has key {
        id: UID,
        balance: Balance<SUI>,
        jobs: TableVec<Job>,
        job_count: u64,
        feedbacks: TableVec<Feedback>
    }

    public struct AdminCapability has key {
        id: UID,
        marketplace: ID,
    }

    public struct Job has copy, drop, store {
        id: u64,
        owner: Option<address>,
        completed: bool,
        taken: bool,
        title: String,
        description: String,
        price: u64,
        url: Url,
        listed: bool,
        category: u8,
        total_supply: u64,
        available: u64
    }

    public struct Feedback has copy, drop, store {
        job_id: u64,
        rating: u8,
        comments: String
    }

    public struct MarketplaceCreated has copy, drop {
        marketplace_id: ID,
        admin_cap_id: ID,
    }

    public struct JobAdded has copy, drop {
        marketplace_id: ID,
        job: u64,
    }

    public struct JobAccepted has copy, drop {
        marketplace_id: ID,
        job_id: u64,
        freelancer: address,
    }

    public struct JobCompleted has copy, drop {
        marketplace_id: ID,
        job_id: u64,
        quantity: u64,
        freelancer: address,
    }

    public struct JobUnlisted has copy, drop {
        marketplace_id: ID,
        job_id: u64,
    }

    public struct MarketplaceWithdrawal has copy, drop {
        marketplace_id: ID,
        amount: u64,
        recipient: address,
    }

    public struct JobFeedbackAdded has copy, drop {
        job_id: u64,
        rating: u8,
        comments: String,
    }

    public fun get_marketplace_count(self: &Marketplace) : u64 {
        self.job_count
    }

    public fun get_marketplace_table_count(self: &Marketplace) : u64 {
        self.jobs.length()
    }

    public fun create_marketplace(ctx: &mut TxContext) {
        let marketplace_uid = object::new(ctx);
        let admin_cap_uid = object::new(ctx);
        let marketplace_id = object::uid_to_inner(&marketplace_uid);
        let admin_cap_id = object::uid_to_inner(&admin_cap_uid);

        transfer::transfer(AdminCapability {
            id: admin_cap_uid,
            marketplace: marketplace_id
        }, ctx.sender());

        transfer::share_object(Marketplace {
            id: marketplace_uid,
            balance: balance::zero<SUI>(),
            jobs: table_vec::empty(ctx),
            job_count: 0,
            feedbacks: table_vec::empty(ctx),
        });

        event::emit(MarketplaceCreated {
            marketplace_id,
            admin_cap_id
        })
    }

    public fun add_job(
        marketplace: &mut Marketplace,
        admin_cap: &AdminCapability,
        title: vector<u8>,
        description: vector<u8>,
        url: vector<u8>,
        price: u64,
        supply: u64,
        category: u8,
        ctx: &mut TxContext
    ) {
        assert!(admin_cap.marketplace == object::uid_to_inner(&marketplace.id), Error_Not_Admin);
        assert!(price > 0, Error_Invalid_Price);
        assert!(supply > 0, Error_Invalid_Supply);
        assert!(url::is_valid_url(string::utf8(url.clone())), Error_Invalid_Url);

        let job_id = marketplace.jobs.length();

        let job = Job {
            id: job_id,
            owner: option::none(),
            completed: false,
            taken: false,
            title: string::utf8(title),
            description: string::utf8(description),
            price: price,
            url: url::new_unsafe_from_bytes(url),
            listed: true,
            category: category,
            total_supply: supply,
            available: supply,
        };

        marketplace.jobs.push_back(job);
        marketplace.job_count = marketplace.job_count + 1;

        event::emit(JobAdded {
            marketplace_id: admin_cap.marketplace,
            job: job_id
        });
    }

    public fun unlist_job(
        marketplace: &mut Marketplace,
        admin_cap: &AdminCapability,
        job_id: u64
    ) {
        assert!(admin_cap.marketplace == object::uid_to_inner(&marketplace.id), Error_Not_Admin);
        assert!(job_id < marketplace.jobs.length(), Error_Invalid_JobId);

        let _job = marketplace.jobs.swap_remove(job_id);
        marketplace.job_count = marketplace.job_count - 1;

        event::emit(JobUnlisted {
            marketplace_id: object::uid_to_inner(&marketplace.id),
            job_id: job_id
        });
    }

    public fun accept_job(
        marketplace: &mut Marketplace,
        job_id: u64,
        ctx: &mut TxContext
    ) {
        assert!(job_id < marketplace.jobs.length(), Error_Invalid_JobId);
        let job = &mut marketplace.jobs[job_id];
        assert!(!job.taken, Error_Invalid_JobId);
        assert!(job.listed == true, Error_JobIsNotListed);

        job.taken = true;
        option::fill(&mut job.owner, ctx.sender());

        event::emit(JobAccepted {
            marketplace_id: object::uid_to_inner(&marketplace.id),
            job_id: job_id,
            freelancer: ctx.sender(),
        });

        if job.available == 0 {
            unlist_job(marketplace, &admin_cap, job_id);
        }
    }

    public fun complete_job(
        marketplace: &mut Marketplace,
        accepted_job: u64,
        ctx: &mut TxContext
    ) {
        assert!(accepted_job < marketplace.jobs.length(), Error_Invalid_JobId);
        let job = marketplace.jobs.borrow_mut(accepted_job);
        assert!(ctx.sender() == job.owner.borrow(), Error_Invalid_JobId);
        job.completed = true;

        event::emit(JobCompleted {
            marketplace_id: object::uid_to_inner(&marketplace.id),
            job_id: accepted_job,
            quantity: job.total_supply - job.available,
            freelancer: ctx.sender(),
        });
    }

    public fun provision(
        marketplace: &mut Marketplace,
        admin_cap: &AdminCapability,
        job_id: u64,
        ctx: &mut TxContext
    ) {
        assert!(admin_cap.marketplace == object::uid_to_inner(&marketplace.id), Error_Not_Admin);
        assert!(job_id < marketplace.jobs.length(), Error_Invalid_JobId);

        let job = marketplace.jobs.swap_remove(job_id);
        assert!(job.completed, Error_Insufficient_Payment);

        let coin_ = coin::take(&mut marketplace.balance, job.total_supply, ctx);
        transfer::public_transfer(coin_, *job.owner.borrow());

        event::emit(JobUnlisted {
            marketplace_id: object::uid_to_inner(&marketplace.id),
            job_id: job_id
        });
    }

    public fun withdraw_from_marketplace(
        marketplace: &mut Marketplace,
        admin_cap: &AdminCapability,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        assert!(admin_cap.marketplace == object::uid_to_inner(&marketplace.id), Error_Not_Admin);
        assert!(amount > 0 && amount <= marketplace.balance.value(), Error_Invalid_WithdrawalAmount);

        let take_coin = coin::take(&mut marketplace.balance, amount, ctx);
        transfer::public_transfer(take_coin, recipient);

        event::emit(MarketplaceWithdrawal {
            marketplace_id: object::uid_to_inner(&marketplace.id),
            amount: amount,
            recipient: recipient
        });
    }

    public fun deposit_to_marketplace(
        marketplace: &mut Marketplace,
        coin_: Coin<SUI>,
    ) {
        marketplace.balance.join(coin::into_balance(coin_));

        event::emit(MarketplaceWithdrawal {
            marketplace_id: object::uid_to_inner(&marketplace.id),
            amount: coin_::value(),
            recipient: address(0) // Indicating deposit event
        });
    }

    public fun get_marketplace_details(marketplace: &Marketplace) : (&Balance<SUI>, u64) {
        (
            &marketplace.balance,
            marketplace.job_count
        )
    }

    public fun get_job_details(marketplace: &Marketplace, job_id: u64) : (u64, String, String, u64, Url, bool, u8, u64, u64) {
        assert!(job_id < marketplace.jobs.length(), Error_Invalid_JobId);
        let job = &marketplace.jobs[job_id];
        (
            job.id,
            job.title,
            job.description,
            job.price,
            job.url,
            job.listed,
            job.category,
            job.total_supply,
            job.available
        )
    }

    public fun update_accepted_job_freelancer(accepted_job: &mut JobAccepted, freelancer: address) {
        accepted_job.freelancer = freelancer;
    }

    public fun add_feedback(
        marketplace: &mut Marketplace,
        job_id: u64,
        rating: u8,
        comments: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(job_id < marketplace.jobs.length(), Error_Invalid_JobId);
        assert!(rating > 0 && rating <= 5, Error_Invalid_Quantity);

        let feedback = Feedback {
            job_id: job_id,
            rating: rating,
            comments: string::utf8(comments)
        };

        marketplace.feedbacks.push_back(feedback);

        event::emit(JobFeedbackAdded {
            job_id: job_id,
            rating: rating,
            comments: string::utf8(comments)
        });
    }

    public fun get_feedback(marketplace: &Marketplace, job_id: u64) : (u64, u8, String) {
        assert!(job_id < marketplace.feedbacks.length(), Error_Invalid_JobId);

        let feedback = &marketplace.feedbacks[job_id];
        (
            feedback.job_id,
            feedback.rating,
            feedback.comments
        )
    }
}
