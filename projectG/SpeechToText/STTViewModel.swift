//
//  STTViewModel.swift
//  projectG
//
//  Created by root0 on 2022/09/15.
//

import Foundation
import RxSwift
import RxCocoa

protocol ViewModelType {
    associatedtype Inputs
    associatedtype Outputs
    
    func transform(input: Inputs) -> Outputs
}

final class STTViewModel: ViewModelType {
    
    struct Inputs {
        let recordOpenBtn_tap: Observable<Void>
        let recordBtn_tap: Observable<Void>
    }
    
    struct Outputs {
        var openRecording: Driver<Void>
        var recordAction: Driver<Void>
    }
    
    var speechScript: Driver<String>
    var recordBtnTitle: Driver<String>
    
    var sttModel = STTModel()
    let dBag = DisposeBag()
    
    var speech: SpeechManager!
    
    init() {
        
        speechScript = sttModel.speechScript
            .distinctUntilChanged()
            .map { $0 }
            .asDriver(onErrorRecover: { _ in .empty() })
        
        recordBtnTitle = sttModel.recordBtnTitle
            .distinctUntilChanged()
            .map { $0 }
            .asDriver(onErrorRecover: { _ in .empty() })
        
        speech = SpeechManager(sttModel)
    }
    
    func transform(input: Inputs) -> Outputs {
        
        let openRecording = input.recordOpenBtn_tap
            .map { $0 }
            .asDriver(onErrorRecover: { _ in .empty() })
        
        let recording = input.recordBtn_tap
            .map { $0 }
            .asDriver(onErrorRecover: { _ in .empty() })
        
        return Outputs(openRecording: openRecording, recordAction: recording)
    }
}
