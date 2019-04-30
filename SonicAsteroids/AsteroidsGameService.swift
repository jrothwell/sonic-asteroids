//
//  AsteroidsGameService.swift
//  SonicAsteroids
//
//  Created by Jonathan Rothwell on 04/07/2016.
//  Copyright © 2016 Zuhlke UK. All rights reserved.
//

import Cocoa
import Starscream

class AsteroidsGameService: NSObject, WebSocketDelegate {
    func websocketDidConnect(socket: WebSocketClient) {
        connectedCallback!(true, nil)
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        if let errorDefinitely = error {
            connectedCallback!(false, errorDefinitely.localizedDescription)
        } else {
            connectedCallback!(false, "Disconnected")
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        if let callbackDefinitely = callback {
            DispatchQueue.main.async {
                callbackDefinitely(text)
            }
            DispatchQueue.global(qos: DispatchQoS.userInteractive.qosClass).async {
                AsteroidsSoundService.shared.processSound(with: text)
            }
        }
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
    }
    
    static let shared = AsteroidsGameService()
    var callback : ((String) -> Void)?
    var connectedCallback : ((Bool, String?) -> Void)?
    var socket : WebSocket?
    
    func connect(_ url: URL, callback: @escaping (String) -> Void, connectedCallback: @escaping (Bool, String?) -> Void) {
        socket = WebSocket(url: url)
        self.callback = callback
        self.connectedCallback = connectedCallback
        socket!.delegate = self
        socket!.connect()
    }
    
    func disconnect() {
        if let socketDefinitely = socket {
            socketDefinitely.disconnect()
        }
    }

}
