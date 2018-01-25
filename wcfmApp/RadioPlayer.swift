//
//  RadioPlayer.swift
//  wcfmApp
//
//  Created by williams user on 1/9/18.
//  Copyright © 2018 williams user. All rights reserved.
//
// https://stackoverflow.com/questions/32614060/avplayer-audio-buffering-from-live-stream
// https://github.com/lukagabric/LGAudioPlayerLockScreen

import Foundation
import AVFoundation
import MediaPlayer
import AVKit
import UIKit

protocol errorMessageDelegate {
    func errorMessageChanged(newVal: String)
}

protocol sharedInstanceDelegate {
    func sharedInstanceChanged(newVal: Bool)
}

class RadioPlayer : NSObject {
    
    private var myPlayer = AVPlayer(url: URL(string: "http://137.165.206.193:8000/stream")!)
    private var isPlaying = false
    
    var errorDelegate:errorMessageDelegate? = nil
    var errorMessage = "" {
        didSet {
            if let delegate = self.errorDelegate {
                delegate.errorMessageChanged(newVal: self.errorMessage)
            }
        }
    }
    
    // DEPENDENCIES
    let audioSession: AVAudioSession
    let commandCenter: MPRemoteCommandCenter
    let nowPlayingInfoCenter: MPNowPlayingInfoCenter
    let notificationCenter: NotificationCenter
    let vc: UIViewController
    
    typealias RadioPlayerDependencies = (audioSession: AVAudioSession, commandCenter: MPRemoteCommandCenter, nowPlayingInfoCenter: MPNowPlayingInfoCenter, notificationCenter: NotificationCenter, viewController: UIViewController)
    
    init(dependencies: RadioPlayerDependencies) {
        self.audioSession = dependencies.audioSession
        self.commandCenter = dependencies.commandCenter
        self.nowPlayingInfoCenter = dependencies.nowPlayingInfoCenter
        self.notificationCenter = dependencies.notificationCenter
        self.vc = dependencies.viewController
        
        super.init()
        
        try! self.audioSession.setCategory(AVAudioSessionCategoryPlayback)
        try! self.audioSession.setActive(true)
        
        //self.configureCommandCenter()
        //self.setUpNowPlayingInfoCenter()
    }
    
    func play() {
        myPlayer.play()
        isPlaying = true
    }
    
    func pause() {
        myPlayer.pause()
        isPlaying = false
    }
    
    func currentlyPlaying() -> Bool {
        return isPlaying
    }
    
    func reset() {
        self.myPlayer = AVPlayer(url: URL(string: "http://137.165.206.193:8000/stream")!)
    }
    
}
