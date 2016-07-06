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

    @IBOutlet weak var addressField: NSTextField!
    @IBOutlet weak var listenButton: NSButton!
    @IBOutlet weak var gameStateField: NSTextField!
    @IBOutlet weak var backgroundMusicField: NSTextField!
    
    override func viewDidAppear() {
        addressField.stringValue = "ws://ec2-52-28-1-127.eu-central-1.compute.amazonaws.com/sound" // sensible default
    }
    
    @IBAction func browseForBackgroundMusic(sender: AnyObject) {
        let filePicker = NSOpenPanel()
        filePicker.runModal()
        
        let path = filePicker.URL?.path
        
        if let pathDefinitely = path {
            backgroundMusicField.stringValue = pathDefinitely
        }
    }
    
    @IBAction func beginListening(sender: AnyObject) {
        listening = !listening
        if listening {
            AsteroidsGameService.INSTANCE.connect(NSURL(string: self.addressField.stringValue)!,
                                                  callback: updateGameState)
            self.addressField.editable = false
            self.listenButton.title = "Stop Listening"
            AsteroidsSoundService.INSTANCE.start(backgroundMusicField.stringValue)
        } else {
            AsteroidsSoundService.INSTANCE.stop()
            AsteroidsGameService.INSTANCE.disconnect()
            self.addressField.editable = true
            self.listenButton.title = "Listen"
            
        }
    }
    
    func updateGameState(state: String) {
        gameStateField.stringValue = state
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

