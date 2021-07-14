//
//  ViewController.swift
//  MyTVForIOS
//
//  Created by lvvi on 2020/3/3.
//  Copyright © 2020 lvvi. All rights reserved.
//

import UIKit

import AVKit
import AVFoundation

import MediaPlayer

import LeanCloud
import Lottie

class PlayerViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var channel: Channel?
    var channels = [Channel]()
    
    var currChannelURL: String?
    var currPlayingChannelURL: String?
    var currPosition = 0
    var currPlayingPosition = 0
    
    var delaySencond = TimeInterval(4)
    var delayTwoSenconds = TimeInterval(2)
    
    var isChangeVolume = false
    var currentVolume = CGFloat(0)
    var currentBrightness = CGFloat(0)
    
    var currentVolumeValue = Float(0)
    var currentBrightnessValue = Float(0)
    
    var lastValue = Float(0)
    var progressStep = CGFloat(0.01)
    
    public var player: AVPlayer?
    
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var picker: UIPickerView!
    @IBOutlet weak var preview: UIImageView!
    
    @IBOutlet weak var volumeAndBrightnessBackGround: RoundedCornerBackGround!
    @IBOutlet weak var volumeAndBrightnessIconView: UIView!
    @IBOutlet weak var volumeAndBrightnessProgress: UIProgressView!
    
    var animationView = AnimationView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let rect = CGRect(x: -100, y: 0, width: 0, height: 0)
        let volumeView = MPVolumeView(frame: rect)
        view.addSubview(volumeView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(resume), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(volumeDidChange), name: NSNotification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification"), object: nil)
        
        self.picker.delegate = self
        self.picker.dataSource = self
        
        view.isUserInteractionEnabled = true
        preview.isUserInteractionEnabled = true
        
        picker.frame.size.height = view.frame.size.height
        preview.center.y = view.center.y
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)
        
        volumeAndBrightnessBackGround.center.x = view.center.x
        
        animationView.frame = volumeAndBrightnessIconView.bounds
        animationView.contentMode = .scaleAspectFit
        
        volumeAndBrightnessIconView.addSubview(animationView)
        
        initPlayer()

        loadSavedData()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let locatioin = touch?.location(in: self.view)
        
        if locatioin!.x < self.view.frame.maxX / 2 {
            isChangeVolume = false
        } else {
            isChangeVolume = true
        }
    }
    
    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: sender.view)

        var beganY = CGFloat(0)
        
        switch sender.state {
        case .began:
            if isChangeVolume {
                currentVolume = CGFloat(AVAudioSession.sharedInstance().outputVolume)
                
                volumeAndBrightnessProgress.progress = Float(currentVolume)
                currentVolumeValue = volumeAndBrightnessProgress.progress
                
                animationView.animation = Animation.named("player_volume_icon_progress_lottie")
                animationView.currentProgress = AnimationProgressTime(currentVolumeValue)
            } else {
                currentBrightness = UIScreen.main.brightness

                volumeAndBrightnessProgress.progress = Float(currentBrightness)
                currentBrightnessValue = volumeAndBrightnessProgress.progress
                
                animationView.animation = Animation.named("player_brightness_icon_lottie")
                animationView.currentProgress = AnimationProgressTime(currentBrightnessValue)
            }
            beganY = translation.y
            
            volumeAndBrightnessBackGround.isHidden = false
            self.view.bringSubviewToFront(volumeAndBrightnessBackGround)
            break
        case .changed:
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideVolumeAndBrightnessBackground), object: nil)
            
            let value = Float(translation.y - beganY)
            
            if isChangeVolume {
                currentVolume = getProgressValue(value: value)
                
                if AVAudioSession.sharedInstance().outputVolume == Float(currentVolume) {
                    return
                }
                
                MPVolumeView.setVolume(Float(currentVolume))
                
                volumeAndBrightnessProgress.progress = Float(currentVolume)
                
                animationView.play(fromProgress: AnimationProgressTime(currentVolumeValue), toProgress: AnimationProgressTime(volumeAndBrightnessProgress.progress), loopMode: .none, completion: nil)
                currentVolumeValue = volumeAndBrightnessProgress.progress
            } else {
                currentBrightness = getProgressValue(value: value)
                
                if UIScreen.main.brightness == currentBrightness {
                    return
                }
                
                UIScreen.main.brightness = (currentBrightness)
                
                volumeAndBrightnessProgress.progress = Float(currentBrightness)
                
                animationView.play(fromProgress: AnimationProgressTime(currentBrightnessValue), toProgress: AnimationProgressTime(volumeAndBrightnessProgress.progress), loopMode: .none, completion: nil)
                currentBrightnessValue = volumeAndBrightnessProgress.progress
            }
            
            lastValue = value
            break
        case .ended:
            lastValue = Float(0)
            perform(#selector(hideVolumeAndBrightnessBackground), with: nil, afterDelay: delayTwoSenconds)
            break
        default:
            break
        }
    }
    
    private func getProgressValue (value: Float) -> CGFloat {
        var currentValue = CGFloat(0)
        
        if isChangeVolume {
            currentValue = currentVolume
        } else {
            currentValue = currentBrightness
        }
        
        if lastValue == 0 {
            if value > 0 {
                currentValue -= progressStep
            } else {
                currentValue += progressStep
            }
        } else {
            if lastValue - value < 0 {
                currentValue -= progressStep
            } else {
                currentValue += progressStep
            }
        }
        
        if currentValue < 0 {
            currentValue = 0
        } else if currentValue > 1 {
            currentValue = 1
        }
        
        return currentValue
    }
    
    @objc private func hideVolumeAndBrightnessBackground() {
        volumeAndBrightnessBackGround.isHidden = true
        self.view.sendSubviewToBack(volumeAndBrightnessBackGround)
    }
    
    private func initPlayer() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        } catch {
            print("Setting category to AVAudioSessionCategoryPlayBack failed.")
        }
        
        player = AVPlayer()
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.view.bounds
        self.view.layer.addSublayer(playerLayer)
    }
    
    private func loadSavedData() {
        if let savedChannels = Channel.loadChannels() {
            channels += savedChannels
        } else {
            print("Load channels failed.")
            return
        }
        
        self.picker.reloadAllComponents()
        
        let savedPlayingURL = Channel.loadPlayingURL()
        
        var isPlaying = false
        
        for (index, channel) in channels.enumerated() {
            if savedPlayingURL == channel.url {
                isPlaying = true
                
                currPlayingChannelURL = channel.url
                currPlayingPosition = index
                self.picker.selectRow(currPlayingPosition, inComponent: 0, animated: false)
                
                play()
            }
        }
        
        if !isPlaying, channels.count > 0 {
            currPlayingChannelURL = channels[0].url
            currPlayingPosition = 0
            play()
        }
    }

    @IBAction func showMenu(_ sender: UITapGestureRecognizer) {
        if menuView.isHidden {
            menuView.isHidden = false
            
            self.view.bringSubviewToFront(menuView)
            
            preview.image = nil
            
            perform(#selector(hideMenu), with: nil, afterDelay: delaySencond)
        } else {
            hideMenu()
        }
    }
    
    @objc private func hideMenu() {
        menuView.isHidden = true
        preview.isHidden = true
        self.view.sendSubviewToBack(menuView)
        
        if picker.selectedRow(inComponent: 0) != currPlayingPosition {
            self.picker.selectRow(currPlayingPosition, inComponent: 0, animated: false)
        }
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideMenu), object: nil)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return channels.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return channels[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if !channels[row].icon.isEmpty {
            preview.downloaded(from: channels[row].icon)
            preview.isHidden = false
        }
        
        currChannelURL = channels[row].url
        currPosition = row
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideMenu), object: nil)
        perform(#selector(hideMenu), with: nil, afterDelay: delaySencond)
    }
    
    @IBAction func playSelectedChannel(_ sender: Any) {
        if currPlayingChannelURL != currChannelURL {
            currPlayingChannelURL = currChannelURL
            currPlayingPosition = currPosition
            
            play()
            
            Channel.savePlayingURL(playingURL: currPlayingChannelURL!)
        }
        
        menuView.isHidden = true
        
        self.view.sendSubviewToBack(menuView)
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideMenu), object: nil)
    }
    
    @objc private func play() {
        guard let url = URL(string: currPlayingChannelURL!) else {
            return
        }
        
        player?.replaceCurrentItem(with: AVPlayerItem(url: url))
        
        player?.play()
    }
    
    @objc private func resume() {
        player?.play()
    }
    
    @objc func volumeDidChange(notification: NSNotification) {
        if menuView.isHidden {
            let volumeType = notification.userInfo!["AVSystemController_AudioVolumeChangeReasonNotificationParameter"] as! String
            
            if volumeType.isEqual("ExplicitVolumeChange") {
                let volume = notification.userInfo!["AVSystemController_AudioVolumeNotificationParameter"] as! Float
                showVolumeProgress(currentVolume: volume)
            }
        }
    }
    
    func showVolumeProgress(currentVolume: Float) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hideVolumeAndBrightnessBackground), object: nil)
        
        volumeAndBrightnessProgress.progress = Float(currentVolume)
        currentVolumeValue = volumeAndBrightnessProgress.progress
        
        animationView.animation = Animation.named("player_volume_icon_progress_lottie")
        animationView.currentProgress = AnimationProgressTime(currentVolumeValue)
        
        volumeAndBrightnessBackGround.isHidden = false
        self.view.bringSubviewToFront(volumeAndBrightnessBackGround)
        
        perform(#selector(hideVolumeAndBrightnessBackground), with: nil, afterDelay: delayTwoSenconds)
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}

extension UIImageView {
    func downloaded(from url: URL, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        contentMode = mode
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        
        let session = URLSession.init(configuration: config)
        
        session.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() {
                self.image = image
            }
        }.resume()
    }
    func downloaded(from link: String, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloaded(from: url, contentMode: mode)
    }
}

extension MPVolumeView {
  static func setVolume(_ volume: Float) {
    let volumeView = MPVolumeView()
    let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider

    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
      slider?.value = volume
    }
  }
}


