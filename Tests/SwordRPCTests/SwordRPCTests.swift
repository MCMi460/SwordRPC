//
//  SwordRPCTests.swift
//
//
//  Created by Deltaion Lee on 7/16/24.
//

@testable import SwordRPC
import XCTest

class SwordRPC_DiscordTests: XCTestCase, SwordRPCDelegate {
    // Use Ongaku's app ID.
    let rpc = SwordRPC(appId: "402370117901484042")

    override func setUp() {
        super.setUp()

        // Connect to the Discord client.
        rpc.connect()
    }

    // Example RPC test
    func testPresence() {
        // Create Rich Presence object.
        var presence = RichPresence()

        // Set to listening status
        presence.type = .listening

        // Assign details & state.
        presence.details = "Love Me Again"
        presence.detailsUrl = "https://music.apple.com/us/album/love-me-again/1440813192?i=1440813380"
        presence.state = "John Newman"
        presence.stateUrl = "https://music.apple.com/us/artist/john-newman/649230577"
        
        // Show song title instead of "Music."
        presence.statusDisplayType = .details

        // Assign image properties.
        presence.assets.largeImage = "big_sur_logo"
        presence.assets.largeText = "Tribute" // This is used as the album text in the "Listening" status.
        presence.assets.smallImage = "play"
        presence.assets.smallText = "Playing"

        // Create timestamps.
        presence.timestamps.start = Date()
        presence.timestamps.end = Date(timeIntervalSinceNow: 240)

        // Add button.
        presence.buttons = [
            RichPresence.Button(
                label: "Apple Music",
                url: "https://music.apple.com/us/album/love-me-again/1440813192?i=1440813380"
            ),
        ]

        // Push over RPC to client.
        rpc.setPresence(presence)

        // Hold main thread for five seconds.
        rpc.log.notice("Now waiting five seconds...")
        Thread.sleep(forTimeInterval: 5)
    }
}
