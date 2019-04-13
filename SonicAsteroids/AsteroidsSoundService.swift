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
    
    
    var bullet: AVAudioPlayer?
    var explosion: AVAudioPlayer?
    
    var bulletData: Data?
    var explosionData: Data?
    
    var playing : Bool = false
    
    var explosionAudioFiles : [Data]
    var bulletAudioFiles : [Data]
    
    var dispatchQueueBulletNoises : DispatchQueue
    var dispatchQueueExplosionNoises : DispatchQueue
    
    override init() {
        engine = AVAudioEngine()
        playerAtmos = AVAudioPlayerNode()
        playerBass = AVAudioPlayerNode()
        playerAction = AVAudioPlayerNode()
        playerAtmos.volume = 0.2
        playerBass.volume = 0.0 // TODO fade in
        playerAction.volume = 0.1
        
        
        bulletData = try? Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "Velocity Zapper_bip11", ofType: "mp3")!))
        explosionData = try? Data(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "11", ofType: "mp3")!))
        
        explosionAudioFiles = [Data]()
        for file : String in ["1", "3", "5", "7", "9", "11", "12"] {
            let path = Bundle.main.path(forResource: file, ofType: "mp3")
            let url = URL(fileURLWithPath: path!)
            if let data = try? Data(contentsOf: url) {
                explosionAudioFiles.append(data)
            }
        }
        bulletAudioFiles = [Data]()
        for file : String in ["Velocity Zapper_bip1", "Velocity Zapper_bip5", "Velocity Zapper_bip7", "Velocity Zapper_bip9", "Velocity Zapper_bip11", "Velocity Zapper_bip13", "Velocity Zapper_bip15", "Velocity Zapper_bip17", "Velocity Zapper_bip18"] {
            let path = Bundle.main.path(forResource: file, ofType: "mp3")
            let url = URL(fileURLWithPath: path!)
            if let data = try? Data(contentsOf: url) {
                bulletAudioFiles.append(data)
            }
        }
        
        bullet = AsteroidsSoundService.setupAudioPlayerWithFile("Velocity Zapper_bip1", type: "mp3")
        explosion = AsteroidsSoundService.setupAudioPlayerWithFile("5", type: "mp3")
        
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
    
    func playBulletSound() {
        bullet!.play()
    }
    
    func playExplosionSound() {
        explosion!.play()
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
            case .shoot?: dispatchQueueBulletNoises.async {
                self.makeBulletNoise(soundEvent: sound)
                }
            case .explosion?: dispatchQueueBulletNoises.async {
                self.makeExplosionNoise(soundEvent: sound)
                }
            case .none:
                break;
            }
            
        }
        
        // TODO Volume is a moving average of activity
        //        playerBass.volume = min(Float(bullets.count) / 40.0, Float(0.3))
        
    }
    
    func makeBulletNoise(soundEvent: SoundEvent) {
        bullet?.play();
        //        let bullet = Bullet(atPpan: soundEvent.pan ?? 0.0)
        //        bullet.play()
    }
    
    func makeExplosionNoise(soundEvent: SoundEvent) {
        explosion?.play();
        //            Explosion(atPan: soundEvent.pan ?? 0.0).play()
    }
    
}

struct Explosion {
    let pan: Float
    let player : AVAudioPlayer?
    
    init(atPan: Float) {
        pan = atPan
        player = AsteroidsSoundService.INSTANCE.getRandomAudioPlayer(AsteroidsSoundService.INSTANCE.explosionAudioFiles)
        player!.volume = 0.9
        player!.prepareToPlay()
    }
    
    func play() {
        player!.play()
        print("FIRED")
    }
}

struct Bullet {
    let pan: Float
    let player : AVAudioPlayer?
    
    init(atPpan: Float) {
        pan = atPpan
        player = AsteroidsSoundService.INSTANCE.getRandomAudioPlayer(AsteroidsSoundService.INSTANCE.bulletAudioFiles)
        player!.volume = 0.6
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
    let pan: Float?
    let sound: SoundType?
    
    init?(json: JSON) {
        self.gameTime = "t" <~~ json;
        self.pan = "pan" <~~ json;
        self.sound = "snd" <~~ json;
    }
}
