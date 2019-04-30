//
//  AsteroidsGameService.swift
//  SonicAsteroids
//
//  Created by Jonathan Rothwell on 04/07/2016.
//  Copyright © 2016 Zuhlke UK. All rights reserved.
//

import Cocoa
import Starscream
import os.log

private let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "game")

class AsteroidsGameService: NSObject, WebSocketDelegate {
    func websocketDidConnect(socket: WebSocketClient) {
        os_log("WebSocket connected", log: log, type: .info)
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        if let error = error {
            os_log("WebSocket disconnected with error: %s", log: log, type: .error, error.localizedDescription)
        } else {
            os_log("WebSocket disconnected cleanly.", log: log, type: .info)
        };
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        os_log("Got a text data frame of length %d", log: log, type: .info, text.count)
        if let callbackDefinitely = callback {
            DispatchQueue.main.async {
                callbackDefinitely(text)
            }
            DispatchQueue.global(qos: DispatchQoS.userInteractive.qosClass).async {
                AsteroidsSoundService.shared.processSound(with: text)
            }
        };
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        os_log("Got a binary data frame of length %d. Doing nothing", log: log, type: .info, data.count)
    }
    
    static let shared = AsteroidsGameService()
    var callback : ((String) -> Void)?
    var socket : WebSocket?
    
    func connect(_ url: URL, callback: @escaping (String) -> Void) {
        socket = WebSocket(url: url)
        self.callback = callback
        socket!.delegate = self
        socket!.connect()
    }
    
    func disconnect() {
        if let socketDefinitely = socket {
            socketDefinitely.disconnect()
        }
    }

}
