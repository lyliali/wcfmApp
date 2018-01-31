//
//  ViewController.swift
//  wcfmApp
//
//  Created by williams user on 1/5/18.
//  Copyright © 2018 williams user. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import MediaPlayer

class ViewController: UIViewController {
    
    private var playerHasBeenInitialized = false
    private var audioSessionHasBeenActivated = false
    
    let audioSession = AVAudioSession.sharedInstance()
    let commandCenter = MPRemoteCommandCenter.shared()
    let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    let notificationCenter = NotificationCenter.default
    
    private var player : RadioPlayer?
    
    @IBOutlet weak var playButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if !playerHasBeenInitialized {
            player = RadioPlayer(dependencies: (audioSession, commandCenter, nowPlayingInfoCenter, notificationCenter, self))
        }
        
        registerForNotifications()
        configureCommandCenter()
        setUpNowPlayingInfoCenter()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func activateAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Configure audio session category, options, and mode
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            // Activate audio session to enable custom configuration
            try audioSession.setActive(true)
        } catch let error as NSError {
            print("Unable to activate audio session: \(error.localizedDescription)")
        }
    }
    
    private func doPlayAction() {
        player!.play()
        playButton.setImage(UIImage(named:"pause_button copy_r.png"), for:UIControlState.normal)
    }
    
    private func doPauseAction() {
        player!.pause()
        playButton.setImage(UIImage(named:"play_button copy_r.png"), for:UIControlState.normal)
    }
    
    @IBAction func playPauseButton(_ sender: AnyObject) {
        if player!.currentlyPlaying() {
            doPauseAction()
        } else {
            doPlayAction()
        }
    }
    
    private func doReset() {
        player!.reset()
        doPlayAction()
    }
    
    // TODO: rename to resetButton
    @IBAction func resetPlayer(_ sender: AnyObject) {
        doReset()
    }
    
    /*
     TODO: Try to refactor code into AppDelegate?
     */
    // Register to observe notifications in order to handle audio interruptions / route changes
    func registerForNotifications() {
        
        notificationCenter.addObserver(self,
                                       selector: #selector(handleInterruption),
                                       name: .AVAudioSessionInterruption,
                                       object: AVAudioSession.sharedInstance())
        
        notificationCenter.addObserver(self,
                                       selector: #selector(handleMediaServerReset),
                                       name: .AVAudioSessionMediaServicesWereReset,
                                       object: AVAudioSession.sharedInstance())
        
        notificationCenter.addObserver(self,
                                       selector: #selector(handleRouteChange),
                                       name: .AVAudioSessionRouteChange,
                                       object: AVAudioSession.sharedInstance())
    }
    
    @objc func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSessionInterruptionType(rawValue: typeValue) else {
                return
        }
        if type == .began {
            // Interruption began, take appropriate actions (save state, update user interface)
            doPauseAction()
        }
        else if type == .ended {
            guard let optionsValue =
                info[AVAudioSessionInterruptionOptionKey] as? UInt else {
                    return
            }
            let options = AVAudioSessionInterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                // Interruption Ended - playback should resume
                doPlayAction()
            }
        }
    }
    
    @objc func handleMediaServerReset(_ notification: Notification) {
        // Dispose of orphaned audio objects (such as players, recorders, converters, or audio queues) and create new ones
        player!.reset()
        // Reset any internal audio states being tracked, including all properties of AVAudioSession
        if player!.currentlyPlaying() {
            doPauseAction()
        }
        // When appropriate, reactivate the AVAudioSession instance using the setActive:error: method
        activateAudioSession()
    }
    
    
    @objc func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSessionRouteChangeReason(rawValue:reasonValue) else {
                return
        }
        switch reason {
        /*case .newDeviceAvailable:
            let session = AVAudioSession.sharedInstance()
            for output in session.currentRoute.outputs where output.portType == AVAudioSessionPortHeadphones {
                headphonesConnected = true
            }*/
            
        case .oldDeviceUnavailable:
            doPauseAction()
            /*if let previousRoute =
                userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                for output in previousRoute.outputs where output.portType == AVAudioSessionPortHeadphones {
                    headphonesConnected = false
                }
            }*/
        default: ()
        }
    }
    
    // COMMAND CENTER
    private func configureCommandCenter() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        self.commandCenter.playCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.doPlayAction()
            return .success
        })
        
        self.commandCenter.pauseCommand.addTarget (handler: { [weak self] event -> MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.doPauseAction()
            return .success
        })
        
        self.commandCenter.nextTrackCommand.addTarget (handler: { [weak self] event ->
            MPRemoteCommandHandlerStatus in
            guard let sself = self else { return .commandFailed }
            sself.doReset()
            return .success
        })
        
        self.commandCenter.previousTrackCommand.isEnabled = false
    }
    
    private func setUpNowPlayingInfoCenter(artwork: UIImage? = nil) {
        /* TODO:
         - add album artwork (should just be a WCFM graphic)
         - consider trying to retrieve the real metadata for the songs currently streaming
         - replace album / artist title fields with information about who is currently on air?
         */
        nowPlayingInfoCenter.nowPlayingInfo = [
            MPMediaItemPropertyTitle: "wcfm stream",
            MPMediaItemPropertyAlbumTitle: "album title",
            MPMediaItemPropertyArtist: "artist name",
            MPMediaItemPropertyPlaybackDuration: 0.0
        ]
        
    }

}
