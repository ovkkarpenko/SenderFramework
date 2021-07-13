//
// Created by Roman Serga on 27/9/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

//https://stackoverflow.com/a/41003985/6415245
final class WeakTimer {
    fileprivate weak var timer: Timer?
    fileprivate weak var target: AnyObject?
    fileprivate let action: (Timer) -> Void

    fileprivate init(timeInterval: TimeInterval,
                     target: AnyObject,
                     repeats: Bool,
                     action: @escaping (Timer) -> Void) {
        self.target = target
        self.action = action
        self.timer = Timer.scheduledTimer(timeInterval: timeInterval,
                                          target: self,
                                          selector: #selector(fire),
                                          userInfo: nil,
                                          repeats: repeats)
    }

    class func scheduledTimer(timeInterval: TimeInterval,
                              target: AnyObject,
                              repeats: Bool,
                              action: @escaping (Timer) -> Void) -> Timer {
        return WeakTimer(timeInterval: timeInterval,
                         target: target,
                         repeats: repeats,
                         action: action).timer!
    }

    @objc fileprivate func fire(timer: Timer) {
        if target != nil {
            action(timer)
        } else {
            timer.invalidate()
        }
    }
}

public extension NSNotification.Name {
    static var MWAudioPlayerProgressChanged: NSNotification.Name {
        return NSNotification.Name("MWAudioPlayerProgressChanged")
    }

    static var MWAudioPlayerWillPlay: NSNotification.Name {
        return NSNotification.Name("MWAudioPlayerWillPlay")
    }

    static var MWAudioPlayerDidPlay: NSNotification.Name {
        return NSNotification.Name("MWAudioPlayerDidPlay")
    }

    static var MWAudioPlayerDidPause: NSNotification.Name {
        return NSNotification.Name("MWAudioPlayerDidPause")
    }

    static var MWAudioPlayerDidStop: NSNotification.Name {
        return NSNotification.Name("MWAudioPlayerDidStop")
    }
}

class AudioPlayer: NSObject, AVAudioPlayerDelegate {

    public let audioPLayer: AVAudioPlayer
    var playbackProgressTimer: Timer?

    var url: URL? { return self.audioPLayer.url }
    var isPlaying: Bool { return self.audioPLayer.isPlaying }
    var duration: TimeInterval { return self.audioPLayer.duration }
    var currentTime: TimeInterval {
        get {
            return self.audioPLayer.currentTime
        }
        set {
            self.audioPLayer.currentTime = newValue
        }
    }

    init(url: URL) throws {
        self.audioPLayer = try AVAudioPlayer(contentsOf: url)
        self.audioPLayer.volume = 1.0
        super.init()
        self.audioPLayer.delegate = self

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(audioRecorderWillPerformAction(notification:)),
                                               name: Notification.Name(rawValue: AudioRecorderWillStartRecording),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(audioRecorderWillPerformAction(notification:)),
                                               name: Notification.Name(rawValue: AudioRecorderWillStartPlaying),
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func play() {
        NotificationCenter.default.post(name: .MWAudioPlayerWillPlay, object: self)
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        self.audioPLayer.play()
        self.startTimer()
        NotificationCenter.default.post(name: .MWAudioPlayerDidPlay, object: self)
    }

    func pause() {
        self.audioPLayer.pause()
        self.stopTimer()
        NotificationCenter.default.post(name: .MWAudioPlayerDidPause, object: self)
    }

    func stop() {
        self.audioPLayer.stop()
        self.stopTimer()
        NotificationCenter.default.post(name: .MWAudioPlayerDidStop, object: self)
    }

    func startTimer() {
        self.playbackProgressTimer = WeakTimer.scheduledTimer(timeInterval: 0.1,
                                                              target: self,
                                                              repeats: true) { [weak self] _ in
            self?.timerFired()
        }
    }

    func stopTimer() {
        self.playbackProgressTimer?.invalidate()
        self.playbackProgressTimer = nil
    }

    func timerFired() {
        NotificationCenter.default.post(name: .MWAudioPlayerProgressChanged, object: self)
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.stop()
    }

    @objc func audioRecorderWillPerformAction(notification: Notification) {
        self.stop()
    }
}

class AudioMessagePlayer: AudioPlayer {
    var playingMessage: Message

    init(messageToPlay: Message, audioURL: URL) throws {
        self.playingMessage = messageToPlay
        try super.init(url: audioURL)
    }
}
