module flowr::track {
    use sui::tx_context;
    use std::string::{Self, String};
    use sui::event;
    use sui::balance::{Balance, Self};
    use sui::sui::SUI;
    use sui::coin::{Coin, Self};
    use sui::package;
    use sui::display;

    // Errors
    const EInvalidMetadata: u64 = 0;
    const EUnauthorizedAction: u64 = 1;
    const EPaymentInvalid: u64 = 2;

    public struct Track has key, store {
        id: UID,
        title: String,
        artist: address,
        genre: String,
        publish_date: String,
        stream_count: u64,
        earnings: Balance<SUI>,
        cover_url: String,
    }

    public struct TrackCreated has copy, drop {
        track_id: ID,
        title: String,
        artist: address
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
            string::utf8(b"Track by {artist}"),
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
        title: String,
        artist: address,
        genre: String,
        publish_date: String,
        cover_url: String,
        ctx: &mut TxContext
    ): ID {
        
        
        let track = Track {
            id: object::new(ctx),
            title,
            artist,
            genre,
            publish_date,
            stream_count: 0,
            earnings: balance::zero<SUI>(),
            cover_url,
        };

        let track_id = object::id(&track);

        event::emit(TrackCreated {
            track_id,
            title,
            artist
        });

        transfer::share_object(track);
        track_id
    }

    // Rest of the functions remain the same...
    public fun stream_track(
        track: &mut Track,
        ctx: &mut TxContext
    ) {
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
    ): Coin<SUI> {
        assert!(track.artist == tx_context::sender(ctx), EUnauthorizedAction);
        let val = balance::value(&track.earnings);
        let coin = coin::take(&mut track.earnings, val, ctx);
        coin
    }

    // Getter functions remain the same
    public fun get_title(track: &Track): String { track.title }
    public fun get_artist(track: &Track): address { track.artist }
}