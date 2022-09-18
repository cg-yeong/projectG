//
//  SpeechViewModel.swift
//  projectG
//
//  Created by root0 on 2022/09/15.
//

import Foundation
import Speech
import RxCocoa

class SpeechManager: NSObject { // Apple Speech - STT
    
    weak var sttModel: STTModel!
    
    // Apple Speech
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "ko-KR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var inputNode: AVAudioInputNode?

    init(_ model: STTModel) {
        super.init()
        self.sttModel = model
        speechRecognizer?.delegate = self
        
        prepare()
    }
    
    deinit {
        print("SpeechManager Deinit")
    }
    
}

extension SpeechManager: SFSpeechRecognizerDelegate {
    
    func prepare() {
        // set AudioSession
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("오디오 세션 프로퍼티가 에러로 제대로 세팅되지 못함")
        }
        inputNode = audioEngine.inputNode
    }
    
    func speechAction() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            // recordbtn -> accept or onNext
        } else {
            startRecording()
        }
    }
    
    func startRecording() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel() // or finish()
            recognitionTask = nil
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        guard let inputNode = inputNode else { return }
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { [weak self] (result, error) in
            guard let self = self else { return }
            var isFinal = false
            
            if result != nil {
                print(result!.bestTranscription.formattedString)
                // model.speechScript.accept
                self.sttModel.speechScript.accept(result!.bestTranscription.formattedString)
                // translate
                isFinal = result!.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                // button ui 말하기 시작
                self.sttModel.recordBtnTitle.accept("말하기 시작")
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an \(error.localizedDescription)")
        }
        sttModel.recordBtnTitle.accept("말 멈추기")
    }
    
}
