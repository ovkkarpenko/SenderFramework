//
// Created by Roman Serga on 26/9/17.
// Copyright (c) 2017 Middleware Inc. All rights reserved.
//

import Foundation

let MessageViewUpdateAudioMessageInfo = "MessageViewUpdateAudioMessageInfo"

extension MessageViewAction {
    static var playAudio: MessageViewAction {
        return MessageViewAction(name: "playAudio")
    }

    static var pauseAudio: MessageViewAction {
        return MessageViewAction(name: "pauseAudio")
    }
}

import UIKit

class WavePatternProgressView: UIView {

    private let progressView = UIView()

    var progressTintColor: UIColor = .blue {
        didSet {
            self.progressView.backgroundColor = self.progressTintColor
        }
    }

    var progress: Float = 0.5 {
        didSet {
            self.fixProgressViewFrame()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUp()
        self.progressView.backgroundColor = self.progressTintColor
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUp()
    }

    func setUp() {
        self.addSubview(self.progressView)
    }

    var wavePatternImage: UIImage? {
        didSet {
            let mask = UIImageView(image: self.wavePatternImage)
            self.mask = mask
            self.setNeedsLayout()
        }
    }

    func fixProgressViewFrame() {
        let progressViewWidth: CGFloat
        switch self.progress {
            case (-Float.infinity)...0: progressViewWidth = 0.0
            case 0..<1: progressViewWidth = CGFloat(self.progress) * self.frame.width
            default: progressViewWidth = 1.0
        }
        self.progressView.frame = CGRect(x: 0.0, y: 0.0, width: progressViewWidth, height: self.frame.height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.mask?.frame = CGRect(origin: .zero, size: self.frame.size)
        self.fixProgressViewFrame()
    }
}

class AudioMessageViewLayout: MessageWithTimeLayout {}

class AudioMessageView: MessageView {
    static let durationLabelFont: UIFont = UIFont.systemFont(ofSize: 12.0)
    static let timeLabelFont: UIFont = UIFont.systemFont(ofSize: 12.0)

    static let playButtonSide: CGFloat = 29.0

    static let durationLabelWidth: CGFloat = 36.0
    static let durationLabelHeight: CGFloat = 14.0

    static let playButtonLeading: CGFloat = 4.0
    static let playButtonTrailing: CGFloat = 4.0
    static let durationToPlayButtonLeading: CGFloat = 8.0
    static let wavePatternToDurationLeading: CGFloat = 8.0
    static let timeLabelToWavePatternLeading: CGFloat = 8.0
    static let timeLabelTrailing: CGFloat = 12.0
    static let timeLabelBottom: CGFloat = 8.0

    static let wavePatternHeight: CGFloat = 29.0
    static let wavePatternWidth: CGFloat = 74.0

    static let progressBackgroundColor = UIColor(red: 144.0 / 255.0,
                                                 green: 164.0 / 255.0,
                                                 blue: 174.0 / 255.0,
                                                 alpha: 1.0)
    static let progressColor = UIColor(red: 102.0 / 255.0, green: 102.0 / 255.0, blue: 204.0 / 255.0, alpha: 1.0)

    let playButton: UIButton = {
        let playButton = UIButton()
        playButton.setImage(UIImage(fromSenderFrameworkNamed: "icPlayAudio"), for: .normal)
        playButton.tintColor = SenderCore.shared().stylePalette.mainAccentColor
        return playButton
    }()

    let durationLabel: UILabel = {
        let durationLabel = UILabel()
        durationLabel.textColor = SenderCore.shared().stylePalette.messageDetailsColor
        durationLabel.textAlignment = .center
        return durationLabel
    }()

    let timeLabel: UILabel = {
        let timeLabel = UILabel()
        timeLabel.textColor = SenderCore.shared().stylePalette.messageDetailsColor
        timeLabel.textAlignment = .center
        return timeLabel
    }()

    let wavePattern: WavePatternProgressView = {
        let wavePattern = WavePatternProgressView()
        wavePattern.wavePatternImage = UIImage(fromSenderFrameworkNamed: "ic-voice")
        wavePattern.backgroundColor = AudioMessageView.progressBackgroundColor
        wavePattern.progressTintColor = AudioMessageView.progressColor
        return wavePattern
    }()

    var isPlayingAudio = false {
        didSet {
            let imageName = self.isPlayingAudio ? "icPauseAudio" : "icPlayAudio"
            playButton.setImage(UIImage(fromSenderFrameworkNamed: imageName), for: .normal)
        }
    }

    var isLoadingAudio = false {
        didSet {
            guard self.isLoadingAudio != oldValue else { return }
            if self.isLoadingAudio {
                let frames = (1...12).flatMap { UIImage(fromSenderFrameworkNamed: "icFilePreloader" + String($0)) }
                let activityIndicator = UIImage.animatedImage(with: frames, duration: 0.8)
                self.playButton.setImage(activityIndicator, for: .normal)
            } else {
                self.playButton.setImage(UIImage(fromSenderFrameworkNamed: "icPlayAudio"), for: .normal)
            }
            self.setNeedsLayout()
        }
    }

    override func setUp() {
        super.setUp()
        self.layer.borderWidth = 1.0
        self.durationLabel.font = type(of: self).durationLabelFont
        self.timeLabel.font = type(of: self).timeLabelFont
        self.addSubview(self.durationLabel)
        self.addSubview(self.timeLabel)
        self.addSubview(self.wavePattern)
        self.addSubview(self.playButton)
        self.playButton.addTarget(self, action: #selector(self.performAction), for: .touchUpInside)
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
        self.layer.masksToBounds = false
    }

    static func layoutWith(audioMessage: AudioMessageViewModel, maxWidth: CGFloat) -> AudioMessageViewLayout {
        let viewHeight: CGFloat = 36.0
        let elementsWidth = self.playButtonLeading + self.playButtonSide + self.durationToPlayButtonLeading +
                self.durationLabelWidth + self.wavePatternToDurationLeading + self.wavePatternWidth +
                self.timeLabelToWavePatternLeading + self.timeLabelTrailing
        let maxTimeWidth = maxWidth - elementsWidth
        let attributedTimeLabelText = NSAttributedString(string: audioMessage.creationTimeDescription ?? "",
                                                         attributes: [.font: self.timeLabelFont])
        let sizeCalculateOptions = [.usesLineFragmentOrigin, .usesFontLeading] as NSStringDrawingOptions
        let maxTimeLabelSize = CGSize(width: maxTimeWidth, height: viewHeight)
        let timeLabelSize = attributedTimeLabelText.boundingRect(with: maxTimeLabelSize,
                                                                 options: sizeCalculateOptions,
                                                                 context: nil).mw_rounded().size
        let viewWidth = timeLabelSize.width + elementsWidth
        return AudioMessageViewLayout(size: CGSize(width: viewWidth, height: viewHeight),
                                      timeIndicatorSize: timeLabelSize)
    }

    func updateWith(audioMessage: AudioMessageViewModel,
                    maxWidth: CGFloat,
                    layout: AudioMessageViewLayout? = nil) -> AudioMessageViewLayout {
        self.setMessageViewColorsWith(message: audioMessage)
        self.timeLabel.text = audioMessage.creationTimeDescription
        self.durationLabel.text = "--:--"
        audioMessage.getDuration { durationDescription in
            DispatchQueue.main.async { self.durationLabel.text = durationDescription }
        }
        self.isLoadingAudio = audioMessage.isLoadingMedia

        let layout = layout ?? type(of: self).layoutWith(audioMessage: audioMessage,
                                                         maxWidth: maxWidth)
        self.frame = CGRect(origin: self.frame.origin, size: layout.size)
        self.timeLabel.frame = CGRect(origin: self.timeLabel.frame.origin, size: layout.timeIndicatorSize)
        self.setNeedsLayout()
        return layout
    }

    func setMessageViewColorsWith(message: MessageViewModel) {
        let ownerMessageColor: UIColor
        let foreignMessageColor: UIColor
        let ownerBorderColor: UIColor
        let foreignBorderColor: UIColor

        if message.isEncrypted {
            ownerMessageColor = SenderCore.shared().stylePalette.encryptedOwnerMessageBackgroundColor
            foreignMessageColor = SenderCore.shared().stylePalette.encryptedMessageBackgroundColor
            ownerBorderColor = ownerMessageColor
            foreignBorderColor = SenderCore.shared().stylePalette.foreignEncryptedMessageBorderColor
        } else {
            ownerMessageColor = SenderCore.shared().stylePalette.myMessageBackgroundColor
            foreignMessageColor = SenderCore.shared().stylePalette.foreignMessageBackgroundColor
            ownerBorderColor = ownerMessageColor
            foreignBorderColor = SenderCore.shared().stylePalette.foreignMessageBorderColor
        }

        self.setNewBackgroundColor(message.author == .owner ? ownerMessageColor : foreignMessageColor)
        self.layer.borderColor = (message.author == .owner ? ownerBorderColor : foreignBorderColor).cgColor

        self.wavePattern.progress = 0.0
    }

    func setNewBackgroundColor(_ newBackgroundColor: UIColor) {
        self.backgroundColor = newBackgroundColor
        self.timeLabel.backgroundColor = newBackgroundColor
        self.durationLabel.backgroundColor = newBackgroundColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.height / 2

        self.playButton.frame = self.bounds
        self.playButton.contentHorizontalAlignment = .left
        self.playButton.frame = CGRect(x: type(of: self).playButtonLeading,
                                       y: (self.frame.height - type(of: self).playButtonSide) / 2,
                                       width: self.frame.width - type(of: self).playButtonTrailing,
                                       height: type(of: self).playButtonSide)

        let playLabelImageMaxX = (self.playButton.imageView?.frame.maxX ?? CGFloat(0.0))

        let durationLabelX = self.playButton.frame.origin.x + playLabelImageMaxX +
                type(of: self).durationToPlayButtonLeading
        self.durationLabel.frame = CGRect(x: durationLabelX,
                                          y: (self.frame.height - type(of: self).durationLabelHeight) / 2,
                                          width: type(of: self).durationLabelWidth,
                                          height: type(of: self).durationLabelHeight)

        let wavePatternFrame = CGRect(x: self.durationLabel.frame.maxX + type(of: self).wavePatternToDurationLeading,
                                      y: (self.frame.height - type(of: self).wavePatternHeight) / 2,
                                      width: type(of: self).wavePatternWidth,
                                      height: type(of: self).wavePatternHeight)
        self.wavePattern.frame = wavePatternFrame

        let timeLabelY = self.frame.height - self.timeLabel.frame.height - type(of: self).timeLabelBottom
        let timeLabelOrigin = CGPoint(x: self.wavePattern.frame.maxX + type(of: self).timeLabelToWavePatternLeading,
                                      y: timeLabelY)
        self.timeLabel.frame = CGRect(origin: timeLabelOrigin, size: self.timeLabel.frame.size)
    }

    @objc open func performAction() {
        let canPerformAction: Bool

        let actionToPerform: MessageViewAction = self.isPlayingAudio ? .pauseAudio : .playAudio

        if let actionsHandler = self.actionsHandler {
            canPerformAction = actionsHandler.messageView(self, canPerformAction: actionToPerform)
        } else {
            canPerformAction = true
        }

        if canPerformAction { self.actionsHandler?.messageView(self, didSelectAction: actionToPerform) }
    }

    @objc(handleUpdate:)
    override func handleUpdate(_ messageViewUpdate: MessageViewUpdate!) {
        super.handleUpdate(_: messageViewUpdate)
        guard messageViewUpdate.name == MessageViewUpdateAudioMessageInfo else { return }
        if let progress = messageViewUpdate.userInfo?["progress"] as? Double {
            self.wavePattern.progress = Float(progress)
        }
        if let newIsPlayingValue = messageViewUpdate.userInfo?["isPlaying"] as? Bool {
            self.isPlayingAudio = newIsPlayingValue
        }
    }
}
