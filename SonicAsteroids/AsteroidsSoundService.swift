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

typealias Payload = [String: AnyObject]

class AsteroidsSoundService: NSObject {
    static let INSTANCE = AsteroidsSoundService()
    
    var engine : AVAudioEngine
    var playerAtmos: AVAudioPlayerNode!
    var playerBass: AVAudioPlayerNode!
    var playerAction: AVAudioPlayerNode!
    
    
    var bullet: AVAudioPlayer?
    var explosion: AVAudioPlayer?
    
    var bulletData: NSData?
    var explosionData: NSData?
    
    var playing : Bool = false
    
    var seenBullets : [Int: Bullet]
    var seenExplosions : [Explosion]
    
    override init() {
        engine = AVAudioEngine()
        playerAtmos = AVAudioPlayerNode()
        playerBass = AVAudioPlayerNode()
        playerAction = AVAudioPlayerNode()
        playerAtmos.volume = 0.8
        playerBass.volume = 0.4
        playerAction.volume = 1.0
        
        
        bulletData = NSData(contentsOfURL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("Velocity Zapper_bip1", ofType: "mp3")!))
        explosionData = NSData(contentsOfURL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("5", ofType: "mp3")!))
        
        bullet = AsteroidsSoundService.setupAudioPlayerWithFile("Velocity Zapper_bip1", type: "mp3")
        explosion = AsteroidsSoundService.setupAudioPlayerWithFile("5", type: "mp3")
        
        seenBullets = [Int: Bullet]()
        seenExplosions = [Explosion]()
    }
    
    static func setupAudioPlayerWithFile(file:NSString, type:NSString) -> AVAudioPlayer?  {
        let path = NSBundle.mainBundle().pathForResource(file as String, ofType: type as String)
        let url = NSURL.fileURLWithPath(path!)
        
        var audioPlayer :AVAudioPlayer?
        
        do {
            try audioPlayer = AVAudioPlayer(contentsOfURL: url)
        } catch {
            print("Player not available")
        }
        
        return audioPlayer
    }

    
    func start(path: String) {
        guard !playing else {
            print("Already playing...")
            return
        }
        
        let atmosUrl = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource("Mars-atmos", ofType: "mp3")!)
        let bassUrl = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource("Mars-bass", ofType: "mp3")!)
        let actionUrl = NSURL.fileURLWithPath(NSBundle.mainBundle().pathForResource("Mars-action", ofType: "mp3")!)
        do {
            let atmosFile = try AVAudioFile(forReading: atmosUrl)
            let atmosBuffer = AVAudioPCMBuffer(PCMFormat: atmosFile.processingFormat, frameCapacity: AVAudioFrameCount(atmosFile.length))
            try atmosFile.readIntoBuffer(atmosBuffer)
            
            let bassFile = try AVAudioFile(forReading: bassUrl)
            let bassBuffer = AVAudioPCMBuffer(PCMFormat: bassFile.processingFormat, frameCapacity: AVAudioFrameCount(bassFile.length))
            try bassFile.readIntoBuffer(bassBuffer)
            
            let actionFile = try AVAudioFile(forReading: actionUrl)
            let actionBuffer = AVAudioPCMBuffer(PCMFormat: actionFile.processingFormat, frameCapacity: AVAudioFrameCount(actionFile.length))
            try actionFile.readIntoBuffer(actionBuffer)
            
            
            engine.attachNode(playerAtmos)
            engine.attachNode(playerBass)
            engine.attachNode(playerAction)

            
            engine.connect(playerAtmos, to: engine.mainMixerNode, format: atmosBuffer.format)
            engine.connect(playerBass, to: engine.mainMixerNode, format: bassBuffer.format)
            engine.connect(playerAction, to: engine.mainMixerNode, format: actionBuffer.format)
            // Schedule playerAtmos and playerBass to play the buffer on a loop
            playerAtmos.scheduleBuffer(atmosBuffer, atTime: nil, options: AVAudioPlayerNodeBufferOptions.Loops, completionHandler: nil)
            playerBass.scheduleBuffer(bassBuffer, atTime: nil, options: AVAudioPlayerNodeBufferOptions.Loops, completionHandler: nil)
            playerAction.scheduleBuffer(actionBuffer, atTime: nil, options: AVAudioPlayerNodeBufferOptions.Loops, completionHandler: nil)

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
    
    func processSound(withText: String) {
//        print("Making noise with this: \(withText)")
        
        var json : Payload!
        
        do {
            json = try NSJSONSerialization.JSONObjectWithData(withText.dataUsingEncoding(NSUTF8StringEncoding)!, options: NSJSONReadingOptions()) as? Payload
        } catch {
            print(error)
            return
        }
        
        guard let bullets = json["b"] as? [[Int]] else {
            print("Couldn't deserialise bullets")
            return
        }
        
        guard let explosions = json["x"] as? [[Int]] else {
            print("Couldn't deserialise explosions")
            return
        }

        print("I see \(bullets.count) bullets and \(explosions.count) explosions");
        
        for bullet in bullets {
            makeBulletNoise(bullet)
        }
        
        for explosion in explosions {
            makeExplosionNoise(explosion)
        }
        
        playExplosionSound()
    }
    
    func makeBulletNoise(bulletInfo : [Int]) {
        guard(seenBullets[bulletInfo[0]] == nil) else {
            print("I've already seen bullet \(bulletInfo[0]), not making a noise")
            return
        }
        let bullet = Bullet(atX: bulletInfo[1], atY: bulletInfo[2])
        seenBullets[bulletInfo[0]] = bullet
        print("I'm making a noise for bullet \(bulletInfo[0])")
        bullet.play()
    }
    
    func makeExplosionNoise(explosionInfo : [Int]) {
        let explosion = Explosion(atX: explosionInfo[0], atY: explosionInfo[1])
        seenExplosions.append(explosion)
        explosion.play()
    }
}

struct Explosion {
    let x : Int
    let y : Int
    let player : AVAudioPlayer?
    
    init(atX: Int, atY: Int) {
        x = atX
        y = atY
        player = AsteroidsSoundService.setupAudioPlayerWithFile("5", type: "mp3")
        player!.volume = 0.3
        player!.prepareToPlay()
    }
    
    func play() {
        player!.play()
    }
}

struct Bullet {
    let x : Int?
    let y : Int?
    let player : AVAudioPlayer?
    
    init(atX: Int, atY: Int) {
        x = atX
        y = atY
        player = AsteroidsSoundService.setupAudioPlayerWithFile("Velocity Zapper_bip1", type: "mp3")
        player!.prepareToPlay()
    }
    func play() {
        player!.play()
    }

}
