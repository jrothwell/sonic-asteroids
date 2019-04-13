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
        print("WebSocket connected!");
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        if let errorDefinitely = error {
            print("WebSocket disconnected with error \(errorDefinitely.localizedDescription)")
        } else {
            print("WebSocket disconnected cleanly.")
        };
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        if let callbackDefinitely = callback {
            DispatchQueue.main.async {
                callbackDefinitely(text)
            }
            DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high).async {
                AsteroidsSoundService.INSTANCE.processSound(text)
            }
        };
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("got some data: \(data.count)");
    }
    
    static let INSTANCE = AsteroidsGameService() // singleton
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
