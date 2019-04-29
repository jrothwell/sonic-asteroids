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
    
    var playing : Bool = false
    var engine : AVAudioEngine
    var playerAtmos: AVAudioPlayerNode!
    var playerBass: AVAudioPlayerNode!
    var playerAction: AVAudioPlayerNode!
    
    var shootPlayers:[AVAudioPlayer]
    var explosionPlayers:[AVAudioPlayer]
    
    var dispatchQueueNoises : DispatchQueue
    
    var eventCountThisSecond = 0;
    var shortRollingCount : CircularCountingList?
    var longRollingCount : CircularCountingList?
    var volumeTimer : Timer?
    
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
        playerAtmos.volume = 0.4
        playerBass.volume = 0.0 // TODO fade in
        playerAction.volume = 0.3
        
        shootPlayers = AsteroidsSoundService.loadSamplesToPlayers(shoot_filenames)
        explosionPlayers = AsteroidsSoundService.loadSamplesToPlayers(explosion_filenames)
        
        dispatchQueueNoises = DispatchQueue(label: "com.zuhlke.asteroids", attributes: [])
        
    }
    
    static func loadSamplesToPlayers(_ filenames: [String]) -> [AVAudioPlayer] {
        var players = [AVAudioPlayer]()
        for file : String in filenames {
            if let player =  AsteroidsSoundService.setupAudioPlayerWithFile(file as NSString, type: "mp3"){
                players.append(player);
            }
        }
        return players;
    }
    
    
    static func setupAudioPlayerWithFile(_ file:NSString, type:NSString) -> AVAudioPlayer?  {
        let path = Bundle.main.path(forResource: file as String, ofType: type as String)
        let url = URL(fileURLWithPath: path!)
        
        var audioPlayer :AVAudioPlayer?
        
        do {
            try audioPlayer = AVAudioPlayer(contentsOf: url)
        } catch {
            print("Player not available")
            // TODO fail if we cannot play sounds...
        }
        
        return audioPlayer
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
        
        eventCountThisSecond = 0;
        shortRollingCount = CircularCountingList(3) // Keep  3 readings of eventCountThisSecond
        longRollingCount = CircularCountingList(6) // Keep 6 readings of eventCountThisSecond
        
        volumeTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(volumeTimerAction), userInfo: nil, repeats: true)
        
        playing = true
        
    }
    
    func stop() {
        playerAtmos.stop()
        playerBass.stop()
        playerAction.stop()
        engine.stop()
        
        volumeTimer?.invalidate()
        
        playing = false
    }
    
    /* Return an idle sound player. If all are busy, choose one to be restarted! */
    func availablePlayer(_ players: [AVAudioPlayer]) -> AVAudioPlayer? {
        let playersIdle = idle(players);
        if (playersIdle.isEmpty) {
            return stop(players.randomElement());
        } else {
            return playersIdle.randomElement();
        }
    }
    
    // Filter players for those not playing
    func idle(_ players: [AVAudioPlayer]) -> [AVAudioPlayer] {
        return players.filter({!$0.isPlaying})
    }
    
    // Stop an audio player and reset playback to beginning
    func stop(_ player: AVAudioPlayer?) -> AVAudioPlayer? {
        player?.stop()
        player?.currentTime = 0
        return player
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
        
        self.eventCountThisSecond += sumSoundEvents(soundEvents)
    }
    
    func makeBulletNoise(soundEvent: SoundEvent) {
        dispatchQueueNoises.async {
            if let player = self.availablePlayer(self.shootPlayers) {
                Bullet(pan: soundEvent.pan ?? 0.0, avPlayer: player).play()
            }
        }
    }
    
    func makeExplosionNoise(soundEvent: SoundEvent) {
        dispatchQueueNoises.async {
            if let player = self.availablePlayer(self.explosionPlayers) {
                Explosion(pan: soundEvent.pan ?? 0.0, avPlayer: player).play()
            }
        }
    }
    
    /* Once per second, adjust the bass volume to be the fraction of the 3s game activity over the 6s game activity */
    @objc func volumeTimerAction() {
        self.shortRollingCount?.add(self.eventCountThisSecond);
        self.longRollingCount?.add(self.eventCountThisSecond);
        
        let volumeDelta:Float = 0.05
        DispatchQueue.main.async {
            let n = Float(self.shortRollingCount?.sum() ?? 0);
            let d = Float(self.longRollingCount?.sum() ?? 1) + 1.0;
            
            let targetBassVolume = volumeDelta + ( (n/d) * 0.5);
            
            if (self.playerBass.volume < targetBassVolume) {
                self.playerBass.volume = self.playerBass.volume + volumeDelta
            } else if (self.playerBass.volume > targetBassVolume) {
                self.playerBass.volume = max(self.playerBass.volume - volumeDelta, volumeDelta)
            }
        }
        self.eventCountThisSecond = 0;
    }
    
}


struct Explosion {
    let player : AVAudioPlayer
    
    init(pan: Double, avPlayer: AVAudioPlayer) {
        player = avPlayer;
        player.pan = adjustPan(pan: pan)
        player.volume = 0.5
        player.prepareToPlay()
    }
    
    func play() {
        player.play()
    }
}

struct Bullet {
    let player : AVAudioPlayer
    
    init(pan: Double, avPlayer: AVAudioPlayer) {
        player = avPlayer;
        player.pan = adjustPan(pan: pan)
        player.volume = 0.4
        player.prepareToPlay()
    }
    func play() {
        player.play()
    }
}

enum SoundType: String {
    case shoot = "f";
    case explosion = "x";
}

struct SoundEvent : JSONDecodable {
    let size: Int?
    let pan: Double?
    let sound: SoundType?
    
    init?(json: JSON) {
        self.size = "size" <~~ json;
        self.pan = "pan" <~~ json;
        self.sound = "snd" <~~ json;
    }
}

func sumSoundEvents(_ soundEvents: [SoundEvent]) -> Int {
    var t = 0
    for e in soundEvents {
        switch e.sound {
        case .shoot?:
            t = t + 1
        case .explosion?:
            t = t + 5
        case .none:
            break;
        }
    }
    return t;
}

/*
 Apply the quadratic function y=x³
 This keeps the pan inside the range -1..1
 yet applies a bathtub curve to keep the sounds
 mostly in the centre of the soundscape.
 
 https://www.wolframalpha.com/input/?i=y%3Dx%5E3,+y%3D1,+y%3D-1
 */
func adjustPan(pan: Double) -> Float {
    if (pan < -1.0) {
        return 0.0;
    } else if (pan > 1.0) {
        return 0.0;
    } else {
        return Float(pan * pan * pan);
    }
}
