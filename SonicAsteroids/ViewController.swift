//
//  ViewController.swift
//  SonicAsteroids
//
//  Created by Jonathan Rothwell on 04/07/2016.
//  Copyright © 2016 Zuhlke UK. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
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
        listening = !listening
        if listening {
            AsteroidsGameService.INSTANCE.connect(URL(string: self.addressField.stringValue)!,
                                                  callback: updateGameState)
            self.addressField.isEditable = false
            self.listenButton.title = "Stop Listening"
            AsteroidsSoundService.INSTANCE.start(backgroundMusicField.stringValue)
        } else {
            AsteroidsSoundService.INSTANCE.stop()
            AsteroidsGameService.INSTANCE.disconnect()
            self.addressField.isEditable = true
            self.listenButton.title = "Listen"
            
        }
    }
    
    func updateGameState(_ state: String) {
        gameStateField.stringValue = state
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

