//
//  ViewController.swift
//  RealtimeCaptioning
//
//  Created by An Tran on 08.05.19.
//  Copyright © 2019 An Tran. All rights reserved.
//

import UIKit
import Speech
import AVFoundation
import Foundation

class ViewController: UIViewController {

    @IBOutlet weak var captionLabel: UILabel!

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?


    private let playerLayer = AVPlayerLayer()
    
    private var vmInput: VideoMediaInput!
    private var isPlaying = true

    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var captionsLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Asset
        guard let url = Bundle.main.url(forResource: "imac7", withExtension: "mp4") else {
            print("can't get url")
            return
        }
        
        vmInput = VideoMediaInput(url: url, delegate: self)

        // Player view
        let playerView: UIView! = view
        playerLayer.player = vmInput.player
        playerLayer.frame = playerView.bounds
        playerView.layer.insertSublayer(playerLayer, at: 0)

        self.setupRecognition()
    }
    @IBAction func didTapPermissionButton(_ sender: UIButton) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                print("Speech recognition authorized")
            case .denied:
                print("Speech recognition authorization denied")
            case .restricted:
                print("Not available on this device")
            case .notDetermined:
                print("Not determined")
            }
        }
    }

    @IBAction func didTapPlayButton(_ sender: UIButton) {
        print("Start playing....")
        if (isPlaying) {
            vmInput.pauseVideo()
            playButton.titleLabel?.text = "Play"
        }else {
            vmInput.playVideo()
            playButton.titleLabel?.text = "Pause"
        }
        isPlaying.toggle()
    }

    private func setupRecognition() {
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        // we want to get continuous recognition and not everything at once at the end of the video
        recognitionRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            self?.captionLabel.text = result?.bestTranscription.formattedString

            // if connected to internet, then once in about every minute recognition task finishes
            // so we need to set up a new one to continue recognition
            if result?.isFinal == true {
                self?.recognitionRequest = nil
                self?.recognitionTask = nil

                self?.setupRecognition()
            }
        }
        self.recognitionRequest = recognitionRequest
    }

    override func viewDidLayoutSubviews() {
        playerLayer.frame = view.bounds
    }
}

extension ViewController: VideoMediaInputDelegate {
    func videoFrameRefresh(sampleBuffer: CMSampleBuffer) {
        recognitionRequest?.appendAudioSampleBuffer(sampleBuffer)
    }
}
