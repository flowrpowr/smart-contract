module flowr::track {
    use sui::object::{Self, UID, ID};
    use sui::tx_context;
    use std::string::{Self, String};
    use sui::event;
    use sui::balance::{Balance, Self};
    use sui::coin::{Coin, Self};
    use sui::package;
    use sui::display;

    use flowr::admin::{Admin};
    use flowr::stream::{STREAM};


    // Errors
    const EUnauthorizedAction: u64 = 1;
    const EPaymentInvalid: u64 = 2;

    public struct Track has key, store {
        id: UID,
        release_type: String,
        release_title: String,
        track_number: u8,
        title: String,
        artist: String,
        artist_address: address,
        genre: String,
        publish_date: String,
        stream_count: u64,
        earnings: Balance<STREAM>,
        cover_url: String,
    }

    public struct TrackCreated has copy, drop {
        track_id: ID,
        title: String,
        track_number: u8,
        artist_address: address
    }

    public struct TrackStreamed has copy, drop {
        track_id: ID,
        title: String,
        listener: address,
    }

    public struct TRACK has drop {}

    fun init(witness: TRACK, ctx: &mut TxContext) {
        let publisher = package::claim(witness, ctx);

        let keys = vector[
            string::utf8(b"title"),
            string::utf8(b"image_url"),
            string::utf8(b"description"),
            string::utf8(b"artist"),
        ];

        let values = vector[
            string::utf8(b"{title}"),
            string::utf8(b"{cover_url}"),
            string::utf8(b"{title}"),
            string::utf8(b"{artist}")
        ];

        // Create and share the Display object
        let mut display = display::new_with_fields<Track>(
            &publisher, 
            keys,
            values,
            ctx
        );

        display::update_version(&mut display);
        transfer::public_transfer(display, tx_context::sender(ctx));
        transfer::public_transfer(publisher, tx_context::sender(ctx));
        
    }

    public fun create_track(
        release_type: String,
        release_title: String,
        track_number: u8,
        title: String,
        artist: String,
        artist_address: address,
        genre: String,
        publish_date: String,
        cover_url: String,
        ctx: &mut TxContext
    ) {
        
        
        let track = Track {
            id: object::new(ctx),
            release_type,
            release_title,
            track_number,
            title,
            artist,
            artist_address,
            genre,
            publish_date,
            stream_count: 0,
            earnings: balance::zero<STREAM>(),
            cover_url,
        };

        let track_id = object::id(&track);

        event::emit(TrackCreated {
            track_id,
            title,
            track_number,
            artist_address
        });

        transfer::share_object(track);
    }

    // Rest of the functions remain the same...
    public fun stream_track(
        track: &mut Track,
        payment: Coin<STREAM>,
        ctx: &mut TxContext
    ) {
        assert!(coin::value(&payment) == 1, EPaymentInvalid);
        coin::put(&mut track.earnings, payment);
        track.stream_count = track.stream_count + 1; 

        event::emit(TrackStreamed{
            title: track.title,
            listener: tx_context::sender(ctx),
            track_id: object::uid_to_inner(&track.id),
        })
    }

    public fun withdraw_earnings(
        track: &mut Track,
        ctx: &mut TxContext
    ): Coin<STREAM> {
        assert!(track.artist_address == tx_context::sender(ctx), EUnauthorizedAction);
        let val = balance::value(&track.earnings);
        let coin = coin::take(&mut track.earnings, val, ctx);
        coin
    }

    public fun change_cover_url(
        _: &Admin,
        track: &mut Track,
        new_url: String
    ) {
        track.cover_url = new_url
    }
}