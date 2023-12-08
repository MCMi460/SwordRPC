//
//  SwordRPC.swift
//  SwordRPC
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

import Combine
import Foundation
import os.log

enum SwordError: Error {
    case runtimeError(String)
}

public class SwordRPC {
    // MARK: App Info

    public let appId: String
    public var handlerInterval: Int
    public let autoRegister: Bool

    // MARK: Technical stuff

    let pid: Int32
    var client: ConnectionClient?
    let worker: DispatchQueue
    var log: Logger
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    let currentPresence = CurrentValueSubject<RichPresence?, Never>(nil)
    var presenceUpdater: AnyCancellable!

    // MARK: Presence-related metadata

    var presence: RichPresence?

    // MARK: Event Handlers

    public weak var delegate: SwordRPCDelegate?

    public init(appId: String, handlerInterval: Int = 1000, autoRegister: Bool = true) {
        self.appId = appId
        self.handlerInterval = handlerInterval
        self.autoRegister = autoRegister

        pid = ProcessInfo.processInfo.processIdentifier
        log = Logger(subsystem: "space.joscomputing.swordrpc.\(pid)", category: "rpc")
        worker = DispatchQueue(
            label: "space.joscomputing.swordrpc.\(pid)",
            qos: .userInitiated
        )
        encoder.dateEncodingStrategy = .secondsSince1970
    }

    public func connect(_ ipcPort: Int) throws {
        let tempDir = NSTemporaryDirectory()

        let socketPath = tempDir + "discord-ipc-\(ipcPort)"
        let localClient = ConnectionClient(pipe: socketPath)
        do {
            try localClient.connect()

            // Set handlers
            localClient.textHandler = handleEvent
            localClient.disconnectHandler = handleEvent

            client = localClient
            // Attempt handshaking
            try handshake()
        } catch {
            // If an error occurrs, we should not log it.
            // We must iterate through all 10 ports before logging.
            throw SwordError.runtimeError("[SwordRPC] Discord not detected")
        }

        subscribe(.join)
        subscribe(.spectate)
        subscribe(.joinRequest)
        return
    }

    /// Replies to an activity join request.
    /// - Parameters:
    ///   - user: The user making the request
    ///   - reply: Whether to accept or decline the request.
    public func reply(to user: PartialUser, with reply: JoinReply) {
        var type: CommandType

        switch reply {
        case .yes:
            type = .sendActivityJoinInvite
        case .ignore, .no:
            type = .closeActivityJoinRequest
        }

        // We must give Discord the requesting user's ID to handle.
        let command = Command(cmd: type, args: [
            "user_id": .string(user.userId),
        ])

        try? send(command)
    }
}
