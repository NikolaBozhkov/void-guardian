//
//  AudioManager.swift
//  ZoeSlasher
//
//  Created by Nikola Bozhkov on 10.12.20.
//  Copyright © 2020 Nikola Bozhkov. All rights reserved.
//

import AVFoundation
import SpriteKit

class SoundEffect {
    
    private let action: SKAction
    
    init(fileNamed fileName: String) {
        action = SKAction.playSoundFileNamed(fileName, waitForCompletion: false)
    }
    
    func play() {
        guard !AudioManager.shared.isMuted else { return }
        AudioManager.shared.skScene?.run(action)
    }
}

class AudioManager {
    static let shared = AudioManager()
    
    let playerMove = SoundEffect(fileNamed: "player-move.wav")
    let playerAttack = SoundEffect(fileNamed: "player-attack.wav")
    let enemyImpact = SoundEffect(fileNamed: "enemy-impact.wav")
    let enemyDeathImpact = SoundEffect(fileNamed: "enemy-death-impact.wav")
    let powerUpPickup = SoundEffect(fileNamed: "power-up.wav")
    let enemyAttack = SoundEffect(fileNamed: "enemy-shot.wav")
    let menuClick = SoundEffect(fileNamed: "menu-click.wav")
    let potionPickup = SoundEffect(fileNamed: "potion.wav")
    let playerHit = SoundEffect(fileNamed: "player-hit.wav")
    let gameOver = SoundEffect(fileNamed: "game-over.wav")
    let stageComplete = SoundEffect(fileNamed: "stage-complete.wav")
    
    let heartbeatLoop: AVAudioPlayer?
    
    var skScene: SKScene?
    
    var isMuted = false {
        didSet {
            bgLoopPlayers[0]?.volume = isMuted ? 0.0 : 1.0
            ProgressManager.shared.isMuted = isMuted
        }
    }
    
    private(set) var bgLoopPlayers = [AVAudioPlayer?]()
    
    private let transitionDurationRange: Range<Float> = 14..<15
    private let loopDurationRange: Range<Float> = 29..<30
    
    private var currentLoopDuration: Float = 0
    private var currentTransitionDuration: Float = 0
    private var currentTime: Float = 0
    
    private var currentLoopIndex = 0
    private var nextLoopIndex = 0
    
    private var playModeOn = false
    
    private init() {
        for i in 1...6 {
            let player = AudioManager.loadPlayer(fileName: "bg-loop-\(i)", isLooping: true)
            bgLoopPlayers.append(player)
        }
        
        heartbeatLoop = AudioManager.loadPlayer(fileName: "heartbeat", isLooping: true)
        heartbeatLoop?.volume = 0
        heartbeatLoop?.play()
        
        isMuted = ProgressManager.shared.isMuted
    }
    
    private static func loadPlayer(fileName: String, isLooping: Bool, type: String = "mp3") -> AVAudioPlayer? {
        guard let path = Bundle.main.path(forResource: fileName, ofType: type) else {
            assert(false, "Path for \(fileName) could not be found in the main bundle")
            return nil
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = isLooping ? -1 : 0
            return player
        } catch {
            assert(false, "\(error.localizedDescription)")
            return nil
        }
    }
    
    func startBackgroundLoops() {
        guard let currentTime = bgLoopPlayers[0]?.deviceCurrentTime else {
            return
        }
        
        for i in 0..<bgLoopPlayers.count {
            bgLoopPlayers[i]?.play(atTime: currentTime + 0.01)
            
            if i != 0 || isMuted {
                bgLoopPlayers[i]?.volume = 0
            }
        }
    }
    
    func enterPlayMode() {
        guard !isMuted else { return }
        
        playModeOn = true
        currentTransitionDuration = Float.random(in: transitionDurationRange)
        currentLoopDuration = 0
        currentTime = 0
        nextLoopIndex = Int.random(in: 1..<bgLoopPlayers.count)
    }
    
    func exitPlayMode() {
        guard !isMuted else { return }
        
        playModeOn = false
        bgLoopPlayers[currentLoopIndex]?.volume = 0
        bgLoopPlayers[nextLoopIndex]?.volume = 0
        bgLoopPlayers[0]?.volume = 1
        currentLoopIndex = 0
    }
    
    func muteBackgroundLoops() {
        bgLoopPlayers.forEach { $0?.volume = 0 }
    }
    
    func update(deltaTime: Float) {
        guard playModeOn, !isMuted else { return }
        
        currentTime += deltaTime
        
        if currentTime >= currentLoopDuration {
            var transitionProgress = (currentTime - currentLoopDuration) / currentTransitionDuration
            transitionProgress = simd_clamp(transitionProgress, 0, 1)
            
//            if transitionProgress <= 0.01 {
//                print("transitioning")
//            }
            
            bgLoopPlayers[currentLoopIndex]?.volume = 1.0 - transitionProgress
            bgLoopPlayers[nextLoopIndex]?.volume = transitionProgress
            
            if transitionProgress == 1 {
                currentTime = 0
                currentLoopDuration = Float.random(in: loopDurationRange)
                currentTransitionDuration = Float.random(in: transitionDurationRange)
                
                currentLoopIndex = nextLoopIndex
                
                let availableNextIndices = [Int](0..<bgLoopPlayers.count).filter { $0 != currentLoopIndex }
                nextLoopIndex = availableNextIndices.randomElement()!
                
//                print("current index: \(currentLoopIndex), next index: \(nextLoopIndex)")
            }
        }
    }
}
