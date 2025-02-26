module flowr::admin {
    use sui::transfer;
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use std::string::{Self, String};
    use sui::package::{Self, Publisher};

    // Error codes
    const ENotAuthorized: u64 = 0;
    const ENotSuperAdmin: u64 = 1;

    // Structs for admin capabilities
    public struct SuperAdmin has key, store {
        id: UID
    }

    public struct Admin has key, store {
        id: UID
    }

    // Mark the module as a package that can have a Publisher
    public struct ADMIN has drop {}

    // Struct for track data
    public struct Track has key, store {
        id: UID,
        cover_url: String,
        // Other track properties can be added here
    }

    // Called when module is published
    fun init(witness: ADMIN, ctx: &mut TxContext) {
        // Claim the Publisher object for this package
        let publisher = package::claim(witness, ctx);
        
        // Transfer the Publisher to the module publisher (sender)
        transfer::public_transfer(publisher, tx_context::sender(ctx));
        
        // Create and transfer SuperAdmin to the module publisher
        let super_admin = SuperAdmin {
            id: object::new(ctx)
        };
        transfer::transfer(super_admin, tx_context::sender(ctx));

        // Create and transfer Admin to the module publisher
        let admin = Admin {
            id: object::new(ctx)
        };
        transfer::transfer(admin, tx_context::sender(ctx));
    }

    // Create a new Admin object (only SuperAdmin can do this)
    public entry fun create_admin(
        _: &SuperAdmin, 
        recipient: address, 
        ctx: &mut TxContext
    ) {
        let admin = Admin {
            id: object::new(ctx)
        };
        transfer::transfer(admin, recipient);
    }
}