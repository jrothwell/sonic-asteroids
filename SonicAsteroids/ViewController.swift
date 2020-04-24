//
//  ViewController.swift
//  SonicAsteroids
//
//  Created by Jonathan Rothwell on 04/07/2016.
//  Copyright © 2016 Zuhlke UK. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    var playing: Bool = false
    var listening: Bool = false
    var initUrl: String = "ws://localhost:8065/0/sound"

    @IBOutlet weak var addressField: NSTextField!
    @IBOutlet weak var listenButton: NSButton!
    @IBOutlet weak var gameStateField: NSTextField!
    @IBOutlet weak var backgroundMusicField: NSTextField!
    
    override func viewDidAppear() {
        addressField.stringValue = self.initUrl
    }
    
    @IBAction func browseForBackgroundMusic(_ sender: AnyObject) {
        let filePicker = NSOpenPanel()
        filePicker.runModal()
        
        let path = filePicker.url?.path
        
        if let pathDefinitely = path {
            backgroundMusicField.stringValue = pathDefinitely
        }
    }
    
    @IBAction func beginListening(_ sender: AnyObject) {
        if !listening {
            AsteroidsGameService.INSTANCE.connect(URL(string: self.addressField.stringValue)!,
                                                  callback: updateGameState,
                                                  connectedCallback: connectedStatus)
            if (!playing) {
                AsteroidsSoundService.INSTANCE.start(backgroundMusicField.stringValue)
                playing = true
            }
        } else {
            AsteroidsGameService.INSTANCE.disconnect()
        }
    }
    
    func updateGameState(_ state: String) {
        gameStateField.stringValue = state
    }

    func connectedStatus(_ connected: Bool, error: String?) {
        if let errorDefinitely = error {
            gameStateField.stringValue = errorDefinitely
            listening = false
        } else {
            listening = !listening
        }
        if listening {
            self.addressField.isEditable = false
            self.listenButton.title = "Stop"
            AsteroidsSoundService.INSTANCE.start(backgroundMusicField.stringValue)
        } else {
            self.addressField.isEditable = true
            self.listenButton.title = "Listen"
        }        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if (CommandLine.arguments.count) >= 2 && (CommandLine.arguments[1].starts(with: "ws")) {
            self.initUrl = CommandLine.arguments[1]
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

