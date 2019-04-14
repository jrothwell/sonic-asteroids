//
//  AsteroidsSoundService.swift
//  SonicAsteroids
//
//  Created by Jonathan Rothwell on 05/07/2016.
//  Copyright © 2016 Zuhlke UK. All rights reserved.
//

import Cocoa
import AVFoundation
import SpriteKit
import Gloss

typealias Payload = [NSDictionary]

class AsteroidsSoundService: NSObject {
    static let INSTANCE = AsteroidsSoundService()
    
    var engine : AVAudioEngine
    var playerAtmos: AVAudioPlayerNode!
    var playerBass: AVAudioPlayerNode!
    var playerAction: AVAudioPlayerNode!
    
    
    var shootPlayers:[AVAudioPlayer]
    var explosionPlayers:[AVAudioPlayer]
    
    var playing : Bool = false
    
    var dispatchQueueBulletNoises : DispatchQueue
    var dispatchQueueExplosionNoises : DispatchQueue
    
    var explosion_filenames:[String] = [
        "12",
        "5",
        "7",
        "3",
        "9",
        "1",
        "11"
    ];
    
    var shoot_filenames:[String] = [
        "Velocity Zapper_bip13",
        "Velocity Zapper_bip11",
        "Velocity Zapper_bip17",
        "Velocity Zapper_bip9",
        "Velocity Zapper_bip15",
        "Velocity Zapper_bip18",
        "Velocity Zapper_bip5",
        "Velocity Zapper_bip1"
    ];
    
    override init() {
        engine = AVAudioEngine()
        playerAtmos = AVAudioPlayerNode()
        playerBass = AVAudioPlayerNode()
        playerAction = AVAudioPlayerNode()
        playerAtmos.volume = 0.2
        playerBass.volume = 0.0 // TODO fade in
        playerAction.volume = 0.1
        
        
        shootPlayers = [AVAudioPlayer]()
        for file : String in shoot_filenames {
            if let player =  AsteroidsSoundService.setupAudioPlayerWithFile(file as NSString, type: "mp3") {
                shootPlayers.append(player);
            }
        }
        explosionPlayers = [AVAudioPlayer]()
        for file : String in explosion_filenames {
            if let player =  AsteroidsSoundService.setupAudioPlayerWithFile(file as NSString, type: "mp3") {
                explosionPlayers.append(player);
            }
        }
        
        
        dispatchQueueBulletNoises = DispatchQueue(label: "com.zuhlke.asteroids", attributes: [])
        dispatchQueueExplosionNoises = DispatchQueue(label: "com.zuhlke.asteroids", attributes: [])
        
    }
    
    static func setupAudioPlayerWithFile(_ file:NSString, type:NSString) -> AVAudioPlayer?  {
        let path = Bundle.main.path(forResource: file as String, ofType: type as String)
        let url = URL(fileURLWithPath: path!)
        
        var audioPlayer :AVAudioPlayer?
        
        do {
            try audioPlayer = AVAudioPlayer(contentsOf: url)
        } catch {
            print("Player not available")
        }
        
        return audioPlayer
    }
    
    func getRandomAudioPlayer(_ withArray: [Data]) -> AVAudioPlayer? {
        var player : AVAudioPlayer?
        do {
            let randomIndex = Int(arc4random_uniform(UInt32(withArray.count)))
            try player = AVAudioPlayer(data: withArray[randomIndex])
        } catch {
            print("Couldn't find data")
        }
        
        return player
    }
    
    
    func start(_ path: String) {
        guard !playing else {
            print("Already playing...")
            return
        }
        
        let atmosUrl = URL(fileURLWithPath: Bundle.main.path(forResource: "Mars-atmos", ofType: "mp3")!)
        let bassUrl = URL(fileURLWithPath: Bundle.main.path(forResource: "Mars-bass", ofType: "mp3")!)
        let actionUrl = URL(fileURLWithPath: Bundle.main.path(forResource: "Mars-action", ofType: "mp3")!)
        do {
            let atmosFile = try AVAudioFile(forReading: atmosUrl)
            let atmosBuffer = AVAudioPCMBuffer(pcmFormat: atmosFile.processingFormat, frameCapacity: AVAudioFrameCount(atmosFile.length))
            try atmosFile.read(into: atmosBuffer!)
            
            let bassFile = try AVAudioFile(forReading: bassUrl)
            let bassBuffer = AVAudioPCMBuffer(pcmFormat: bassFile.processingFormat, frameCapacity: AVAudioFrameCount(bassFile.length))
            try bassFile.read(into: bassBuffer!)
            
            let actionFile = try AVAudioFile(forReading: actionUrl)
            let actionBuffer = AVAudioPCMBuffer(pcmFormat: actionFile.processingFormat, frameCapacity: AVAudioFrameCount(actionFile.length))
            try actionFile.read(into: actionBuffer!)
            
            
            engine.attach(playerAtmos)
            engine.attach(playerBass)
            engine.attach(playerAction)
            
            
            engine.connect(playerAtmos, to: engine.mainMixerNode, format: atmosBuffer!.format)
            engine.connect(playerBass, to: engine.mainMixerNode, format: bassBuffer!.format)
            engine.connect(playerAction, to: engine.mainMixerNode, format: actionBuffer!.format)
            // Schedule playerAtmos and playerBass to play the buffer on a loop
            playerAtmos.scheduleBuffer(atmosBuffer!, at: nil, options: AVAudioPlayerNodeBufferOptions.loops, completionHandler: nil)
            playerBass.scheduleBuffer(bassBuffer!, at: nil, options: AVAudioPlayerNodeBufferOptions.loops, completionHandler: nil)
            playerAction.scheduleBuffer(actionBuffer!, at: nil, options: AVAudioPlayerNodeBufferOptions.loops, completionHandler: nil)
            
            // Start the audio engine
            engine.prepare()
            try engine.start()
            
            playerAtmos.play()
            playerBass.play()
            playerAction.play()
        } catch {
            print("Error!")
        }
        
        playing = true
        
    }
    
    func stop() {
        playerAtmos.stop()
        playerBass.stop()
        playerAction.stop()
        engine.stop()
        
        playing = false
    }
    
    /* Return an idle sound player. If all are busy, choose one to be restarted! */
    func availablePlayer(_ candidates: [AVAudioPlayer]) -> AVAudioPlayer? {
        let playersIdle = candidates.filter({!$0.isPlaying});
        if (playersIdle.isEmpty) {
            let p = candidates.randomElement()
            p?.stop()
            p?.currentTime = 0
            return p;
        } else {
            return playersIdle.randomElement();
        }
    }
    
    func processSound(_ withText: String) {
        var json : Payload!
        do {
            json = try JSONSerialization.jsonObject(with: withText.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions()) as? Payload
        } catch {
            print(error)
            return
        }
        
        guard let soundEvents = [SoundEvent].from(jsonArray: json as! [JSON]) else {
            print("Bad sound stream")
            return
        }
        
        for sound in soundEvents {
            switch sound.sound {
            case .shoot?: self.makeBulletNoise(soundEvent: sound)
            case .explosion?: self.makeExplosionNoise(soundEvent: sound)
            case .none:
                break;
            }
        }
        // TODO Volume is a moving average of activity
        //        playerBass.volume = min(Float(bullets.count) / 40.0, Float(0.3))
    }
    
    func makeBulletNoise(soundEvent: SoundEvent) {
        dispatchQueueBulletNoises.async {
            let player = self.availablePlayer(self.shootPlayers)
            let bullet = Bullet(pan: soundEvent.pan ?? 0.0, avPlayer: player)
            bullet.play()
        }
    }
    
    func makeExplosionNoise(soundEvent: SoundEvent) {
        dispatchQueueExplosionNoises.async {
            let player = self.availablePlayer(self.explosionPlayers)
            let explosion = Explosion(pan: soundEvent.pan ?? 0.0, avPlayer: player)
            explosion.play()
        }
    }
    
}

struct Explosion {
    let player : AVAudioPlayer?
    
    init(pan: Double, avPlayer: AVAudioPlayer?) {
        player = avPlayer;
        player!.pan = adjustPan(pan: pan)
        player!.volume = 0.8
        player!.prepareToPlay()
    }
    
    func play() {
        player!.play()
    }
}

struct Bullet {
    let player : AVAudioPlayer?
    
    init(pan: Double, avPlayer: AVAudioPlayer?) {
        player = avPlayer;
        player!.pan = adjustPan(pan: pan)
        player!.volume = 0.3
        player!.prepareToPlay()
    }
    func play() {
        player!.play()
    }
    
}

enum SoundType: String {
    case shoot = "f";
    case explosion = "x";
}

struct SoundEvent : JSONDecodable {
    let gameTime: Int?
    let pan: Double?
    let sound: SoundType?
    
    init?(json: JSON) {
        self.gameTime = "t" <~~ json;
        self.pan = "pan" <~~ json;
        self.sound = "snd" <~~ json;
    }
}

/*
 Apply the quadratic function y=x^5
 This keeps the pan inside the range -1..1
 But applies a bathtub curve to keep the sounds
 mostly in the centre of the soundscape.
 
 https://www.wolframalpha.com/input/?i=y%3Dx%5E5,+y%3D1,+y%3D-1
 */
func adjustPan(pan: Double) -> Float {
    if (pan < -1.0) {
        return 0.0;
    } else if (pan > 1.0) {
        return 0.0;
    } else {
        return Float(pan * pan * pan * pan * pan);
    }
}
